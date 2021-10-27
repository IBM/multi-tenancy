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
export PROJECT_NAME_A=multi-tenancy-serverless-tmp-a
export PROJECT_NAME_B=multi-tenancy-serverless-tmp-b

# Applications
export SERVICE_CATALOG_NAME_A="service-catalog-movies"
export FRONTEND_NAME_A="frontend-movies"

export SERVICE_CATALOG_NAME_B="service-catalog-fantasy"
export FRONTEND_NAME_B="frontend-fantasy"

# App ID
export APPID_SERVICE_INSTANCE_NAME_A="multi-tenancy-serverless-appid-a"
export APPID_SERVICE_KEY_NAME_A="multi-tenancy-serverless-appid-key-a"

export APPID_SERVICE_INSTANCE_NAME_B="multi-tenancy-serverless-appid-b"
export APPID_SERVICE_KEY_NAME_B="multi-tenancy-serverless-appid-key-b"

# Postgres
export POSTGRES_SERVICE_INSTANCE_A="multi-tenant-pg-a"
export POSTGRES_SERVICE_INSTANCE_B="multi-tenant-pg-b"

export POSTGRES_SERVICE_KEY_NAME_A="multi-tenant-pg-service-key-a"
export POSTGRES_SERVICE_KEY_NAME_B="multi-tenant-pg-service-key-b"

# **********************************************************************************
# Functions definition
# **********************************************************************************

# TBD

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " Clean Tenant A"
echo "************************************"

bash ./ce-clean-up.sh $PROJECT_NAME_A \
                      $APPID_SERVICE_INSTANCE_NAME_A \
                      $APPID_SERVICE_KEY_NAME_A \
                      $SERVICE_CATALOG_NAME_A \
                      $FRONTEND_NAME_A \
                      $POSTGRES_SERVICE_INSTANCE_A \
                      $POSTGRES_SERVICE_KEY_NAME_A

bash ./ce-clean-up.sh $PROJECT_NAME_B \
                      $APPID_SERVICE_INSTANCE_NAME_B \
                      $APPID_SERVICE_KEY_NAME_B \
                      $SERVICE_CATALOG_NAME_B \
                      $FRONTEND_NAME_B \
                      $POSTGRES_SERVICE_INSTANCE_B \
                      $POSTGRES_SERVICE_KEY_NAME_B