#! /usr/bin/env bash
set -e

if [ -z "$INPUT_IMAGE_SHA" ]; then
    IMAGE="delphai$INPUT_DELPHAI_ENVIROMENT.azurecr.io/$REPOSITORY_NAME:$GITHUB_REF_SLUG"
else
    IMAGE=$INPUT_IMAGE_SHA
fi


if [ -z "$INPUT_FILE_SHARES" ]; then
    FILE_SHARES=""
else
    FILE_SHARES=$INPUT_FILE_SHARES
fi

if [ "$GITHUB_REF_SLUG" = "master" ] || [ "$INPUT_DELPHAI_ENVIROMENT" == "GREEN" ] || [ "$INPUT_DELPHAI_ENVIROMENT" == "LIVE" ]; then
    RELEASE_NAME=$REPOSITORY_NAME
else
    RELEASE_NAME="$REPOSITORY_NAME-$GITHUB_REF_SLUG"
fi

if [ -z "$INPUT_SUBDOMAIN" ]; then
    echo "No Subdomain"
else
    RELEASE_NAME="$REPOSITORY_NAME-$INPUT_SUBDOMAIN"
fi

if [ -z "$INPUT_DOMAINS" ]; then
    DOMAINS=""
else
    DOMAINS=$INPUT_DOMAINS
fi
# Azure Login and set kubernetes cluster context
az login --service-principal --username $INPUT_CLIENT_ID --password $INPUT_CLIENT_SECRET --tenant $INPUT_TENANT_ID
az aks get-credentials -n delphai-$INPUT_DELPHAI_ENVIROMENT -g tf-cluster 
kubectl config current-context

# Create namespace - patch service principle - set domain variable 
kubectl create namespace $REPOSITORY_NAME --output yaml --dry-run=client | kubectl apply -f -
kubectl patch serviceaccount default --namespace $REPOSITORY_NAME -p "{\"imagePullSecrets\": [{\"name\": \"acr-credentials\"}]}"
DOMAIN=$(kubectl get secret domain -o json --namespace default | jq .data.domain -r | base64 -d)

# Helm
helm repo add delphai https://delphai.github.io/helm-charts && helm repo update

if [ "$INPUT_DELPHAI_ENVIROMENT" == "GREEN" ] || [ "$INPUT_DELPHAI_ENVIROMENT" == "LIVE" ]; then
    DELPHAI_ENVIRONMENT_ENV_VAR=production
else
    DELPHAI_ENVIRONMENT_ENV_VAR=$INPUT_DELPHAI_ENVIROMENT
fi

# Helm Delphai with Ui
if  [ "$INPUT_IS_UI" == "true" ] && [ "$INPUT_IS_GRPC" == "false" ] ; then
    echo "Using helm delphai-with-ui"
    helm upgrade --install --wait --atomic --reset-values\
          ${RELEASE_NAME} \
          delphai/delphai-with-ui \
          --namespace=$REPOSITORY_NAME \
          --set image=${IMAGE} \
          --set httpPort=$INPUT_HTTPPORT \
          --set domain=${DOMAIN} \
          --set domains=${DOMAINS} \
          --set delphaiEnvironment=${DELPHAI_ENVIRONMENT_ENV_VAR} \
          --set subdomain=$INPUT_SUBDOMAIN
    kubectl patch deployment ${RELEASE_NAME} --namespace $REPOSITORY_NAME -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"

elif   [ "$INPUT_IS_UI" == "false" ] && [ "$INPUT_IS_GRPC" == "false" ] ; then
    echo "Using helm delphai-knative service"
    helm upgrade --install --wait --atomic --reset-values\
          ${RELEASE_NAME} \
          delphai/delphai-knative-service \
          --namespace=$REPOSITORY_NAME \
          --set image=${IMAGE} \
          --set httpPort=$INPUT_HTTPPORT \
          --set grpcPort=$INPUT_GRPCPORT \
          --set isPublic=$INPUT_IS_PUBLIC \
          --set isUi=$INPUT_IS_UI \
          --set domain=${DOMAIN} \
          --set domains=${DOMAINS} \
          --set delphaiEnvironment=${DELPHAI_ENVIRONMENT_ENV_VAR} 

elif  [ "$INPUT_IS_UI" == "false" ] && [ "$INPUT_MICROSERVICE" == "true" ] ; then
    echo "Using helm delphai-microservice service"
    helm upgrade --install --wait --atomic --reset-values\
          ${RELEASE_NAME} \
          delphai/delphai-microservice \
          --namespace=$REPOSITORY_NAME \
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

echo "IMAGE:${IMAGE}\nENVIRONMENT:${DELPHAI_ENVIRONMENT_ENV_VAR}\nRELEASE:${RELEASE_NAME}\nREOSITORY:$REPOSITORY_NAME"
echo "BRANCH:$GITHUB_REF_SLUG\nHTTP:$INPUT_HTTPPORT\nDOMAIN:${DOMAIN}\nDOMAINS:${DOMAINS}\nIs_Ui:$INPUT_IS_UI"