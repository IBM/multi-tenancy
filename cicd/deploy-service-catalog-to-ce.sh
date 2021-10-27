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


#echo "default.datasource.certs=${default.datasource.certs:5df929c2-b76a-11e9-b3dd-4acf6c229d45}"

export default_datasource_username=${default_datasource_username:ibm_cloud_a66ff784_d8a6_4545_bb4c_b24dec4e02b8}
export default_datasource_password=${default_datasource_password:7f5dfe3c8d3eabcf52d15a7b81ce845a013e681ed753e063a4be3276a4461530}
export default_datasource_jdbc_url=${default_datasource_jdbc_url:jdbc:postgresql://3bd53622-20ce-426b-8232-cf6a3d0c52ce.bkvfv1ld0bj2bdbncbeg.databases.appdomain.cloud:30143/ibmclouddb}

export default_datasource_base_username=${default_datasource_base_username:ibm_cloud_a66ff784_d8a6_4545_bb4c_b24dec4e02b8}
export default_datasource_base_password=${default_datasource_base_password:7f5dfe3c8d3eabcf52d15a7b81ce845a013e681ed753e063a4be3276a4461530}
export default_datasource_base_jdbc.url=${default_datasource_base_jdbc.url:jdbc:postgresql://3bd53622-20ce-426b-8232-cf6a3d0c52ce.bkvfv1ld0bj2bdbncbeg.databases.appdomain.cloud:30143/ibmclouddb}

export default_datasource_mycompany_username=${default_datasource_mycompany_username:ibm_cloud_27df2776_ca1d_4e5d_acc8_79e557a60482}
export default_datasource_mycompany_password=${default_datasource_mycompany_password:1381b9739602be4254a0dedd56a5093f1d641414b3714643c3a8003b10efe146}
export default_datasource_mycompany_jdbc_url="jdbc\:${default.datasource.mycompany.jdbc.url:jdbc:postgresql://5e6b66a4-70b6-4caf-be8b-23cd2d1ed26b.c00no9sd0hobi6kj68i0.databases.appdomain.cloud:30266/ibmclouddb}"

export default_datasource_base_certs=${default_datasource_base_certs:5df929c2-b76a-11e9-b3dd-4acf6c229d45}

export default_datasource_mycompany_certs=${default_datasource_mycompany_certs:=2b11af40-8aa6-4b13-a424-1a9109624264}


export default_datasource_certs_data="${default_datasource_certs_data:=-----BEGIN CERTIFICATE-----
                                                                    MIIDDzCCAfegAwIBAgIJANEH58y2/kzHMA0GCSqGSIb3DQEBCwUAMB4xHDAaBgNV
                                                                    BAMME0lCTSBDbG91ZCBEYXRhYmFzZXMwHhcNMTgwNjI1MTQyOTAwWhcNMjgwNjIy
                                                                    MTQyOTAwWjAeMRwwGgYDVQQDDBNJQk0gQ2xvdWQgRGF0YWJhc2VzMIIBIjANBgkq
                                                                    hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA8lpaQGzcFdGqeMlmqjffMPpIQhqpd8qJ
                                                                    Pr3bIkrXJbTcJJ9uIckSUcCjw4Z/rSg8nnT13SCcOl+1to+7kdMiU8qOWKiceYZ5
                                                                    y+yZYfCkGaiZVfazQBm45zBtFWv+AB/8hfCTdNF7VY4spaA3oBE2aS7OANNSRZSK
                                                                    pwy24IUgUcILJW+mcvW80Vx+GXRfD9Ytt6PRJgBhYuUBpgzvngmCMGBn+l2KNiSf
                                                                    weovYDCD6Vngl2+6W9QFAFtWXWgF3iDQD5nl/n4mripMSX6UG/n6657u7TDdgkvA
                                                                    1eKI2FLzYKpoKBe5rcnrM7nHgNc/nCdEs5JecHb1dHv1QfPm6pzIxwIDAQABo1Aw
                                                                    TjAdBgNVHQ4EFgQUK3+XZo1wyKs+DEoYXbHruwSpXjgwHwYDVR0jBBgwFoAUK3+X
                                                                    Zo1wyKs+DEoYXbHruwSpXjgwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQsFAAOC
                                                                    AQEAJf5dvlzUpqaix26qJEuqFG0IP57QQI5TCRJ6Xt/supRHo63eDvKw8zR7tlWQ
                                                                    lV5P0N2xwuSl9ZqAJt7/k/3ZeB+nYwPoyO3KvKvATunRvlPBn4FWVXeaPsG+7fhS
                                                                    qsejmkyonYw77HRzGOzJH4Zg8UN6mfpbaWSsyaExvqknCp9SoTQP3D67AzWqb1zY
                                                                    doqqgGIZ2nxCkp5/FXxF/TMb55vteTQwfgBy60jVVkbF7eVOWCv0KaNHPF5hrqbN
                                                                    i+3XjJ7/peF3xMvTMoy35DcT3E2ZeSVjouZs15O90kI3k2daS2OHJABW0vSj4nLz
                                                                    +PQzp/B9cQmOO8dCe049Q3oaUA==
                                                                    -----END CERTIFICATE-----
                                        }"

export default_datasource_base_certs_data="${default_datasource_base_certs_data:-----BEGIN CERTIFICATE-----
                                                                    MIIDDzCCAfegAwIBAgIJANEH58y2/kzHMA0GCSqGSIb3DQEBCwUAMB4xHDAaBgNV
                                                                    BAMME0lCTSBDbG91ZCBEYXRhYmFzZXMwHhcNMTgwNjI1MTQyOTAwWhcNMjgwNjIy
                                                                    MTQyOTAwWjAeMRwwGgYDVQQDDBNJQk0gQ2xvdWQgRGF0YWJhc2VzMIIBIjANBgkq
                                                                    hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA8lpaQGzcFdGqeMlmqjffMPpIQhqpd8qJ
                                                                    Pr3bIkrXJbTcJJ9uIckSUcCjw4Z/rSg8nnT13SCcOl+1to+7kdMiU8qOWKiceYZ5
                                                                    y+yZYfCkGaiZVfazQBm45zBtFWv+AB/8hfCTdNF7VY4spaA3oBE2aS7OANNSRZSK
                                                                    pwy24IUgUcILJW+mcvW80Vx+GXRfD9Ytt6PRJgBhYuUBpgzvngmCMGBn+l2KNiSf
                                                                    weovYDCD6Vngl2+6W9QFAFtWXWgF3iDQD5nl/n4mripMSX6UG/n6657u7TDdgkvA
                                                                    1eKI2FLzYKpoKBe5rcnrM7nHgNc/nCdEs5JecHb1dHv1QfPm6pzIxwIDAQABo1Aw
                                                                    TjAdBgNVHQ4EFgQUK3+XZo1wyKs+DEoYXbHruwSpXjgwHwYDVR0jBBgwFoAUK3+X
                                                                    Zo1wyKs+DEoYXbHruwSpXjgwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQsFAAOC
                                                                    AQEAJf5dvlzUpqaix26qJEuqFG0IP57QQI5TCRJ6Xt/supRHo63eDvKw8zR7tlWQ
                                                                    lV5P0N2xwuSl9ZqAJt7/k/3ZeB+nYwPoyO3KvKvATunRvlPBn4FWVXeaPsG+7fhS
                                                                    qsejmkyonYw77HRzGOzJH4Zg8UN6mfpbaWSsyaExvqknCp9SoTQP3D67AzWqb1zY
                                                                    doqqgGIZ2nxCkp5/FXxF/TMb55vteTQwfgBy60jVVkbF7eVOWCv0KaNHPF5hrqbN
                                                                    i+3XjJ7/peF3xMvTMoy35DcT3E2ZeSVjouZs15O90kI3k2daS2OHJABW0vSj4nLz
                                                                    +PQzp/B9cQmOO8dCe049Q3oaUA==
                                                                    -----END CERTIFICATE-----
                                        }"


