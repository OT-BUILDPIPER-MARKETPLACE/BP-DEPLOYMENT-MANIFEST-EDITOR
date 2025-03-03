#!/bin/bash

source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source getDynamicVars.sh

TASK_STATUS=0

# Main logic to check conditions and call fetch_service_details
if [ -n "$SOURCE_VARIABLE_REPO" ]; then
    # Check if NEW_SERVICE_ACCOUNT is provided
    if [ -n "$NEW_SERVICE_ACCOUNT" ]; then
        echo "NEW_SERVICE_ACCOUNT is provided. Skipping fetching details from SOURCE_VARIABLE_REPO."
    else
        echo "Fetching details from $SOURCE_VARIABLE_REPO as NEW_SERVICE_ACCOUNT is not provided."
        fetch_service_details
    fi
else
    logErrorMessage "SOURCE_VARIABLE_REPO is not defined. Skipping fetching details from $SOURCE_VARIABLE_REPO."
fi

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

# Fetch the current serviceAccountName
CURRENT_SERVICE_ACCOUNT=$(yq e '.spec.template.spec.serviceAccountName' "$DEPLOYMENT_FILE")

# Check if NEW_SERVICE_ACCOUNT is provided and not empty
if [[ -n "$NEW_SERVICE_ACCOUNT" && "$NEW_SERVICE_ACCOUNT" != "null" ]]; then
    logInfoMessage "Updating serviceAccountName to: $NEW_SERVICE_ACCOUNT"
    yq e -i ".spec.template.spec.serviceAccountName = \"$NEW_SERVICE_ACCOUNT\"" "$DEPLOYMENT_FILE"
    logInfoMessage "serviceAccountName updated successfully!"
else
    logWarningMessage "No valid new service account name provided. Keeping existing service account: $CURRENT_SERVICE_ACCOUNT"
fi

# Main logic to check conditions and call fetch_service_details
if [ -n "$SOURCE_VARIABLE_REPO" ]; then
    # Check if NEW_SERVICE_ACCOUNT is provided
    if [[ -n "$fsGroup" && -n "$runAsUser" ]]; then
        echo "fsGroup and runAsUser are provided. Skipping fetching details from SOURCE_VARIABLE_REPO."
    else
        echo "Fetching details from $SOURCE_VARIABLE_REPO as fsGroup and runAsUser are not provided."
        fetch_service_details
    fi
else
    logErrorMessage "SOURCE_VARIABLE_REPO is not defined. Skipping fetching details from $SOURCE_VARIABLE_REPO."
fi

# Update securityContext with fsGroup and runAsUser
if [[ -n "$fsGroup" && -n "$runAsUser" ]]; then
    logInfoMessage "Updating securityContext with fsGroup: $fsGroup and runAsUser: $runAsUser"
    yq e -i ".spec.template.spec.securityContext.fsGroup = $fsGroup" "$DEPLOYMENT_FILE"
    yq e -i ".spec.template.spec.securityContext.runAsUser = $runAsUser" "$DEPLOYMENT_FILE"
    logInfoMessage "securityContext updated successfully!"
else
    logWarningMessage "fsGroup or runAsUser values are missing. Skipping securityContext update."
fi

# Ensure securityContext exists in containers
logInfoMessage "Updating securityContext in container specification"
yq e -i '.spec.template.spec.containers[].securityContext.allowPrivilegeEscalation = false' "$DEPLOYMENT_FILE"
yq e -i '.spec.template.spec.containers[].securityContext.capabilities.drop = ["ALL"]' "$DEPLOYMENT_FILE"
yq e -i '.spec.template.spec.containers[].securityContext.readOnlyRootFilesystem = true' "$DEPLOYMENT_FILE"
yq e -i '.spec.template.spec.containers[].securityContext.runAsNonRoot = true' "$DEPLOYMENT_FILE"
yq e -i '.spec.template.spec.containers[].securityContext.seccompProfile.type = "RuntimeDefault"' "$DEPLOYMENT_FILE"

logInfoMessage "Container securityContext updated successfully!"

TASK_STATUS=$?

saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
