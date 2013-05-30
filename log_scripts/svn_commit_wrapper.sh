#!/bin/sh
HERE=`pwd`
VER=`svnversion |awk -F: {'print $2'}|sed 's/M//g'|sed 's/S//g'`
if [ "$VER" = "" ]; then
    VER=`svnversion |sed 's/M//g'|sed 's/S//g'`
fi
NVER=`expr $VER + 1`
echo $NVER > $HERE/version.txt
echo "updated verion.txt to revision: $NVER"
svn commit
