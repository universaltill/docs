# Code Structure

Where things live in each repo. A map for finding your way around, not an
exhaustive file list — the tree evolves, so trust the source.

---

## `universal-till` (POS host)

Single Go module; entrypoint is `main.go` at the root. Standard `internal/` layout:

```
main.go                     # wires config → data → server → run
internal/
  config/                   # env-driven configuration (incl. marketplace conn)
  db/migrations/            # 001_init.sql (append-only SQLite schema)
  data/                     # repositories (repo-owned SQL: *_repo.go)
  pos/                      # checkout / catalog / inventory / sales domain
  catalogtypes/             # shared catalog value types
  settings/                 # store & device settings
  plugins/                  # the plugin host  ← see below
  pages/ ui/ httpx/         # HTTP handlers + HTMX view layer
  server/                   # HTTP server assembly & routing
  logging/ testsupport/
web/
  locales/                  # i18n message files (no hardcoded UI strings)
  ui/ public/               # templates & static assets
```

### `internal/plugins/` — the plugin host

The subsystem that installs, verifies, and runs plugins:

- `manifest.go`, `types.go` — the `Manifest` contract (the signing source of truth).
- `manifest_verifier.go` — **Ed25519 signature verification** against the
  marketplace public key.
- `installer_marketplace.go`, `install.go`, `download_manager.go` — download →
  verify → install flow.
- `install_reporter.go`, `install_status.go` — report install state back to the
  marketplace (`/ui/api/installs/{id}/state`).
- `marketplace/` (client), `oauth/`, `storage/` — subpackages.
- `supervisor.go`, `ipc.go`, `permissions.go`, `authorizer.go` — running plugins.
- `update_checker.go`, `revocation.go`, `rollback.go`, `importer.go` — lifecycle.

---

## `ut-market-place` (marketplace)

Go module with multiple entrypoints under `cmd/` and a broad `internal/`:

```
cmd/
  marketplace/              # the HTTP service
  marketplace-sync/         # sync worker
  mp-cli/                   # admin/ops CLI (install intents, etc.)
internal/
  repositories/ent/         # ent ORM — schema/ is the DB source of truth
  data/                     # ent client open + auto-migrate (Postgres/SQLite)
  config/                   # env configuration
  api/  httpapi/  server/   # HTTP handlers (vendor upload, admin, /ui) + routing
  app/  lifecycle/  platform/  observability/
  downloads/                # ingest (upload+validate+checksum) + scan + serve
  reviews/                  # review assignment, gatekeeper, approver (signing)
  signing/                  # Ed25519 CanonicalManifest + sign/verify
  entitlements/  installs/  # store entitlements + POS install intents
  catalog/  vendors/  versioning/
  compliance/  revocations/  telemetry/  events/  auth/
  i18n/  tls/  gen/
```

Key flows and their homes: **upload/ingest** → `internal/downloads`, **validation
scan** → `internal/downloads` (scanner), **review/approve/sign** →
`internal/reviews` + `internal/signing`, **entitlement gate + download token** →
`internal/entitlements` + downloads, **install status** → `internal/installs`.

> The signing contract (`internal/signing.CanonicalManifest`) must mirror the POS
> `plugins.Manifest` struct field-for-field — a cross-repo test guards it.

---

## `ut-plugin-faq` (sample plugin & template)

The reference a plugin repo copies:

```
src/               # plugin runtime (compiled to bin/<name>); manifest under src/manifest
content/           # localized content (<locale>.json)
assets/            # icons etc.
tools/pkgtool/     # stdlib-only manifest validator + stage/release-json helper
scripts/           # validate.sh, package.sh, publish.sh
specs/  tests/      # spec + tests
dist/              # build output (packaged artifacts) — gitignored
```

---

## `infra` & `homelab-k8s`

- `infra/` — Terraform for the Azure platform (ACR, Key Vault, DNS) with a
  GitHub Actions plan/apply pipeline.
- `homelab-k8s/` — ArgoCD GitOps manifests; `kubernetes/apps/…` (the marketplace
  app) and `kubernetes/infrastructure/…` (cert-manager, CSI driver, etc.).

See [deployment.md](deployment.md) for how these produce the live system.
