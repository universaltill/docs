# Integration Architecture (POS ↔ Marketplace ↔ Plugins)

This document describes how the major parts interact today based on code and docs found in the multi-repo workspace.

## Parts

- **POS Host** (`universal-till`): offline-first POS + local DB + plugin host + UI.
- **Marketplace Service** (`ut-market-place`): catalog, auth, downloads, UI; supports snapshots for disconnected stores.
- **Plugins** (`ut-plugin-faq` and others): packaged artifacts installed into POS; add pages/actions/integrations.
- **Docs Hub** (`docs`): centralized documentation and BMAD artifacts.

## Key Integration Flows

### 1) Catalog Discovery & Offline Snapshot

Marketplace provides:
- `GET /v1/catalog/plugins` (catalog browsing; REST gateway/gRPC-gateway generated route)
- Snapshot endpoints for offline POS consumption:
  - `GET /v1/catalog/snapshots/{locale}/{arch}`
  - `GET /v1/catalog/snapshots/{locale}/{arch}/{version}`
  - `GET /v1/catalog/snapshots/{locale}/{arch}/versions`
  (see `ut-market-place/internal/api/v1/snapshot_handler.go`)

POS provides a local cache:
- Stores a JSON snapshot in `./data/plugins/cache/catalog-snapshot.json` and marks it stale after 15 minutes (see `universal-till/internal/plugins/marketplace/catalog_repository.go`).

### 2) POS ↔ Marketplace API Client (Auth + REST)

POS marketplace client (`universal-till/internal/plugins/marketplace/client.go`):
- Uses OAuth bearer token from a token provider.
- Calls marketplace REST endpoints directly at `UT_MARKETPLACE_ENDPOINT_URL`.
- Uses `x-marketplace-api-version` header.

Observed endpoints used by POS client:
- Catalog: `GET /v1/catalog/plugins`
- Downloads: `GET /v1/downloads/{plugin_id}/url?...`
- Revocations: `GET /v1/revocations?since_version=...`
- Telemetry: `POST /v1/telemetry/status` (gated by `UT_MARKETPLACE_TELEMETRY_OPT_IN`)
- Download ack: `POST /v1/download/ack` (note: verify endpoint path matches marketplace implementation)

### 3) Plugin Install & Lifecycle (Current State)

POS side:
- DB tables exist for plugin catalog cache + installed plugin state + permissions/hooks/settings (see POS migration `internal/db/migrations/001_init.sql`).
- POS exposes multiple plugin endpoints under `/api/plugins/*` including marketplace install and install-from-marketplace handlers (see `internal/pages/plugin_api.go`).
- POS includes a “plugin store” UI route (`/plugins/store`) and refresh handler (`/plugins/store/refresh`) intended for HTMX updates.

Marketplace side:
- Marketplace provides catalog and download services; it also includes a sync CLI (`cmd/marketplace-sync/main.go`) for offline bundle workflows.
- Telemetry handler skeleton exists under `internal/api/telemetrysvc`, but route registration is marked TODO (meaning end-to-end status reporting may still be incomplete in the service).

Plugin side:
- FAQ plugin currently has a placeholder main until wired to POS plugin SDK; it registers a navigation entry targeting `/plugin/faq` (see `ut-plugin-faq/src/main.go`).

### 4) Telemetry / Health Loop (Intended)

Intended flow:
1. POS installs plugin and updates local plugin state.
2. POS reports plugin status back to marketplace (`POST /v1/telemetry/status`) if opted-in.
3. Marketplace aggregates telemetry for merchant/device/plugin dashboards.

Observed gap:
- Marketplace telemetry handler file exists but notes “TODO: Register routes with main HTTP router” and “TODO: Call telemetry service” (see `ut-market-place/internal/api/telemetrysvc/handler.go`), suggesting this integration may not be fully wired yet.

## Integration Points Summary

- **Config boundary:** POS reads marketplace endpoint and credentials from env; marketplace reads auth/db/nats/redis from env.
- **Contract boundary:** Marketplace contracts live under `ut-market-place/pkg/contracts/*` and are used for gRPC and REST-gateway generation.
- **Artifact boundary:** Plugin bundles are downloaded and validated (manifest/schema/signature/SHA256) before install; POS keeps cached artifacts and metadata for offline use.

## Known Risks / Questions (for roadmap)

- Confirm marketplace implements all REST endpoints the POS client calls (`/v1/download/ack`, `/v1/telemetry/status`, `/v1/revocations`), or align POS client to marketplace API paths.
- Decide canonical “install intent” and “install status” endpoints for CLI-assisted plugin install MVP.
- Wire telemetry routes in marketplace (or adjust POS to report via a supported endpoint such as `/api/v1/telemetry/report` if that becomes canonical).
- Define how plugins are executed/served in POS (routing, sandboxing, permissions, lifecycle hooks).

