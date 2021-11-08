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

# Verification
# In case the script doesn't use the parameters
export FRONTEND_IMAGE='quay.io/tsuedbroecker/multi-tenancy-frontend:v10'
export SERVICE_CATALOG_IMAGE='quay.io/tsuedbroecker/multi-tenancy-service-catalog:v10'

# **********************************************************************************
# Execution
# **********************************************************************************

cd ..
export ROOT_PATH=$(PWD)
echo "Path: $ROOT_PATH"

echo "************************************"
echo " Clean up container if needed"
echo "************************************"

podman image rm -f "$SERVICE_CATALOG_IMAGE"
podman image rm -f "$FRONTEND_IMAGE"

echo "************************************"
echo " Service catalog $SERVICE_CATALOG_IMAGE"
echo "************************************"
cd $ROOT_PATH/code/service-catalog
pwd
POSTGRES_CERTIFICATE_DATA login quay.io
podman build -t "$SERVICE_CATALOG_IMAGE" -f Dockerfile .
podman push "$SERVICE_CATALOG_IMAGE"

echo ""

echo "************************************"
echo " Frontend $FRONTEND_IMAGE"
echo "************************************"
cd $ROOT_PATH/code/frontend

podman login quay.io
podman build -t "$FRONTEND_IMAGE" -f Dockerfile.os4-webapp .
podman push "$FRONTEND_IMAGE"