#!/usr/bin/env bash

export IBMCLOUD_API_KEY
export IBMCLOUD_TOOLCHAIN_ID
export IBMCLOUD_IKS_REGION
export IBMCLOUD_IKS_CLUSTER_NAME
export IBMCLOUD_IKS_CLUSTER_NAMESPACE
export IMAGE_PULL_SECRET_NAME
export TARGET_ENVIRONMENT
export HOME
export BREAK_GLASS
export DEPLOYMENT_DELTA

if [ -f /config/api-key ]; then
  IBMCLOUD_API_KEY="$(cat /config/api-key)" # pragma: allowlist secret
else
  IBMCLOUD_API_KEY="$(cat /config/ibmcloud-api-key)" # pragma: allowlist secret
fi

HOME=/root

TARGET_ENVIRONMENT="$(cat /config/environment)"
INVENTORY_PATH="$(cat /config/inventory-path)"
DEPLOYMENT_DELTA_PATH="$(cat /config/deployment-delta-path)"
DEPLOYMENT_DELTA=$(cat "${DEPLOYMENT_DELTA_PATH}")

echo "Target environment: ${TARGET_ENVIRONMENT}"
echo "Deployment Delta (inventory entries with updated artifacts)"
echo ""

echo "$DEPLOYMENT_DELTA" | jq '.'

echo ""
echo "Inventory content"
echo ""

ls -la ${INVENTORY_PATH}

BREAK_GLASS=$(cat /config/break_glass || echo "")
IBMCLOUD_TOOLCHAIN_ID="$(jq -r .toolchain_guid /toolchain/toolchain.json)"
IBMCLOUD_IKS_REGION="$(cat /config/dev-region | awk -F ":" '{print $NF}')"
IBMCLOUD_IKS_CLUSTER_NAMESPACE="$(cat /config/dev-cluster-namespace)"
IBMCLOUD_IKS_CLUSTER_NAME="$(cat /config/cluster-name)"

if [[ -n "$BREAK_GLASS" ]]; then
  export KUBECONFIG
  KUBECONFIG=/config/cluster-cert
else
  IBMCLOUD_IKS_REGION=$(echo "${IBMCLOUD_IKS_REGION}" | awk -F ":" '{print $NF}')
  ibmcloud login -r "$IBMCLOUD_IKS_REGION"
  ibmcloud ks cluster config --cluster "$IBMCLOUD_IKS_CLUSTER_NAME"

  ibmcloud ks cluster get --cluster "${IBMCLOUD_IKS_CLUSTER_NAME}" --json > "${IBMCLOUD_IKS_CLUSTER_NAME}.json"
  # If the target cluster is openshift then make the appropriate additional login with oc tool
  if which oc > /dev/null && jq -e '.type=="openshift"' "${IBMCLOUD_IKS_CLUSTER_NAME}.json" > /dev/null; then
    echo "${IBMCLOUD_IKS_CLUSTER_NAME} is an openshift cluster. Doing the appropriate oc login to target it"
    oc login -u apikey -p "${IBMCLOUD_API_KEY}"
  fi
  #
  # check pull traffic & storage quota in container registry
  #
  if ibmcloud cr quota | grep 'Your account has exceeded its pull traffic quota'; then
    echo "Your account has exceeded its pull traffic quota for the current month. Review your pull traffic quota in the preceding table."
    exit 1
  fi

  if ibmcloud cr quota | grep 'Your account has exceeded its storage quota'; then
    echo "Your account has exceeded its storage quota. You can check your images at https://cloud.ibm.com/kubernetes/registry/main/images"
    exit 1
  fi
fi

#example: https://github.com/IBM/multi-tenancy/blob/main/configuration/global.json
CONFIG_FILE="multi-tenancy/configuration/global.json"
IBM_CLOUD_RESOURCE_GROUP=$(cat ./$CONFIG_FILE | jq '.IBM_CLOUD.RESOURCE_GROUP' | sed 's/"//g')
IBM_CLOUD_REGION=$(cat ./$CONFIG_FILE | jq '.IBM_CLOUD.REGION' | sed 's/"//g')
REGISTRY_NAMESPACE=$(cat ./$CONFIG_FILE | jq '.REGISTRY.NAMESPACE' | sed 's/"//g')
REGISTRY_TAG=$(cat ./$CONFIG_FILE | jq '.REGISTRY.TAG' | sed 's/"//g')
REGISTRY_URL=$(cat ./$CONFIG_FILE | jq '.REGISTRY.URL' | sed 's/"//g')
REGISTRY_SECRET_NAME=$(cat ./$CONFIG_FILE | jq '.REGISTRY.SECRET_NAME' | sed 's/"//g')
IMAGES_NAME_BACKEND=$(cat ./$CONFIG_FILE | jq '.IMAGES.NAME_BACKEND' | sed 's/"//g')
IMAGES_NAME_FRONTEND=$(cat ./$CONFIG_FILE | jq '.IMAGES.NAME_FRONTEND' | sed 's/"//g')

