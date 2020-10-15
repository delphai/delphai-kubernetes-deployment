#! /usr/bin/env bash

REPO_SLUG=$1
REPO_NAME="repo"

if [ "${REPO_SLUG}" = "master" ]; then
    RELEASE_NAME=${REPO_NAME}
else
    RELEASE_NAME=${REPO_NAME}-${REPO_SLUG}
fi

echo ${RELEASE_NAME}