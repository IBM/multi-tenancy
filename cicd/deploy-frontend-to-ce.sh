#!/bin/bash
# uncomment to debug the script
#set -x
# copy the script below into your app code repo (e.g. ./scripts/deploy_kubectl.sh) and 'source' it from your pipeline job
#    source ./scripts/deploy_kubectl.sh
# alternatively, you can source it from online script:
#    source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/deploy_kubectl.sh")
# ------------------
# source: https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/deploy_kubectl.sh
# Input env variables (can be received via a pipeline environment properties.file.
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "IMAGE_TAG=${IMAGE_TAG}"
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"
echo "DEPLOYMENT_FILE=${DEPLOYMENT_FILE}"

#View build properties
# cat build.properties
# also run 'env' command to find all available env variables
# or learn more about the available environment variables at:
# https://console.bluemix.net/docs/services/ContinuousDelivery/pipeline_deploy_var.html#deliverypipeline_environment

# Input env variables from pipeline job
#echo "PIPELINE_KUBERNETES_CLUSTER_NAME=${PIPELINE_KUBERNETES_CLUSTER_NAME}"
#if [ -z "${CLUSTER_NAMESPACE}" ]; then CLUSTER_NAMESPACE=default ; fi
#echo "CLUSTER_NAMESPACE=${CLUSTER_NAMESPACE}"

#echo "=========================================================="
#echo "DEPLOYING using manifest"
#echo -e "Updating ${DEPLOYMENT_FILE} with image name: ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}"
#if [ -z "${DEPLOYMENT_FILE}" ]; then DEPLOYMENT_FILE=deployment.yml ; fi
#if [ -f ${DEPLOYMENT_FILE} ]; then
#    sed -i "s~^\([[:blank:]]*\)image:.*$~\1image: ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}~" ${DEPLOYMENT_FILE}
#    cat ${DEPLOYMENT_FILE}
#else 
#    echo -e "${red}Kubernetes deployment file '${DEPLOYMENT_FILE}' not found${no_color}"
#    exit 1
#fi    
set -x
#kubectl apply --namespace ${CLUSTER_NAMESPACE} -f ${DEPLOYMENT_FILE} 

ibmcloud plugin install code-engine
ibmcloud resource groups
ibmcloud target -g Default
ibmcloud ce project select --name multi-tenant
#ibmcloud ce registry create --name ibm-container-registry --server us.icr.io --username iamapikey --password $API

ibmcloud ce application create --name frontend-a --image us.icr.io/multi-tenancy-cr/frontend:latest --port 8081 --rs test
set +x

echo ""
echo "=========================================================="
IMAGE_REPOSITORY=${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}
echo -e "CHECKING deployment status of ${IMAGE_REPOSITORY}:${IMAGE_TAG}"
echo ""
#for ITERATION in {1..30}
#do
#  DATA=$( kubectl get pods --namespace ${CLUSTER_NAMESPACE} -o json )
#  NOT_READY=$( echo $DATA | jq '.items[].status | select(.containerStatuses!=null) | .containerStatuses[] | select(.image=="'"${IMAGE_REPOSITORY}:${IMAGE_TAG}"'") | select(.ready==false) ' )
#  if [[ -z "$NOT_READY" ]]; then
#    echo -e "All pods are ready:"
#    echo $DATA | jq '.items[].status | select(.containerStatuses!=null) | .containerStatuses[] | select(.image=="'"${IMAGE_REPOSITORY}:${IMAGE_TAG}"'") | select(.ready==true) '
#    break # deployment succeeded
#  fi
#  REASON=$(echo $DATA | jq '.items[].status | select(.containerStatuses!=null) | .containerStatuses[] | select(.image=="'"${IMAGE_REPOSITORY}:${IMAGE_TAG}"'") | .state.waiting.reason')
#  echo -e "${ITERATION} : Deployment still pending..."
#  echo -e "NOT_READY:${NOT_READY}"
#  echo -e "REASON: ${REASON}"
#  if [[ ${REASON} == *ErrImagePull* ]] || [[ ${REASON} == *ImagePullBackOff* ]]; then
#    echo "Detected ErrImagePull or ImagePullBackOff failure. "
#    echo "Please check proper authenticating to from cluster to image registry (e.g. image pull secret)"
#    break; # no need to wait longer, error is fatal
#  elif [[ ${REASON} == *CrashLoopBackOff* ]]; then
#    echo "Detected CrashLoopBackOff failure. "
#    echo "Application is unable to start, check the application startup logs"
#    break; # no need to wait longer, error is fatal
#  fi
#  sleep 5
#done

