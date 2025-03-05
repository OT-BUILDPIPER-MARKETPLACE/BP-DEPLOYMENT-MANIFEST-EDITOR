#!/bin/bash

export yq_query_file=sample_deployment_patch.yq

# Apply yq modifications to the deployment file if the query file exists
if [ -f "$yq_query_file" ]; then
    echo "Applying deployment modifications from $yq_query_file..."
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        yq eval -i "$line" deployment.yaml || {
            echo "Error: Failed to apply yq modification: $line"
            return 1
        }
    done < "$yq_query_file"

else
    echo "No deployment modifications found in $yq_query_file."
fi