#!/bin/bash

WORDLIST="./shares.txt"

while read -r share
do
		# Add your target IP
        smbclient //<target>/$share -U "%" >&/dev/null
if [ $? -eq 0 ];  then
        echo "[+] target/$share"
else
        echo "[-] Fail"
fi
