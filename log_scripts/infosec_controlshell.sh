#!/bin/bash
NAME="Auditcontrol Menu v2.1"
#runs security programs:
#nmap, nessus, nikto, ghba, dnascan, dig, whois for auditing purposes
#by Matt Reid matthew@servepath.com / themattreid@gmail.com

##################################
#MY SHELL - LOCAL SCANNER
##################################

#Set file locations - modify as needed
#ROOTDIR is where nikto/dna/ghba progs live
ROOTDIR="/home/adminsp/security"
REPORTDIR="/home/adminsp/reports"
DIG=`which dig`
GHBA="$ROOTDIR/ghba"
WHOIS=`which whois`
NIKTO="$ROOTDIR/nikto/nikto.pl"
NIKTOCONFIG="$ROOTDIR/nikto/config.txt"
DNASCAN="$ROOTDIR/dnascan.pl"
NESSUS=`which nessus`
NMAP=`which nmap`
NESSUSUSER="adminsp"
NESSUSPASS="1980isahardONE"
NESSUSIP="localhost"
NESSUSPORT="1241"
DATE=`date +"%a.%b.%Y.%T"`
UNIXDATESTART=`date +"%s"`
FINALREPORT="$REPORTDIR/Audit.Report_CRID=$CRID.$DATE"

################################
#these args are no longer in use
HOST=$2
EMAIL=$3
CRID=$4
################################

#begin scanning functions
#
function write2file {
    echo -n  "Save report to file? [no]: "
    read CONFIRM
    if [ "$CONFIRM" = "" ]; then
        echo "Not saving file."
	echo ""
    elif [ "$DISPLAYREPORT" = "no" ]; then
        echo "Not saving file."
	echo ""
    else
        echo -n "Save file as: "
	read SAVEAS
	touch $SAVEAS && cat $FINALREPORT > $SAVEAS
    fi
}

function scanTime {
    UNIXDATEEND=`date +"%s"`
    SCANTOTAL=$(($UNIXDATEEND - $UNIXDATESTART))
    echo ""
    echo "Scan took this many seconds: $SCANTOTAL"
}

function email {
        #redefine $DATE to get current time
        DATE=`date +"%a.%b.%Y.%T"`
        MAILREPORT=`mail -v -s "Audit Report for $CRID / $IPADDRESS / $HOST on $DATE" $EMAIL < $FINALREPORT`
        echo "Emailed report: [$FINALREPORT] to [$EMAIL] on $DATE"
}

function display {
        echo ""
        echo -n "Press ENTER for report. "
	read NULLVAR
	clear
	echo ""
	echo "##########################"
	echo ""
        cat $FINALREPORT
	echo ""
	echo "##########################"
	echo ""
}

function reporter {
    if [ "$EMAIL" = "" ]; then
	scanTime
	display
	write2file
    else 
    echo -n "Display Report? [no]"
    read DISPLAYREPORT
        if [ "$DISPLAYREPORT" = "" ]; then
	    scanTime
	    email
	elif [ "$DISPLAYREPORT" = "no" ]; then
	    scanTime
	    email
	else 
	    scanTime
	    email
	    display
	    write2file
	fi
    fi
}

function nmapPing {
    REPORTNAME="$REPORTDIR/nmap.ping.report_$CRID_.$DATE.nor"
    echo "Running NMap Ping Scan...."
    scan=`sudo $NMAP -sP -v -oN $REPORTNAME $IPADDRESS`
    echo "#### NMAP PING SCAN ####" >> $FINALREPORT
    cat $REPORTNAME >> $FINALREPORT
}

function nmapStealth {
    REPORTNAME="$REPORTDIR/nmap.stealth.report_$CRID_.$DATE.nor"
    echo "Running NMap Stealth Port Scan..."
    scan=`sudo $NMAP -sS -v -T Aggressive -O -oN $REPORTNAME $IPADDRESS`
    echo "#### NMAP STEALTH SCAN ####" >> $FINALREPORT
    cat $REPORTNAME >> $FINALREPORT
}

function niktoScan {
    REPORTNAME="$REPORTDIR/nikto.report_$CRID_.$DATE.html"
    #Faster scan =>20 minutes 
    echo "Running Nikto Web Vuln Scan... this could take a while."
    scan=`$NIKTO -config $NIKTOCONFIG -cookies -Format htm -o $REPORTNAME -host $IPADDRESS`
    #Slow scan but very thorough - I'm talking hours!
    #echo "Running Nikto Web Vuln Scan. This is the long one!
    #scan=`$NIKTO -config $NIKTOCONFIG -cookies -Cgidirs all -evasion 9 -Format htm -o $REPORTNAME -host $IPADDRESS`
    echo "#### NIKTO SCAN ####" >> $FINALREPORT
    cat $REPORTNAME >> $FINALREPORT
}

function nessusScan {
    REPORTNAME="nessus.report.txt"
    HOSTFILE="$REPORTDIR/nessus_IP_Scan_$CRID_.$DATE.foo"
    HOST2SCAN=`echo $IPADDRESS > $HOSTFILE`
    echo "Running Nessus Scan... this could take a while."
    scan=`$NESSUS -q -T txt $NESSUSIP $NESSUSPORT $NESSUSUSER $NESSUSPASS $HOSTFILE $REPORTNAME`
    rm $HOSTFILE
    echo "#### NESSUS SCAN ####" >> $FINALREPORT
    cat $REPORTNAME >> $FINALREPORT
}

