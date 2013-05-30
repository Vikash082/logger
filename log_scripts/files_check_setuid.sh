#!/bin/sh

#find SUID and SGID files
echo "Finding SUID and SGID files..."
sudo find / \( -perm -4000 -o -perm -2000 \) -type f -exec file {} \; | grep -v ELF

#find SUID and SGID directories
echo "Finding SUID and SGID directories..."
sudo find / -type d \( -perm -g+w -o -perm -o+w \) -exec ls -lad {} \;

#check for listening sockets
echo "Checking for listening sockets..."
sudo netstat -luntp