export "default_datasource_mycompany_certs_data=${default_datasource_mycompany_certs_data:-----BEGIN CERTIFICATE-----
                                                                    MIIDDzCCAfegAwIBAgIJANEH58y2/kzHMA0GCSqGSIb3DQEBCwUAMB4xHDAaBgNV
                                                                    BAMME0lCTSBDbG91ZCBEYXRhYmFzZXMwHhcNMTgwNjI1MTQyOTAwWhcNMjgwNjIy
                                                                    MTQyOTAwWjAeMRwwGgYDVQQDDBNJQk0gQ2xvdWQgRGF0YWJhc2VzMIIBIjANBgkq
                                                                    hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA8lpaQGzcFdGqeMlmqjffMPpIQhqpd8qJ
                                                                    Pr3bIkrXJbTcJJ9uIckSUcCjw4Z/rSg8nnT13SCcOl+1to+7kdMiU8qOWKiceYZ5
                                                                    y+yZYfCkGaiZVfazQBm45zBtFWv+AB/8hfCTdNF7VY4spaA3oBE2aS7OANNSRZSK
                                                                    pwy24IUgUcILJW+mcvW80Vx+GXRfD9Ytt6PRJgBhYuUBpgzvngmCMGBn+l2KNiSf
                                                                    weovYDCD6Vngl2+6W9QFAFtWXWgF3iDQD5nl/n4mripMSX6UG/n6657u7TDdgkvA
                                                                    1eKI2FLzYKpoKBe5rcnrM7nHgNc/nCdEs5JecHb1dHv1QfPm6pzIxwIDAQABo1Aw
                                                                    TjAdBgNVHQ4EFgQUK3+XZo1wyKs+DEoYXbHruwSpXjgwHwYDVR0jBBgwFoAUK3+X
                                                                    Zo1wyKs+DEoYXbHruwSpXjgwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQsFAAOC
                                                                    AQEAJf5dvlzUpqaix26qJEuqFG0IP57QQI5TCRJ6Xt/supRHo63eDvKw8zR7tlWQ
                                                                    lV5P0N2xwuSl9ZqAJt7/k/3ZeB+nYwPoyO3KvKvATunRvlPBn4FWVXeaPsG+7fhS
                                                                    qsejmkyonYw77HRzGOzJH4Zg8UN6mfpbaWSsyaExvqknCp9SoTQP3D67AzWqb1zY
                                                                    doqqgGIZ2nxCkp5/FXxF/TMb55vteTQwfgBy60jVVkbF7eVOWCv0KaNHPF5hrqbN
                                                                    i+3XjJ7/peF3xMvTMoy35DcT3E2ZeSVjouZs15O90kI3k2daS2OHJABW0vSj4nLz
                                                                    +PQzp/B9cQmOO8dCe049Q3oaUA==
                                                                    -----END CERTIFICATE-----

                                        }"


