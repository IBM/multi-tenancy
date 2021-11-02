#!/bin/bash

root_folder=$(cd $(dirname $0); cd ..; pwd)

exec 3>&1

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function triggerScript() { 

  echo "You need to create a Postgres database first"
  echo "Copy the credentials in local.env"
  echo "Starting catalog service locally"
  echo curl  \"http://localhost:8081/category\"
  echo curl  \"http://localhost:8081/category/2/products\"

  cd ${root_folder}
  CFG_FILE=${root_folder}/local.env
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi
  set -o allexport
  source $CFG_FILE
  cat $CFG_FILE

  cd ${root_folder}/code/service-catalog
  mvn clean package
  mvn quarkus:dev
}

triggerScript