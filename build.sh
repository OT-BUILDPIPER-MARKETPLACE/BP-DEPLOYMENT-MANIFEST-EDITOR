#!/bin/bash

source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source getDynamicVars.sh

TASK_STATUS=0

CANARY_STATUS=`canary_status`

canary_generator(){
    # check canary status available or not

    if [ -n $CANARY_STATUS ]; then
        echo "canary status not available!! hence exiting the canary_generator process"
        exit 1
    else
        echo "Canary Status:- ${CANARY_STATUS}"
    fi 

    # if canary is true call canaryTrafficManager else call rollingTrafficManager

    if ["$CANARY_STATUS" == "true"]; then
        echo "We will using the canaryTrafficManager process for traffic routing" 
        canaryTrafficManager
    else
        echo "We will using the rollingTrafficManager process for traffic routing"
        rollingTrafficManager
    fi

}

canaryTrafficManager(){
    CODEBASE_LOCATION="/bp/data/k8s_manifest"
    MAIN_SERVICE_FILE="$CODEBASE_LOCATION/service.yaml"

    #copying the main service file
    BASELINE_FILE="base-line-service.yaml"
    CANARY_FILE="canary-service.yaml"

    label_generator 

    # Check if the source file exists
    if [ -f "$MAIN_SERVICE_FILE" ]; then
    # Copy the source file to the baseline file
        cp "$MAIN_SERVICE_FILE" "$BASELINE_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $BASELINE_FILE"
        yq -i "
            .metadata.labels.${BASELINE_LABEL} = \"${BASELINE_LABEL_VALUE}\" |
            .spec.selector.${BASELINE_LABEL} = \"${BASELINE_LABEL_VALUE}\"
            " "$BASELINE_FILE"

    # Copy the source file to the canary file
        cp "$MAIN_SERVICE_FILE" "$CANARY_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $CANARY_FILE"
        yq -i "
            .metadata.labels.${CANARY_LABEL} = \"${CANARY_LABEL_VALUE}\" |
            .spec.selector.${CANARY_LABEL} = \"${CANARY_LABEL_VALUE}\"
            " "$CANARY_FILE"
    else
        echo "Error: Source file $MAIN_SERVICE_FILE not found."
        exit 1
    fi
}

rollingTrafficManager(){
    CODEBASE_LOCATION="/bp/data/k8s_manifest"
    MAIN_SERVICE_FILE="$CODEBASE_LOCATION/service.yaml"

    BASELINE_FILE="baseline-service.yaml"

    if [ -f "$MAIN_SERVICE_FILE" && -f "$BASELINE_FILE"]; then
        echo "Both files exist. Proceeding with the rolling traffic manager process."
    else
        cp "$MAIN_SERVICE_FILE" "$BASELINE_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $BASELINE_FILE"
        yq -i "
            .metadata.labels.${LABEL_KEY} = \"${LABEL_VALUE}\" |
            .spec.selector.${LABEL_KEY} = \"${LABEL_VALUE}\"
            " "$BASELINE_FILE"
    fi
}




patchDeployment() {
    logInfoMessage "I'll patch the deployment file with the provided details."
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

    logInfoMessage "I'll patch the deployments available at [$CODEBASE_LOCATION]"

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
        # Check if USE_SECURITY_CONTEXT is provided
        if [[ -n "$USE_SECURITY_CONTEXT" ]]; then
            echo "USE_SECURITY_CONTEXT value is provided. Skipping fetching details from SOURCE_VARIABLE_REPO."
        else
            echo "Fetching details from $SOURCE_VARIABLE_REPO as USE_SECURITY_CONTEXT value is not provided."
            fetch_service_details
        fi
    else
        logErrorMessage "SOURCE_VARIABLE_REPO is not defined. Skipping fetching details from $SOURCE_VARIABLE_REPO."
    fi

    TASK_STATUS=$?

    saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
}

# Function to update environment variables in deployment manifests old
updateEnvVariables() {
    logInfoMessage "I'll update the environment variables in deployment manifests."

    YAML_DIR="/bp/data/k8s_manifest"
    JSON_FILE="/bp/data/deploy_stateless_app"
    ENV_FILE="/tmp/env_variables"
    LOG_FILE="/tmp/env_update.log"

    logInfoMessage "Starting environment variable substitution..." | tee "$LOG_FILE"
    > "$ENV_FILE"

    # Extract environment variables
    jq -r '.addition_meta_data.environment_variables.envs_list[] | "\(.env_key)=\"\(.env_value)\""' "$JSON_FILE" >> "$ENV_FILE"

    # Extract placeholders and store them in the same format
    jq -r '.addition_meta_data.placeholders[] | "\(.key | gsub("\\$\\{";"") | gsub("\\}";""))=\"\(.value)\""' "$JSON_FILE" >> "$ENV_FILE"

    set -o allexport
    source "$ENV_FILE"
    set +o allexport

    # Process all YAML files in YAML_DIR
    find "$YAML_DIR" -type f \( -name "*.yml" -o -name "*.yaml" \) | while read -r yaml_file; do
        yaml_filename=$(basename "$yaml_file")
        TMP_FILE="${yaml_file}.tmp"
        BACKUP_FILE="${yaml_file}.backup"

        if [[ -f "$yaml_file" ]]; then
            cp "$yaml_file" "$BACKUP_FILE"

            envsubst < "$yaml_file" > "$TMP_FILE"

            if ! cmp -s "$BACKUP_FILE" "$TMP_FILE"; then
                mv "$TMP_FILE" "$yaml_file"

                echo -e "\n🟢 UPDATED: $yaml_filename" | tee -a "$LOG_FILE"
                echo "🔽 Changes in $yaml_filename:" | tee -a "$LOG_FILE"

                diff --color=always -u "$BACKUP_FILE" "$yaml_file" | tee -a "$LOG_FILE"
            fi

            rm -f "$BACKUP_FILE"
        else
            logErrorMessage "❌ ERROR: Manifest file '$yaml_filename' not found in '$YAML_DIR'. Skipping..." | tee -a "$LOG_FILE"
        fi
    done

    echo -e "\n✔️ Environment variables substituted successfully." | tee -a "$LOG_FILE"

    rm -f "$ENV_FILE"

    TASK_STATUS=$?

    saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
}

# Determine action type from environment variable
if [[ "$ACTION_TYPE" == "patch" ]]; then
    patchDeployment
elif [[ "$ACTION_TYPE" == "update" ]]; then
    updateEnvVariables
else
    logErrorMessage "❌ ERROR: Invalid ACTION_TYPE '$ACTION_TYPE'. Please set it to 'patch' or 'update'."
    TASK_STATUS=1
fi

saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}