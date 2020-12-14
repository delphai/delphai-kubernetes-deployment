#! /usr/bin/env bash
set -e

REPO_NAME=$REPOSITORY_NAME
REPO_SLUG=$GITHUB_REF_SLUG
IMAGE=$INPUT_IMAGE_SHA
HTTPPORT=$INPUT_HTTPPORT
GRPCPORT=$INPUT_GRPCPORT
IS_PUBLIC=$INPUT_IS_PUBLIC
IS_UI=$INPUT_IS_UI
IS_GRPC=$INPUT_IS_GRPC
IS_MICROSERVICE=$INPUT_MICROSERVICE
FILE_SHARES=$INPUT_FILE_SHARES

if [ -z "$IMAGE" ]; then
    echo "Atrifact not set"
    IMAGE="delphai$INPUT_DELPHAI_ENVIROMENT.azurecr.io/${REPO_NAME}:${REPO_SLUG}"
fi

if [ -z "$FILE_SHARES" ]; then
    FILE_SHARES=""
fi

if [ "${REPO_NAME}" == "delphai-ui" ]; then
    REPO_NAME="app"
fi

if [ "${REPO_SLUG}" = "master" ] || [ "$INPUT_DELPHAI_ENVIROMENT" == "GREEN" ] || [ "$INPUT_DELPHAI_ENVIROMENT" == "LIVE" ]; then
    RELEASE_NAME=${REPO_NAME}
else
    RELEASE_NAME=${REPO_NAME}-${REPO_SLUG}
fi

if [ -z "$INPUT_SUBDOMAIN" ]; then
    echo "No Subdomain"
else
    RELEASE_NAME="${REPO_NAME}-$INPUT_SUBDOMAIN"
fi

if [ -z "$INPUT_DOMAINS" ]; then
    DOMAINS=""
else
    DOMAINS=$INPUT_DOMAINS
fi
# Login and set context
az login --service-principal --username $INPUT_CLIENT_ID --password $INPUT_CLIENT_SECRET --tenant $INPUT_TENANT_ID
az aks get-credentials -n delphai-$INPUT_DELPHAI_ENVIROMENT -g tf-cluster 
kubectl config current-context

#Helming
kubectl create namespace ${REPO_NAME} --output yaml --dry-run=client | kubectl apply -f -
kubectl patch serviceaccount default --namespace ${REPO_NAME} -p "{\"imagePullSecrets\": [{\"name\": \"acr-credentials\"}]}"
DOMAIN=$(kubectl get secret domain -o json --namespace default | jq .data.domain -r | base64 -d)
helm repo add delphai https://delphai.github.io/helm-charts && helm repo update

if [ "$INPUT_DELPHAI_ENVIROMENT" == "GREEN" ] || [ "$INPUT_DELPHAI_ENVIROMENT" == "LIVE" ]; then
    DELPHAI_ENVIRONMENT_ENV_VAR=production
else
    DELPHAI_ENVIRONMENT_ENV_VAR=$INPUT_DELPHAI_ENVIROMENT
fi

if  [ "${IS_UI}" == "true" ] && [ "${IS_MICROSERVICE}" == "false" ] ; then
    echo "Using helm delphai-with-ui"
    helm upgrade --install --wait --atomic --reset-values\
          ${RELEASE_NAME} \
          delphai/delphai-with-ui \
          --namespace=${REPO_NAME} \
          --set image=${IMAGE} \
          --set httpPort=${HTTPPORT} \
          --set domain=${DOMAIN} \
          --set domains=${DOMAINS} \
          --set delphaiEnvironment=${DELPHAI_ENVIRONMENT_ENV_VAR} \
          --set subdomain=$INPUT_SUBDOMAIN
    kubectl patch deployment ${RELEASE_NAME} --namespace ${REPO_NAME} -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
elif   [ "${IS_UI}" == "false" ] && [ "${IS_MICROSERVICE}" == "false" ] ; then
    echo "Using helm delphai-knative service"
    helm upgrade --install --wait --atomic --reset-values\
          ${RELEASE_NAME} \
          delphai/delphai-knative-service \
          --namespace=${REPO_NAME} \
          --set image=${IMAGE} \
          --set httpPort=${HTTPPORT} \
          --set grpcPort=${GRPCPORT} \
          --set isPublic=${IS_PUBLIC} \
          --set isUi=${IS_UI} \
          --set domain=${DOMAIN} \
          --set domains=${DOMAINS} \
          --set delphaiEnvironment=${DELPHAI_ENVIRONMENT_ENV_VAR} 
elif  [ "${IS_UI}" == "false" ] && [ "${IS_MICROSERVICE}" == "true" ] ; then
    echo "Using helm delphai-microservice service"
    helm upgrade --install --wait --atomic --reset-values\
          ${RELEASE_NAME} \
          delphai/delphai-microservice \
          --namespace=${REPO_NAME} \
          --set image=${IMAGE} \
          --set replicas=1 \
          --set gatewayPort=7070 \
          --set deployGateway=false\
          --set authRequired=false\
          --set delphaiEnvironment=${DELPHAI_ENVIRONMENT_ENV_VAR} \
          --set domain=${DOMAIN} \
          --set domains=${DOMAINS} \
          --set fileShares=${FILE_SHARES}
fi

# Logs
python3.8 /app/slack-bot/get_logs.py