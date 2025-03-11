# **Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor`**

---

## Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor:0.0.1`

---

**Version:** `deployment-manifest-editor:0.0.1`  
**Release Date:** *2025-02-10*  
**Maintainer:** *[Mukul Joshi](mukul.joshi@opstree.com), [GitHub](https://github.com/mukulmj)*  

### Added

- Initial version of the script `build.sh` to update `serviceAccountName` in `deployment.yaml`.
- Added a Dockerfile to run the script inside a container with `yq` pre-installed.

### Changed

- The script now checks if `NEW_SERVICE_ACCOUNT` is provided.
- If `NEW_SERVICE_ACCOUNT` is missing, it logs a warning and continues with the pre-configured value.

### Fixed

- Corrected issue where the script exited if `deployment.yaml` was missing.
- Ensured `yq` is installed inside the container.

---

## Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor:0.0.2`

---

**Version:** `deployment-manifest-editor:0.0.2`  
**Release Date:** *2025-02-10*  
**Maintainer:** *[Mukul Joshi](mukul.joshi@opstree.com), [GitHub](https://github.com/mukulmj)*  

### Added

- Implemented logic to update an already generated `deployment.yaml` with a new service account if provided.
- Added a function `fetch_service_details` in `getDynamicVars.sh` to dynamically fetch service details from a repository.
- Enhanced repository handling with cloning, updating, and validation steps.
- Added logging for better debugging and error handling.

### Changed

- `build.sh` now fetches details from `SOURCE_VARIABLE_REPO` only if `NEW_SERVICE_ACCOUNT` is not provided.
- Improved `fetch_service_details` to determine `CODEBASE_DIR` dynamically from `deploy_stateless_app`.
- Updated error handling for missing `deployment.yaml` and missing `mavenrepos.json`.
- `NEW_SERVICE_ACCOUNT` is now extracted dynamically if not provided as input.

### Fixed

- Resolved an issue where `fetch_service_details` failed if the repository directory did not exist.
- Fixed incorrect removal of cloned repository, ensuring cleanup happens only after extracting variables.
- Ensured `git fetch` and `git pull` are used properly when updating an already cloned repository.
- Addressed an issue where `DEPLOY_SERVICE_NAME` was not being set correctly from JSON.
- Fixed missing dependency check for `jq` and ensured proper error messages are displayed when required tools are missing.

---

## Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor:0.0.3`

---

**Version:** `deployment-manifest-editor:0.0.3`  
**Release Date:** *2025-02-11*  
**Maintainer:** *[Mukul Joshi](mukul.joshi@opstree.com), [GitHub](https://github.com/mukulmj)*  

### Fixed

- Prevented serviceAccountName update in deployment.yaml if NEW_SERVICE_ACCOUNT is null or blank.
- It ensures that if NEW_SERVICE_ACCOUNT is null or blank, the script does not modify the serviceAccountName field in deployment.yaml, preserving the existing configuration.

---

## Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor:0.0.4`

---

**Version:** `deployment-manifest-editor:0.0.4`
**Release Date:** *2025-03-03*
**Maintainer:** *[Mukul Joshi](mukul.joshi@opstree.com), [GitHub](https://github.com/mukulmj)*  

### Fixed

- Updated script to check and update `fsGroup` and `runAsUser` in `securityContext`.
- Ensured `securityContext` settings for containers are enforced.
- Improved logging for missing or incorrect values.

---

## Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor:0.0.5`

---

**Version:** `deployment-manifest-editor:0.0.5`  
**Release Date:** *2025-03-04*  
**Maintainer:** *[Mukul Joshi](mukul.joshi@opstree.com), [GitHub](https://github.com/mukulmj)*  

### **Fixed**

- Improved validation to ensure `fsGroup` and `runAsUser` are neither empty nor set to `"null"`.  
- Enhanced logging for better debugging of `securityContext` updates.  
- Ensured `securityContext` modifications apply only when valid values are provided.

---

## Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor:0.0.6`

---
 
**Version:** `deployment-manifest-editor:0.0.6`  
**Release Date:** *2025-03-05*  
**Maintainer:** *[Mukul Joshi](mukul.joshi@opstree.com), [GitHub](https://github.com/mukulmj)*  

### Added

- Added `local_test.sh` script for local testing.
- Added `sample_deployment_patch.yq` for reference use.
- Added logic to check if USE_SECURITY_CONTEXT is set to "Yes" before applying yq modifications.

### Improved

- Made yq_query_file Check Conditional on USE_SECURITY_CONTEXT:
  - Ensured yq modifications are only applied when USE_SECURITY_CONTEXT is set to "Yes".
- Enhanced logging for better debugging of `securityContext` updates.
- Ensured `securityContext` modifications apply only when valid values are provided.
- Made `yq_query_file` check conditional on `USE_SECURITY_CONTEXT`.

---

## Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor:0.0.7`

---

**Version:** `deployment-manifest-editor:0.0.7`  
**Release Date:** *2025-03-06*  
**Maintainer:** *[Mukul Joshi](mukul.joshi@opstree.com), [GitHub](https://github.com/mukulmj)*  

### Added

- Implemented a check for `ACTION_TYPE` to prevent execution if no valid value (`patch` or `update`) is provided.  
- Added enhanced error handling for missing or invalid `ACTION_TYPE`.  
- Included more detailed logging messages for better debugging.  

### Improved

- Refactored `patchDeployment` to check `NEW_SERVICE_ACCOUNT` before fetching details from `SOURCE_VARIABLE_REPO`.  
- Improved `updateEnvVariables` by adding a validation check for `JSON_FILE` before extracting environment variables.  
- Optimized `envsubst` substitution logic to prevent unnecessary overwrites.  
- Strengthened error handling to ensure safer script execution.  

### Fixed

- Fixed a redundant call to `fetch_service_details` when `NEW_SERVICE_ACCOUNT` or `USE_SECURITY_CONTEXT` is already set.  
- Resolved an issue where `TASK_STATUS` was being overwritten unnecessarily.  

---

## Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor:0.0.8`

---

**Version:** `deployment-manifest-editor:0.0.8`  
**Release Date:** *2025-03-11*  
**Maintainer:** *[Mukul Joshi](mukul.joshi@opstree.com), [GitHub](https://github.com/mukulmj)*  

### Added

- Implemented a check for `ACTION_TYPE` to prevent execution if no valid value (`patch` or `update`) is provided.  
- Added enhanced error handling for missing or invalid `ACTION_TYPE`.  
- Included more detailed logging messages for better debugging.  
- Included `gettext` `libintl` `coreutils` `diffutils` packages in `Dockerfile` for better logs visibility.

### Improved

- Refactored `patchDeployment` to check `NEW_SERVICE_ACCOUNT` before fetching details from `SOURCE_VARIABLE_REPO`.  
- Improved `updateEnvVariables` by adding a validation check for `JSON_FILE` before extracting environment variables.  
- Optimized `envsubst` substitution logic to prevent unnecessary overwrites.  
- Strengthened error handling to ensure safer script execution.  

### Fixed

- Fixed a redundant call to `fetch_service_details` when `NEW_SERVICE_ACCOUNT` or `USE_SECURITY_CONTEXT` is already set.  
- Resolved an issue where `TASK_STATUS` was being overwritten unnecessarily.
- Handling of updated manifest files by only updating the files selected for deployment now not dependent over `*.yaml`.  

---
