#!/bin/sh
################################################################################
## Kontrollkit
## NAME: kt-rotate-logs.sh
## DATE: 2008-10-01
## AUTHOR: Matt Reid & Jim Wood
## WEBSITE: http://kontrollsoft.com
## EMAIL: themattreid@gmail.com
## LICENSE: BSD http://www.opensource.org/licenses/bsd-license.php
################################################################################
## Copyright 2008 Matt Reid
## All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##################################################################################
#
## WHAT THIS SCRIPT DOES #########################################################
#rotates mysql general and slow logs on a periodic basis when run from crontab
####
#/etc/crontab entry
# MySQL rotate logs
#05 * * * * root /usr/local/bin/mysql_rotatelogs > /dev/null 2>&1
####
# SET OPTIONS HERE
ROTATE_SLOW="1" # 0 for no rotation, 1 for yes
ROTATE_GENERAL="1" # 0 for no rotation, 1 for yes
MYUSER="root" #username
MYPASS="nGEdcbrQlPkL" #password
LOG_DIR="/var/lib/mysql" #location of mysql log files
ROTATE_DIR="/home/mysql-backups/archive" #location to rotate files to
GEN_LOG="mysql-gen.log" #general query log name
SLOW_LOG="mysql-slow.log" #slow query log name
#### DO NOT EDIT BELOW HERE ######
##################################################################################
export LOG_DIR ROTATE_DIR GEN_LOG SLOW_LOG DSTAMP MYUSER MYPASS
DSTAMP=`date '+%d%m%G-%H%M%S'`

# Zero the vars
GEN_SIZE=0
GEN_LIMIT=0
SLOW_SIZE=0
SLOW_LIMIT=0
DONE_GEN=0
DONE_SLOW=0

# Rotate General log
rotate_gen ()
{
    #echo "GEN Log is " ${GEN_SIZE}
    mv ${LOG_DIR}/${GEN_LOG} ${ROTATE_DIR}/${GEN_LOG}.${DSTAMP}
}

# Rotate Slow log
rotate_slow ()
{
    #echo "SLOW Log is " ${SLOW_SIZE}
    mv ${LOG_DIR}/${SLOW_LOG} ${ROTATE_DIR}/${SLOW_LOG}.${DSTAMP}
}

start_func() {
# Flush and compress accordingly
    test -d ${ROTATE_DIR} || mkdir -p ${ROTATE_DIR}
    if [ "$ROTATE_GENERAL" = "1" ]; then
	GEN_SIZE=`ls -l ${LOG_DIR}/${GEN_LOG} | awk -F" " '{ print $5 }'`
	GEN_LIMIT=500
	#echo "GEN_SIZE=$GEN_SIZE"
	#echo "GEN_LIMIT=$GEN_LIMIT"
	if [ ${GEN_SIZE} -gt ${GEN_LIMIT} ]; then
	    STATE_GEN="1"
	    rotate_gen
	fi
    fi
    if [ "$ROTATE_SLOW" = "1" ]; then
	SLOW_SIZE=`ls -l ${LOG_DIR}/${SLOW_LOG} | awk -F" " '{ print $5 }'`
	SLOW_LIMIT=1500
        #echo "SLOW_SIZE=$SLOW_SIZE"
        #echo "SLOW_LIMIT=$SLOW_LIMIT"
	if [ ${SLOW_SIZE} -gt ${SLOW_LIMIT} ]; then
	    STATE_SLOW="1"
	    rotate_slow
	fi
    fi
    
    # Flush MySQL Logs
    /usr/bin/mysqladmin --user="$MYUSER" --password="$MYPASS" flush-logs
    
    # Compress rotated logs
   if [ "$STATE_GEN" = "1" ]; then
       /bin/gzip ${ROTATE_DIR}/${GEN_LOG}.${DSTAMP}
   fi
   if [ "$STATE_SLOW" = "1" ]; then
       /bin/gzip ${ROTATE_DIR}/${SLOW_LOG}.${DSTAMP}
   fi
}

start_func
