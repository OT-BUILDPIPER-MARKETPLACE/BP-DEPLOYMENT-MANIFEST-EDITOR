#!/bin/bash

source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source getDynamicVars.sh
source labelGenerator.sh
source /opt/buildpiper/shell-functions/getDataFile.sh 

TASK_STATUS=0

CANARY_STATUS=`canary_status`
APPLICATION_ID=`application_id`
PIPELINE_ID=`pipeline_id`
PIPELINE_EXECUTION_ID=`pipeline_execution_id`



# deployment_canary_editor(){
#     deployment_name=`baseline_deployment_name`
#     deployment_canary_name=`canary_deployment_name`

#     CODEBASE_LOCATION="/bp/data/k8s_manifest"
#     BASELINE_DEPLOYMENT_FILE="$CODEBASE_LOCATION/baseline_deployment.yaml"
#     CANARY_DEPLOYMENT_FILE="$CODEBASE_LOCATION/deployment.yaml"

#     logInfoMessage "I'll update the labels of the canary deployment and baseline deployment available at [$CODEBASE_LOCATION]"

#     if [ ! -f "$BASELINE_DEPLOYMENT_FILE" ] && [ -f "$CANARY_DEPLOYMENT_FILE"]; then
#         logErrorMessage "Both Canary and Baseline Deployment files not found at $CODEBASE_LOCATION"
#         exit 1
#     fi

#     logInfoMessage "Adding the label in the baseline and canary deployment file"

#     yq e -i ".metadata.labels.version = \"$deployment_name\"" "$BASELINE_DEPLOYMENT_FILE"
#     yq e -i ".spec.template.metadata.labels.version = \"$deployment_name\"" "$BASELINE_DEPLOYMENT_FILE"
#     yq e -i ".spec.selector.matchLabels.version = \"$deployment_name\"" "$BASELINE_DEPLOYMENT_FILE"
#     yq e -i ".metadata.labels.version = \"$deployment_canary_name\"" "$CANARY_DEPLOYMENT_FILE"
#     yq e -i ".spec.template.metadata.labels.version = \"$deployment_canary_name\"" "$CANARY_DEPLOYMENT_FILE"
#     yq e -i ".spec.selector.matchLabels.version = \"$deployment_canary_name\"" "$CANARY_DEPLOYMENT_FILE"

# }

# deployment_rolling_editor(){
#     deployment_name=`getDeploymentName`

#     CODEBASE_LOCATION="/bp/data/k8s_manifest"
#     DEPLOYMENT_FILE="$CODEBASE_LOCATION/deployment.yaml"

#     logInfoMessage "I'll update the labels of the deployments available at [$CODEBASE_LOCATION]"

#     if [ ! -f "$DEPLOYMENT_FILE" ]; then
#         logErrorMessage "Deployment file not found at $DEPLOYMENT_FILE"
#         exit 1
#     fi

#     logInfoMessage "Adding the label to the deployment file"

#     yq e -i ".metadata.labels.version = \"$deployment_name\"" "$DEPLOYMENT_FILE"
#     yq e -i ".spec.template.metadata.labels.version = \"$deployment_name\"" "$DEPLOYMENT_FILE"
#     yq e -i ".spec.selector.matchLabels.version = \"$deployment_name\"" "$DEPLOYMENT_FILE"

# }

canary_generator(){

    logDebugMessage "Canary Status:- ${CANARY_STATUS}"
    pod_shift_percentage=`canary_deployment_pod_shift_percentage`
    logDebugMessage "Pod shift percentage: $pod_shift_percentage"
    if [[ -n "$APPLICATION_ID" && -n "$PIPELINE_ID" && -n "$PIPELINE_EXECUTION_ID" ]]; then
        if [ "$CANARY_STATUS" == "true" ] && [ "$pod_shift_percentage" != '100' ]; then
            echo "We will using the canaryTrafficManager process for traffic routing" 
            canaryTrafficManager
        elif [ "$CANARY_STATUS" == "true" ] && [ "$pod_shift_percentage" == '100' ]; then
            echo "canary is in 100 percentage stage therefore switching both services to same label"
            pod_shift_service_editor "true"
        else 
            echo "we will be using the rolling traffic manger process for traffic routing"
            rollingTrafficManager
        fi
    else
        echo "we will be using the rolling traffic manager process for the traffic routing"
        rollingTrafficManager
    fi
}

