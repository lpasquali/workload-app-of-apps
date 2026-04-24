# Your cluster overlay (optional)

This repo is generic: **reuse `examples/default` or `examples/k8s-only`** as the root `path` in Argo, or add a small folder here if you need **cluster-specific** patches (CSI secret name, extra `Application` YAMLs, etc.).

**Suggested flow**

1. Copy an example:

   `cp -R examples/proxmox-secret-name "clusters/<your-name>"`  
   *or* `cp -R examples/default "clusters/<your-name>"` if the defaults work.

2. Edit patches or add `platform/<app>.yaml` and list them in `kustomization.yaml`.

3. Set the bootstrap / root `Application` to `WORKLOAD_APP_OF_APPS_GIT_PATH=clusters/<your-name>` (or to `examples/...` while experimenting).

4. The root `Application` `metadata.name` is still your management-side `WORKLOAD_CLUSTER_NAME` — that is independent of the child app names in this tree.

You do not need a `clusters/` entry at all if a path under `examples/` is enough for your org.
