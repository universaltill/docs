# Deployment & Infrastructure (Universal Till)

How the Universal Till marketplace and its supporting infrastructure are
provisioned and deployed. **All provisioning and installation is done through
GitHub Actions pipelines** — local `terraform apply` / `kubectl apply` is for
validation and dry-runs only, never as the delivery mechanism.

---

## Topology overview

```
                 GitHub Actions (CI/CD)
   ┌─────────────────────┬──────────────────────┬─────────────────────┐
   │  terraform          │  build & push        │  GitOps commit      │
   │  (infra/)           │  (ut-market-place)   │  (homelab-k8s)      │
   ▼                     ▼                      ▼
Azure platform      ACR image              ArgoCD app-store app
uni-till-platform   unitillacr01.azurecr   → k3s homelab cluster
(RG, ACR, KeyVault, .io/ut-market-place    → store.home.taskrunnertech.co.uk
 DNS)
```

## 1. Azure platform — `infra/unitill-infra` (Terraform)

Terraform root at `infra/unitill-infra` (providers: `azurerm ~> 4.0`,
`github ~> 6.0` with owner `universaltill`). State is currently **local**; the
azurerm remote backend block is commented out (target subscription
`7e341019-7961-47ba-9251-1ca1e2859a78`).

Resources:

| Resource | Name | Notes |
|---|---|---|
| Resource group | `uni-till-platform` | region `uksouth` |
| Container registry | `unitillacr01` | SKU Basic, `admin_enabled=true` → `unitillacr01.azurecr.io` |
| Key Vault | `kv-unitill-dev` | stores SP passwords / ACR creds |
| DNS zone | `home.taskrunnertech.co.uk` | in RG `uni-till-platform`; wildcard `*` CNAME → `farshiduk.ddns.net` |
| DNS NS record | `home` in `taskrunnertech.co.uk` (RG `DNS`) | delegates the `home` subzone to the zone above |

Outputs expose the ACR login server + admin creds (sensitive), Key Vault
id/endpoint, and the DNS zone name servers.

**Pipeline:** a workflow runs `terraform fmt -check` / `validate` / `plan` on PRs
and `apply` on merge to `main` (gated). Azure auth via an OIDC federated
credential or `AZURE_CREDENTIALS` service principal secret.

## 2. Marketplace image — `ut-market-place`

`ut-market-place/.github/workflows/build-and-push.yml` runs CI verification,
logs in to Azure + ACR, builds the `production` Docker target, and pushes
`:<sha>` and `:latest`.

> **Action item:** the workflow currently targets `utmarketplaceacr.azurecr.io/ut-market-place`.
> It must be repointed at the terraform-managed registry
> `unitillacr01.azurecr.io/ut-market-place` (with matching `ACR_USERNAME` /
> `ACR_PASSWORD` secrets sourced from Key Vault / terraform outputs).

## 3. Cluster delivery — `homelab-k8s` (ArgoCD GitOps)

Homelab k3s v1.31 cluster (repo `git@github.com:taskrunnertech/homelab-k8s.git`,
2 Raspberry Pi nodes). ArgoCD runs with `selfHeal: true` + `prune: true`, so the
only durable way to change the cluster is a git commit; manual kubectl edits are
reverted within ~3 minutes.

Cluster services relevant to the marketplace:
- **Traefik** ingress controller (`ingressClassName: traefik`).
- **cert-manager** `letsencrypt-prod` ClusterIssuer (Azure DNS-01 challenge) with
  a wildcard `Certificate` producing secret **`wildcard-tls`** for
  `*.home.taskrunnertech.co.uk`.
- **MetalLB** (192.168.1.200–220), **NFS provisioner**, `local-path` storage
  class on the `storage-tier=fast` control-plane node.

The marketplace is the **`app-store`** ArgoCD application (Pattern B — plain
manifests):

| File | Contents |
|---|---|
| `kubernetes/apps/app-store/deployment.yaml` | Deployment + Service (80→3000) + Ingress `store.home.taskrunnertech.co.uk` (cert-manager, `wildcard-tls`) |
| `kubernetes/apps/app-store/postgres.yaml` | Postgres 16-alpine StatefulSet, 20Gi `local-path` PVC on `storage-tier=fast`, headless service, envFrom `appstore-pg-secret` |
| `kubernetes/apps/app-store/secret.yaml` | placeholder DB creds — **must be sealed with kubeseal, never committed in plaintext** |
| `kubernetes/bootstrap/apps/app-store.yaml` | ArgoCD `Application` — **currently commented out (not deployed)** |

**To go live:**
1. Repoint `deployment.yaml` image to `unitillacr01.azurecr.io/ut-market-place:<tag>`
   and confirm the container listen port (currently `3000`).
2. Seal the DB secret: `kubeseal --format yaml < secret.yaml > sealed-secret.yaml`.
3. Uncomment `kubernetes/bootstrap/apps/app-store.yaml`.
4. Commit + push (via the deploy pipeline) → ArgoCD syncs.

## Known mismatches to reconcile before first deploy

1. **ACR name** — marketplace CI pushes to `utmarketplaceacr.azurecr.io`; terraform
   provisions `unitillacr01`. Pick one and align both.
2. **App-store image** — homelab deployment references the stale
   `ghcr.io/taskrunnertech/app-store:latest`, not the marketplace image.
3. **DNS / cert-manager subscription** — the ClusterIssuer solves DNS in
   subscription `a1e235f5-ab51-4005-8217-9ece95fe20a9` (RG `DNS`), which differs
   from the terraform subscription. Verify the SP has rights in the zone actually
   serving `home.taskrunnertech.co.uk`.

## Secrets

- Cluster secrets: **sealed-secrets** (`kubeseal`) committed to `homelab-k8s`.
- Azure/ACR creds for CI: GitHub Actions secrets, ideally sourced from Key Vault
  `kv-unitill-dev` or terraform outputs.
- cert-manager Azure DNS SP secret lives in-cluster as `azure-dns-secret`.
