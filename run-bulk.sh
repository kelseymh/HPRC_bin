#!/bin/sh
#
# Usage: run-bulk.sh <type> <events> [threads=15]
# Generate DMC events in <type> crystal (iZIP5, iZIP7, NF-C, etc.)
# Uses SimProdMacros directly; get number of events from command line
# Number of worker threads may be specified optionally; default is 15
#
# Non-zero run number can be specfied with RUNNUM envvar
#
# 20200718  Michael Kelsey
# 20210315  Add support for WIMPs with 10 GeV mass option
# 20210319  Add optional number of threads argument

#SBATCH -A 122745056737
#SBATCH -o "%x_%j.log"
#SBATCH --mem=56G
#SBATCH --ntasks=1

# Get command line arguments
det=$1
evt=$2
thr=${3:-15}
run=${RUNNUM:-0}

# Map different detector names to generic "types" (for -f option)
[[ "$det" == iZIP* || "$det" == HV100* || "$det" == CDMSlite* ]] && type=zip
[[ "$det" == HVeV || "$det" == NF-* ]] && type=hvev
[[ "$det" == QIS* ]] && type=qis

# Make sure CDMS environment is set up
[ -z "$CDMS_SUPERSIM" ] && source /scratch/group/mitchcomp/bin/cdms-setup

# Get number of events from command line
time runSourceSim DMC -f $type -v $det -n $evt -m 1e-6 -r $run -t $thr -o `pwd -P` -E

sstat -j $SLURM_JOB_ID.batch --format=jobid,MaxRSS,MaxVMSize,AveCPU,NodeList
