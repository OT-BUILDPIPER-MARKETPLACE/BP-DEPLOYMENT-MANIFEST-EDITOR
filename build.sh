#!/bin/bash

source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh

TASK_STATUS=0

CODEBASE_LOCATION="/bp/data/k8s_manifest"
DEPLOYMENT_FILE="$CODEBASE_LOCATION/deployment.yaml"

logInfoMessage "I'll build the code available at [$CODEBASE_LOCATION]"

# Check if yq is installed
yq --version &>/dev/null
if [ $? -ne 0 ]; then
    logErrorMessage "yq is not installed. Please install it before running this script."
    exit 1
fi

# Check if deployment.yaml exists
if [ ! -f "$DEPLOYMENT_FILE" ]; then
    logErrorMessage "Deployment file not found at $DEPLOYMENT_FILE"
    exit 1
fi

TASK_STATUS=$?

# Check if NEW_SERVICE_ACCOUNT is provided
if [[ -z "$NEW_SERVICE_ACCOUNT" ]]; then
    logWarningMessage "No new service account name provided. Continuing with the pre-configured name."
    NEW_SERVICE_ACCOUNT=$(yq e '.spec.template.spec.serviceAccountName' "$DEPLOYMENT_FILE")
    logInfoMessage "Using pre-configured service account: $NEW_SERVICE_ACCOUNT"
else
    logInfoMessage "Updating serviceAccountName to: $NEW_SERVICE_ACCOUNT"
    yq e -i ".spec.template.spec.serviceAccountName = \"$NEW_SERVICE_ACCOUNT\"" "$DEPLOYMENT_FILE"
    logInfoMessage "serviceAccountName updated successfully!"
fi

TASK_STATUS=$?

saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
