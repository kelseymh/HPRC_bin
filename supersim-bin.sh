#!/bin/sh
#
# Copy bin, lib, tmp from $G4WORKDIR to $CDMS_SUPERSIM for other users

cd $CDMS_SUPERSIM
/bin/rm -rf bin lib tmp

# Start by transferring everyting
cp -r $G4WORKDIR/bin bin
cp -r $G4WORKDIR/lib lib
cp -r $G4WORKDIR/tmp tmp

chmod -R g+w bin lib tmp

# Remove everything which isn't SuperSim-specific
ls -1d bin/$G4SYSTEM/*|grep -v CDMS|xargs /bin/rm -rf
ls -1d lib/$G4SYSTEM/*|grep -v CDMS|xargs /bin/rm -rf
ls -1d tmp/$G4SYSTEM/*|grep -v CDMS|xargs /bin/rm -rf
