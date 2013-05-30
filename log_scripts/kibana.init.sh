#!/bin/sh
#
# chkconfig: 2345 70 40
# description: kibana startup script
# author: Matt Reid
# websites: http://themattreid.com
# license: GPL v2
# date: 2012-12-06
# version: 0000.1
#
KHOME="/root/monitor/Kibana-0.2.0"
KBIN="kibana-daemon.rb" #short name
KSRV="$KHOME/kibana-daemon.rb" #script to issue start/stop/etc commands
TMPDIR=/dev/shm
LOGFILE="/var/log/kibana/kibana.log"

function missing_bin() { 
    echo "Failed to find kibana binary file: [$KSRV]"; 
    echo "Check /etc/init.d/kibana file for correct settings."
    RETVAL=1; 
    exit 1;
}

which ruby > /dev/null
if [ $? -ne 0 ]; then 
    echo "Ruby cannot be found. Please install ruby or put in PATH."
    exit 1;
fi

test -f $KSRV || missing_bin

. /etc/rc.d/init.d/functions

RETVAL=0

case "$1" in
    start)
    echo -n "Starting Kibana: "

    #check to see if we're already running
    pgrep -f ${KBIN} > /dev/null
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then		    
        echo "[FAILED]"
	echo	    
	echo "Reason: kibana is already running."
	RETVAL=1
	exit 1;
    fi
    
    ruby $KSRV start
    ;;
    
    stop)
    echo -n "Shutting down Kibana: "
    ruby $KSRV stop
    RETVAL=$?
    ;;
    
    restart|reload)
    ruby $KSRV stop
    ruby $KSRV start
    RETVAL=$?

    ;;
    status)
    ruby $KSRV status
    RETVAL=$?
    ;;

    *)
    echo "Usage: $0 {start | stop | restart | status}"
    exit 1
esac

exit $RETVAL
