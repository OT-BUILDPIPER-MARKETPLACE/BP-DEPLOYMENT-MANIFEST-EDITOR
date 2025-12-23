#!/bin/bash
source /opt/buildpiper/shell-functions/getDataFile.sh 

# summary_file="/bp/execution_dir/${GLOBAL_TASK_ID}/summary.json"

# deployment_name=`getDeploymentName`

# canary_deployment_name=`canary_deployment_name`

function makeName(){
    echo '$1$2'
}

label_generator(){
    if [ -z "$(`canary_status`)" ]; then
        echo "canary status does not exists. Hence it is not a pipeline trigger."
        export BASELINE_LABEL="version"
        export BASELINE_LABEL_VALUE=$(getVersion)
    else
       # Labels
        export BASELINE_LABEL="version"
        export CANARY_LABEL="version"

        # Label values (string concatenation)
        export BASELINE_LABEL_VALUE=`getpreviousVersion`
        export CANARY_LABEL_VALUE=`getVersion`
    fi
}

