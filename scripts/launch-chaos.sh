#!/bin/bash

set -x

# curl -sL https://github.com/uditgaurav/hce-api-template/releases/download/0.1.0-saas/hce-api-linux-amd64 -o hce-api-saas
# curl -sL https://storage.googleapis.com/hce-api/hce-api-linux-amd64 -o hce-api-saas
curl -Lo ./hce-api-saas https://app.harness.io/public/shared/tools/chaos/hce-cli/0.0.4/hce-cli-0.0.4-linux-amd64

ls -lh hce-api-saas
chmod +x hce-api-saas

./hce-api-saas generate --api launch-experiment --account-id=${ACCOUNT_ID} --project-id ${PROJECT_ID} --workflow-id ${WORKFLOW_ID} --api-key ${API_KEY} --file-name hce-api.sh
