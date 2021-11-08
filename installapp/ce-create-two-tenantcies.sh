#!/bin/bash

# CLI Documentation
# ================
# command documentation: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create

# Install jq to extract json in bash on mac
# ===============
# brew install jq

# **************** Global variables

# Code Engine
#export PROJECT_NAME_A=multi-tenancy-serverless-a
export PROJECT_NAME_A=multi-tenancy-serverless
export PROJECT_NAME_B=multi-tenancy-serverless-tmp-b

# Applications
export SERVICE_CATALOG_NAME_A="service-catalog-movies"
export FRONTEND_NAME_A="frontend-movies"

export SERVICE_CATALOG_NAME_B="service-catalog-fantasy"
export FRONTEND_NAME_B="frontend-fantasy"

export CATEGORY_A=Movies
export CATEGORY_B=Fantasy

# IBM CLoud CR
#export SERVICE_CATALOG_IMAGE="us.icr.io/multi-tenancy-cr/service-catalog:latest"
#export FRONTEND_IMAGE="us.icr.io/multi-tenancy-cr/frontend:latest"

# Quay and Docker
export SERVICE_CATALOG_IMAGE="quay.io/tsuedbroecker/multi-tenancy-service-catalog:v1"
export FRONTEND_IMAGE="quay.io/tsuedbroecker/multi-tenancy-frontend:v3"
#export SERVICE_CATALOG_IMAGE="docker.io/karimdeif/service-catalog-quarkus-reactive:1.0.0-SNAPSHOT"
#export FRONTEND_IMAGE="quay.io/kdeif/frontend:v0.0"

# App ID
export APPID_SERVICE_INSTANCE_NAME_A="multi-tenancy-serverless-appid-a"
export APPID_SERVICE_KEY_NAME_A="multi-tenancy-serverless-appid-key-a"

export APPID_SERVICE_INSTANCE_NAME_B="multi-tenancy-serverless-appid-b"
export APPID_SERVICE_KEY_NAME_B="multi-tenancy-serverless-appid-key-b"

# Postgres
export POSTGRES_SERVICE_INSTANCE_A="multi-tenant-pg-a-working"
export POSTGRES_SERVICE_INSTANCE_B="multi-tenant-pg-b"

export POSTGRES_SERVICE_KEY_NAME_A="multi-tenant-pg-service-key-a-working"
export POSTGRES_SERVICE_KEY_NAME_B="multi-tenant-pg-service-key-b"

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

bash ./ce-install-application.sh $PROJECT_NAME_A \
                                 $APPID_SERVICE_INSTANCE_NAME_A \
                                 $APPID_SERVICE_KEY_NAME_A \
                                 $SERVICE_CATALOG_NAME_A \
                                 $FRONTEND_NAME_A \
                                 $SERVICE_CATALOG_IMAGE \
                                 $FRONTEND_IMAGE \
                                 $CATEGORY_A \
                                 $POSTGRES_SERVICE_INSTANCE_A \
                                 $POSTGRES_SERVICE_KEY_NAME_A

echo "************************************"
echo " Tenant B"
echo "************************************"

# bash ./ce-install-application.sh $PROJECT_NAME_B \
#                                  $APPID_SERVICE_INSTANCE_NAME_B \
#                                  $APPID_SERVICE_KEY_NAME_B \
#                                  $SERVICE_CATALOG_NAME_B \
#                                  $FRONTEND_NAME_B \
#                                  $SERVICE_CATALOG_IMAGE \
#                                  $FRONTEND_IMAGE \
#                                  $CATEGORY_B \
#                                  $POSTGRES_SERVICE_INSTANCE_B \
#                                  $POSTGRES_SERVICE_KEY_NAME_A