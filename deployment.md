# Deployment & Infrastructure (Universal Till)

How the Universal Till marketplace and its supporting infrastructure are
provisioned and deployed. Intended delivery is **GitHub Actions-driven**
(terraform + image build + GitOps commit); the initial bring-up was done live and
still has some GitOps debt (see the last section).

Current live state: the marketplace runs at
**https://marketplace.home.taskrunnertech.co.uk** on the homelab k3s cluster, with
Postgres in-cluster and its secrets sourced from Azure Key Vault via the Secrets
Store CSI driver.

---

## Topology overview

```
                 GitHub Actions (CI/CD)
   ┌─────────────────────┬──────────────────────┬─────────────────────┐
   │  terraform          │  build & push        │  GitOps commit      │
   │  (infra/)           │  (ut-market-place)   │  (homelab-k8s)      │
   ▼                     ▼                      ▼
Azure platform      ACR image              ArgoCD unitill-marketplace app
uni-till-platform   unitillacr01.azurecr   → k3s homelab cluster
(RG, ACR, KeyVault, .io/ut-market-place    → marketplace.home.taskrunnertech.co.uk
 DNS)
```

## 1. Azure platform — `infra/unitill-infra` (Terraform)

Terraform root at `infra/unitill-infra` (providers `azurerm ~> 4.0`,
`github ~> 6.0`, `random ~> 3.6`). Provisions, in subscription
`7e341019-…` / tenant `6823ebc7-…`:

| Resource | Name |
|---|---|
| Resource group | `uni-till-platform` (uksouth) |
| Container registry | `unitillacr01` → `unitillacr01.azurecr.io` |
| Key Vault | `kv-unitill-dev` — single source of truth for credentials |
| DNS zone | `home.taskrunnertech.co.uk` (delegated subzone; `*` CNAME → `farshiduk.ddns.net`) |

`secrets.tf` generates the Postgres password, upload token, and a 32-byte Ed25519
signing seed and writes them (plus the Postgres DSN and ACR admin creds) into Key
Vault. Pipeline: `.github/workflows/terraform.yml` (fmt/validate/plan on PR, gated
apply). Remote state uses the azurerm backend (see `infra/README.md` for the
one-time bootstrap).

## 2. Marketplace image — `ut-market-place`

`.github/workflows/build-and-push.yml` runs CI verification, authenticates to
Azure via **OIDC**, reads the ACR credentials from **Key Vault**, and builds +
pushes the `production` Docker target for **linux/arm64** (buildx + QEMU; the
cluster nodes are Raspberry Pi) as `unitillacr01.azurecr.io/ut-market-place:{sha,latest}`.
The binary links go-sqlite3 (CGO), so the runtime image is debian-slim; it serves
plain HTTP on **:8081** behind Traefik (`HTTP_TLS_AUTO_DEV_CERT=false`).

## 3. Cluster delivery — `homelab-k8s` (ArgoCD GitOps)

Homelab k3s v1.31 cluster (`git@github.com:taskrunnertech/homelab-k8s.git`, 2
Raspberry Pi nodes), ArgoCD with `selfHeal`/`prune`. Relevant services: Traefik
ingress, cert-manager, MetalLB (192.168.1.200–220), NFS provisioner, `local-path`.

The marketplace is the **`unitill-marketplace`** ArgoCD application
(`kubernetes/apps/unitill-marketplace/`):

| File | Contents |
|---|---|
| `deployment.yaml` | Deployment (image `unitillacr01.azurecr.io/ut-market-place:latest`, port 8081, non-root, /healthz probes) + Service (80→8081) + Ingress `marketplace.home.taskrunnertech.co.uk` (issuer `letsencrypt-home`, `wildcard-tls`). Mounts the CSI volume; `envFrom` the synced `marketplace-pg-secret`. Reloader-annotated. |
| `postgres.yaml` | Postgres 16-alpine StatefulSet, 20Gi `local-path`; static DB/USER, `POSTGRES_PASSWORD` from the synced secret. |
| `secretproviderclass.yaml` | Maps KV → `marketplace-pg-secret` (POSTGRES_PASSWORD/DSN, MARKETPLACE_UPLOAD_TOKEN/SIGNING_KEY). |
| `pvc.yaml` | blob + Postgres PVCs. |

Supporting apps (ArgoCD): `secrets-store-csi` (CSI driver + Azure provider),
`reloader` (restarts the marketplace on KV rotation).

**TLS:** the default `letsencrypt-prod` issuer solves DNS-01 against the parent
`taskrunnertech.co.uk` zone (RG `DNS`, subscription `a1e235f5-…`), which is not
reachable from this subscription. The marketplace instead uses **`letsencrypt-home`**
(`kubernetes/infrastructure/cert-manager/clusterissuer-home.yaml`) which solves
against the terraform-managed `home.taskrunnertech.co.uk` subzone.

## 4. Secrets model

- **App config** (DSN, upload token, signing key): Key Vault → CSI driver →
  synced `marketplace-pg-secret` → `envFrom`. Rotation is picked up by Reloader
  (marketplace only; Postgres password rotation is a DB-level `ALTER ROLE`).
- **Two bootstrap secrets can't come from Key Vault** (root of trust):
  `secrets-store-creds` (the SP the CSI driver uses to reach KV) and `acr-pull`
  (image pull — kubelet pulls before the CSI volume mounts). Plus
  `azure-dns-home-secret` (the SP for the cert DNS-01 challenge).

## GitOps debt (initial bring-up was done live)

The following exist **live but are not yet in git / terraform-managed**, so a
clean rebuild would need them recreated:

- KV secret **values** were set by hand (terraform `secrets.tf` would generate
  them, but applying it now would rotate the live values → Reloader restart, and
  the signing pubkey would change, requiring a POS update).
- Two service principals created via `az`: `unitill-kv-csi` (KV get/list) and
  `unitill-cert-dns` (DNS Zone Contributor on the home subzone). Not in terraform.
- k8s secrets `secrets-store-creds`, `acr-pull`, `azure-dns-home-secret` created
  via `kubectl` (not sealed — the sealed-secrets controller is not installed).
- The `letsencrypt-home` ClusterIssuer **is** now in git; the deployed image was
  built locally (CI can build it now that the branches are merged).

To retire the debt: install sealed-secrets and seal the three bootstrap secrets;
add the two SPs + their KV/DNS access policies to terraform; run terraform to own
the KV secrets (accepting a one-time rotation).
