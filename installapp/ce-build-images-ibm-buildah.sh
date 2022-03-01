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
echo "Registry URL                 : $3"
echo "---------------------------------"
echo ""

# **************** Global variables
export SERVICE_CATALOG_IMAGE=$1
export FRONTEND_IMAGE=$2
export REGISTRY_URL=$3

export ROOT_PROJECT=multi-tenancy
export FRONTEND_SOURCEFOLDER=multi-tenancy-frontend
export BACKEND_SOURCEFOLDER=multi-tenancy-backend



# **********************************************************************************
# Functions
# **********************************************************************************

cleanUpLocalImages() {
   
    echo "************************************"
    echo " Clean up local images, if needed"
    echo "************************************"

    buildah rmi -f "$SERVICE_CATALOG_IMAGE"
    buildah rmi -f "$FRONTEND_IMAGE"
}

setROOT_PATH() {
   echo "************************************"
   echo " Set ROOT_PATH"
   echo "************************************"
   cd ../../
   export ROOT_PATH=$(PWD)
   echo "Path: $ROOT_PATH"
}

buildAndPushBackend() {
    echo "************************************"
    echo " Backend $SERVICE_CATALOG_IMAGE"
    echo "************************************"
    cd $ROOT_PATH/$BACKEND_SOURCEFOLDER
    
    ibmcloud iam oauth-tokens | sed -ne '/IAM token/s/.* //p' | buildah login -u iambearer --password-stdin $REGISTRY_URL

    buildah bud -t "$SERVICE_CATALOG_IMAGE" -f Dockerfile .
    buildah push "$SERVICE_CATALOG_IMAGE"
    echo ""
}

buildAndPushFrontend() {
    echo "************************************"
    echo " Frontend $FRONTEND_IMAGE"
    echo "************************************"
    cd $ROOT_PATH/$FRONTEND_SOURCEFOLDER

    ibmcloud iam oauth-tokens | sed -ne '/IAM token/s/.* //p' | buildah login -u iambearer --password-stdin $REGISTRY_URL

    buildah bud -t "$FRONTEND_IMAGE" -f Dockerfile .
    buildah push "$FRONTEND_IMAGE"
    echo ""
}

resetPath() {
   echo "************************************"
   echo " Reset path"
   echo "************************************"
   cd $ROOT_PATH/$ROOT_PROJECT
   echo ""
}


# **********************************************************************************
# Execution
# **********************************************************************************

setROOT_PATH
cleanUpLocalImages
buildAndPushBackend
buildAndPushFrontend
resetPath
