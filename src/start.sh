#! /usr/bin/env bash

DELPHAI_ENVIROMENT=$INPUT_DELPHAI_ENVIROMENT
APP_ID=$INPUT_CLIENT_ID
PASSWORD=$INPUT_CLIENT_SECRET
TENANT_ID=$INPUT_TENANT_ID

az login --service-principal --username $APP_ID --password $PASSWORD --tenant $TENANT_ID
az aks get-credentials -n delphai-${DELPHAI_ENVIROMENT} -g tf-cluster 
kubectl config current-context
kubectl get pods --namespace delphai-boilerplate 
