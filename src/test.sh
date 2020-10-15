#! /usr/bin/env bash

REPO_NAME=$1

if [ "${REPO_NAME}" == "delphai-ui" ]; then
    REPO_NAME="app"
fi

echo ${REPO_NAME}