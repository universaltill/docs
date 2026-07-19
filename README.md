<p align="center">
  <img src="logo/ut-logo-name.svg" alt="Universal Till" width="320">
</p>

# Universal Till — Documentation

**Universal Till (unitill)** is an **offline-first Point-of-Sale platform** with a
**plugin marketplace**. Merchants run the POS on till hardware; every feature —
pages, payments, integrations, reports, devices, background jobs — is a **plugin**
that is published to a marketplace, reviewed and **Ed25519-signed**, then
downloaded and installed onto tills where the signature is verified before it runs.

## Goals

- **Offline-first:** checkout never blocks on the network; plugin bundles are
  self-contained and verifiable offline.
- **A trustworthy plugin supply chain:** publish → review → sign → verify → install,
  so a till only ever runs a plugin the marketplace has signed.
- **Everything-as-a-plugin:** one manifest contract for all extension types.
- **Boring, testable code:** money as integer minor units; domain logic testable
  without DB/network/UI.

## The projects

| Repo | What it is |
|---|---|
| **`universal-till`** | The POS host — checkout, catalog, inventory, receipts, sync, settings, and the plugin host. Go, SQLite, HTMX. |
| **`ut-cloud`** | Universal Till Cloud (renamed from `ut-market-place` 2026-07-19) — the plugin marketplace, store claim/enrolment, owner back-office, admin/vendor consoles. Go, ent, Postgres/SQLite. Deployed to the homelab cluster. |
| **`ut-plugin-faq`** | The first sample plugin (a multilingual FAQ page) and the template every plugin repo copies for packaging/publishing. Go. |
| `ut-infra` | Terraform for the Azure platform (ACR, Key Vault, DNS). |
| `homelab-k8s` | ArgoCD GitOps manifests for the k3s cluster the marketplace runs on. |

## Start here

| I want to… | Read |
|---|---|
| Understand the whole system | [architecture.md](architecture.md) |
| Build / test / run the code | [for-developers.md](for-developers.md) |
| Build & publish a plugin | [for-plugin-developers.md](for-plugin-developers.md) |
| Use the POS | [guides/pos.md](guides/pos.md) |
| Use the marketplace (vendor/admin) | [guides/marketplace-admin.md](guides/marketplace-admin.md) |
| Build your own POS terminal (hardware + 3D print) | [hardware/diy-pos.md](hardware/diy-pos.md) |
| Look up a technical contract | [reference/](reference/) |
| See what's done and what's left | [STATUS.md](STATUS.md) |

## Documentation layout

```
README.md                 ← you are here (index + projects & goals)
architecture.md           ← what the system is / how it fits together
for-developers.md         ← build, test, run, conventions, CI/CD
for-plugin-developers.md  ← build & publish a plugin
guides/
  pos.md                  ← using the till
  marketplace-admin.md    ← publishing, reviewing, approving
reference/                ← coding standards, code structure, data model,
                            manifest, lifecycle, release artifact, deployment
STATUS.md                 ← consolidated status / tasks
```
