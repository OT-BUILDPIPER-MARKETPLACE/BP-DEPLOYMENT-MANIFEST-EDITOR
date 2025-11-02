### **Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor`**  

| **Version** | **Release Date** | **Changes** |  
|------------|---------------|------------|  
| **0.0.1** | *2025-02-10* | **Added:** Initial version of `build.sh`, Dockerfile with `yq`. <br> **Changed:** Checks `NEW_SERVICE_ACCOUNT`, logs a warning if missing. <br> **Fixed:** Prevented script exit if `deployment.yaml` is missing, ensured `yq` is installed. |  
| **0.0.2** | *2025-02-10* | **Added:** Function `fetch_service_details` in `getDynamicVars.sh`, better repository handling, logging. <br> **Changed:** `build.sh` fetches details only if `NEW_SERVICE_ACCOUNT` is missing. Improved error handling. <br> **Fixed:** Various issues related to repository updates, `DEPLOY_SERVICE_NAME` extraction, and dependency checks. |  
| **0.0.3** | *2025-02-11* | **Fixed:** Prevented `serviceAccountName` update if `NEW_SERVICE_ACCOUNT` is null or blank. |  
| **0.0.4** | *2025-03-03* | **Fixed:** Updated script to check and update `fsGroup` and `runAsUser` in `securityContext`, improved logging. |  
| **0.0.5** | *2025-03-04* | **Fixed:** Validated `fsGroup` and `runAsUser`, prevented empty or `"null"` values, enhanced logging. |  
| **0.0.6** | *2025-03-05* | **Added:** `local_test.sh` for local testing, `sample_deployment_patch.yq`. <br> **Improved:** Made `yq_query_file` check conditional on `USE_SECURITY_CONTEXT`, enhanced logging. |  
| **0.0.7** | *2025-03-06* | **Added:** `ACTION_TYPE` validation, detailed error handling, improved logging. <br> **Improved:** Refactored `patchDeployment`, optimized `envsubst`, strengthened error handling. <br> **Fixed:** Redundant `fetch_service_details` call, `TASK_STATUS` overwrite issue. |  
| **0.0.8** | *2025-03-11* | **Added:** Included `gettext`, `libintl`, `coreutils`, `diffutils` in `Dockerfile` for better logs. <br> **Improved:** Further optimized error handling, deployment file selection logic. <br> **Fixed:** Redundant `fetch_service_details` calls, unnecessary overwrites, improved handling of updated manifest files. |
| **0.0.9** | *2025-03-11* | **Added:** Included `gettext`, `libintl`, `coreutils`, `diffutils` in `Dockerfile` for better logs. <br> **Improved:** Further optimized error handling, deployment file selection logic. <br> **Fixed:** Handling any file which need to be used for deployments. |
| **0.1.0** | *2025-06-27* | **Improved:** Enhanced logic in `getDynamicVars.sh` to handle `CODEBASE_DIR` resolution using the deployment's `git_repo` value if no direct match is found in `repositories[]`. <br> **Fixed:** Fallback mechanism for `CODEBASE_DIR` ensures correct service data extraction even when the deployment name does not directly match repository names. <br> |
| **0.1.0-nr** | *2025-11-02*     | **Refactored:** Dockerfile to be fully Alpine-compatible. Replaced `groupadd`/`useradd` with `addgroup` and `adduser` for lightweight build and faster layer creation. <br> **Added:** Ownership enforcement with `COPY --chown=buildpiper:buildpiper` ensuring all files and scripts are owned by `buildpiper`. <br> **Improved:** Fixed `ENV` syntax warnings (`ENV key=value` format). Added non-root execution with `USER buildpiper` for better container security. <br> **Fixed:** Build failure caused by missing `groupadd` in Alpine base image. |

---