set -x

ibmcloud plugin install code-engine
ibmcloud resource groups
ibmcloud target -g Default
ibmcloud ce project select --name multi-tenant

ibmcloud ce application create --name service-catalog-a --image us.icr.io/multi-tenancy-cr/service-catalog:latest \
                                                        --port 8081 --rs test \
                                                        --env default.datasource.certs=${default_datasource_certs} \
                                                        --env default.datasource.certs.data=${default_datasource_certs_data} \
                                                        --env default.datasource.username=${default_datasource_username} \
                                                        --env default.datasource.password=${default_datasource_password} \
                                                        --env default.datasource.jdbc.url=${default_datasource_jdbc_url} \
                                                        --env default.datasource.base.certs=${default_datasource_base_certs} \
                                                        --env default.datasource.base.certs.data=${default_datasource_base_certs_data} \
                                                        --env default.datasource.base.username=${default_datasource_base_username} \
                                                        --env default.datasource.base.password=${default_datasource_base_password} \
                                                        --env default.datasource.base.jdbc.url=${default_datasource_base_jdbc_url} \
                                                        --env default.datasource.mycompany.certs=${default_datasource_mycompany_certs} \
                                                        --env default.datasource.mycompany.certs.data=${default_datasource_mycompany_certs_data} \
                                                        --env default.datasource.mycompany.username=${default_datasource_mycompany_username} \
                                                        --env default.datasource.mycompany.password=${default_datasource_mycompany_password} \
                                                        --env default.datasource.mycompany.jdbc.url=${default_datasource_mycompany_jdbc_url}

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
