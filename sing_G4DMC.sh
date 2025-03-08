#!/bin/sh
#
# Usage: sing_G4DMC.sh <macro> [ arg1 arg2 ... ]
#
# Submit batch job to run specified macro with command line arguments in
# Latest offline release container.  The output log file will be assigned
# the macro name.
#
# 20250208  Michael Kelsey -- Adapted from submit_G4DMC.sh

# Execution
name=`basename $1 .mac`
macr=`dirname $1`/${name}.mac
shift
doit="CDMS_G4DMC $macr $*"

# Create wrapper script suitable for Slurm

wrap=/tmp/submit_${name}.$$.sh
cat > $wrap <<EOF
#!/bin/bash
#SBATCH --export=NONE
#SBATCH --get-user-env=L
module load scdms-singularity
singularity-exec $doit
sstat -j \$SLURM_JOB_ID.batch --format=jobid,MaxRSS,MaxVMSize,AveCPU,NodeList
/bin/rm -f $wrap
EOF
chmod +x $wrap

# Log filename includes job arguments to avoid collisions
log=`echo $name $*|tr ' ' '_'`.log

# Terra uses SLURM
# Let user submission scripts override envvars
[ -z "$SBATCH_MEM_PER_NODE" ] && export SBATCH_MEM_PER_NODE=128G
[ -z "$SBATCH_NTHREAD" ] && export SBATCH_NTHREAD=21  # Master + 20 workers
[ -z "$SBATCH_TIMELIMIT" ] && export SBATCH_TIMELIMIT="20:00:00"

sbatch -o $log --mem=$SBATCH_MEM_PER_NODE --ntasks=1 --cpus-per-task=$SBATCH_NTHREAD $wrap
