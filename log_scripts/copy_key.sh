#!/bin/sh
USERNAME="mreid"
if test -z $1
then
    echo "you must specify a hostname or ip address as the first argument"
    exit 1
fi
key=`cat ~/.ssh/id_dsa.pub`
ssh $USERNAME@$1 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo \"$key\" >> ~/.ssh/authorized_keys && chmod 644 ~/.ssh/authorized_keys"
if [ $? = "0" ]; then
    echo "key copy successful"
else
    echo "key copy failed"
fi