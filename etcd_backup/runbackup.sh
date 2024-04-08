#!/bin/bash

oc logout
oc login -u admin https://api.ocp4.tingnkai.com:6443 
/root/backupetcd.sh
oc logout
