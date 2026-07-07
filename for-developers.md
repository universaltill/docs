# Developer Guide

How to build, test, and run the Universal Till components. Read
[`architecture.md`](architecture.md) first for the big picture.

## Prerequisites

- **Go** (per each repo's `go.mod`: POS `1.25`, marketplace `1.25.3`, plugin `1.21`).
- **Docker** + buildx (for the marketplace container image; arm64).
- **Terraform** ≥ 1.5, **Azure CLI**, **kubectl** (for infra/cluster work only).

## Repositories

| Repo | What it is |
|---|---|
| `universal-till` | POS host (Go). Single binary (`main.go`); SQLite; HTMX UI. |
| `ut-market-place` | Marketplace (Go, ent, Postgres/SQLite, blob storage). |
| `ut-plugin-faq` | Sample plugin + the packaging/publish scripts other plugins copy. |
| `infra` | Terraform (Azure ACR / Key Vault / DNS). |
| `homelab-k8s` | ArgoCD manifests for the k3s cluster. |

For where things live inside each repo see
[`reference/code-structure.md`](reference/code-structure.md); for the persistence
layer see [`reference/data-model.md`](reference/data-model.md).

## Build, test, run

### Marketplace (`ut-market-place`)

```bash
go build ./...
go test ./...
# run locally (SQLite + file blob, plain HTTP on :8081)
DATABASE_DRIVER=sqlite SQLITE_PATH=./var/data/mp.db \
  BLOB_BUCKET_URL='file://./var/blob?create_dir=true&no_tmp_dir=true' \
  MARKETPLACE_HTTP_ADDRESS=:8081 HTTP_TLS_AUTO_DEV_CERT=false \
  go run ./cmd/marketplace
```

Key env vars: `DATABASE_DRIVER` (`sqlite`|`postgres`), `POSTGRES_DSN`,
`BLOB_BUCKET_URL`, `MARKETPLACE_UPLOAD_TOKEN` (gates upload/admin endpoints),
`MARKETPLACE_SIGNING_KEY` (hex Ed25519 seed or key — enables signing/approval).
The web UI is under `/ui/`; the public key is served at `/ui/api/signing-key`.

The **ent schema is the source of truth** for the DB. After changing
`internal/repositories/ent/schema/*`, run `go generate ./internal/repositories/ent`.
Postgres uses ent **auto-migrate** (`internal/data/database.go`) — no hand-written
SQL migrations.

### POS host (`universal-till`)

```bash
go build ./...
go test ./...
go run .        # serves the POS UI; SQLite self-migrates on start
```

Marketplace integration is configured via env (see the POS `internal/config`):
`UT_MARKETPLACE_ENDPOINT_URL` (**must include the `/api` base**, e.g.
`https://marketplace.home.taskrunnertech.co.uk/api`), `UT_MARKETPLACE_PUBLIC_KEY`
(the marketplace signing public key), `UT_MARKETPLACE_UPLOAD_TOKEN`
(for reporting install state), and merchant/store/device identifiers.

### Plugin (`ut-plugin-faq`)

```bash
scripts/validate.sh                     # validate manifest + version alignment
SKIP_TESTS=1 scripts/package.sh         # build the release artifact into dist/
MARKETPLACE_BASE_URL=... scripts/publish.sh   # upload to a marketplace
```

See [`for-plugin-developers.md`](for-plugin-developers.md).

## Conventions

The **authoritative, enforced** rules — repository pattern, no inline SQL,
naming, API/format, offline-first, i18n — are in
[`reference/coding-standards.md`](reference/coding-standards.md). Highlights:

- **Money** is always integer minor units.
- Domain logic must be testable without DB/network/UI; side effects live in adapters.
- API responses use the `{data}` / `{error:{message,details}}` JSON shape, snake_case.
- No inline SQL outside the repo-owned data layer (POS: `internal/data/*_repo.go`);
  no hardcoded user-facing strings (use locale files under `web/locales`).
- POS SQL migrations live under `internal/db/migrations/` and are **append-only**
  after the first release (pre-release, `001_init.sql` may still be edited).
- Server-rendered HTML + HTMX (`v2.x`), minimal JS. Kiosk/admin separation:
  status/lock/exit must always be reachable.
- Each feature needs happy-path and edge-case tests. E2E uses Playwright under each
  repo's `tests/`. Secrets are never logged or written to plain files.

## Reviews & commits

Run a code review before every commit and record it under the touched repo's
`docs/code-reviews/<date>-<topic>.md`. Work on feature branches; commit with a
`Co-Authored-By: Claude` trailer.

## CI/CD

- **Marketplace image:** `ut-market-place/.github/workflows/build-and-push.yml` —
  builds the arm64 image via buildx and pushes to ACR `unitillacr01`, reading ACR
  creds from Key Vault via OIDC.
- **Infra:** `infra/.github/workflows/terraform.yml` — fmt/validate/plan on PRs,
  gated apply.
- **Plugin release:** `ut-plugin-faq/.github/workflows/release.yml` — on `v*` tags,
  packages + publishes.
- **Cluster:** ArgoCD watches `homelab-k8s` `main`; committing manifests deploys.

## Deployment

The marketplace is deployed to the homelab k3s cluster via ArgoCD, with Azure
Key Vault as the source of truth for secrets. See
[`reference/deployment.md`](reference/deployment.md) for the full topology and the
one-time credential/bootstrap steps.
