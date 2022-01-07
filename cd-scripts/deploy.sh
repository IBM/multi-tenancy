#!/usr/bin/env bash

echo "niklas deploy.sh"
IBM_KUBERNETES_SERVICE_NAMESPACE=$(get_env "IBM_KUBERNETES_SERVICE_NAMESPACE")-prod
IBMCLOUD_IKS_CLUSTER_NAMESPACE=${IBM_KUBERNETES_SERVICE_NAMESPACE}

#
# create cluster namespace
#
if kubectl get namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE"; then
  echo "Namespace ${IBMCLOUD_IKS_CLUSTER_NAMESPACE} found!"
else
  kubectl create namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE";
fi

deploy_count=0
overall_status=success

DEPLOYMENT_DELTA_PATH="$(cat /config/deployment-delta-path)"
DEPLOYMENT_DELTA=$(cat "${DEPLOYMENT_DELTA_PATH}")
INVENTORY_PATH="$(cat /config/inventory-path)"

echo "niklas deployment_delta"
echo "${DEPLOYMENT_DELTA}"

ls -la /config








if kubectl get secret -n "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" "$IMAGE_PULL_SECRET_NAME"; then
  echo "Image pull secret ${IMAGE_PULL_SECRET_NAME} found!"
else
  if [[ -n "$BREAK_GLASS" ]]; then
    kubectl create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $IMAGE_PULL_SECRET_NAME
  namespace: $IBMCLOUD_IKS_CLUSTER_NAMESPACE
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: $(jq .parameters.docker_config_json /config/artifactory)
EOF
  else
    kubectl create secret docker-registry \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --docker-server "$REGISTRY_URL" \
      --docker-password "$IBMCLOUD_API_KEY" \
      --docker-username iamapikey \
      --docker-email ibm@example.com \
      "$IMAGE_PULL_SECRET_NAME"
  fi
fi

if kubectl get serviceaccount -o json default --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" | jq -e 'has("imagePullSecrets")'; then
  if kubectl get serviceaccount -o json default --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" | jq --arg name "$IMAGE_PULL_SECRET_NAME" -e '.imagePullSecrets[] | select(.name == $name)'; then
    echo "Image pull secret $IMAGE_PULL_SECRET_NAME found in $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
  else
    echo "Adding image pull secret $IMAGE_PULL_SECRET_NAME to $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
    kubectl patch serviceaccount \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --type json \
      --patch '[{"op": "add", "path": "/imagePullSecrets/-", "value": {"name": "'"$IMAGE_PULL_SECRET_NAME"'"}}]' \
      default
  fi
else
  echo "Adding image pull secret $IMAGE_PULL_SECRET_NAME to $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
  kubectl patch serviceaccount \
    --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
    --patch '{"imagePullSecrets":[{"name":"'"$IMAGE_PULL_SECRET_NAME"'"}]}' \
    default
fi


#####################

ibmcloud resource service-key ${POSTGRES_SERVICE_KEY_NAME} --output JSON > ./postgres-key-temp.json  
POSTGRES_CERTIFICATE_CONTENT_ENCODED=$(cat ./postgres-key-temp.json | jq '.[].credentials.connection.cli.certificate.certificate_base64' | sed 's/"//g' ) 
POSTGRES_USERNAME=$(cat ./postgres-key-temp.json | jq '.[].credentials.connection.postgres.authentication.username' | sed 's/"//g' )
POSTGRES_PASSWORD=$(cat ./postgres-key-temp.json | jq '.[].credentials.connection.postgres.authentication.password' | sed 's/"//g' )
POSTGRES_HOST=$(cat ./postgres-key-temp.json | jq '.[].credentials.connection.postgres.hosts[].hostname' | sed 's/"//g' )
POSTGRES_PORT=$(cat ./postgres-key-temp.json | jq '.[].credentials.connection.postgres.hosts[].port' | sed 's/"//g' )
POSTGRES_CERTIFICATE_DATA=$(echo "$POSTGRES_CERTIFICATE_CONTENT_ENCODED" | base64 -d)

POSTGRES_CONNECTION_TYPE='jdbc:postgresql://'
POSTGRES_CERTIFICATE_PATH='/cloud-postgres-cert'
POSTGRES_DATABASE_NAME="ibmclouddb"
POSTGRES_URL="$POSTGRES_CONNECTION_TYPE$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE_NAME?sslmode=verify-full&sslrootcert=$POSTGRES_CERTIFICATE_PATH"

#####################

ibmcloud resource service-key ${APPID_SERVICE_KEY_NAME} --output JSON > ./appid-key-temp.json
APPID_OAUTHSERVERURL=$(cat ./appid-key-temp.json | jq '.[].credentials.oauthServerUrl' | sed 's/"//g' ) 
APPID_CLIENT_ID=$(cat ./appid-key-temp.json | jq '.[].credentials.clientId' | sed 's/"//g' )

