# **BP-DEPLOYMENT-MANIFEST-EDITOR**  
This script updates an already generated deployment.yaml with a new service account if an input is provided. 

## **Setup Instructions**  

![Deployment Manifest Editor](Deployment_Manifest_Editor.png)

### **1️⃣ Clone the Repository**  
Clone the project from the official repository:  
```bash
git clone --recurse-submodules https://github.com/OT-BUILDPIPER-MARKETPLACE/BP-DEPLOYMENT-MANIFEST-EDITOR
cd BP-DEPLOYMENT-MANIFEST-EDITOR
```

If you've already cloned the repository, ensure submodules are initialized and updated:  
```bash
git submodule init  
git submodule update  
```

---

### **2️⃣ Build the Docker Image**  
To build the Docker image, run:  
```bash
docker build -t registry.buildpiper.in/deployment-manifest-editor:$tag .
```

---

### **3️⃣ Local Testing**  
Run the container with environment variables and mount the current directory:  
```bash
docker run -it --rm -v "$PWD:/src" \
  -e VAR1="key1" -e VAR2="key2" \
  ot/<image-name>:0.1
```

---

### **4️⃣ Debugging**  
To enter a shell inside the container for troubleshooting:  
```bash
docker run -it --rm -v "$PWD:/src" \
  -e VAR1="key1" -e VAR2="key2" \
  --entrypoint sh ot/<image-name>:0.1
```

---

## **Notes**  
- Ensure **Docker** is installed and running before executing these commands.  
- Replace `<image-name>` with the actual image name used in your project.  

---

## Local Testing

To facilitate local testing, we have provided a script `local_test.sh` and a sample patch file `sample_deployment_patch.yq`. These can be used to apply modifications to your `deployment.yaml` file.

### Prerequisites

Ensure you have `yq` installed on your system. You can install it using the following command:

```bash
sudo wget https://github.com/mikefarah/yq/releases/download/v4.6.1/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
```

### Usage

1. **Prepare your deployment.yaml file:**

   Ensure you have a deployment.yaml file in the same directory as local_test.sh.

2. **Run the local test script:**

   Execute the local_test.sh script to apply the modifications specified in sample_deployment_patch.yq to your deployment.yaml file.

   ```bash
   ./local_test.sh
   ```

3. **Check the output:**

   The script will read the sample_deployment_patch.yq file and apply the specified changes to deployment.yaml. If the patch file or deployment.yaml is missing, the script will log an appropriate message.

### Example sample_deployment_patch.yq

Here is an example of what the sample_deployment_patch.yq file looks like:

```yaml
.spec.template.spec.securityContext.fsGroup = 2000
.spec.template.spec.securityContext.runAsUser = 1001
.spec.template.spec.containers[].securityContext.allowPrivilegeEscalation = false
.spec.template.spec.containers[].securityContext.capabilities.drop = ["ALL"]
.spec.template.spec.containers[].securityContext.readOnlyRootFilesystem = true
.spec.template.spec.containers[].securityContext.runAsNonRoot = true
.spec.template.spec.containers[].securityContext.seccompProfile.type = "RuntimeDefault"
```

### Script Details

The local_test.sh script performs the following steps:

1. Sets the `yq_query_file` environment variable to sample_deployment_patch.yq.
2. Checks if the `yq_query_file` exists.
3. Reads each line from the `yq_query_file` and applies it to deployment.yaml using `yq`.
4. Logs success or error messages based on the outcome of each modification.

Here is the content of local_test.sh:

```bash
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
```

By following these steps, you can easily test and apply deployment modifications locally.
