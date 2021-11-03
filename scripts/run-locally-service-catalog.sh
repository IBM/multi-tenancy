#!/bin/bash

root_folder=$(cd $(dirname $0); cd ..; pwd)

exec 3>&1

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function triggerScript() { 

  echo "Have you created a Postgres instance?"
  echo "Copy the credentials in local.env: POSTGRES_USERNAME, POSTGRES_PASSWORD, POSTGRES_URL, POSTGRES_CERTIFICATE_FILE_NAME"
  echo "Copy the Postgres certificate in code/service-catalog/src/main/resources/certificates"
  echo "Starting catalog service locally ..."
  echo curl  \"http://localhost:8081/category\"
  echo curl  \"http://localhost:8081/category/2/products\"

  cd ${root_folder}
  CFG_FILE=${root_folder}/local.env
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi

  cp ${root_folder}/local.env ${root_folder}/local.env.tmp
  rm ${root_folder}/local.env
  CERTIFICATE_PATH=${root_folder}/code/service-catalog/src/main/resources/certificates/cloud-postgres-cert
  sed "s#ABSOLUTE_PATH_TO_CERT_IS_INSERTED_AUTOMATICALLY#${CERTIFICATE_PATH}#g" ${root_folder}/local.env.tmp > ${root_folder}/local.env
  rm ${root_folder}/local.env.tmp

  set -o allexport
  source $CFG_FILE
  cat $CFG_FILE

  echo "niklas"
  echo $POSTGRES_URL
  echo $POSTGRES_PASSWORD

  cp ${root_folder}/code/service-catalog/src/main/resources/certificates/${POSTGRES_CERTIFICATE_FILE_NAME} ${CERTIFICATE_PATH}

  cd ${root_folder}/code/service-catalog
  mvn clean package
  mvn quarkus:dev
}

triggerScript