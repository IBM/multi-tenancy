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

export ROOT_PROJECT=multi-tenancy
export FRONTEND_SOURCEFOLDER=multi-tenancy-frontend
export BACKEND_SOURCEFOLDER=multi-tenancy-backend

# **********************************************************************************
# Functions
# **********************************************************************************

function cleanUpLocalImages() {
   
    echo "************************************"
    echo " Clean up local images, if needed"
    echo "************************************"

    docker image rm -f "$SERVICE_CATALOG_IMAGE"
    docker image rm -f "$FRONTEND_IMAGE"
}

function setROOT_PATH() {
   echo "************************************"
   echo " Set ROOT_PATH"
   echo "************************************"
   cd ../../
   export ROOT_PATH=$(PWD)
   echo "Path: $ROOT_PATH"
}

function buildAndPushBackend() {
    echo "************************************"
    echo " Backend $SERVICE_CATALOG_IMAGE"
    echo "************************************"
    cd $ROOT_PATH/$BACKEND_SOURCEFOLDER
    pwd
    docker build -t "$SERVICE_CATALOG_IMAGE" -f Dockerfile .
    docker push "$SERVICE_CATALOG_IMAGE"
    echo ""
}

function buildAndPushFrontend() {
    echo "************************************"
    echo " Frontend $FRONTEND_IMAGE"
    echo "************************************"
    cd $ROOT_PATH/$FRONTEND_SOURCEFOLDER

    docker build -t "$FRONTEND_IMAGE" -f Dockerfile .
    docker push "$FRONTEND_IMAGE"
    echo ""
}

function checkDocker () {
    
    echo "************************************"
    echo " Check Docker is running"
    echo "************************************"
    docker ps 2> tmp.txt
    RESULT=$(cat tmp.txt)
    echo "LOG **** [$RESULT] *****"
    rm tmp.txt

    if [[ $RESULT =~ "Cannot connect to the Docker daemon" ]]; then
        echo "*** Docker is NOT running !"
        echo "*** The script 'ce-build-images-ibm-docker.sh' ends here!"
        exit 1
    else 
        echo "- Docker is running!"
    fi
}



function resetPath() {
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
checkDocker
cleanUpLocalImages
buildAndPushBackend
buildAndPushFrontend
resetPath
