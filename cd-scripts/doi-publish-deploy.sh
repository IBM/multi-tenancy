#!/usr/bin/bash

export IBM_CLOUD_API
export IBMCLOUD_API_KEY
export BREAK_GLASS
export DEPLOYMENT_DELTA

if [ -f /config/api-key ]; then
  IBMCLOUD_API_KEY="$(cat /config/api-key)" # pragma: allowlist secret
else
  IBMCLOUD_API_KEY="$(cat /config/ibmcloud-api-key)" # pragma: allowlist secret
fi

BREAK_GLASS=$(cat /config/break_glass || echo false)

if [[ "$BREAK_GLASS" != "false" ]]; then
  echo "Break-Glass mode is on, skipping the rest of the task..."
  exit 0
fi

IBM_CLOUD_API="$(cat /config/ibmcloud-api || echo "https://cloud.ibm.com")"
##########################################################################
# Setting HOME explicitly to have ibmcloud plugins available
# doing the export rather than env definition is a workaround
# until https://github.com/tektoncd/pipeline/issues/1836 is fixed
export HOME="/root"
##########################################################################
if [[ "$IBM_CLOUD_API" == *test* ]]; then
  export IBM_CLOUD_DEVOPS_ENV=dev
fi

TOOLCHAIN_ID=$(cat /config/doi-toolchain-id)
CURRENT_TOOLCHAIN_ID=$(jq -r '.toolchain_guid' /toolchain/toolchain.json)
DOI_IN_TOOLCHAIN=$(jq -e '[.services[] | select(.service_id=="draservicebroker")] | length' /toolchain/toolchain.json)
DOI_ENVIRONMENT=$(cat /config/doi-environment 2> /dev/null || echo "")
ENVIRONMENT=$(cat /config/environment 2> /dev/null || echo "")
DEPLOYMENT_DELTA_PATH="$(cat /config/deployment-delta-path)"
DEPLOYMENT_DELTA=$(cat "${DEPLOYMENT_DELTA_PATH}")
JOB_URL=$(cat /config/job-url)
INVENTORY_PATH="$(cat /config/inventory-path)"

if [ "$DOI_IN_TOOLCHAIN" == 0 ]; then
  if [ -z "$TOOLCHAIN_ID" ] || [ "$CURRENT_TOOLCHAIN_ID" == "$TOOLCHAIN_ID" ]; then
    echo "No Devops Insights integration found in toolchain. Skipping ..."
    exit 0
  fi
fi

if [ "$DEPLOY_EXIT" -eq 0 ]; then
  DEPLOY_STATUS="pass"
else
  DEPLOY_STATUS="fail"
fi

# Default Toolchain ID if needed
if [ -z "$TOOLCHAIN_ID" ]; then
  TOOLCHAIN_ID="$CURRENT_TOOLCHAIN_ID"
fi

# Default Job URL if needed
if [ -z "$JOB_URL" ]; then
  JOB_URL="$PIPELINE_RUN_URL"
fi

export TOOLCHAIN_ID=${TOOLCHAIN_ID} # for doi plugin

if [ "$DOI_ENVIRONMENT" ]; then
  ENVIRONMENT="$DOI_ENVIRONMENT"
fi

ibmcloud login --apikey "${IBMCLOUD_API_KEY}" -a "${IBM_CLOUD_API}" --no-region


declare -A app_hash_map
for INVENTORY_ENTRY in $(echo "${DEPLOYMENT_DELTA}" | jq -r '.[] '); do
  APP=$(cat "${INVENTORY_PATH}/${INVENTORY_ENTRY}")
  BUILD_NUMBER=$(echo "${APP}" | jq -r '.build_number')

  APP_REPO=$(echo "${APP}" | jq -r '.repository_url')
  APP_REPO=$(echo -n "${APP_REPO}" | sed 's:/*$::')
  APP_NAME=$(echo "${APP_REPO}" | cut -f5 -d/)

  if [ ! "${app_hash_map[$APP_NAME]}" ] ; then 
    ibmcloud doi publishdeployrecord \
      --env "${ENVIRONMENT}" \
      --status="${DEPLOY_STATUS}" \
      --joburl="${JOB_URL}" \
      --buildnumber="${BUILD_NUMBER}" \
      --logicalappname="${APP_NAME}"
  fi
  app_hash_map[$APP_NAME]=1
done