#####################

kubectl create secret generic postgres.certificate-data \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --from-literal "POSTGRES_CERTIFICATE_DATA=$POSTGRES_CERTIFICATE_DATA"
kubectl create secret generic postgres.username \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --from-literal "POSTGRES_USERNAME=$POSTGRES_USERNAME"
kubectl create secret generic postgres.password \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --from-literal "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
kubectl create secret generic postgres.url \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --from-literal "POSTGRES_URL=$POSTGRES_URL"

kubectl create secret generic appid.oauthserverurl \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --from-literal "APPID_AUTH_SERVER_URL=$APPID_OAUTHSERVERURL"
kubectl create secret generic appid.client-id-catalog-service \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --from-literal "APPID_CLIENT_ID=$APPID_CLIENT_ID"

#####################








#
# iterate over inventory deployment delta
#
for INVENTORY_ENTRY in $(echo "${DEPLOYMENT_DELTA}" | jq -r '.[] '); do

  APP=$(cat "${INVENTORY_PATH}/${INVENTORY_ENTRY}")

  if [ -z "$(echo "${APP}" | jq -r '.name' 2> /dev/null)" ]; then continue ; fi # skip non artifact file

  APP_NAME=$(echo "${APP}" | jq -r '.name')

  if [[ $APP_NAME =~ _deployment$ ]]; then continue ; fi # skip deployment yamls

  ARTIFACT=$(echo "${APP}" | jq -r '.artifact')
  REGISTRY_URL="$(echo "${ARTIFACT}" | awk -F/ '{print $1}')"
  IMAGE="${ARTIFACT}"
  IMAGE_PULL_SECRET_NAME="ibmcloud-toolchain-${IBMCLOUD_TOOLCHAIN_ID}-${REGISTRY_URL}"

  #
  # create pull secrets for the image registry
  #
  if kubectl get secret -n "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" "$IMAGE_PULL_SECRET_NAME"; then
    echo "Image pull secret ${IMAGE_PULL_SECRET_NAME} found!"
  else
    if [[ -n "$BREAK_GLASS" ]]; then
      kubectl create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $IMAGE_PULL_SECRET_NAME
  namespace: $IBMCLOUD_IKS_CLUSTER_NAMESPACE
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: $(jq .parameters.docker_config_json /config/artifactory)
EOF
    else
      kubectl create secret docker-registry \
        --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
        --docker-server "$REGISTRY_URL" \
        --docker-password "$IBMCLOUD_API_KEY" \
        --docker-username iamapikey \
        --docker-email ibm@example.com \
        "$IMAGE_PULL_SECRET_NAME"
    fi
  fi

  if kubectl get serviceaccount -o json default --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" | jq -e 'has("imagePullSecrets")'; then
    if kubectl get serviceaccount -o json default --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" | jq --arg name "$IMAGE_PULL_SECRET_NAME" -e '.imagePullSecrets[] | select(.name == $name)'; then
      echo "Image pull secret $IMAGE_PULL_SECRET_NAME found in $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
    else
      echo "Adding image pull secret $IMAGE_PULL_SECRET_NAME to $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
      kubectl patch serviceaccount \
        --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
        --type json \
        --patch '[{"op": "add", "path": "/imagePullSecrets/-", "value": {"name": "'"$IMAGE_PULL_SECRET_NAME"'"}}]' \
        default
    fi
  else
    echo "Adding image pull secret $IMAGE_PULL_SECRET_NAME to $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
    kubectl patch serviceaccount \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --patch '{"imagePullSecrets":[{"name":"'"$IMAGE_PULL_SECRET_NAME"'"}]}' \
      default
  fi

  #
  # get the deployment yaml for the app from inventory
  #
  DEPLOYMENT_INVENTORY=$(cat "${INVENTORY_PATH}/${INVENTORY_ENTRY}_deployment")
  NORMALIZED_APP_NAME=$(echo "${APP_NAME}" | sed 's/\//--/g')

  # we're in the deploy script folder, the GIT token is one folder up
  # provide git token to download artifacts. In sample app artifacts are stored in the app repo
  # If your app is GitHub based then you need to provide your personal access token in the environment property.
  export GIT_TOKEN
  if [[ -z $(get_env artifact-token "") ]]; then
    GIT_TOKEN="$(cat ../git-token)"
  else
    GIT_TOKEN="$(get_env artifact-token)"
  fi
  #
  # read inventory entry for artifact
  #
  ARTIFACT_URL=$(echo "$DEPLOYMENT_INVENTORY" | jq -r '.artifact')

  #
  # download artifact
  #
  DEPLOYMENT_FILE="${NORMALIZED_APP_NAME}-deployment.yaml"
  echo "niklas DEPLOYMENT_FILE"
  echo ${DEPLOYMENT_FILE}

  if [[ "${ARTIFACT_URL}" == *"github"* ]]; then
    http_response=$(curl -H "Authorization: token ${GIT_TOKEN}" -s -w "%{http_code}\n" ${ARTIFACT_URL} -o $DEPLOYMENT_FILE)
  else
    http_response=$(curl -H "PRIVATE-TOKEN: ${GIT_TOKEN}" -s -w "%{http_code}\n" ${ARTIFACT_URL} -o $DEPLOYMENT_FILE)
  fi
  if [ "$http_response" != "200" ]; then
    echo "Failed to download the artifact. Please provide the correct token as the env property 'artifact-token'."
  fi




  #sed -i "s#hello-compliance-app#${NORMALIZED_APP_NAME}#g" $DEPLOYMENT_FILE
  #sed -i "s#hello-service#${NORMALIZED_APP_NAME}-service#g" $DEPLOYMENT_FILE
  sed -i "s~^\([[:blank:]]*\)image:.*$~\1image: ${IMAGE}~" $DEPLOYMENT_FILE

  CLUSTER_INGRESS_SUBDOMAIN=$( ibmcloud ks cluster get --cluster ${IBMCLOUD_IKS_CLUSTER_NAME} --json | jq -r '.ingressHostname // .ingress.hostname' | cut -d, -f1 )
  CLUSTER_INGRESS_SECRET=$( ibmcloud ks cluster get --cluster ${IBMCLOUD_IKS_CLUSTER_NAME} --json | jq -r '.ingressSecretName // .ingress.secretName' | cut -d, -f1 )
  if [ ! -z "${CLUSTER_INGRESS_SUBDOMAIN}" ] && [ "${KEEP_INGRESS_CUSTOM_DOMAIN}" != true ]; then
    echo "=========================================================="
    echo "UPDATING manifest with ingress information"
    INGRESS_DOC_INDEX=$(yq read --doc "*" --tojson $DEPLOYMENT_FILE | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="ingress") | .key')
    if [ -z "$INGRESS_DOC_INDEX" ]; then
      echo "No Kubernetes Ingress definition found in $DEPLOYMENT_FILE."
    else
      # Update ingress with cluster domain/secret information
      # Look for ingress rule whith host contains the token "cluster-ingress-subdomain"
      INGRESS_RULES_INDEX=$(yq r --doc $INGRESS_DOC_INDEX --tojson $DEPLOYMENT_FILE | jq '.spec.rules | to_entries | .[] | select( .value.host | contains("cluster-ingress-subdomain")) | .key')
      if [ ! -z "$INGRESS_RULES_INDEX" ]; then
        INGRESS_RULE_HOST=$(yq r --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.rules[${INGRESS_RULES_INDEX}].host)
        HOST_APP_NAME="$(cut -d'.' -f1 <<<"$INGRESS_RULE_HOST")"
        HOST_APP_NAME_DEPLOYMENT=${HOST_APP_NAME}-deployment
        yq w --inplace --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.rules[${INGRESS_RULES_INDEX}].host ${INGRESS_RULE_HOST/$HOST_APP_NAME/$HOST_APP_NAME_DEPLOYMENT}
        INGRESS_RULE_HOST=$(yq r --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.rules[${INGRESS_RULES_INDEX}].host)
        yq w --inplace --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.rules[${INGRESS_RULES_INDEX}].host ${INGRESS_RULE_HOST/cluster-ingress-subdomain/$CLUSTER_INGRESS_SUBDOMAIN}
      fi
      # Look for ingress tls whith secret contains the token "cluster-ingress-secret"
      INGRESS_TLS_INDEX=$(yq r --doc $INGRESS_DOC_INDEX --tojson $DEPLOYMENT_FILE | jq '.spec.tls | to_entries | .[] | select(.secretName="cluster-ingress-secret") | .key')
      if [ ! -z "$INGRESS_TLS_INDEX" ]; then
        yq w --inplace --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.tls[${INGRESS_TLS_INDEX}].secretName $CLUSTER_INGRESS_SECRET
        INGRESS_TLS_HOST_INDEX=$(yq r --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.tls[${INGRESS_TLS_INDEX}] --tojson | jq '.hosts | to_entries | .[] | select( .value | contains("cluster-ingress-subdomain")) | .key')
        if [ ! -z "$INGRESS_TLS_HOST_INDEX" ]; then
          INGRESS_TLS_HOST=$(yq r --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.tls[${INGRESS_TLS_INDEX}].hosts[$INGRESS_TLS_HOST_INDEX])
          HOST_APP_NAME="$(cut -d'.' -f1 <<<"$INGRESS_TLS_HOST")"
          HOST_APP_NAME_DEPLOYMENT=${HOST_APP_NAME}-deployment
          yq w --inplace --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.tls[${INGRESS_TLS_INDEX}].hosts[$INGRESS_TLS_HOST_INDEX] ${INGRESS_TLS_HOST/$HOST_APP_NAME/$HOST_APP_NAME_DEPLOYMENT}
          INGRESS_TLS_HOST=$(yq r --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.tls[${INGRESS_TLS_INDEX}].hosts[$INGRESS_TLS_HOST_INDEX])
          yq w --inplace --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE spec.tls[${INGRESS_TLS_INDEX}].hosts[$INGRESS_TLS_HOST_INDEX] ${INGRESS_TLS_HOST/cluster-ingress-subdomain/$CLUSTER_INGRESS_SUBDOMAIN}
        fi
      fi
      if kubectl explain route > /dev/null 2>&1; then 
        if kubectl get secret ${CLUSTER_INGRESS_SECRET} --namespace=openshift-ingress; then
          if kubectl get secret ${CLUSTER_INGRESS_SECRET} --namespace ${IBMCLOUD_IKS_CLUSTER_NAMESPACE}; then 
            echo "TLS Secret exists in the ${IBMCLOUD_IKS_CLUSTER_NAMESPACE} namespace."
          else 
            echo "TLS Secret does not exists in the ${IBMCLOUD_IKS_CLUSTER_NAMESPACE} namespace. Copying from openshift-ingress."
            kubectl get secret ${CLUSTER_INGRESS_SECRET} --namespace=openshift-ingress -oyaml | grep -v '^\s*namespace:\s' | kubectl apply --namespace=${IBMCLOUD_IKS_CLUSTER_NAMESPACE} -f -
          fi
        fi
      fi
    fi
  fi


  deployment_name=$(yq r "$DEPLOYMENT_FILE" metadata.name)
  service_name=$(yq r -d1 "$DEPLOYMENT_FILE" metadata.name)


  #
  # deploy the app
  #
  kubectl apply --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" -f $DEPLOYMENT_FILE
  if kubectl rollout status --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" "deployment/$deployment_name"; then
      status=success
      ((deploy_count+=1))
  else
      status=failure
  fi

  kubectl get events --sort-by=.metadata.creationTimestamp -n "$IBMCLOUD_IKS_CLUSTER_NAMESPACE"

  if [ "$status" == failure ]; then
      echo "Deployment failed"
      ibmcloud cr quota
      overall_status=failure
      break
  fi


