#!/bin/bash

# CLI Documentation
# ================
# command documentation: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create

# Install jq to extract json in bash on mac
# ===============
# brew install jq

# **************** Global variables

# Tenancies
export TENANT_A="tenant-a-parameters.json"
export TENANT_B="tenant-b-parameters.json"

# **********************************************************************************
# Functions definition
# **********************************************************************************

function createAndPushContainer () {
    bash ./ce-build-images-quay-docker.sh $SERVICE_CATALOG_IMAGE \
                                          $FRONTEND_IMAGE

}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " Create container in Quay registry"
echo "************************************"

# createAndPushContainer

echo "************************************"
echo " Tenant A"
echo "************************************"

bash ./ce-install-application.sh $TENANT_A

# echo "************************************"
# echo " Tenant B"
# echo "************************************"

# bash ./ce-install-application.sh $TENANT_B