# Universal Till — Architecture & Information Architecture

Universal Till (unitill) is an **offline-first Point-of-Sale (POS) platform** with
a **plugin marketplace**. Merchants run the POS on till hardware; functionality is
extended by plugins that are published to a marketplace, reviewed and signed, then
downloaded and installed onto tills.

This document is the single source of truth for *what the system is* and *how the
pieces fit together*. For task-specific docs see the [documentation map](#documentation-map).

---

## The three repositories

The workspace lives at `~/repos/unitill/` (not itself a git repo; each component
is its own repo).

| Repo | Role | Language |
|------|------|----------|
| **`universal-till`** | The POS host — the till application. Runs checkout, catalog, inventory, receipts, sync, settings, and the **plugin host** that installs and runs plugins. | Go |
| **`ut-market-place`** | The marketplace — publishes/validates/signs plugin releases, serves downloads, and hosts the vendor + admin web UI. Deployed to the homelab cluster. | Go (ent ORM, Postgres/SQLite) |
| **`ut-plugin-faq`** | The first sample plugin (a multilingual FAQ page). The template for how a plugin repo packages and publishes. | Go |
| `infra` | Terraform for the Azure platform (ACR, Key Vault, DNS). | Terraform |
| `homelab-k8s` | ArgoCD GitOps manifests for the k3s homelab cluster the marketplace runs on. | YAML |

## System overview

```
   Plugin repo (ut-plugin-faq)          Marketplace (ut-market-place)          POS host (universal-till)
   ┌──────────────────────┐   upload    ┌───────────────────────────┐  token   ┌──────────────────────┐
   │ package.sh → artifact ├───────────► │ validate → scan → review  ├────────► │ download → verify    │
   │ publish.sh            │             │ → approve + Ed25519 sign  │  bundle  │ (Ed25519) → install  │
   └──────────────────────┘             └───────────────────────────┘          └──────────────────────┘
                                          Postgres + blob storage                  SQLite + plugin dir
```

- A plugin is packaged into a **release artifact** (`.tar.gz` with a `manifest.json`
  at the root — see [reference/release-artifact.md](reference/release-artifact.md)).
- The marketplace validates the manifest, runs a structural scan, and on approval
  **signs the release with an Ed25519 key** and repackages the bundle so its
  manifest carries the signature.
- The POS requests a download token, downloads the signed bundle, **verifies the
  Ed25519 signature** against the marketplace public key, and installs it —
  registering the plugin's UI entries (e.g. the FAQ page under Help/Support).

Full step-by-step: [reference/plugin-lifecycle.md](reference/plugin-lifecycle.md).

## Core design principles

- **Offline-first:** checkout must never be blocked by the network; plugin bundles
  are self-contained and verifiable offline.
- **Signed supply chain:** every installed plugin is Ed25519-signed by the
  marketplace and verified by the POS before it runs.
- **Everything-as-a-plugin:** payments, integrations, pages, reports, devices, and
  background jobs are all plugins with a common manifest contract.
- **Money is integer minor units.** Domain logic is testable without DB/network/UI.
- **Server-rendered HTML + HTMX**, minimal JS. No hardcoded user-facing strings —
  all copy goes through locale files.

## Technology stack

- **Go** across POS, marketplace, and plugins.
- **Marketplace persistence:** [ent](https://entgo.io) ORM over **Postgres** (prod)
  / **SQLite** (dev). Blob storage via `gocloud.dev/blob` (`file://` on a PVC in
  the cluster). The ent schema is the single source of truth for the DB (auto-migrate).
- **POS persistence:** SQLite with in-repo migrations.
- **Signing:** Ed25519. The marketplace holds the private key; the POS is configured
  with the public key.
- **Cluster:** k3s (arm64 Raspberry Pi), ArgoCD, Traefik ingress, cert-manager,
  Azure Key Vault via the Secrets Store CSI driver.

## Live deployment topology

The marketplace runs on the homelab cluster at
**`https://marketplace.home.taskrunnertech.co.uk`**:

- Image built + pushed to Azure Container Registry `unitillacr01`, pulled by the
  ArgoCD `unitill-marketplace` app.
- Secrets (DB DSN, upload token, Ed25519 signing seed) live in Azure Key Vault
  `kv-unitill-dev` and are synced into the cluster by the CSI driver.
- Postgres runs **in-cluster** (StatefulSet); TLS is issued by cert-manager via a
  DNS-01 challenge on the delegated `home.taskrunnertech.co.uk` subzone.

Full details, including the one-time credential setup: [reference/deployment.md](reference/deployment.md).

## Documentation map

| Audience / purpose | Document |
|---|---|
| **What the system is** (this doc) | `architecture.md` |
| **Working on the codebase** | [`for-developers.md`](for-developers.md) |
| **Building & publishing a plugin** | [`for-plugin-developers.md`](for-plugin-developers.md) |
| **Using the POS** | [`guides/pos.md`](guides/pos.md) |
| **Using the marketplace (vendor + admin)** | [`guides/marketplace-admin.md`](guides/marketplace-admin.md) |
| **Technical contracts** | [`reference/`](reference/) — code structure, data model, plugin manifest, lifecycle, release artifact, deployment |
| **Project status / tasks** | [`STATUS.md`](STATUS.md) |
