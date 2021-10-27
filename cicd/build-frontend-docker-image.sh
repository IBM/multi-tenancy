#!/bin/bash
# uncomment to debug the script
#set -x
# copy the script below into your app code repo (e.g. ./scripts/build_image.sh) and 'source' it from your pipeline job
#    source ./scripts/build_image.sh
# alternatively, you can source it from online script:
#    source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/build_image.sh")
# ------------------
# source: https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/build_image.sh

# This script does build a Docker image into IBM Container Service private image registry, and copies information into
# a build.properties file, so they can be reused later on by other scripts (e.g. image url, chart name, ...)
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "ARCHIVE_DIR=${ARCHIVE_DIR}"
echo "GIT_BRANCH=${GIT_BRANCH}"
echo "GIT_COMMIT=${GIT_COMMIT}"
echo "DOCKER_ROOT=${DOCKER_ROOT}"
echo "DOCKER_FILE=${DOCKER_FILE}"
echo "CLIENT_ID=${CLIENT_ID}"
echo "DISCOVERYENDPOINT=${DISCOVERYENDPOINT}"
echo "CATEGORY_NAME=${CATEGORY_NAME}"
echo "HEADLINE=${HEADLINE}"

# View build properties
if [ -f build.properties ]; then 
  echo "build.properties:"
  cat build.properties
else 
  echo "build.properties : not found"
fi 
# also run 'env' command to find all available env variables
# or learn more about the available environment variables at:
# https://console.bluemix.net/docs/services/ContinuousDelivery/pipeline_deploy_var.html#deliverypipeline_environment

# To review or change build options use:
# bx cr build --help

echo -e "Existing images in registry"
ibmcloud cr images

# Minting image tag using format: BRANCH-BUILD_NUMBER-COMMIT_ID-TIMESTAMP
# e.g. master-3-50da6912-20181123114435

TIMESTAMP=$( date -u "+%Y%m%d%H%M%S")
IMAGE_TAG=${TIMESTAMP}
if [ ! -z "${GIT_COMMIT}" ]; then
  GIT_COMMIT_SHORT=$( echo ${GIT_COMMIT} | head -c 8 ) 
  IMAGE_TAG=${GIT_COMMIT_SHORT}-${IMAGE_TAG}
fi
IMAGE_TAG=${BUILD_NUMBER}-${IMAGE_TAG}
if [ ! -z "${GIT_BRANCH}" ]; then IMAGE_TAG=${GIT_BRANCH}-${IMAGE_TAG} ; fi
echo "=========================================================="
echo -e "BUILDING CONTAINER IMAGE: ${IMAGE_NAME}:${IMAGE_TAG}"
#if [ -z "${DOCKER_ROOT}" ]; then DOCKER_ROOT=. ; fi
#if [ -z "${DOCKER_FILE}" ]; then DOCKER_FILE=${DOCKER_ROOT}/Dockerfile ; fi
set -x

cd /workspace/code/frontend/

rm -f public/env-config.js

touch public/env-config.js

echo "window.VUE_APPID_CLIENT_ID='b3adeb3b-36fc-40cb-9bc3-dd6f15047195'" >> public/env-config.js
echo "window.VUE_APPID_DISCOVERYENDPOINT='https://us-south.appid.cloud.ibm.com/oauth/v4/a7ec8ce4-3602-42c7-8e88-6f8a9db31935/.well-known/openid-configuration'" >>  public/env-config.js
echo 'window.VUE_APP_CATEGORY_NAME="Movies"' >>  public/env-config.js
echo 'window.VUE_APP_HEADLINE="Electronic and Movie Depot"' >>  public/env-config.js

echo 'window.VUE_APP_API_URL_CATEGORIES="https://service-catalog.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/base/category"' >>  public/env-config.js
echo 'window.VUE_APP_API_URL_PRODUCTS="https://service-catalog.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/base/category/"' >>  public/env-config.js
echo 'window.VUE_APP_API_URL_ORDERS="https://service-catalog.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/base/Customer/Orders"' >>  public/env-config.js

#ibmcloud cr build --file Dockerfile --tag ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG} .
ibmcloud cr build --file Dockerfile.os4-webapp --tag ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/frontend:latest .
set +x

ibmcloud cr image-inspect ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/frontend:latest

# Set PIPELINE_IMAGE_URL for subsequent jobs in stage (e.g. Vulnerability Advisor)
export PIPELINE_IMAGE_URL="$REGISTRY_URL/$REGISTRY_NAMESPACE/frontend:latest"

ibmcloud cr images --restrict ${REGISTRY_NAMESPACE}/frontend

######################################################################################
# Copy any artifacts that will be needed for deployment and testing to $WORKSPACE    #
######################################################################################
echo "=========================================================="
echo "COPYING ARTIFACTS needed for deployment and testing (in particular build.properties)"

echo "Checking archive dir presence"
if [ -z "${ARCHIVE_DIR}" ]; then
  echo -e "Build archive directory contains entire working directory."
else
  echo -e "Copying working dir into build archive directory: ${ARCHIVE_DIR} "
  mkdir -p ${ARCHIVE_DIR}
  find . -mindepth 1 -maxdepth 1 -not -path "./$ARCHIVE_DIR" -exec cp -R '{}' "${ARCHIVE_DIR}/" ';'
fi

# Persist env variables into a properties file (build.properties) so that all pipeline stages consuming this
# build as input and configured with an environment properties file valued 'build.properties'
# will be able to reuse the env variables in their job shell scripts.

# If already defined build.properties from prior build job, append to it.
cp build.properties $ARCHIVE_DIR/ || :

# IMAGE information from build.properties is used in Helm Chart deployment to set the release name
echo "IMAGE_NAME=${IMAGE_NAME}" >> $ARCHIVE_DIR/build.properties
echo "IMAGE_TAG=${IMAGE_TAG}" >> $ARCHIVE_DIR/build.properties
# REGISTRY information from build.properties is used in Helm Chart deployment to generate cluster secret
echo "REGISTRY_URL=${REGISTRY_URL}" >> $ARCHIVE_DIR/build.properties
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}" >> $ARCHIVE_DIR/build.properties
echo "GIT_BRANCH=${GIT_BRANCH}" >> $ARCHIVE_DIR/build.properties
echo "File 'build.properties' created for passing env variables to subsequent pipeline jobs:"
cat $ARCHIVE_DIR/build.properties
