#!/bin/bash
#
# Usage: submit_valgrind.sh <macro> [ arg1 arg2 ... ]
#
# Runs specified macro with command line arguments in the CDMS offline
# release container, using Valgrind.  The output log file will be
# assigned the macro name.
#
# Specify Valgrind tool using VTOOL=name (default is memcheck)
# Specify CDMS executable with CDMSBIN=name (default is CDMS_G4DMC)
#
# 20251031  Rewrite to invoke submit_sing.sh with Valgrind as CDMSBIN

# Get override definitions
[ -z "$VTOOL" ] && VTOOL=memcheck
[ -z "$CDMSBIN" ] && CDMSBIN=CDMS_G4DMC

# Set up to invoke valgrind as the "executable"
noroot="\$ROOTSYS/etc/valgrind-root.supp"
export CDMSBIN="valgrind --tool=$VTOOL --suppressions=$noroot $CDMSBIN"

submit_sing.sh $*