if [ ! -z "${CLUSTER_INGRESS_SUBDOMAIN}" ] && [ "${KEEP_INGRESS_CUSTOM_DOMAIN}" != true ]; then
  INGRESS_DOC_INDEX=$(yq read --doc "*" --tojson $DEPLOYMENT_FILE | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="ingress") | .key')
  if [ -z "$INGRESS_DOC_INDEX" ]; then
    echo "No Kubernetes Ingress definition found in $DEPLOYMENT_FILE."
  else
     service_name=$(yq r --doc $INGRESS_DOC_INDEX $DEPLOYMENT_FILE metadata.name)  
     APPURL=$(kubectl get ing ${service_name} --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" -o json | jq -r  .spec.rules[0].host)
     echo "Application URL: https://${APPURL}/category/2/products"
     APP_URL_PATH="$(echo "${INVENTORY_ENTRY}" | sed 's/\//_/g')_app-url.json"
     echo -n https://${APPURL} > ../app-url
  fi

else 

  IP_ADDRESS=$(kubectl get nodes -o json | jq -r '[.items[] | .status.addresses[] | select(.type == "ExternalIP") | .address] | .[0]')
  PORT=$(kubectl get service -n  "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" "$service_name" -o json | jq -r '.spec.ports[0].nodePort')

  echo "Application URL: http://${IP_ADDRESS}:${PORT}/category/2/products"

  APP_URL_PATH="$(echo "${INVENTORY_ENTRY}" | sed 's/\//_/g')_app-url.json"

  echo -n "http://${IP_ADDRESS}:${PORT}" > "../$APP_URL_PATH"

fi

 

done

echo "Deployed $deploy_count from $(echo "${DEPLOYMENT_DELTA}" | jq '. | length') entries"

if [ "$overall_status" == failure ]; then
    echo "Overall deployment failed"
    kubectl get events --sort-by=.metadata.creationTimestamp -n "$IBMCLOUD_IKS_CLUSTER_NAMESPACE"
    ibmcloud cr quota
    exit 1
fi
