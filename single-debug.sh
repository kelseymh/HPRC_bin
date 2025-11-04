#!/bin/bash
#
# Usage: ./single-debug.sh <eventfile>|<eventnum> <logfile>
#
# Uses the "eventfile", which should consist of lines of the form
#     G4WT# nnnnnn
# indicating the thread and event number where a job got stuck, the last event
# processed by that thread; this file may nave been generated using
# ./thread-last.awk.  The log file must be from the same job, where those
# events had verbosity enabled.
#
# The script extracts all output for the specified event (which may not be
# on the same thread shown in the event-file), and writes it to a file named
# "single_nnnnnn.log".
#
# 20250417  Michael Kelsey

# Get command line arguments
export EVTFILE=$1
export LOGFILE=$2

if [ -z "$EVTFILE" -o -z "$LOGFILE" ]; then
    echo "Usage: $0 <eventfile> <logfile>"
    exit 1
fi

# Define function to process single event and extract info
function pull_event() {
    event=$1

    # Get thread ID for event from log file
    thread=`awk "/^G4WT.* Event $event /"' { print $1; exit; }' $LOGFILE`

    echo "Processing event $event, thread $thread ..."

    # Pick off all the debugging output for that event, using thread ID
    TRKINFO=stuck_${event}.log
    egrep "^($thread |(?!G4WT))" $LOGFILE |\
      sed -n "/Event $event /,/--> Event/p" > $TRKINFO
}

# Process first argument as file of events, or just a number
if [ -r $EVTFILE ]; then
    while read _ event; do
	pull_event $event
    done < $EVTFILE
else
    pull_event $EVTFILE
fi
