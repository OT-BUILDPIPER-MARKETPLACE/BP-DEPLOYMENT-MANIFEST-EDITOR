#!/bin/bash
source /opt/buildpiper/shell-functions/getDataFile.sh 
source /opt/buildpiper/shell-functions/log-functions.sh

deployment_name=`getDeploymentName`

canary_deployment_name=`canary_deployment_name`
baseline_deployment_name=`baseline_deployment_name`

extractVersionFromDeployment() {
    local deployment_name="$1"

    if [[ "$deployment_name" =~ (v-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

label_generator_rolling(){
    local extracted_version
    extracted_version=$(get_version)

    export BASELINE_LABEL="version"

    if [ -z "$extracted_version" ]; then
        export BASELINE_LABEL_VALUE="v0"
    else
        export BASELINE_LABEL_VALUE="${extracted_version}"
    fi
}

label_generator_canary() {
    local canary_extracted_version
    local baseline_extracted_version

    canary_extracted_version=$(get_version)
    baseline_extracted_version=$(get_previous_version)

    export BASELINE_LABEL="version"
    export CANARY_LABEL="version"

    # Baseline label value
    if [ -z "$baseline_extracted_version" ]; then
        export BASELINE_LABEL_VALUE="v0"
    else
        export BASELINE_LABEL_VALUE="${baseline_extracted_version}"
    fi

    # Canary label value
    if [ -z "$canary_extracted_version" ]; then
        export CANARY_LABEL_VALUE="v0"
    else
        export CANARY_LABEL_VALUE="${canary_extracted_version}"
    fi
}


label_generator(){
  if [[ -n "$APPLICATION_ID" && -n "$PIPELINE_ID" && -n "$PIPELINE_EXECUTION_ID" ]]; then
        if [ "$CANARY_STATUS" == "true" ]; then
            echo "Generating label for the canary deployment" 
            label_generator_canary
        else 
            echo "Generating labels for the rolling deployment"
            label_generator_rolling
        fi
    else
        echo "Generating labels for the rolling deployment"
        label_generator_rolling
  fi
}