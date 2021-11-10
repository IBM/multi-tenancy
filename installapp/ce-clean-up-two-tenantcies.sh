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

# TBD

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " Clean Tenant A"
echo "************************************"

# bash ./ce-clean-up.sh $TENANT_A

bash ./ce-clean-up.sh $TENANT_B