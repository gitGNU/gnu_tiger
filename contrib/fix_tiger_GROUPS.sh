#!/bin/sh

# Script to recursively change "GROUPS" to "TIGER_GROUPS" in
# the tiger source files.  Only run it once (or you'll end up
# with "TIGER_TIGER_GROUPS") and you only need to run it if you 
# are getting an error about "readonly variable GROUPS".  

# Edit this script to reflect the location of your tiger source files.
# ellenm@net.tamu.edu  07/10/2000

PATH_TO_TIGER=/tmp/TIGER

WDIR=/tmp/TIGER-CHGRP

[ ! -d "$PATH_TO_TIGER" ] && {
  echo " "
  echo "Run this script if you are getting a 'readonly variable GROUPS' error."
  echo "If you are not getting this error, you do not need to run the script."
  echo " "
  echo "Edit this script to reflect the location of your tiger files:"
  echo "Change the variable 'PATH_TO_TIGER' and try again."
  echo " "
  exit 1
}

[ ! -d "$WDIR" ] && mkdir "$WDIR"

echo "Processing..."

/bin/find $PATH_TO_TIGER -type f | 
while read file
do
  echo $file
  BASENAME=`basename $file`
  /bin/cp $file $WDIR/$BASENAME.$$
  sed -e 's/GROUPS/TIGER_GROUPS/g' < $WDIR/$BASENAME.$$ > $file
  /bin/rm $WDIR/$BASENAME.$$
done

echo " "
echo "You may want to rmdir $WDIR."

