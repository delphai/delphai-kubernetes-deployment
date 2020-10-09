#! /usr/bin/env bash

git clone https://github.com/ahmedmahmo/docker-build-push.git
cd docker-build-push
npm install
node dist/index.js
