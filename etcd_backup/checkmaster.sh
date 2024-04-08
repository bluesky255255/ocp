#!/bin/bash

oc logout
oc login -u admin https://api.ocp4.tingnkai.com:6443
retn_value=$(oc get node | grep master | grep  -E '(^|\s)Ready($|\s)' | wc -l)
oc logout

if [ $retn_value = 3 ]; then
 exit 0
else
 exit 1 
fi
