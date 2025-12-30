# Comprehensive Analysis — Marketplace (ut-market-place)

## Entry Points

- Server: `cmd/marketplace/main.go`
- Sync CLI: `cmd/marketplace-sync/main.go` (bundle export/import for disconnected stores)

## Configuration

Key env vars (see `internal/config/config.go`):
- Database: `DATABASE_DRIVER`, `DATABASE_AUTH_MODE`, etc.
- Auth: `AUTH_DISABLED`, `AUTH_JWT_SECRET`, `AUTH_TOKEN_DURATION`, `AUTH_ISSUER_URL`, `AUTH_AUDIENCE`, `AUTH_JWKS_URL`
- Redis: `REDIS_URL`
- NATS: `NATS_URL`, `NATS_STREAM`, `NATS_CONSUMER_PREFIX`, and related tuning vars
- UI port: `MARKETPLACE_UI_PORT`

## Observability

- OpenTelemetry exporters and Prometheus metrics handler are wired in startup (see `cmd/marketplace/main.go`).

## i18n / Localization

- Locale files exist under `locales/` (e.g., `en-US.json`, `fa-IR.json`, `tr-TR.json`, etc.).

## CI / Verification

- CI runs `scripts/ci/verify.sh` (see `.github/workflows/ci.yml`).

