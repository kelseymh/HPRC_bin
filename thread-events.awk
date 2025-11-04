#!/usr/bin/awk -f
/^G4WT.* Event /{ n[$1]++ }
END { for (t in n) { print t,n[t]; }}
