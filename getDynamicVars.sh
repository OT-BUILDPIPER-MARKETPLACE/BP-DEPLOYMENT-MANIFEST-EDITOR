source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/proxy-handling.sh

# Function to clone the repository, extract details, and set environment variables
function fetch_service_details() {
    
    # Repository details
    # local SOURCE_VARIABLE_REPO="https://github.com/buildpipermasterpipeline.git"
    local LOCAL_REPO_DIR="/tmp/buildpipermasterpipeline"

    # Ensure the directory exists
    if [ ! -d "$LOCAL_REPO_DIR" ]; then
        echo "Directory $LOCAL_REPO_DIR does not exist. Creating it..."
        mkdir -p "$LOCAL_REPO_DIR" || { echo "Error: Failed to create directory $LOCAL_REPO_DIR."; return 1; }
    fi

    # Clone the repository with retry logic (3 attempts total)
    if [ ! -d "$LOCAL_REPO_DIR/.git" ]; then
        echo "Cloning repository $SOURCE_VARIABLE_REPO into $LOCAL_REPO_DIR on branch $APPLICATION_NAME with depth 2..."

        attempt=1
        max_attempts=3
        wait_times=(0 30 60)

        while [ $attempt -le $max_attempts ]; do
            if [ $attempt -gt 1 ]; then
                sleep_time=${wait_times[$((attempt-1))]}
                echo "Retrying clone attempt $attempt after $sleep_time seconds..."
                sleep "$sleep_time"
            fi

            echo "Attempt $attempt: Cloning..."
            output=$(run_without_proxy_then_with_fallback git clone --branch "$APPLICATION_NAME" --depth 2 "$SOURCE_VARIABLE_REPO" "$LOCAL_REPO_DIR" 2>&1)
            clone_status=$?

            if [ $clone_status -eq 0 ]; then
                echo "Clone successful on attempt $attempt."
                break
            else
                echo "Clone attempt $attempt failed: $output"
            fi

            attempt=$((attempt + 1))
        done

        if [ $clone_status -ne 0 ]; then
            echo "Error: Cloning failed after $max_attempts attempts."
            return 1
        fi
    else
        echo "Repository already exists. Fetching latest changes..."
        cd "$LOCAL_REPO_DIR" || { echo "Error: Cannot change directory to $LOCAL_REPO_DIR"; return 1; }
        git fetch origin "$APPLICATION_NAME" --depth 2 || { echo "Error: Fetching latest changes failed."; return 1; }
        git pull origin "$APPLICATION_NAME" || { echo "Error: Pulling latest changes failed for branch $APPLICATION_NAME."; return 1; }
    fi

    # Path to the mavenrepos.json file
    local json_file="$LOCAL_REPO_DIR/mavenrepos.json"
    local env_suffixes_file="$LOCAL_REPO_DIR/env_suffixes.txt"  # <-- Path for env suffixes file
    local yq_query_file="$LOCAL_REPO_DIR/deployment_patch.yq"  # <-- Path for yq query file

    # Check if mavenrepos.json exists
    if [ ! -f "$json_file" ]; then
        echo "Error: $json_file not found for branch $APPLICATION_NAME"
        return 1
    fi

    # Find the service details in the JSON file
    echo "Extracting service details for $CODEBASE_DIR..."

    # Function to get the deployment service name
    function getDeploymentServiceName() {
      DEPLOY_SERVICE_NAME=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "service") | .metadata.name' < /bp/data/deploy_stateless_app)
      echo "$DEPLOY_SERVICE_NAME"
    }

    # Get the deployment service name
    DEPLOY_SERVICE_NAME=`getDeploymentServiceName`
    echo "Deployment service name: $DEPLOY_SERVICE_NAME"

    # Set default suffixes if env_suffixes.txt does not exist
    if [ -f $env_suffixes_file ]; then
        ENV_SUFFIX_PATTERN=$(paste -sd'|' $env_suffixes_file)
    else
        ENV_SUFFIX_PATTERN="dev|prod|qa|staging|uat"
    fi

    if [ -z "$CODEBASE_DIR" ]; then
        CODEBASE_DIR=$(echo "$DEPLOY_SERVICE_NAME" | sed -E "s/-($ENV_SUFFIX_PATTERN)(-.*)?\$//")
        echo "CODEBASE_DIR was empty, using deployment service name: $CODEBASE_DIR"
    fi

    # Try to match by bitbucketRepoName first
    local service_data=$(jq -r --arg CODEBASE_DIR "$CODEBASE_DIR" '.repositories[] | select(.bitbucketRepoName == $CODEBASE_DIR)' "$json_file")

    # If not found, fallback to match CODEBASE_DIR in deployment_name array
    if [ -z "$service_data" ]; then
        logInfoMessage "bitbucketRepoName match failed. Trying to match deployment_name array..."

        service_data=$(jq -r --arg CODEBASE_DIR "$CODEBASE_DIR" '.repositories[] | select(.deployment_name!= null and (.deployment_name | split(",") | map(gsub("^\\s+|\\s+$"; "")) | index($CODEBASE_DIR)))' "$json_file")
    fi

    if [ -z "$service_data" ]; then
        echo "Error: Service $CODEBASE_DIR not found in $json_file"
        return 1
    fi

    # Extract the specific details and export them as environment variables    
    export NEW_SERVICE_ACCOUNT=$(echo "$service_data" | jq -r '.NEW_SERVICE_ACCOUNT')
    export CODEBASE_LOCATION="/bp/data/k8s_manifest"
    export DEPLOYMENT_FILE="$CODEBASE_LOCATION/deployment.yaml"

    # Check if security context should be used
    USE_SECURITY_CONTEXT=$(echo "$service_data" | jq -r '.USE_SECURITY_CONTEXT')

    # Apply if security context is set to be Yes
    if [ "$USE_SECURITY_CONTEXT" == "Yes" ]; then
        echo "Security context is enabled. Patching deployment with yq..."

        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ -n "$line" && "$line" != "#"* ]]; then
                yq eval -i "$line" "$DEPLOYMENT_FILE" || {
                    echo "Error: Failed to apply yq modification: $line"
                    return 1
                }
            fi
        done < "$yq_query_file"

    else
        echo "Security context is disabled for this service."
    fi

    # Remove the cloned repository
    echo "Removing the cloned repository..."
    rm -rf "$LOCAL_REPO_DIR" || { echo "Error: Failed to remove directory $LOCAL_REPO_DIR."; return 1; }

    echo "Environment variables have been set and repository has been removed."
}