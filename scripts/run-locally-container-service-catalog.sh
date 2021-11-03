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
  echo "Starting catalog service locally in a container ..."
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
  CERTIFICATE_PATH=/cloud-postgres-cert
  POSTGRES_URL="$POSTGRES_URL?sslmode=verify-full&sslrootcert=$CERTIFICATE_PATH"

  printf "POSTGRES_USERNAME=\"$POSTGRES_USERNAME\"" >> $CFG_FILE
  printf "\nPOSTGRES_PASSWORD=\"$POSTGRES_PASSWORD\"" >> $CFG_FILE
  printf "\nPOSTGRES_URL=\"$POSTGRES_URL\"" >> $CFG_FILE
  printf "\nPOSTGRES_CERTIFICATE_FILE_NAME=\"$POSTGRES_CERTIFICATE_FILE_NAME\"" >> $CFG_FILE
  cat $CFG_FILE

  POSTGRES_CERTIFICATE_DATA=$(<${root_folder}/code/service-catalog/src/main/resources/certificates/${POSTGRES_CERTIFICATE_FILE_NAME})

  cd ${root_folder}/code/service-catalog
  podman container stop service-catalog --ignore
  podman container rm -f service-catalog --ignore
  podman build --file Dockerfile --tag service-catalog

  podman run --name=service-catalog \
    -it \
    -e POSTGRES_CERTIFICATE_DATA="${POSTGRES_CERTIFICATE_DATA}" \
    -e POSTGRES_USERNAME="${POSTGRES_USERNAME}" \
    -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    -e POSTGRES_URL="${POSTGRES_URL}" \
    -p 8081:8081/tcp \
    localhost/service-catalog:latest
}

triggerScript