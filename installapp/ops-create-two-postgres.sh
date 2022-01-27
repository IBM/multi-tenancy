#!/bin/bash

# CLI Documentation
# ================
# command documentation: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create

# Install jq to extract json in bash on mac
# ===============
# brew install jq

# **************** Global variables

# Configurations
export GLOBAL="tenants-config/global/global.json"
export TENANT_A="tenants-config/tenants/tenant-a.json"
export TENANT_B="tenants-config/tenants/tenant-b.json"

# **********************************************************************************
# Functions definition
# **********************************************************************************

# TBD

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " Postgres for Tenant A"
echo "************************************"

bash ./ops-install-single-postgres.sh $GLOBAL $TENANT_A

if [ $? == "1" ]; then
  echo "*** The installation for '$GLOBAL' '$TENANT_A' configuation failed !"
  echo "*** The script 'ops-create-two-postgres.sh' ends here!"
  exit 1
fi

echo "************************************"
echo " App ID for Tenant B"
echo "************************************"

bash ./ops-install-single-postgres.sh $GLOBAL $TENANT_B

if [ $? == "1" ]; then
  echo "*** The installation for '$GLOBAL' '$TENANT_B' configuation failed !"
  echo "*** The script 'ops-create-two-postgres.sh' ends here!"
  exit 1
fi