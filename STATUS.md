# Project Status

_Last updated: 2026-07-07._

Single place for what's done, what's in flight, and what's left. This replaces the
old BMAD sprint-status / story tracking.

---

## 🎯 Primary goal — ACHIEVED & VERIFIED LIVE

> Publish a plugin (`ut-plugin-faq`) to the store → approve & make it available →
> download, verify, install, and use it on the POS.

The whole chain works end-to-end against the **live** marketplace
(`https://marketplace.home.taskrunnertech.co.uk`):

publish → validate → structural scan → review → approve + **Ed25519 sign** →
download-token → POS download (971 KB bundle, checksum match) → **signature
verified** → install → FAQ page registered under Help/Support.

Verified with the real production installer (`plugins.MarketplaceInstaller`),
not a mock.

## ✅ Done

| Area | Status |
|---|---|
| Plugin packaging (`ut-plugin-faq`) | Manifest aligned to the real POS contract; `tools/pkgtool` validator; `package.sh` cross-compile + checksum. |
| Publish pipeline | `publish.sh` + `release.yml` (tag-triggered). |
| Marketplace upload API | `/ui/api/vendor/releases/upload` — validate, checksum-verify, persist release, auto-create draft listing. |
| Release validation | Structural scan post-ingest; ent-backed review gatekeeper. |
| Review & approval | Assign + decision endpoints; approval signs (Ed25519) + repackages. |
| Signing | `MARKETPLACE_SIGNING_KEY` (32-byte seed from Key Vault); pubkey at `/ui/api/signing-key`. |
| POS install | Download-token → download → Ed25519 verify → install → register entries. |
| Install-state reporting | POS reports state to `/ui/api/installs/{id}/state`; `mp-cli` create/query. |
| Postgres migrations | Switched to **ent auto-migrate** (was drifting); proven on a fresh DB. |
| Deployment | Marketplace live on k3s via ArgoCD; secrets from Azure Key Vault (CSI); Postgres in-cluster; Let's Encrypt TLS. |
| CI/CD | Marketplace image → ACR (creds from Key Vault via OIDC); Terraform fmt/validate/plan; plugin release workflow. |

## 🔶 Optional / not blocking the goal

- **Self-serve entitlement** — a store's entitlement was granted by hand. There is
  no "acquire"/self-entitle flow yet (or auto-entitle for free listings).
- **Review-queue UI** — `review_queue.html` still shows mock data; the API behind
  it is real.
- **Epics 2–5 acceptance** — catalog/inventory/tender/receipt/sync/offline/
  settings/permissions/etc. **code exists and tests are green**; only formal
  per-story acceptance authoring is outstanding (not greenfield work).
- **POS UI MVP (epic 1-4)** and **offline export/import bundles (epic 1-1 AC3)** —
  backlog.

## 🔧 GitOps / reproducibility debt

- Some live cluster resources were created by hand and aren't in git yet: the
  bootstrap secrets (`secrets-store-creds`, `acr-pull`, `azure-dns-home-secret`)
  need sealing (sealed-secrets controller not installed).
- Terraform should own the Key Vault secret **values** and the two service
  principals (`unitill-kv-csi`, `unitill-cert-dns`) via `import` — deferred because
  applying now would rotate live secrets (restart + signing-pubkey change).

## 👤 Needs Farshid (creds/cluster access)

- Add `ut-market-place` repo OIDC access to ACR (or `ACR_USERNAME`/`ACR_PASSWORD`).
- Push `infra/` to a GitHub remote; add `azure-prod` env + OIDC secrets.
- Install sealed-secrets + seal the three bootstrap secrets.

## Working agreements

- Work on **feature branches**; merge to `main` when ready.
- **Code review before every commit**, recorded in the touched repo's
  `docs/code-reviews/<date>-<topic>.md`.
- All installs go through **GitHub Actions / ArgoCD** — no local `apply`.
- Postgres stays **in-cluster** (not Azure) for now.