pod_shift_service_editor(){

    CURRENT_VERSION=$(get_version)

    logInfoMessage "Current Version is :- $CURRENT_VERSION"

    CODEBASE_LOCATION="/bp/data/k8s_manifest"
    MAIN_SERVICE_FILE="$CODEBASE_LOCATION/service.yaml"
    BASELINE_FILE="$CODEBASE_LOCATION/baseline_routing_service.yaml"
    CANARY_FILE="$CODEBASE_LOCATION/canary_routing_service.yaml"

    SVC_NAME=$(yq '.metadata.name' "$MAIN_SERVICE_FILE")

    canary_parent_global_task_id=`get_canary_parent_global_task_id`

    remove_old_routing_files
    
    label_generator
    # Check if the source file exists
    if [ -f "$MAIN_SERVICE_FILE" ]; then
    # Copy the source file to the baseline file
        cp "$MAIN_SERVICE_FILE" "$BASELINE_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $BASELINE_FILE"

        # CANARY_LABEL_VALUE

        yq -i "
        .metadata.name = \"${SVC_NAME}-baseline-svc\" |
        .metadata.labels.${BASELINE_LABEL} = \"${CURRENT_VERSION}\" |
        .spec.selector.${BASELINE_LABEL} = \"${CURRENT_VERSION}\"
        " "$BASELINE_FILE"

    # Copy the source file to the canary file
        cp "$MAIN_SERVICE_FILE" "$CANARY_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $CANARY_FILE"
        yq -i "
        .metadata.name = \"${SVC_NAME}-canary-svc\" |
        .metadata.labels.${CANARY_LABEL} = \"${CURRENT_VERSION}\" |
        .spec.selector.${CANARY_LABEL} = \"${CURRENT_VERSION}\"
        " "$CANARY_FILE"
    else
        echo "Error: Source file $MAIN_SERVICE_FILE not found."
        exit 1
    fi

    logInfoMessage "Adding the files to the git"

    cd "$CODEBASE_LOCATION"

    git add .

    git commit -m "canary traffic files commited to repo"

    logInfoMessage "canary_parent_global_task_id: $canary_parent_global_task_id"

    # cd "$CODEBASE_LOCATION"

    #copying the main service file
    MAIN_SERVICE_FILE="$CODEBASE_LOCATION/service.yaml"
    BASELINE_FILE="$CODEBASE_LOCATION/baseline_routing_service.yaml"
    CANARY_FILE="$CODEBASE_LOCATION/canary_routing_service.yaml"

    git checkout "$canary_parent_global_task_id"
    echo "Checked out to branch: $canary_parent_global_task_id"

    # Check if the source file exists
    if [ -f "$MAIN_SERVICE_FILE" ]; then
    # Copy the source file to the baseline file
        cp "$MAIN_SERVICE_FILE" "$BASELINE_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $BASELINE_FILE"

        yq -i "
        .metadata.name = \"${SVC_NAME}-baseline-svc\" |
        .metadata.labels.${BASELINE_LABEL} = \"${CURRENT_VERSION}\" |
        .spec.selector.${BASELINE_LABEL} = \"${CURRENT_VERSION}\"
        " "$BASELINE_FILE"

    # Copy the source file to the canary file
        cp "$MAIN_SERVICE_FILE" "$CANARY_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $CANARY_FILE"
        yq -i "
        .metadata.name = \"${SVC_NAME}-canary-svc\" |
        .metadata.labels.${CANARY_LABEL} = \"${CURRENT_VERSION}\" |
        .spec.selector.${CANARY_LABEL} = \"${CURRENT_VERSION}\"
        " "$CANARY_FILE"
    else
        echo "Error: Source file $MAIN_SERVICE_FILE not found."
        exit 1
    fi
    logInfoMessage "commit the files to the checkout branch"
    cd "$CODEBASE_LOCATION"
    git add "$BASELINE_FILE" "$CANARY_FILE"
    git commit -m "canary traffic files commited to repo"
}

