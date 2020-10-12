#! /usr/bin/env bash

case $1 in

  'common')
    DOMIAN='delphai.red'
    ;;

  'review')
    DOMIAN='delphai.pink'
    ;;

  'development')
    DOMIAN='delphai.pink'
    ;;

esac
echo $DOMIAN