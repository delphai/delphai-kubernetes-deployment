#! /usr/bin/env bash

IS_UI=true
IS_GRPC=false
IS_MICROSERVICE=false

if  [ "${IS_UI}" == "true" ] && [ "${IS_MICROSERVICE}" == "false" ] ; then
    echo "Using helm delphai-with-ui"
   
elif  [ "${IS_UI}" == "false" ] && [ "${IS_GRPC}" == "false" ] ; then
    echo "Using helm delphai-knative service with grpc off"
    
elif  [ "${IS_UI}" == "false" ] && [ "${IS_GRPC}" == "true" ] ; then
    echo "Using helm delphai-knative service with grpc on"
    
fi