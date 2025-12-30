# Component Inventory — Marketplace (ut-market-place)

This inventory focuses on major server components and UI surface areas.

## HTTP API / Router (`internal/httpapi`)

- Root router: `internal/httpapi/router/router.go`
- HTTP handlers: health, discovery, downloads, API docs

## gRPC Services (`internal/api/*`)

- Auth service (`internal/api/authsvc`)
- Catalog service (`internal/api/catalogsvc`)
- Download service (`internal/api/downloadsvc`)
- Telemetry handler exists (`internal/api/telemetrysvc`) but route registration is TODO

## Data Layer (`internal/data`, `internal/repositories/ent`)

- Ent schemas: `internal/repositories/ent/schema/*`
- Entities: PluginListing, PluginRelease, VendorOrganization, MerchantOrganization, StoreEntitlement, AuditEvent, etc.

## Domain Services (`internal/catalog`, `internal/downloads`, etc.)

- Catalog service and snapshot model
- Download session/token manager

## UI (`internal/api` server mounted at `/ui/`)

- UI server is created in `internal/api` and mounted at `/ui/` via router.
- Documentation references multiple UI paths (merchant/vendor/compliance) in README.

## Ops/Infra

- Deployment: `deploy/helm`, `deploy/kustomize`
- Observability: `internal/observability`
- Events: `internal/events`, `internal/telemetry`
