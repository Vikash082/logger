#!/bin/sh
HOST="localhost"
USER="root"
PASS="pass"

DBS=`mysql -u$USER --password=$PASS --host=$HOST -s -e "show databases"`

for each in $DBS; do 
    DB=$each
    if [ $DB = "Database" ]; then
	echo ""	
    else 
	TABLE=`mysql -u$USER --password=$PASS --host=$HOST -s -e "show tables" $DB`	    
	echo "$DB.$TABLE"
    fi
done
