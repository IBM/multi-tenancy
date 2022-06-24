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
echo "Build CE Project             : $4"
echo "Registry Secret Name         : $5"
echo "---------------------------------"
echo ""

# **************** Global variables
export SERVICE_CATALOG_IMAGE=$1
export FRONTEND_IMAGE=$2
export REGISTRY_URL=$3
export PROJECT_NAME=$4
export SECRET_NAME=$5

export ROOT_PROJECT=multi-tenancy
export FRONTEND_SOURCEFOLDER=multi-tenancy-frontend
export BACKEND_SOURCEFOLDER=multi-tenancy-backend


# **********************************************************************************
# Functions
# **********************************************************************************

setROOT_PATH() {
   echo "************************************"
   echo " Set ROOT_PATH"
   echo "************************************"
   cd ../../
   export ROOT_PATH=$(pwd)
   echo "Path: $ROOT_PATH"
}

setupCRenvCE() {
   
   IBMCLOUDCLI_KEY_NAME="cliapikey_for_multi_tenant_$PROJECT_NAME"
   IBMCLOUDCLI_KEY_DESCRIPTION="CLI APIkey $IBMCLOUDCLI_KEY_NAME"
   CLIKEY_FILE="cli_key.json"
   USERNAME="iamapikey"
   
   RESULT=$(ibmcloud iam api-keys | grep '$IBMCLOUDCLI_KEY_NAME' | awk '{print $1;}' | head -n 1)
   echo "API key: $RESULT"
   if [[ $RESULT == $IBMCLOUDCLI_KEY_NAME ]]; then
        echo "*** The Cloud API key '$IBMCLOUDCLI_KEY_NAME' already exists !"
        echo "*** The script 'ce-install-application.sh' ends here!"
        echo "*** Review your existing API keys 'https://cloud.ibm.com/iam/apikeys'."
        exit 1
   fi

   ibmcloud iam api-key-create $IBMCLOUDCLI_KEY_NAME -d "My IBM CLoud CLI API key for project $PROJECT_NAME" --file $CLIKEY_FILE
   CLIAPIKEY=$(cat $CLIKEY_FILE | grep '"apikey":' | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g' )
   #echo $CLIKEY
   rm -f $CLIKEY_FILE

   ibmcloud ce project select --name $PROJECT_NAME
   
   ibmcloud ce registry create --name $SECRET_NAME \
                               --server $REGISTRY_URL \
                               --username $USERNAME \
                               --password $CLIAPIKEY
}

buildBackend() {
    echo "************************************"
    echo " Backend $SERVICE_CATALOG_IMAGE"
    echo "************************************"
    cd $ROOT_PATH/$BACKEND_SOURCEFOLDER

    # ibmcloud iam oauth-tokens | sed -ne '/IAM token/s/.* //p' | buildah login -u iambearer --password-stdin $REGISTRY_URL

    # buildah bud -t "$SERVICE_CATALOG_IMAGE" -f Dockerfile .
    # buildah push "$SERVICE_CATALOG_IMAGE"

    ibmcloud ce buildrun submit --name service-catalog --image $SERVICE_CATALOG_IMAGE \
                                --registry-secret $SECRET_NAME --source .

    ibmcloud ce buildrun logs -f -n service-catalog
    echo ""
}

buildFrontend() {
    echo "************************************"
    echo " Frontend $FRONTEND_IMAGE"
    echo "************************************"
    cd $ROOT_PATH/$FRONTEND_SOURCEFOLDER

    # ibmcloud iam oauth-tokens | sed -ne '/IAM token/s/.* //p' | buildah login -u iambearer --password-stdin $REGISTRY_URL

    # buildah bud -t "$FRONTEND_IMAGE" -f Dockerfile .
    # buildah push "$FRONTEND_IMAGE"

    ibmcloud ce buildrun submit --name frontend-image --image $FRONTEND_IMAGE \
                                --registry-secret $SECRET_NAME --source .
    
    ibmcloud ce buildrun logs -f -n frontend-image
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
setupCRenvCE
buildBackend
buildFrontend
resetPath
