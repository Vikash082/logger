#!/bin/sh
# Date: 2011-07-29, update: 2012-04-23
# Author: Matt Reid
# Function: Decrypts and Encrypts files

function generate_digests() {
    echo "  Input file: $filein"
    openssl dgst -md5 $1
    echo "  Output file: $fileout"
    openssl dgst -md5 $2
}

function header() {
    echo " -------------------------------- "
    echo "|CryptR | security for the masses|"
    echo " -------------------------------- "
    echo "m.reid 2012.04.23 ver 2.68        "
    echo ""
}

function help() {
    echo "Purpose: Encrypts and Decrypts files via AES-256"
    echo "  -e, --encrypt       encrypt the file"
    echo "  -d, --decrypt       decrypt the file"
    echo "  -i, --input         input file to read"
    echo "  -o, --output        output file to write"
    echo ""
}

## Start GetOpt stuff
encrypt="no"    #encrypt function state (e,encrypt)
decrypt="no"    #decrypt function state (d,decrypt)
filein="no"   #filename IN flag (i,input)
fileout="no"  #filename OUT flag (o,output)

while [ $# -gt 0 ]; do
    case $1 in
        -e|--encrypt) encrypt="yes" ;;
        -d|--decrypt) decrypt="yes" ;;
        #long opts need additional shift
        -i|--input) filein="$2" ; shift;;
        -o|--output) fileout="$2" ; shift;;
        (--) shift; break;;
        (-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
        (*) break;;
    esac
    shift
done
## End GetOpt

## Secure delete process
function sdelete() {
    if [ $(uname -s) == 'Darwin' ]; then
        srm $1
    elif [ $(uname -s) == 'Linux' ]; then
        shred -u $1
    fi
}

## Decrypt Process
function decrypt() {
    filein="$1"
    fileout="$2"
    if [ "$filein" = "no" ]; then
        echo -n "No encrypted file specified, what file are we decrypting: "
        read filein
    fi

    if [ -r "$filein" ]; then
        if [ "$fileout" = "no" ]; then
            fileout="$filein.decrypted"
        fi
        openssl enc -d -aes256 -in $filein -out $fileout
        generate_digests $filein $fileout
        exit 0;
    else
        echo "File '$filein' is not readable or does not exist."
        exit 1;
    fi
}

## Encrypt Process
function encrypt() {
    filein="$1"
    fileout="$2"
    if [ "$filein" = "no" ]; then
        echo -n "No input file specified, what file are we encrypting: "
        read filein
    fi

    if [ -r "$filein" ]; then
        if [ "$fileout" = "no" ]; then
            fileout="$filein.aes256"
        fi
        if [ -f "$fileout" ]; then
            echo "Output file exists already, encrypting will overwrite this file."
            echo -n "Do you want to encrypt anyway? [Y/n]: "
            read choice
            if [ "$choice" = "Y" ] || [ "$choice" = "y" ] || [ "$choice" = "" ]; then
                openssl enc -aes256 -in $filein -out $fileout
                generate_digests $filein $fileout
                sdelete $filein
                exit 0;
            else
                exit 2;
            fi
        else
            openssl enc -aes256 -in $filein -out $fileout
            generate_digests $filein $fileout
            sdelete $filein
            exit 0;
        fi
    else
        echo "Input file does not exist or is not readable. You're attempting to encrypt file: '$filein'"
        exit 1;
    fi
}

if [ "$encrypt" = "yes" ] && [ "$decrypt" = "no" ]; then
    encrypt $filein $fileout
elif [ "$decrypt" = "yes" ] && [ "$encrypt" = "no" ]; then
    decrypt $filein $fileout
else
    #clear
    header
    help
fi

