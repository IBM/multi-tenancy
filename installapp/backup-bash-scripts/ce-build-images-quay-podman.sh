#!/bin/bash

# **************** Global variables
export REPOSITORY=tsuedbroecker
export SERVICE_CATALOG="multi-tenancy-service-catalog:v1"
export FRONTEND="multi-tenancy-frontend:v1"
#quay.io/tsuedbroecker/multi-tenancy-service-catalog:v1
# **********************************************************************************
# Execution
# **********************************************************************************

cd ..
export ROOT_PATH=$(PWD)
echo "Path: $ROOT_PATH"

echo "************************************"
echo " Clean up container if needed"
echo "************************************"
podman image list
podman container list
#podman container stop -f  "TBD"
#podman container rm -f "TBD"
podman image prune -a -f
podman version
podman image rm -f "$SERVICE_CATALOG"
podman image rm -f "$FRONTEND"
# rm -rf ~/var/home/core/.local/share/containers/storage/overlay/* f
#podman image rm -f "docker.io/adoptopenjdk/maven-openjdk11"
#podman image rm -f "docker.io/adoptopenjdk/openjdk11-openj9:ubi-minimal"
#podman image rm -f "registry.access.redhat.com/ubi8/ubi-minimal"

echo "************************************"
echo " Service catalog $SERVICE_CATALOG"
echo "************************************"
cd $ROOT_PATH/code/service-catalog-tmp
pwd
podman login quay.io
podman build -t "quay.io/$REPOSITORY/$SERVICE_CATALOG" -f Dockerfile.simple-v1 .
# podman push "quay.io/$REPOSITORY/$SERVICE_CATALOG"

echo ""

echo "************************************"
echo " Frontend $FRONTEND"
echo "************************************"
cd $ROOT_PATH/code/frontend
#pwd
# podman login quay.io
# podman build -t "quay.io/$REPOSITORY/$FRONTEND" -f Dockerfile.os4-webapp .
# podman push "quay.io/$REPOSITORY/$FRONTEND"
