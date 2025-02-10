### **Change Log for Docker Image: `registry.buildpiper.in/deployment-manifest-editor:0.0.1`**  

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

