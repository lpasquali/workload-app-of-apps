# New cluster from template

1. Copy the example and rename the folder to your CAPI `Cluster` name:

   ```bash
   cp -R ../capi-quickstart ../<workload-name>
   ```

2. In `../<workload-name>/`, replace the string `capi-quickstart` with your workload name in:

   - `platform/*.yaml` `metadata.name` (prefix before `-metrics-server`, `-proxmox-csi`, …)
   - `platform/proxmox-csi.yaml` `existingConfigSecret` (Secret created by `bootstrap-capi.sh` is `<name>-proxmox-csi-config`).

3. Set bootstrap (or `proxmox-bootstrap-config` / `config.yaml`):

   - `WORKLOAD_APP_OF_APPS_GIT_PATH=clusters/<workload-name>`
   - `WORKLOAD_CLUSTER_NAME=<workload-name>`

4. Run `kustomize build ../<workload-name>` to validate.
