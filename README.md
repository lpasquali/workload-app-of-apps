# Workload app-of-apps (Argo CD)

A **reusable, generic** in-cluster [Argo CD](https://argo-cd.readthedocs.io/) app-of-apps tree: child `Application` resources for **metrics-server**, **Kyverno**, **cert-manager**, and (optionally) **Proxmox CSI**. Use it for any cluster where Argo runs **in-cluster** and the destination is `https://kubernetes.default.svc`.

You can also wire it from **Cluster API** workload [GitOps (CAAPH)](https://cluster-api.sigs.k8s.io/tasks/workload-bootstrap-gitops); nothing here is hard-coded to a single cluster name.

## Layout

| Path | Purpose |
|------|---------|
| `base/core/` | Kustomize bundle: **metrics-server**, **kyverno**, **cert-manager** (no Proxmox). |
| `base/platform/proxmox-csi.yaml` | Optional **Proxmox CSI** `Application` (Helm, OCI). |
| `base/kustomization.yaml` | **Full** stack: `core` + Proxmox CSI. |
| `examples/default/` | Root path = full `base` (default CSI Secret name). |
| `examples/k8s-only/` | Root path = `core` only (no Proxmox). |
| `examples/proxmox-secret-name/` | Full `base` + **example patch** for `<cluster>-proxmox-csi-config` style secrets. |
| `clusters/<name>/` | Optional: **your** overlay (copy an `example` and customize). |
| `cluster.env.example` | Optional env var hints for Git URL/path/ref (for bootstrap or scripts). |

Child `Application` **metadata.name** values are **short and cluster-agnostic** (e.g. `metrics-server`), because a typical in-cluster Argo per workload cluster has one namespace and no collision with other clusters.

## Secret management

This repo has **no credentials in Git**. Values such as Proxmox CSI’s `existingConfigSecret` only **reference** a `Secret` that must already exist on the **workload (destination) cluster**—Argo never needs the raw secret material in the app-of-apps manifests. That matches Argo CD’s recommended **destination cluster** model (see [Secret Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/)).

In our environments, **sensitive data for Argo CD and the workloads it syncs** is provided via the **[Kubernetes Secrets Store CSI driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver)** (integrate an external or cloud secret store, sync into Kubernetes `Secret` objects, optional rotation). The Helm values here only point at those **Secret names**; provisioning the backing volume/provider is outside this tree (bootstrap, platform chart, or a dedicated platform app).

## Point your root `Application` (or CAAPH) at a path

1. Push this repo to your Git forge.

2. Set the **Kustomize root** as the `Application` **source path** (the directory that contains `kustomization.yaml`):

   - Full stack, default secret name: **`examples/default`** (or **`base`**, equivalent via `default`).
   - No Proxmox: **`examples/k8s-only`**.
   - Secret named like `<name>-proxmox-csi-config`: start from **`examples/proxmox-secret-name`**, edit `patches/proxmox-csi-secret-name.yaml` (`MY_CLUSTER` → your name), and use that directory as the path, **or** copy it to e.g. `clusters/prod-foo/`.

Example bootstrap-style variables (names vary by your management script):

```text
WORKLOAD_GITOPS_MODE=caaph
WORKLOAD_APP_OF_APPS_GIT_URL=https://github.com/<org>/workload-app-of-apps.git
WORKLOAD_APP_OF_APPS_GIT_PATH=examples/default
WORKLOAD_APP_OF_APPS_GIT_REF=main
```

The [argocd-apps](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd-apps) (or your) root `Application` should use that **path**; it expands to the child `Application` manifests. The root app’s **`metadata.name`** is usually your `WORKLOAD_CLUSTER_NAME` on the **management** cluster — that is **independent** of the short names inside this tree.

## Optional: `clusters/<name>/`

For team-specific **patches** or extra charts, copy `examples/default` (or `examples/proxmox-secret-name`) to `clusters/<name>/` and set `WORKLOAD_APP_OF_APPS_GIT_PATH=clusters/<name>`. See `clusters/_template/README.md`.

## Conventions (defaults in `base/`)

- **Destination** is `https://kubernetes.default.svc` (same cluster as Argo).
- **Sync waves** use `argocd.argoproj.io/sync-wave` to order installs.
- **Chart / image versions** are pinned in YAML; bump as you need (Renovate-friendly).

## Validate locally

With [kustomize](https://kubectl.docs.k8s.io/installation/kustomize/):

```bash
make render
# or
kustomize build examples/default
kustomize build examples/k8s-only
kustomize build base
```

## References

- [Argo CD: Secret management](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/) (destination-cluster vs manifest-generation)
- [Kubernetes Secrets Store CSI driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver)
- [Argo CD cluster bootstrapping / app of apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Cluster API workload GitOps (CAAPH)](https://cluster-api.sigs.k8s.io/tasks/workload-bootstrap-gitops)
- [CAAPH quick start](https://github.com/kubernetes-sigs/cluster-api-addon-provider-helm/blob/main/docs/quick-start.md)
