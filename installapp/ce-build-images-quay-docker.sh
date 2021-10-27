#!/bin/bash

echo "************************************"
echo " Display parameter"
echo "************************************"
echo ""
echo "Parameter count : $@"
echo "Parameter zero 'name of the script': $0"
echo "---------------------------------"
echo "Service catalog image        : $1"
echo "Frontend image               : $2"
echo "---------------------------------"
echo ""

# **************** Global variables
export SERVICE_CATALOG_IMAGE=$1
export FRONTEND_IMAGE=$2

#Verify new ui
#export FRONTEND_IMAGE="quay.io/tsuedbroecker/multi-tenancy-frontend:v4"


# **********************************************************************************
# Execution
# **********************************************************************************

cd ..
export ROOT_PATH=$(PWD)
echo "Path: $ROOT_PATH"

echo "************************************"
echo " Clean up container if needed"
echo "************************************"
docker image rm -f "$SERVICE_CATALOG_IMAGE"
docker image rm -f "$FRONTEND_IMAGE"

echo "************************************"
echo " Service catalog $SERVICE_CATALOG_IMAGE"
echo "************************************"
cd $ROOT_PATH/code/service-catalog
pwd
docker login quay.io
docker build -t "$SERVICE_CATALOG_IMAGE" -f Dockerfile .
docker push "$SERVICE_CATALOG_IMAGE"

echo ""

echo "************************************"
echo " Frontend $FRONTEND_IMAGE"
echo "************************************"
cd $ROOT_PATH/code/frontend

docker login quay.io
docker build -t "$FRONTEND_IMAGE" -f Dockerfile.os4-webapp .
docker push "$FRONTEND_IMAGE"
