#!/bin/sh
#
# Usage: run-lite.sh <source> <events> [threads=5]
# Generate <source> events in SCDMS Soudan, including G4DMC
# Uses SimProdMacros directly; get number of events from command line
# Number of worker threads may be specified optionally; default is 15
#
# Non-zero run number can be specfied with RUNNUM envvar
#
# 20200718  Michael Kelsey
# 20210315  Add support for WIMPs with 10 GeV mass option
# 20210319  Add optional number of threads argument
# 20210405  Set default to 5 threads for CDMSlite jobs

#SBATCH -A 122745056737
#SBATCH -o "%x_%j.log"
#SBATCH --mem=56G
#SBATCH --ntasks=1

# Get command line arguments                                                    
src=$1
evt=$2
thr=${3:-5}
run=${RUNNUM:-0}

# Use cryo opts for calibration sources (Cf252, Ba133)
[ "$src" = "Cf252" -o "$src" = "Ba133" ] && opts="-p cryo"
[ "$src" = "WIMP" ] && opts="-m 10"

# Make sure CDMS environment is set up
[ -z "$CDMS_SUPERSIM" ] && source /scratch/group/mitchcomp/bin/cdms-setup

# Get number of events from command line
set -e
time runSourceSim $src -f cdmslite $opts -n $evt -r $run -t $thr -o `pwd -P` -E

sstat -j $SLURM_JOB_ID.batch --format=jobid,MaxRSS,MaxVMSize,AveCPU,NodeList
