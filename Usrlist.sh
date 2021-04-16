#!/bin/bash
path=$(cat /etc/shadow | grep -v "*" | grep -v "\!")
for value in $path; do 
	user=$(echo $value | cut -d: -f1)
	pass=$(echo $value | cut -d: -f2)
	echo "$user:$pass"
done
