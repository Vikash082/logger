#!/bin/sh
echo ">>>> Shell Copy >>>>"
echo ""
HOST=$1
BIN=`which scp`
if test -z $HOST
then
    echo "You must specify a hostname or ip address as the first argument"
    exit 1
fi

echo "Starting copy process for host: $HOST"
FILES=".bashrc .emacs .emacs.d .bash_logout .bash_profile"
for file in $FILES; do
    cd $HOME
    echo -n "Copying file[$file]: "
    flag=''
    if [ -d $file ]; then flag=-r; fi
    echo "$BIN $flag $file $HOST:."
    $BIN $flag $file $HOST:.
    if [ $? -ne 0 ]; then
	echo "[FAILED]"
	exit 2
    fi
    echo "[OK]"
done

#echo -n "Copy .my.cnf file as well? [y,N]"
#if [ "$REPLY" = y ]; then
#    echo -n "Copying file[$file]: "
#    $BIN ~/.my.cnf $HOST:.
#fi

echo ""
echo "Finished copying shell files to host: $HOST"
echo ""
exit 0