#!/bin/bash

# Small port checking utility.
# Usage: ./checkport.sh IP PORT
#
# Based on:
# https://superuser.com/questions/621870/test-if-a-port-on-a-remote-system-is-reachable-without-telnet
# https://serverfault.com/questions/751506/how-can-i-find-out-if-a-port-on-a-remote-server-is-open-as-well-as-a-service-is

output=`nc -zv $1 $2 -w 3 2>&1`

if [[ $output == *"succeeded!"* ]]; then
  echo -e "\e[32mPort is open and service is listening."
elif [[ $output == *"Connection refused"* ]]; then
  echo -e "\e[32mPort is open \e[39mbut \e[93mno service is listening."
elif [[ $output == *"Connection timed out"* ]]; then
  echo -e "\e[31mPort is propably \e[1mNOT\e[21m open."
else
  echo -e "\e[93mCould not determine the port status :("
fi