function dnaScan {
    REPORTNAME="$REPORTDIR/DNA_$CRID_report.$DATE.txt"
    echo "Running DNA Scan..."
    scan=`$DNASCAN http://$IPADDRESS > $REPORTNAME`
    echo "#### DNA SCAN ####" >> $FINALREPORT
    cat $REPORTNAME >> $FINALREPORT
}

function ghbaScan {
    REPORTNAME="$REPORTDIR/GHBA_$CRID_report.$DATE.txt"
    echo "Running GHBA Scan..."
    scan=`$GHBA $IPADDRESS -f $REPORTNAME`
    echo "#### GHBA SCAN ####" >> $FINALREPORT
    cat $REPORTNAME >> $FINALREPORT
}

function whoisScan {
    if [ "$HOST" = "" ]; then
	echo "Hostname NULL, Not running WHOIS Scan."
    else
	REPORTNAME="$REPORTDIR/WhoIS_$CRID_report.$DATE.txt"
	echo "Running WhoIS Scan..."
	scan=`$WHOIS $HOST > $REPORTNAME`
	echo "#### WHOIS SCAN ####" >> $FINALREPORT
	cat $REPORTNAME >> $FINALREPORT
    fi
}

function digScan {
    if [ "$HOST" = "" ]; then
	echo "Hostname NULL, not running DIG Scan."
    else
	REPORTNAME="$REPORTDIR/Dig_$CRID_report.$DATE.txt"
	echo "Running Dig Scan..."
	scan=`$DIG $HOST any > $REPORTNAME`
	cat $REPORTNAME >> $FINALREPORT
    fi
}

function helpMeMenu {
    clear
    echo "$NAME"
    echo ""
    echo "1. Run All Audits"
    echo "2. NMap Ping Scan [ip/net/domain]"
    echo "3. NMap Stealth Port Scan [ip/net/domain]"
    echo "4. Nikto Web Vuln Scan [ip/domain]"
    echo "5. Nessus Vuln Scan [ip/net/domain]"
    echo "6. DNA ASP Vuln Scan [ip/domain]"
    echo "7. GHBA RNDS Scan [ip/net]"
    echo "8. WhoIs Scan [domain]"
    echo "9. Dig Scan [domain]"
    echo "   -ctrl-c to quit"
    echo ""
    echo "ip= xxx.xxx.xxx.xxx"
    echo "net= xxx.xxx.xxx.xxx/xx"
    echo "domain= mydomain.com"
    echo ""
    echo -n "Enter an Audit Choice: "
    read MENUCHOICE
    echo ""
    echo -n "Enter the IP/Net-Block to scan [none]: "
    read IPADDRESS
    echo -n "Enter the Domain to scan [none]: "
    read HOST
    echo -n "Enter the email address to report to [none]: "
    read EMAIL
    echo -n "Enter the CRID of the server [none]: "
    read CRID
    echoVars
    UNIXDATESTART=`date +"%s"`
    
    case $MENUCHOICE in
	"1") 
	     nmapPing
	     ghbaScan
	     whoisScan
	     digScan
             nmapStealth
	     dnaScan
             niktoScan
             nessusScan
             reporter
	     echo -n "All Scans Finished. Press Enter. "
	     read NULLKEY
	     clear
	     helpMeMenu
	     ;;
        "2") nmapPing
	     reporter
             echo -n "Ping Scan Finished. Press Enter. "
             read NULLKEY
             clear
             helpMeMenu
	;;
        "3") nmapStealth
             reporter
             echo -n "Stealth Scan Finished. Press Enter. "
             read NULLKEY
             clear
             helpMeMenu
        ;;
        "4") niktoScan
             reporter
             echo -n "Nikto Scan Finished. Press Enter. "
             read NULLKEY
             clear
             helpMeMenu
        ;;
        "5") nessusScan
             reporter
             echo -n "Nessus Scan Finished. Press Enter. "
             read NULLKEY
             clear
             helpMeMenu
        ;;
        "6") dnaScan
             reporter
             echo -n "DNA Scan Finished. Press Enter. "
             read NULLKEY
             clear
             helpMeMenu
        ;;
        "7") ghbaScan
             reporter
             echo -n "GHBA Scan Finished. Press Enter. "
             read NULLKEY
             clear
             helpMeMenu
        ;;
        "8") whoisScan
             reporter
             echo -n "WhoIS Scan Finished. Press Enter. "
             read NULLKEY
             clear
             helpMeMenu
        ;;
        "9") digScan
             reporter
             echo -n "Dig Scan Finished. Press Enter. "
             read NULLKEY
             clear
             helpMeMenu
        ;;
	"") echo ""
	    echo -n "YOU DIDN'T CHOOSE AN AUDIT!!!!"
	    read NULLKEY
	    helpMeMenu
	;;
    esac
}

function echoVars {
    echo ""
    echo "#############################################################################"
    echo "Scanning CRID: $CRID on IP/NET-BLOCK: $IPADDRESS for HOST: $HOST"
    echo "Emailing Report to: $EMAIL"
    echo "#############################################################################"
    echo ""
}

#This is the money shot
helpMeMenu