#example: https://github.com/IBM/multi-tenancy/blob/main/configuration/tenants/tenant-a.json
TENANT=$(get_env tenant '')
CONFIG_FILE="multi-tenancy/configuration/tenants/${TENANT}.json"
APPID_SERVICE_INSTANCE_NAME=$(cat ./$CONFIG_FILE | jq '.APP_ID.SERVICE_INSTANCE' | sed 's/"//g')
APPID_SERVICE_KEY_NAME=$(cat ./$CONFIG_FILE | jq '.APP_ID.SERVICE_KEY_NAME' | sed 's/"//g')
POSTGRES_SERVICE_INSTANCE=$(cat ./$CONFIG_FILE | jq '.POSTGRES.SERVICE_INSTANCE' | sed 's/"//g') 
POSTGRES_SERVICE_KEY_NAME=$(cat ./$CONFIG_FILE | jq '.POSTGRES.SERVICE_KEY_NAME' | sed 's/"//g')
POSTGRES_SQL_FILE=$(cat ./$CONFIG_FILE | jq '.POSTGRES.SQL_FILE' | sed 's/"//g')
APPLICATION_CONTAINER_NAME_BACKEND=$(cat ./$CONFIG_FILE | jq '.APPLICATION.CONTAINER_NAME_BACKEND' | sed 's/"//g') 
APPLICATION_CONTAINER_NAME_FRONTEND=$(cat ./$CONFIG_FILE | jq '.APPLICATION.CONTAINER_NAME_FRONTEND' | sed 's/"//g')
APPLICATION_CATEGORY=$(cat ./$CONFIG_FILE | jq '.APPLICATION.CATEGORY' | sed 's/"//g')
CODE_ENGINE_PROJECT_NAME=$(cat ./$CONFIG_FILE | jq '.CODE_ENGINE.PROJECT_NAME' | sed 's/"//g') 
IBM_KUBERNETES_SERVICE_NAME=$(cat ./$CONFIG_FILE | jq '.IBM_KUBERNETES_SERVICE.NAME' | sed 's/"//g') 
IBM_KUBERNETES_SERVICE_NAMESPACE=$(cat ./$CONFIG_FILE | jq '.IBM_KUBERNETES_SERVICE.NAMESPACE' | sed 's/"//g') 

#dev namespace for dummy tenant for CI pipeline
IBM_KUBERNETES_SERVICE_NAMESPACE=${IBM_KUBERNETES_SERVICE_NAMESPACE}

IBMCLOUD_IKS_REGION=${IBM_CLOUD_REGION}
IBMCLOUD_IKS_CLUSTER_NAMESPACE=${IBM_KUBERNETES_SERVICE_NAMESPACE}
IBMCLOUD_IKS_CLUSTER_NAME=${IBM_KUBERNETES_SERVICE_NAME}
IMAGE="$(cat /config/image)"
IMAGE_PULL_SECRET_NAME="ibmcloud-toolchain-${IBMCLOUD_TOOLCHAIN_ID}-${REGISTRY_URL}"

IBMCLOUD_IKS_REGION=$(echo "${IBMCLOUD_IKS_REGION}" | awk -F ":" '{print $NF}')
ibmcloud login -r "${IBMCLOUD_IKS_REGION}"
ibmcloud target -g ${IBM_CLOUD_RESOURCE_GROUP}
ibmcloud ks cluster config --cluster "${IBMCLOUD_IKS_CLUSTER_NAME}"

ibmcloud ks cluster get --cluster "${IBMCLOUD_IKS_CLUSTER_NAME}" --json > "${IBMCLOUD_IKS_CLUSTER_NAME}.json"
# If the target cluster is openshift then make the appropriate additional login with oc tool
if which oc > /dev/null && jq -e '.type=="openshift"' "${IBMCLOUD_IKS_CLUSTER_NAME}.json" > /dev/null; then
  echo "${IBMCLOUD_IKS_CLUSTER_NAME} is an openshift cluster. Doing the appropriate oc login to target it"
  oc login -u apikey -p "${IBMCLOUD_API_KEY}"
fi

set_env IBM_CLOUD_REGION "${IBM_CLOUD_REGION}"
set_env IBM_CLOUD_RESOURCE_GROUP "${IBM_CLOUD_RESOURCE_GROUP}"
set_env REGISTRY_NAMESPACE "${REGISTRY_NAMESPACE}"
set_env REGISTRY_TAG "${REGISTRY_TAG}"
set_env REGISTRY_URL "${REGISTRY_URL}"
set_env REGISTRY_SECRET_NAME "${REGISTRY_SECRET_NAME}"
set_env IMAGES_NAME_BACKEND "${IMAGES_NAME_BACKEND}"
set_env IMAGES_NAME_FRONTEND "${IMAGES_NAME_FRONTEND}"
set_env APPID_SERVICE_INSTANCE_NAME "${APPID_SERVICE_INSTANCE_NAME}"
set_env APPID_SERVICE_KEY_NAME "${APPID_SERVICE_KEY_NAME}"
set_env POSTGRES_SERVICE_INSTANCE "${POSTGRES_SERVICE_INSTANCE}"
set_env POSTGRES_SERVICE_KEY_NAME "${POSTGRES_SERVICE_KEY_NAME}"
set_env POSTGRES_SQL_FILE "${POSTGRES_SQL_FILE}"
set_env APPLICATION_CONTAINER_NAME_BACKEND "${APPLICATION_CONTAINER_NAME_BACKEND}"
set_env APPLICATION_CONTAINER_NAME_FRONTEND "${APPLICATION_CONTAINER_NAME_FRONTEND}"
set_env APPLICATION_CATEGORY "${APPLICATION_CATEGORY}"
set_env CODE_ENGINE_PROJECT_NAME "${CODE_ENGINE_PROJECT_NAME}"
set_env IBM_KUBERNETES_SERVICE_NAME "${IBM_KUBERNETES_SERVICE_NAME}"
set_env IBM_KUBERNETES_SERVICE_NAMESPACE "${IBM_KUBERNETES_SERVICE_NAMESPACE}"