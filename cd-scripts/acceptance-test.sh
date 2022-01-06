#!/usr/bin/bash

export TARGET_ENVIRONMENT
export HOME
export DEPLOYMENT_DELTA

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

test_count=0

#
# prepare acceptance tests
#
source /root/.nvm/nvm.sh
npm ci

#
# iterate over inventory deployment delta
# and run acceptance tests
#
exit_code=0
for INVENTORY_ENTRY in $(echo "${DEPLOYMENT_DELTA}" | jq -r '.[] '); do
  APP_URL_PATH="$(echo ${INVENTORY_ENTRY} | sed 's/\//_/g')_app-url.json"
  if [[ -f "../$APP_URL_PATH" ]]; then
    export APP_URL=$(cat "../${APP_URL_PATH}")

    echo "Running acceptance test for: '$APP_URL_PATH'"
    if ! npm run acceptance-test; then
      exit_code=1
    fi
    ((test_count+=1))
  fi
done

echo "Run $test_count tests for $(echo "${DEPLOYMENT_DELTA}" | jq '. | length') entries"
exit $exit_code
