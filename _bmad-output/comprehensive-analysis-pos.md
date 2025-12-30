# Comprehensive Analysis — POS (universal-till)

## Entry Points

- Main: `main.go`
- Local scripts: `scripts/*/main.go` (smoke tests, mock marketplace, migrations)

## Configuration

Primary env vars (see `internal/config/config.go`):
- `UT_LISTEN_ADDR`, `UT_DB_PATH`, `UT_STORE_NAME`, `UT_LOG_LEVEL`, `UT_THEME`
- Localization: `UT_DEFAULT_LOCALE`, `UT_CURRENCY`, `UT_CURRENCY_SYMBOL`
- Marketplace integration: `UT_MARKETPLACE_ENDPOINT_URL`, `UT_MARKETPLACE_CLIENT_ID`, `UT_MARKETPLACE_CLIENT_SECRET`, `UT_MARKETPLACE_API_VERSION`

## Plugin & Marketplace Integration

- Plugin cache dirs created: `./data/plugins/cache`, `./data/plugins/tmp` (`main.go`)
- Marketplace catalog repository initialized when `UT_MARKETPLACE_ENDPOINT_URL` is set (`main.go`)
- POS exposes plugin management endpoints under `/api/plugins/*` and a store UI under `/plugins/store`.

## Testing

- Go tests exist in `internal/pages/*_test.go`, `internal/pos/*_test.go`, etc.
- CI runs `go build ./...` and `go test ./...` (see `.github/workflows/ci.yml`).

## i18n

- Locales loaded from `web/locales/*.json` via `internal/config/i18n.go` (seen locales include `en.json`, `fa.json`).