#APP_NAME=$(kubectl get pods --namespace ${CLUSTER_NAMESPACE} -o json | jq -r '[ .items[] | select(.spec.containers[]?.image=="'"${IMAGE_REPOSITORY}:${IMAGE_TAG}"'") | .metadata.labels.app] [1]')
#echo -e "APP: ${APP_NAME}"
#echo "DEPLOYED PODS:"
#kubectl describe pods --selector app=${APP_NAME} --namespace ${CLUSTER_NAMESPACE}
#if [ ! -z "${APP_NAME}" ]; then
#  APP_SERVICE=$(kubectl get services --namespace ${CLUSTER_NAMESPACE} -o json | jq -r ' .items[] | select (.spec.selector.app=="'"${APP_NAME}"'") | .metadata.name ')
#  echo -e "SERVICE: ${APP_SERVICE}"
#  echo "DEPLOYED SERVICES:"
#  kubectl describe services ${APP_SERVICE} --namespace ${CLUSTER_NAMESPACE}
#fi
#echo "Application Logs"
#kubectl logs --selector app=${APP_NAME} --namespace ${CLUSTER_NAMESPACE}  
echo ""
#if [[ ! -z "$NOT_READY" ]]; then
#  echo ""
#  echo "=========================================================="
#  echo "DEPLOYMENT FAILED"
#  exit 1
#fi

echo ""
echo "=========================================================="
echo "DEPLOYMENT SUCCEEDED"
#if [ ! -z "${APP_SERVICE}" ]; then
#  echo ""
  # check if a route resource exists in the this kubernetes cluster
#  if kubectl explain route > /dev/null 2>&1; then
    # Assuming the kubernetes target cluster is an openshift cluster
    # Check if a route exists for exposing the service ${APP_SERVICE}
#    if  kubectl get routes --namespace ${CLUSTER_NAMESPACE} -o json | jq --arg service "$APP_SERVICE" -e '.items[] | select(.spec.to.name==$service)'; then
#      echo "Existing route to expose service $APP_SERVICE"
#    else
#      # create OpenShift route
#cat > test-route.json << EOF
#{"apiVersion":"route.openshift.io/v1","kind":"Route","metadata":{"name":"${APP_SERVICE}"},"spec":{"to":{"kind":"Service","name":"${APP_SERVICE}"}}}
#EOF
#      echo ""
#      cat test-route.json
#      kubectl apply -f test-route.json --validate=false --namespace ${CLUSTER_NAMESPACE}
#      kubectl get routes --namespace ${CLUSTER_NAMESPACE}
#    fi
#    echo "LOOKING for host in route exposing service $APP_SERVICE"
#    IP_ADDR=$(kubectl get routes --namespace ${CLUSTER_NAMESPACE} -o json | jq --arg service "$APP_SERVICE" -r '.items[] | select(.spec.to.name==$service) | .status.ingress[0].host')
#    PORT=80
#  else 
#    IP_ADDR=$(bx cs workers --cluster ${PIPELINE_KUBERNETES_CLUSTER_NAME} | grep normal | head -n 1 | awk '{ print $2 }')
#    PORT=$( kubectl get services --namespace ${CLUSTER_NAMESPACE} | grep ${APP_SERVICE} | sed 's/.*:\([0-9]*\).*/\1/g' )
#  fi
#  echo ""
#  echo -e "VIEW THE APPLICATION AT: http://${IP_ADDR}:${PORT}"
#fi
