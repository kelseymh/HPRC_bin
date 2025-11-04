#!/usr/bin/awk -f
/^G4WT.* Event /{ evt[$1]=$5; }
END{for (t in evt) { print t,evt[t]; }}
