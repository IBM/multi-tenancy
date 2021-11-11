#!/bin/bash

# CLI tools Documentation
# ================
# IBM Cloud CLI
# Code Engine: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create
# Cloud databases
# IBM Cloud Container Registry 

# Needed IBM Cloud CLI plugins
# =============
# - code engine 
# - cloud databases (ibmcloud plugin install cloud-databases)
# - ibm cloud container registry 

# Needed tools 
# ============
# brew install libpq
# brew link --force libpq

# Install jq to extract json in bash on mac
# ===============
# brew install jq

# **************** Global variables

# Tenancies
export TENANT_A="tenants-config/tenant-a-parameters.json"
export TENANT_B="tenants-config/tenant-b-parameters.json"

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

bash ./ce-clean-up.sh $TENANT_A

bash ./ce-clean-up.sh $TENANT_B