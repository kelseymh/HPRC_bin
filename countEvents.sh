#!/bin/sh
#
# Usage: countEvents.sh <logfile>
#
# Evaluates the event processing for SuperSim/G4DMC jobs, with particular
# configuration:
#
# If `/run/printProcess 1` is set, macro can report total number of events
# started during job, and which events ran on which threads.
#
# If ParticleHits or DMC text file is written out, macro can report total
# number of events completed during job.
#
# During normal running, those two values should differ by the number of
# worker threads.  A successfully completed job should have equal values,
# and zero active threads.
#
# 20230503  Michael Kelsey

# If multiple log files specified (e.g., by wildcard), loop over them
if [ $# -gt 1 ]; then
    while [ $# -gt 0 ]; do
	echo "Processing job $1 ..."
	$0 $1
	shift
    done
    exit
fi

log=$1
if [ -z "$log" ]; then
    1>&2 echo "Usage: $0 <logfile>	Log file must be specfied"
    exit 1
elif [ ! -r "$log" ]; then
    1>&2 echo "$0: $log not found."
    exit 2
fi

# Get ParticleHits text file from log file; may be blank
data=`awk '/^Writing.*[0-9].*txt$/{print $5; exit}' $log`

echo "Found $data ParticleHits file"

# Check if /CDMS/reportEvents or /run/printProgress was used
evtMatch="Event"
grep -q 'Preparing Event' $log && evtMatch="Preparing Event"

# Count number of events started during job
nStarted=`grep -wc "$evtMatch" $log`

echo "$nStarted started"

# Count number of completed, written out events
nEvents=0
[ -n "$data" ] && nEvents=`tail -n +5 $data|cut -f1|sort -u|wc -l`

echo "$nEvents written"

# Analyze threading behaviour
[ "$nStarted" -gt 0 ] && nThread=`awk '/^G4WT/{print $1}' $log|sort -u|wc -l`

if [ -n "$nThread" ]; then
    evtDiff=`expr $nStarted - $nEvents`
    echo "$evtDiff of $nThread workers still active"
fi

if [ -n "$nThread" -a "$nStarted" -gt 0 ]; then
    echo ; echo "Event processing by thread"

    [ "$evtMatch" = "Event" ] && field='$5' || field='$6'
    grep -w "$evtMatch" $log |\
	awk '{ evt[$1] = sprintf("%s %s",evt[$1],'"$field"'); }\
	     END { for (tid in evt) { print tid ":" evt[tid]; } }' |\
	sort -k 1.5n
fi
