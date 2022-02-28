#!/bin/bash

# **************** Global variables

export DEVELOPER_1_PROJECT=deleeuw
export DEVELOPER_2_PROJECT=saas-operator-development-thomas

export APPID_SECRET_NAME=multi-tenancy-appid-ten-f-secret
export POSTGRES_SECRET_NAME=multi-tenancy-pg-ten-f-secret

# **********************************************************************************
# Functions
# **********************************************************************************

function setROOT_PATH() {
   echo "************************************"
   echo " Set ROOT_PATH"
   echo "************************************"
   export ROOT_PATH=$(PWD)
   echo "Path: $ROOT_PATH"
}

function showExistingSecrets(){
    echo "Set Project $DEVELOPER_1_PROJECT"
    oc project $DEVELOPER_1_PROJECT
    oc get secret $APPID_SECRET_NAME -o yaml
    oc get secret $POSTGRES_SECRET_NAME -o yaml
}

function extractSecrets () {
    echo "Extract secrect for AppID"
    mkdir $ROOT_PATH/appid_secrets
    cd appid_secrets
    oc extract secret/$APPID_SECRET_NAME --to=.
    cd ..

    echo "Extract secrect for Postgres"
    mkdir $ROOT_PATH/postgres_secrets
    cd postgres_secrets
    oc extract secret/$POSTGRES_SECRET_NAME --to=.
    cd ..
}

function copySecrets () {
    echo "Set Project $DEVELOPER_2_PROJECT"
    oc project $DEVELOPER_2_PROJECT

    echo "Create postgres secret: $APPID_SECRET_NAME"
    cd $ROOT_PATH/appid_secrets
    kubectl create secret generic $APPID_SECRET_NAME \
                --from-file=apikey=../appid_secrets/apikey \
                --from-file=appidServiceEndpoint=../appid_secrets/appidServiceEndpoint \
                --from-file=clientId=../appid_secrets/clientId \
                --from-file=discoveryEndpoint=../appid_secrets/discoveryEndpoint \
                --from-file=iam_apikey_description=../appid_secrets/iam_apikey_description \
                --from-file=iam_apikey_name=../appid_secrets/iam_apikey_name \
                --from-file=iam_role_crn=../appid_secrets/iam_role_crn \
                --from-file=iam_serviceid_crn=../appid_secrets/iam_serviceid_crn \
                --from-file=managementUrl=../appid_secrets/managementUrl \
                --from-file=oauthServerUrl=../appid_secrets/oauthServerUrl \
                --from-file=secret=../appid_secrets/secret \
                --from-file=tenantId=../appid_secrets/tenantId
    cd ..
    rm -r $ROOT_PATH/appid_secrets

    echo "Create postgres secret: $POSTGRES_SECRET_NAME"
    cd $ROOT_PATH/postgres_secrets
    kubectl create secret generic $POSTGRES_SECRET_NAME \
                --from-file=connection=../postgres_secrets/connection \
                --from-file=instance_administration_api=../postgres_secrets/instance_administration_api
    cd ..
    rm -r $ROOT_PATH/postgres_secrets
}

# **********************************************************************************
# Execution
# **********************************************************************************

setROOT_PATH
extractSecrets
copySecrets









