#!/bin/bash
export HOME_PATH_NEW=$(pwd)
export PATH_TO_CODE="Downloads/dev/multi-tenancy"

echo "************************************"
echo " Home path: $HOME_PATH_NEW"
echo "************************************"
export NAME=service-catalog-tmp
export MICROSERVICE="$PATH_TO_CODE/code/$NAME"
export MESSAGE="Starting $NAME"

echo "************************************"
echo " $MESSAGE"
echo "************************************"
pwd
cd $MICROSERVICE
# Don't start quarkus in dev-mode
# https://adambien.blog/roller/abien/entry/avoiding_port_collisions_by_launching
mvn clean
mvn compile -Ddebug=false quarkus:dev