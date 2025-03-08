#!/bin/sh
#
# Usage: submit_G4DMC.sh <macro> [ arg1 arg2 ... ]
#
# Runs specified macro with command line arguments.  The output log file
# will be assigned the macro name.
#
# 20200216  Michael Kelsey
# 20200225  SLURM can only take shell scripts as input, not commands
# 20200414  Use process ID to make submission scripts unique, clean up at end
# 20200614  Prepare for multithreaded running
# 20201014  Update with current MT batch settings (56 GB, 21 threads, 20 hours)
# 20201028  Check for CDMS setup
# 20201208  Add some SLURM accouting info to running job (for log file)
# 20201211  Update with CDMS Research Account
# 20210224  Preserve path to input macro for execution
# 20210719  Use envvar for memory to allow for overriding, drop manual setting 
#           of account (use |myproject -d|).
# 20250302  Add SBATCH_EXCLUDE here to set --exclude option; not provided by
#	    Slurm itself.

# Environment
[ -z "$CDMS_SUPERSIM" ] && 1>&2 echo "Set up CDMS environment" && exit

# Execution
name=`basename $1 .mac`
macr=`dirname $1`/${name}.mac
shift
doit="CDMS_GGSim $macr $*"

# Create wrapper script suitable for LSF or SLURM
wrap=/tmp/submit_${name}.$$.sh
cat > $wrap <<EOF
#!/bin/sh
/usr/bin/time $doit
echo "======================================================================"
sstat -j \$SLURM_JOB_ID.batch --format=jobid,MaxRSS,MaxVMSize,AveCPU,NodeList
/bin/rm -f $wrap
EOF
chmod +x $wrap

# Log filename includes job arguments to avoid collisions
log=`echo $name $*|tr ' ' '_'`.log

# Terra uses SLURM
# Let user submission scripts override envvars
[ -z "$SBATCH_MEM_PER_NODE" ] && export SBATCH_MEM_PER_NODE=128G
[ -z "$SBATCH_NTHREAD" ] && export SBATCH_NTHREAD=21	# Master + 20 workers
[ -z "$SBATCH_TIMELIMIT" ] && export SBATCH_TIMELIMIT="20:00:00"
[ -n "$SBATCH_EXCLUDE" ]   && doexcl="--exclude=$SBATCH_EXCLUDE"

sbatch -o $log $doexcl --mem=$SBATCH_MEM_PER_NODE --ntasks=1 --cpus-per-task=$SBATCH_NTHREAD $wrap
