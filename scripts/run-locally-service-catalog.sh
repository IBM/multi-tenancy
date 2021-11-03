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

  set -o allexport
  source $CFG_FILE
  rm $CFG_FILE
  touch $CFG_FILE

  POSTGRES_URL=$(echo $POSTGRES_URL| cut -d'?' -f 1)
  CERTIFICATE_PATH=${root_folder}/code/service-catalog/src/main/resources/certificates/cloud-postgres-cert
  cp ${root_folder}/code/service-catalog/src/main/resources/certificates/$POSTGRES_CERTIFICATE_FILE_NAME $CERTIFICATE_PATH
  POSTGRES_URL="$POSTGRES_URL?sslmode=verify-full&sslrootcert=$CERTIFICATE_PATH"

  printf "POSTGRES_USERNAME=\"$POSTGRES_USERNAME\"" >> $CFG_FILE
  printf "\nPOSTGRES_PASSWORD=\"$POSTGRES_PASSWORD\"" >> $CFG_FILE
  printf "\nPOSTGRES_URL=\"$POSTGRES_URL\"" >> $CFG_FILE
  printf "\nPOSTGRES_CERTIFICATE_FILE_NAME=\"$POSTGRES_CERTIFICATE_FILE_NAME\"" >> $CFG_FILE
  cat $CFG_FILE

  cd ${root_folder}/code/service-catalog
  mvn clean package
  mvn quarkus:dev
}

triggerScript