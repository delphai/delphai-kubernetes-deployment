#! /usr/bin/env bash

INPUT=$1
IFS=', ' read -r -a FILES <<< ${INPUT}
echo "${INPUT[*]}"