function remove_old_routing_files(){
    CODEBASE_LOCATION="/bp/data/k8s_manifest"
    OLD_BASELINE_FILE="$CODEBASE_LOCATION/baseline_routing_service_baseline.yaml" 
    OLD_CANARY_FILE="$CODEBASE_LOCATION/canary_routing_service_baseline.yaml" 
 

    if [ -f "$OLD_BASELINE_FILE" ]; then
        rm "$OLD_BASELINE_FILE"
        echo "Removed old file: $OLD_BASELINE_FILE"
    fi
    
    if [ -f "$OLD_CANARY_FILE" ]; then
        rm "$OLD_CANARY_FILE"
        echo "Removed old file: $OLD_CANARY_FILE"
    fi

    logInfoMessage "Removed old routing files"
}

canaryTrafficManager(){
    CODEBASE_LOCATION="/bp/data/k8s_manifest"
    MAIN_SERVICE_FILE="$CODEBASE_LOCATION/service.yaml"

    #copying the main service file
    BASELINE_FILE="$CODEBASE_LOCATION/baseline_routing_service.yaml"
    CANARY_FILE="$CODEBASE_LOCATION/canary_routing_service.yaml"

    SVC_NAME=$(yq '.metadata.name' "$MAIN_SERVICE_FILE")

    #remove old routing files
    remove_old_routing_files

    #deployment_canary_editor

    label_generator 

    # Check if the source file exists
    if [ -f "$MAIN_SERVICE_FILE" ]; then
    # Copy the source file to the baseline file
        cp "$MAIN_SERVICE_FILE" "$BASELINE_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $BASELINE_FILE"

        yq -i "
        .metadata.name = \"${SVC_NAME}-baseline-svc\" |
        .metadata.labels.${BASELINE_LABEL} = \"${BASELINE_LABEL_VALUE}\" |
        .spec.selector.${BASELINE_LABEL} = \"${BASELINE_LABEL_VALUE}\"
        " "$BASELINE_FILE"

    # Copy the source file to the canary file
        cp "$MAIN_SERVICE_FILE" "$CANARY_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $CANARY_FILE"
        yq -i "
        .metadata.name = \"${SVC_NAME}-canary-svc\" |
        .metadata.labels.${CANARY_LABEL} = \"${CANARY_LABEL_VALUE}\" |
        .spec.selector.${CANARY_LABEL} = \"${CANARY_LABEL_VALUE}\"
        " "$CANARY_FILE"
    else
        echo "Error: Source file $MAIN_SERVICE_FILE not found."
        exit 1
    fi
    cd /bp/data/k8s_manifest
    git add .
    git commit -m "canary traffic files commited to repo"
}

