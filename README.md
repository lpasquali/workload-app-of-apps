# Workload app-of-apps (Argo CD)

A **reusable** in-cluster [Argo CD](https://argo-cd.readthedocs.io/) app-of-apps tree. **`examples/default`** keeps a **small** set: **metrics-server**, **Kyverno**, **cert-manager**, **Proxmox CSI**. **`examples/full-bootstrap-parity`** adds every optional add-on the legacy `apply_workload_argocd_applications` path in `bootstrap-capi.sh` used to create (Crossplane, CNPG, ESO, Infisical, SPIRE, VictoriaMetrics, OTel, Grafana, Keycloak). The destination is always `https://kubernetes.default.svc`.

This repo is the **Kustomize `source.path`** for the **root** `Application` that points at these manifests (same cluster, `https://kubernetes.default.svc`).

**How Argo runs:** the **Argo CD control plane** on the workload is expected from the **[Argo CD Operator](https://argocd-operator.readthedocs.io/)** (e.g. an `ArgoCD` custom resource) or an equivalent product (e.g. **Red Hat OpenShift GitOps**). This repository does **not** install the Argo server or repo-server itself—only child `Application` YAMLs and optional patches.

**How that root app is registered:** in our bootstrap, `bootstrap-capi.sh` uses **CAAPH** to apply the **[argocd-apps](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd-apps)** `HelmChartProxy` on the management cluster, which creates the root `Application` and Git coordinates. The upstream **argo-cd** Helm chart via CAAPH is **off by default** so it does not replace the operator. **CAAPH is the only supported GitOps mode** for that wiring. Nothing in this tree is hard-coded to a single cluster name.

## What Argo CD installs (audit)

| Source | What it creates | Notes |
|--------|----------------|--------|
| **CAAPH `argocd-apps` Helm chart** (from `bootstrap-capi.sh`) | One **root** `Application` named `WORKLOAD_CLUSTER_NAME` with `source.repoURL` + `source.path` pointing at this repo | The only `Application` not stored in Git here; it is the entry point for the app-of-apps. |
| **This Git tree** (Kustomize under your chosen `source.path`) | Child `Application` resources — see `base/core`, `base/platform`, and optionally `base/addons` | `examples/default` = core + Proxmox; `examples/full-bootstrap-parity` = default + all `base/addons` (matches legacy bootstrap list). **Not in Git:** Backstage (no default chart URL in the script) and **keycloak-realm-operator** (needs a Git `repoURL`); add those in your own overlay if you use them. |

**HelmChart** installs that are **not** Argo `Application` resources (e.g. Cilium or optional `argo-cd` via CAAPH) are outside this list.

`bootstrap-capi.sh` no longer calls the legacy `apply_workload_argocd_applications` path, so the script does not push platform `Application` YAML to the workload **besides** what the `argocd-apps` `HelmChartProxy` creates (the root) and what Git defines (the children).

## Layout

| Path | Purpose |
|------|---------|
| `base/core/` | Kustomize bundle: **metrics-server**, **kyverno**, **cert-manager** (no Proxmox). |
| `base/platform/proxmox-csi.yaml` | Optional **Proxmox CSI** `Application` (Helm, OCI). |
| `base/kustomization.yaml` | **Full** stack: `core` + Proxmox CSI. |
| `base/addons/` | Extra `Application` YAMLs (Crossplane, CNPG, ESO, Infisical, SPIRE, VM, OTel, Grafana, Keycloak) for parity with in-script Argo. |
| `examples/default/` | Root path = full `base` (default CSI Secret name). |
| `examples/k8s-only/` | Root path = `core` only (no Proxmox). |
| `examples/proxmox-secret-name/` | Full `base` + **example patch** for `<cluster>-proxmox-csi-config` style secrets. |
| `examples/full-bootstrap-parity/` | `base` + **`base/addons`** — large footprint; use when you want the same add-ons the script used to `kubectl apply` as Argo apps. |
| `clusters/<name>/` | Optional: **your** overlay (copy an `example` and customize). |
| `cluster.env.example` | Optional env var hints for `bootstrap-capi.sh` (CAAPH) and Git `path`/`ref`. |

Child `Application` **metadata.name** values are **short and cluster-agnostic** (e.g. `metrics-server`), because a typical in-cluster Argo per workload cluster has one namespace and no collision with other clusters.

## Secret management

This repo has **no credentials in Git**. Values such as Proxmox CSI’s `existingConfigSecret` only **reference** a `Secret` that must already exist on the **workload (destination) cluster**—Argo never needs the raw secret material in the app-of-apps manifests. That matches Argo CD’s recommended **destination cluster** model (see [Secret Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/)).

In our environments, **sensitive data for Argo CD and the workloads it syncs** is provided via the **[Kubernetes Secrets Store CSI driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver)** (integrate an external or cloud secret store, sync into Kubernetes `Secret` objects, optional rotation). The Helm values here only point at those **Secret names**; provisioning the backing volume/provider is outside this tree (bootstrap, platform chart, or a dedicated platform app).

## Point CAAPH at a path

1. Push this repo to your Git forge.

2. Set the **Kustomize root** as the `Application` **source path** (the directory that contains `kustomization.yaml`):

   - Full stack, default secret name: **`examples/default`** (or **`base`**, equivalent via `default`).
   - No Proxmox: **`examples/k8s-only`**.
   - Secret named like `<name>-proxmox-csi-config`: start from **`examples/proxmox-secret-name`**, edit `patches/proxmox-csi-secret-name.yaml` (`MY_CLUSTER` → your name), and use that directory as the path, **or** copy it to e.g. `clusters/prod-foo/`.
   - **Legacy in-script add-ons** (same as old `apply_workload_argocd_applications`): set **`WORKLOAD_APP_OF_APPS_GIT_PATH=examples/full-bootstrap-parity`**. Review **SPIRE** `global.spire.clusterName` / `trustDomain` in `base/addons/spire.yaml` and **Keycloak** / SPIFFE discovery URLs; patch in an overlay to match your cluster and release names.

Install the **Argo CD Operator** (or your vendor GitOps operator) on the **workload** cluster *before* the `argocd-apps` Helm release can create `Application` CRs, or sync will fail. Then `bootstrap-capi.sh` (CAAPH) should set the app-of-apps Git coordinates, for example:

```text
WORKLOAD_GITOPS_MODE=caaph
WORKLOAD_APP_OF_APPS_GIT_URL=https://github.com/<org>/workload-app-of-apps.git
WORKLOAD_APP_OF_APPS_GIT_PATH=examples/default
WORKLOAD_APP_OF_APPS_GIT_REF=main
```

The **argocd-apps** `HelmChartProxy` (CAAPH) creates the root `Application` with that **path**; that app expands to the child `Application` manifests on the **workload** (in-cluster Argo from the operator). The root app’s **`metadata.name`** is your `WORKLOAD_CLUSTER_NAME` in bootstrap terms and is **independent** of the short names (e.g. `metrics-server`) used for child apps in this tree.

## Optional: `clusters/<name>/`

For team-specific **patches** or extra charts, copy `examples/default` (or `examples/proxmox-secret-name`) to `clusters/<name>/` and set `WORKLOAD_APP_OF_APPS_GIT_PATH=clusters/<name>` in your CAAPH bootstrap. See `clusters/_template/README.md`.

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
make render-full
# or
kustomize build examples/full-bootstrap-parity
```

## References

- [Argo CD: Secret management](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/) (destination-cluster vs manifest-generation)
- [Kubernetes Secrets Store CSI driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver)
- [Argo CD operator (community)](https://argocd-operator.readthedocs.io/) — workload control plane
- [Argo CD cluster bootstrapping / app of apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Cluster API workload GitOps (CAAPH)](https://cluster-api.sigs.k8s.io/tasks/workload-bootstrap-gitops)
- [CAAPH quick start](https://github.com/kubernetes-sigs/cluster-api-addon-provider-helm/blob/main/docs/quick-start.md)
