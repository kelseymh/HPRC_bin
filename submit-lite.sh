#!/bin/sh
# Submit SLURM job to generate SimProdMacros events, using 10 worker threads
#
# Usage: ./submit-lite.sh <source> <Nevents> <threads=5>
#
# NOTE: Non-zero run number may be specified with RUNNUM envvar
#
# 20210312  Michael Kelsey
# 20210321  Allow running from outside this directory
# 20210405  Set default to 5 threads

dir=$(dirname $0)	# Directory to find run-lite.sh script

src=$1
nevt=${2:-100}		# Number of events, use to compute job time, etc.
nthread=${3:-5}		# Number of worker threads

# Job requires one master thread plus worker threads
ncores=$(($nthread + 1))

# Rate of good DMC events vs. total generated events
dmceff=1
case $src in
    Ba133) dmceff=2000 ;;
    Cf252) dmceff=20 ;;
esac

# Estimate job time need; all integer divisions are rounded up
dmcmin=40
dmcevt=$(($nevt / $dmceff + 1 ))	# Number of "good DMC" events in job
mins=$(($dmcevt * $dmcmin / $nthread + 1))	# Wall-clock time, given cores
hours=$(($mins / 60 + 1))

sbatch -J $src -t "${hours}:00:00" --cpus-per-task=$ncores $dir/run-lite.sh $src $nevt $nthread
