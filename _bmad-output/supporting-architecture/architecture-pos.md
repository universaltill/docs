# Architecture — POS (universal-till)

Part: `pos`  
Repo: `~/repos/unitill/universal-till`

## Executive Summary

The POS application is an offline-first Go service that serves a browser UI (server-rendered HTML with HTMX-style partials) and exposes local APIs for POS operations (scan, tender, inventory, shifts, plugins). It uses a local SQLite database for persistence and embeds a plugin host model with explicit DB tables and HTTP endpoints for plugin lifecycle and marketplace-driven installation.

## Technology Stack

- Language/runtime: Go (go.mod: `go 1.25`)
- Storage: SQLite via pure-Go driver `modernc.org/sqlite`
- Config: dotenv (`github.com/joho/godotenv`) reading `pos.env` / `UT_ENV_FILE`
- Web server: Go `net/http` `http.ServeMux`
- UI: `web/ui` templates + `web/public` assets + HTMX-style partial rendering helpers (`internal/httpx`)
- i18n: JSON locale files under `web/locales` loaded by `internal/config/i18n.go`

## Architecture Pattern

- **Single-process edge server**: One Go binary orchestrates:
  - HTTP routes (UI + API)
  - Local DB and migrations
  - Plugin host and plugin state
  - Marketplace catalog caching and install actions
- **Offline-first by default**:
  - Core POS operates entirely without internet.
  - Marketplace connectivity adds capability but should not block sales flow.

## Key Modules

Entry point:
- `main.go`: loads env, initializes logging, config, DB+migrations, settings, plugins, marketplace catalog repo, and starts server.

Core packages:
- `internal/config`: env parsing, marketplace config, i18n initialization
- `internal/db`: DB open + migrations (`internal/db/migrations/001_init.sql`)
- `internal/pages`: route registration and handlers (UI + API endpoints)
- `internal/pos`: domain logic (basket, sales, etc.)
- `internal/plugins`: plugin manager and runtime integration points
- `internal/plugins/marketplace`: marketplace HTTP client and catalog snapshot repository
- `internal/settings`: runtime config persisted in DB
- `web/`: UI templates, assets, locales

## Data Architecture

- SQLite schema defined via SQL migrations.
- Plugin-specific tables exist for:
  - Marketplace catalog cache (`plugin_catalog`)
  - Installed plugin state (`plugins`)
  - Plugin UI/action registry (`plugin_entries`)
  - Permissions (`plugin_permissions`), settings (`plugin_settings`), hooks (`plugin_hooks`)

See: `_bmad-output/data-models-pos.md`.

## API Design (Local)

- UI routes: `/`, `/inventory`, `/shifts`, `/settings`, `/plugins`, `/catalog`, `/plugins/store`, etc.
- APIs: `/api/pos/*`, `/api/inventory/*`, `/api/shifts/*`, `/api/catalog/*`, `/api/plugins/*`

See: `_bmad-output/api-contracts-pos.md`.

## Marketplace Integration

Config variables:
- `UT_MARKETPLACE_ENDPOINT_URL`, `UT_MARKETPLACE_CLIENT_ID`, `UT_MARKETPLACE_CLIENT_SECRET`, `UT_MARKETPLACE_API_VERSION`

Behavior:
- Initializes a marketplace client and a catalog repository cache at `./data/plugins/cache`.
- Uses cached snapshot when offline; fetches fresh catalog when possible.
- Download and telemetry flows are present in the client; ensure API path alignment with marketplace server.

## Deployment / Operations

- Default port: `:8080` (configurable via `UT_LISTEN_ADDR`)
- Local DB file: `./data/unitill-pos.db` by default (configurable via `UT_DB_PATH`)
- Supports Docker via `docker-compose.edge.yml` (see README).

## Testing

- Unit/integration tests in Go (`go test ./...`)
- CI: `.github/workflows/ci.yml` runs build + tests with Go 1.25

## Open Questions / Risks

- Confirm canonical plugin install/update flow (CLI-assisted vs POS UI driven).
- Confirm security/auth model for production deployments (POS currently local-first).
- Standardize Go versions across repos (POS 1.25 vs plugin 1.21).

