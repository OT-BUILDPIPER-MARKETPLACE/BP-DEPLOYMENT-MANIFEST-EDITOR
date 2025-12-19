#!/bin/bash

summary_file="/bp/execution_dir/${GLOBAL_TASK_ID}/summary.json"

label_generator(){
    if [ -f "$summary_file" ]; then
        echo "$summary_file exists. Fetching data..."

        # Fetch values from JSON
        deployment_name=$(jq -r '.deployment_name' "$summary_file")
        prev_version=$(jq -r '.previous_version' "$summary_file")
        version=$(jq -r '.current_version' "$summary_file")

    else
        echo "$summary_file does not exist. Cannot fetch data."
        exit 1
    fi

    # Labels
    export BASELINE_LABEL="version"
    export CANARY_LABEL="version"

    # Label values (string concatenation)
    export BASELINE_LABEL_VALUE="${prev_version}-${deployment_name}"
    export CANARY_LABEL_VALUE="${version}-${deployment_name}"
}

