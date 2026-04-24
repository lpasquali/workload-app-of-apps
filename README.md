# Workload app-of-apps (Argo CD)

This repository is a **per-cluster (or per-environment) Argo CD app-of-apps** tree for a **CAPI/Proxmox workload cluster** where Argo CD runs **in-cluster** and platform components are no longer defined only inside `bootstrap-capi.sh` ([Cluster API + CAAPH + GitOps](https://cluster-api.sigs.k8s.io/tasks/workload-bootstrap-gitops)).

## Layout

| Path | Purpose |
|------|---------|
| `clusters/<name>/` | Kustomize root Argo points at. `<name>` should match your CAPI `Cluster` name (e.g. `capi-quickstart`) so bootstrap flags stay obvious. |
| `clusters/<name>/kustomization.yaml` | One place to enable/disable `Application` manifests under `platform/`. |
| `clusters/<name>/platform/` | Child `Application` resources (Helm: metrics-server, CSI, policy, cert-manager, …). |

## Wire `bootstrap-capi.sh` (CAAPH path)

1. Point Git at this repo (push it to your forge and replace the URL below).

2. For cluster name **`capi-quickstart`**, set:

   ```text
   WORKLOAD_GITOPS_MODE=caaph
   WORKLOAD_APP_OF_APPS_GIT_URL=https://github.com/<org>/workload-app-of-apps.git
   WORKLOAD_APP_OF_APPS_GIT_PATH=clusters/capi-quickstart
   WORKLOAD_APP_OF_APPS_GIT_REF=main
   ```

   The [argocd-apps](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd-apps) chart in bootstrap creates a **root** `Application` whose `metadata.name` is your `WORKLOAD_CLUSTER_NAME` and whose `source.path` is the value of `WORKLOAD_APP_OF_APPS_GIT_PATH`. Kustomize in that path expands to the child `Application` manifests here.

3. The bootstrap script (CAAPH) still creates the **Proxmox CSI** API token **Secret** on the workload named `<workload-name>-proxmox-csi-config` when tokens are available; theCSI `Application` here references that name.

4. **No API secrets** are stored in this repo. `existingConfigSecret` in the CSI `Application` must match the Secret created on the cluster.

## Add a new cluster

1. Copy the example:

   ```bash
   cp -R clusters/capi-quickstart "clusters/<your-cluster-name>"
   ```

2. Replace the prefix in `platform/*.yaml` from `capi-quickstart-` to `<your-cluster-name>-` (or use a small kustomize `namePrefix` in `kustomization.yaml`).

3. Set bootstrap `WORKLOAD_APP_OF_APPS_GIT_PATH=clusters/<your-cluster-name>` and `WORKLOAD_CLUSTER_NAME=<your-cluster-name>`.

## Conventions

- **Destination** is always `https://kubernetes.default.svc` (Argo on the same cluster that runs the workloads).
- **Sync waves** use `argocd.argoproj.io/sync-wave` to order installs (e.g. metrics-server before other controllers).
- **Chart pin versions** are defaults aligned with `bootstrap-capi.sh`; pin or bump as you need (Renovate/bump-friendly).

## Included platform apps (example `clusters/capi-quickstart`)

| Wave | App | Notes |
|------|-----|--------|
| -3 | metrics-server | Upstream [charts/metrics-server](https://github.com/kubernetes-sigs/metrics-server) (kubelet TLS flags match typical CAPMOX). |
| -2 | proxmox-csi | OCI chart; `existingConfigSecret` must exist on the cluster. |
| 0 | kyverno | Policy engine; [Argo + Kyverno notes](https://kyverno.io/docs/installation/platform-notes/#notes-for-argocd-users). |
| 0 | cert-manager | CRDs + controller; `installCRDs: true`. |

Other add-ons (VictoriaMetrics, OpenTelemetry, Crossplane, CNPG, SPIRE, etc.) are easy to add as more `Application` YAMLs under `platform/`.

## Validate locally

With [kustomize](https://kubectl.docs.k8s.io/installation/kustomize/):

```bash
kustomize build clusters/capi-quickstart
```

## References

- [Argo CD cluster bootstrapping / app of apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Cluster API workload GitOps (CAAPH)](https://cluster-api.sigs.k8s.io/tasks/workload-bootstrap-gitops)
- [CAAPH quick start](https://github.com/kubernetes-sigs/cluster-api-addon-provider-helm/blob/main/docs/quick-start.md)