rollingTrafficManager(){
    CODEBASE_LOCATION="/bp/data/k8s_manifest"
    MAIN_SERVICE_FILE="$CODEBASE_LOCATION/service.yaml"

    SVC_NAME=$(yq '.metadata.name' "$MAIN_SERVICE_FILE")

    BASELINE_FILE="$CODEBASE_LOCATION/baseline_routing_service.yaml"

    

    # DEPLOYMENT_FILE="$CODEBASE_LOCATION/deployment.yaml"

    # CURRENT_DEPLOYMENT_NAME=$(yq e '.metadata.name' "$DEPLOYMENT_FILE")

    # if [ -z "$CURRENT_DEPLOYMENT_NAME" ]; then
    #     echo "Error: Deployment name not found in $DEPLOYMENT_FILE."
    #     exit 1
    # fi

    # echo "Current deployment name: $CURRENT_DEPLOYMENT_NAME"

    #deployment_rolling_editor

    label_generator

    if [ -f "$MAIN_SERVICE_FILE" ]&& [ -f "$BASELINE_FILE" ]; then
        echo "Both files exist. Proceeding with the rolling traffic manager process."
    else
        cp "$MAIN_SERVICE_FILE" "$BASELINE_FILE"
        echo "Content of $MAIN_SERVICE_FILE copied to $BASELINE_FILE"
        yq -i "
        .metadata.name = \"${SVC_NAME}-baseline-svc\" |
        .metadata.labels.${BASELINE_LABEL} = \"${BASELINE_LABEL_VALUE}\" |
        .spec.selector.${BASELINE_LABEL} = \"${BASELINE_LABEL_VALUE}\"
        " "$BASELINE_FILE"
    fi

    cd /bp/data/k8s_manifest

    git add .
    git commit -m "canary traffic files commited to repo"


    # CODEBASE_LOCATION="/bp/data/k8s_manifest"
    # MAIN_SERVICE_FILE="$CODEBASE_LOCATION/service.yaml"
    # BASELINE_FILE="$CODEBASE_LOCATION/baseline_routing_service.yaml"
    # DEPLOYMENT_FILE="$CODEBASE_LOCATION/deployment.yaml"

    # CURRENT_DEPLOYMENT_NAME=$(yq e '.metadata.name' "$DEPLOYMENT_FILE")

    # if [ -z "$CURRENT_DEPLOYMENT_NAME" ]; then
    #     echo "Error: Deployment name not found in $DEPLOYMENT_FILE."
    #     exit 1
    # fi

    # echo "Current deployment name: $CURRENT_DEPLOYMENT_NAME"

    # # -------------------------------------------------
    # # Skip baseline generation if deployment is versioned (starts with v-)
    # # -------------------------------------------------
    # if [[ "$CURRENT_DEPLOYMENT_NAME" =~ ^v- ]]; then
    #     echo "Versioned deployment detected ($CURRENT_DEPLOYMENT_NAME). Skipping baseline routing generation."
    #     exit 0
    # fi

    # # -------------------------------------------------
    # # Non-versioned deployment → generate baseline routing
    # # -------------------------------------------------
    # label_generator

    # if [ -f "$MAIN_SERVICE_FILE" ] && [ -f "$BASELINE_FILE" ]; then
    #     echo "Both files exist. Proceeding with the rolling traffic manager process."
    # else
    #     cp "$MAIN_SERVICE_FILE" "$BASELINE_FILE"
    #     echo "Content of $MAIN_SERVICE_FILE copied to $BASELINE_FILE"

    #     yq -i "
    #     .metadata.name = \"baseline-svc-routing\" |
    #     .metadata.labels.${BASELINE_LABEL} = \"${BASELINE_LABEL_VALUE}\" |
    #     .spec.selector.${BASELINE_LABEL} = \"${BASELINE_LABEL_VALUE}\"
    #     " "$BASELINE_FILE"
    # fi

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
# if [[ "$ACTION_TYPE" == "patch" ]]; then
#     patchDeployment
# elif [[ "$ACTION_TYPE" == "update" ]]; then
#     updateEnvVariables
# elif [[ "$ACTION_TYPE" == "canary" ]]; then
#     canary_generator
# else
#     logErrorMessage "❌ ERROR: Invalid ACTION_TYPE '$ACTION_TYPE'. Please set it to 'patch' or 'update'."
#     TASK_STATUS=1
# fi

function rollback_stateless_app(){
    rollback_file=/bp/data/rollback_stateless_app
    deployment_previous_global_task_id=$(jq -r .buildpiper_meta_data.rollback.component_global_task_id < "$rollback_file")
    logInfoMessage "The previous deployment global task id:- $deployment_previous_global_task_id"
    cd /bp/data/k8s_manifest/
    git checkout "$deployment_previous_global_task_id"
    if command -v kubectl &> /dev/null; then
        echo "✅ kubectl is installed and available in the PATH."
    else
        echo "❌ kubectl is not installed or not found in the PATH."
        echo "Please ensure kubectl is correctly installed and accessible."
        exit 1
    fi
    kubectl apply -f /bp/data/k8s_manifest/
    TASK_STATUS=1
}

# Determine action type from environment variable
if [[ "$ACTION_TYPE" == "patch" ]]; then
    patchDeployment
elif [[ "$ACTION_TYPE" == "update" ]]; then
    updateEnvVariables
elif [[ "$ACTION_TYPE" == "canary" ]]; then
    canary_generator
elif [[ "$ACTION_TYPE" == "rollback" ]]; then
    rollback_stateless_app
else
    logErrorMessage ":x: ERROR: Invalid ACTION_TYPE '$ACTION_TYPE'. Please set it to 'patch', 'update', 'canary', or 'rollback'."
    TASK_STATUS=1
fi

saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}