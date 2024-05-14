#!/bin/sh

# Configuration
oc whoami --kubeconfig=$HOME/kubeconfig
oc version --kubeconfig=$HOME/kubeconfig

APIURL=$(oc cluster-info --kubeconfig=$HOME/kubeconfig | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*")
echo "API url is " $APIURL
CONSOLEURL=$(oc whoami --show-console --kubeconfig=$HOME/kubeconfig)
echo "console url is " $CONSOLEURL
OAUTHURL=$(oc get route -A --kubeconfig=$HOME/kubeconfig | grep oauth | awk '{ print $3 }')
echo "oauth url is " $OAUTHURL

# Set KUBECONFIG
echo "Waiting for OpenShift cluster start..."

  # Wait for API to come online
  until [ $(curl -k -s $APIURL/version?timeout=10s | jq -r '.major' | grep -v null | wc -l) -eq 1 ]
  do
    echo "Waiting for API..."
    sleep 10
  done
  echo "API is up"
  echo "Cluster version is $(oc get clusterversion version -o json --kubeconfig=$HOME/kubeconfig | jq -r '.status.history[0].version')"

  # Wait for router come online
  until [ not $(curl -k -s https://$CONSOLEURL >/dev/null) ]
  do
    echo "Waiting for router..."
    sleep 10 
  done
  echo "Router is up"

  # Wait for authentication come online
  while true
  do
    code=$(curl -k -s https://$OAUTHURL)
    if [[ ! -z ${code} ]] && [[ "${code:0:1}" == "{" ]] && [[ $(echo $code | jq -r '.code') -eq 403 ]]
    then
      break
    fi
    echo "Waiting for authentication..."
    sleep 10
  done
  echo "Authentication is ready"

  # Wait for critical operators come online
  for oper in ingress kube-apiserver
  do
    while true
    do
      RETURN=0
      JSON=$(oc get clusteroperators ${oper} -o json --kubeconfig=$HOME/kubeconfig) || RETURN=1
      [ ${RETURN} -eq 1 ] && echo "Could not reach Openshit API, trying again..."
      FILTER=$(echo ${JSON} | jq -r '.status.conditions[]|select((.status=="True") and (.type=="Progressing"))') || RETURN=1
      if [ ${RETURN} -eq 0 ] && [ "x${FILTER}" == "x" ]
      then
        RETURN=0
        break
      fi
      echo "Waiting for the ${oper} operator to be ready..."
      sleep 10
    done
    echo "The ${oper} operator is ready"
  done

#  # Wait for MCP finish applying changes
#  while true
#  do
#    RETURN=0
#    JSON=$(oc get mcp -o json --kubeconfig=$HOME/kubeconfig) || RETURN=1
#    [ ${RETURN} -eq 1 ] && echo "Could not reach Openshit API, trying again..."
#    FILTER=$(echo ${JSON} | jq -r '.items[].status.conditions[]|select((.status=="True") and (.type=="Updating"))') || RETURN=1
#    if [ ${RETURN} -eq 0 ] && [ "x${FILTER}" == "x" ]
#    then
#      RETURN=0
#      break
#    fi
#    echo "Waiting for Machine Config Operator to finish applying changes..."
#    sleep 10
#  done
#  echo "Machine Config Operator changes applied"

ENDCOLOR="\e[0m"
GREEN="\e[32m"
echo -e "${GREEN}[OK]${ENDCOLOR} OpenShift cluster ready."
