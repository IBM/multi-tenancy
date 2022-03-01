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
pwd
# Configurations
export GLOBAL="../configuration/global.json"
export TENANT_A="../configuration/tenants/tenant-a.json"
export TENANT_B="../configuration/tenants/tenant-b.json"

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

bash ./ce-clean-up.sh $GLOBAL $TENANT_A

bash ./ce-clean-up.sh $GLOBAL $TENANT_B