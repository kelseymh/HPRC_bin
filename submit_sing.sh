#!/bin/sh
#
# Usage: submit_sing.sh <macro> [ arg1 arg2 ... ]
#
# Submit batch job to run specified macro with command line arguments in
# latest offline release container.  The output log file will be assigned
# the macro name.
#
# Envvar CDMSBIN specifies which executable to use; default is CDMS_G4DMC
# Envvar USECDMS specifies a SuperSim build directory to use
# Envvar RELEASE specifies a particular Offline Release container
#
# 20251031  Michael Kelsey -- Generalized from sing_G4DMC.sh
# 20260812  Add RELEASE to support selecting past containers

# Get SuperSim executable name
[ -z "$CDMSBIN" ] && CDMSBIN=CDMS_G4DMC

# Execution
name=`basename $1 .mac`
macr=`dirname $1`/${name}.mac
shift
doit="$CDMSBIN $macr $*"

# Create internal wrapper for singularity-shell, including SuperSim setup
if [ -n "$USECDMS" -a -d "$USECDMS" ]; then
    usecdms="source $USECDMS/CDMSbuild/g4setup.sh"
fi

singwrap=$PWD/sing_${name}.$$.sh
cat > $singwrap <<EOF
#!/bin/bash
echo "Starting $singwrap ..."
cd $PWD
if [ -n "$usecdms" ]; then
    unset CDMS_SUPERSIM G4CMPINSTALL G4CMPLIB G4CMPINCLUDE G4WORKDIR
    $usecdms
fi
echo "=========="
echo "Verifying SuperSim version information:"
$CDMSBIN --version
echo "=========="
$doit
EOF
chmod +x $singwrap

# Create wrapper script suitable for Slurm
jobwrap=/tmp/submit_${name}.$$.slrm
cat > $jobwrap <<EOF
#!/bin/bash
#SBATCH --export=NONE
#SBATCH --get-user-env=L
echo "Starting $jobwrap ..."
module load scdms-singularity${RELEASE:+/}${RELEASE}
singularity-exec $singwrap
sstat -j \$SLURM_JOB_ID.batch --format=jobid,MaxRSS,MaxVMSize,AveCPU,NodeList
/bin/rm -f $singwrap $jobwrap
EOF
chmod +x $jobwrap

# Log filename includes job arguments to avoid collisions
log=`echo $CDMSBIN|cut -f1 -d' '`_${name}_`echo $*|tr ' ' '_'`.log

# Let user submission scripts override envvars
[ -z "$SBATCH_MEM_PER_NODE" ] && export SBATCH_MEM_PER_NODE=128G
[ -z "$SBATCH_NTHREAD" ] && export SBATCH_NTHREAD=21  # Master + 20 workers
[ -z "$SBATCH_TIMELIMIT" ] && export SBATCH_TIMELIMIT="20:00:00"
[ -n "$SBATCH_EXCLUDE" ]   && doexcl="--exclude=$SBATCH_EXCLUDE"

sbatch -o $log $doexcl --mem=$SBATCH_MEM_PER_NODE --ntasks=1 --cpus-per-task=$SBATCH_NTHREAD $jobwrap
