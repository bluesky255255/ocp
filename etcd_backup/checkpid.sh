#!/bin/bash

retn_value=$(ps -ef | grep backupetcd.sh | wc -l)

if [ $retn_value = 1 ]; then
 exit 0
else
 exit 1 
fi
