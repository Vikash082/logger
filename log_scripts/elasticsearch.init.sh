#!/bin/sh
#
# chkconfig: 2345 70 40
# description: elasticsearch startup script
# author: Matt Reid
# websites: http://themattreid.com
# license: GPL v2
# date: 2012-12-06
# version: 0000.1
#
ELHOME="/opt/elasticsearch"
ELBIN="$ELHOME/bin/elasticsearch"
ELSRV="$ELHOME/bin/service/elasticsearch"
ELCONF="$ELHOME/bin/service/elasticsearch.conf"
TMPDIR=/dev/shm
LOGFILE="/var/log/elasticsearch.log"

function missing_bin() { 
    echo "Failed to find elasticsearch binary file: [$ELBIN]"; 
    echo "Check /etc/init.d/elasticsearch file for correct settings."
    RETVAL=1; 
    exit 1;
}

function missing_srv() { 
    echo "Failed to find elasticsearch service file: [$ELBIN]"; 
    echo "Check /etc/init.d/elasticsearch file for correct settings."
    RETVAL=1; 
    exit 1;
}

test -f $ELBIN || missing_bin
test -f $ELSRV || missing_srv

. /etc/rc.d/init.d/functions

RETVAL=0

case "$1" in
    start)
    echo -n "Starting elasticsearch: "

    #check to see if we're already running
    pgrep -f ${ELCONF} > /dev/null
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then		    
        echo "[FAILED]"
	    echo	    
	        echo "Reason: elasticsearch is already running."
		    RETVAL=1
		        exit 1;
			fi

			$ELSRV start
			;;
    
    stop)
    echo -n "Shutting down elasticsearch: "
    $ELSRV stop
    RETVAL=$?
    ;;
    
    restart|reload)
    $ELSRV stop
    $ELSRV start
    RETVAL=$?
    ;;
    status)
    $ELSRV status
    RETVAL=$?
    ;;
    console)
    $ELSRV console
    RETVAL=$?
    ;;	
    condrestart)
    $ELSRV condrestart
    RETVAL=$?
    ;;	
    install)
    $ELSRV install
    RETVAL=$?
    ;;	
    remove)
    $ELSRV remove
    RETVAL=$?
    ;;	
    dump)
    $ELSRV dump
    RETVAL=$?
    ;;	
    *)
    echo "Usage: $0 {console | start | stop | restart | condrestart | status | install | remove | dump}"
    exit 1
esac

exit $RETVAL
