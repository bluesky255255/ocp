#!/bin/bash

oc logout
oc login -u admin https://api.ocp4.tingnkai.com:6443 
/home/wccheng/backupetcd.sh
oc logout
