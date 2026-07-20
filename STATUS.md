# Project Status

_Last updated: 2026-07-07 (self-serve entitlement + money-type + review-queue-real-data + cleanups merged; epics 2–5 test-verified)._

Single place for what's done, what's in flight, and what's left. This replaces the
old BMAD sprint-status / story tracking.

---

## 🎯 Primary goal — ACHIEVED & VERIFIED LIVE

> Publish a plugin (`ut-plugin-faq`) to the store → approve & make it available →
> download, verify, install, and use it on the POS.

The whole chain works end-to-end against the **live** marketplace
(`https://cloud.home.taskrunnertech.co.uk`):

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
| Self-serve entitlement | **Done.** Free listings auto-acquire on the download path (`entitlements.Service.Acquire` + `downloadsvc` `WithAcquirer`); paid still needs approval. No more hand-granting. |
| Money typing (POS) | `internal/money.Money` (compiler-enforced minor units) now covers the sale/tender engine **and** the shifts/cash-drawer module; conversions only at DB/DTO seams. |
| Postgres migrations | Switched to **ent auto-migrate** (was drifting); proven on a fresh DB. |
| Deployment | Marketplace live on k3s via ArgoCD; secrets from Azure Key Vault (CSI); Postgres in-cluster; Let's Encrypt TLS. |
| CI/CD | Marketplace image → ACR (creds from Key Vault via OIDC); Terraform fmt/validate/plan; plugin release workflow. |

## 🔶 Optional / not blocking the goal

- **Epics 2–5 acceptance** — **formalized** as a capability→test matrix grounded in
  the green suite: [`reference/pos-acceptance-matrix.md`](reference/pos-acceptance-matrix.md)
  (verified 2026-07-07: `universal-till` 12 test packages + `ut-market-place` 18, **0
  failures**). The code exists and each capability is mapped to the tests that accept
  it. Remaining under this heading is only true greenfield (below), not story text.
- **Offline export/import bundles (epic 1-1 AC3)** — **shipped for the single-plugin
  case.** Import already existed; export was added (`internal/plugins/exporter.go`) and
  both are wired: `GET /api/plugins/{id}/export?version=` + an Export action on the
  plugins page, round-tripping through `POST /api/plugins/import-from-file`. Remaining:
  **multi-plugin** bundles + making the `./data/plugins` base dir configurable — a
  scope decision, not blocking.
- **POS UI MVP (epic 1-4)** — still needs a design/scope decision (which screens/flows
  constitute the MVP); the POS already renders functional pages (see the acceptance
  matrix). The plugin Export action above is one concrete UI increment.

### Recently cleared (2026-07-07)

- Self-serve entitlement (see Done above) — was the top optional item.
- Dead `entitlementssvc` package removed from `ut-market-place` (never mounted,
  off-contract).
- **Review-queue UI** now renders real data — `/admin/reviews` lists releases with
  an open review assignment (`reviews.Service.ListQueue`), replacing the mock row.
- Money typing extended to the shifts/cash-drawer module (see Done above).
- Dev flow / READMEs repointed to the deployed dev marketplace (mock fallback
  dropped).
- Review-queue Approve/Reject buttons wired to the decision endpoint.
- Epics 2–5 acceptance formalized as a capability→test matrix.
- Offline plugin export bundle + endpoint + Export UI action (see above).

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
