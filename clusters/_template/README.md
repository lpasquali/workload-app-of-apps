# Your cluster overlay (optional)

This repo is generic: with **CAAPH**, reuse **`examples/default`** or **`examples/k8s-only`** as `WORKLOAD_APP_OF_APPS_GIT_PATH`, or add a small folder under `clusters/<name>/` for **cluster-specific** patches (CSI secret name, extra `Application` YAMLs, etc.).

**Suggested flow**

1. Copy an example:

   `cp -R examples/proxmox-secret-name "clusters/<your-name>"`  
   *or* `cp -R examples/default "clusters/<your-name>"` if the defaults work.

2. Edit patches or add `platform/<app>.yaml` and list them in `kustomization.yaml`.

3. In CAAPH bootstrap, set `WORKLOAD_APP_OF_APPS_GIT_PATH=clusters/<your-name>` (or `examples/...` while experimenting).

4. The root `Application` `metadata.name` is still your management-side `WORKLOAD_CLUSTER_NAME` — that is independent of the child app names in this tree.

You do not need a `clusters/` entry at all if a path under `examples/` is enough for your org.
