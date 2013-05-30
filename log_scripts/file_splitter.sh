#!/bin/sh

# spitter - splits a file into parts for parallel transfer

test "$4" || { echo "usage: $0 filename chunksize remote-host remote-dir"; exit 1; }

INFILE=$1
CHUNKSIZE=$2
REMOTEHOST=$3
REMOTEDIR=$4

test -s ${INFILE} || { echo "File is inaccessible or zero length"; exit 1; }
test -w $PWD || { echo "No write permission on current directory."; exit 1; }
#test -f combine.sh || { echo "Cannot find combine.sh. Aborting."; exit 1; }

# see if we can reach the remote host
ping -c 1 -W 5 $REMOTEHOST >/dev/null 2>/dev/null
test $? -eq 0 || { echo "Unable to ping $REMOTEHOST"; exit 1; }

#echo "local md5: `md5sum ${INFILE}`"
#md5sum -b ${INFILE} >${INFILE}.md5

split --bytes=${CHUNKSIZE} --numeric-suffixes $1 $1.split.
test $? -eq 0 || { echo "Error during split. Make sure you use a chunk size that results in 100 or fewer chunks. Aborting."; exit 1; }

echo "parallel scp started - see scp.log for progress."
echo "run combine.sh on other side when xfer completed."

# send over the recombination script
./scpwrap.sh combine.sh ${REMOTEDIR} ${REMOTEHOST}

for i in `ls ${INFILE}.split.*`; do
  ./scpwrap.sh $i ${REMOTEDIR} ${REMOTEHOST} >> scp.log &
  sleep 1   ## slight pause
done
#./scpwrap.sh ${INFILE}.md5 ${REMOTEDIR} ${REMOTEHOST} >> scp.log
