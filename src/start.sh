#! /usr/bin/env bash

CHART_NAME=delphai-knative-service
CHART_VERSION=0.1.0
DELPHAI_ENVIROMENT=$INPUT_DELPHAI_ENVIROMENT
APP_ID=$INPUT_CLIENT_ID
PASSWORD=$INPUT_CLIENT_SECRET
TENANT_ID=$INPUT_TENANT_ID
sudo apt-get install jq -y


az login --service-principal --username $APP_ID --password $PASSWORD --tenant $TENANT_ID
az aks get-credentials -n delphai-${DELPHAI_ENVIROMENT} -g tf-cluster 
kubectl config current-context
kubectl get pods --namespace delphai-boilerplate 

PASSWORD=$(az acr credential show --name delphai${DELPHAI_ENVIROMENT} --resource-group delphai-${DELPHAI_ENVIROMENT} | jq .passwords[0].value -r)
helm registry login delphai${DELPHAI_ENVIROMENT}.azurecr.io --username delphai${DELPHAI_ENVIROMENT} --password ${PASSWORD}
helm chart pull delphai${DELPHAI_ENVIROMENT}.azurecr.io/helm/${CHART_NAME}:${CHART_VERSION}


