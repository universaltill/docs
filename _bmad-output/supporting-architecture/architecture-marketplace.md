# Architecture — Marketplace (ut-market-place)

Part: `marketplace`  
Repo: `~/repos/unitill/ut-market-place`

## Executive Summary

Marketplace is a Go service that provides:
- a plugin catalog and metadata,
- artifact download flows (including resumability),
- an operator/merchant/vendor UI (templates),
- gRPC services bridged to REST via gRPC-Gateway,
- operational features: observability, security headers, multi-locale support, and deployment assets (helm/kustomize).

It is designed to support offline-first environments via catalog snapshots and export/import bundling (sync CLI).

## Technology Stack

- Language/runtime: Go (go.mod: `go 1.25.3`)
- API: gRPC + gRPC-Gateway REST surface (mounted under `/api/`)
- HTTP routing: Go `http.ServeMux` + `chi` where used in internal handlers
- DB: Ent ORM (`entgo.io/ent`) with drivers for Postgres and SQLite
- Auth: JWT-based (configurable; dev can generate a secret)
- Messaging: NATS
- Cache: Redis
- Blob storage abstraction: `gocloud.dev` (supports S3-compatible storage)
- Observability: OpenTelemetry + Prometheus
- i18n: locale bundles under `locales/` and runtime i18n components

## Architecture Pattern

- **Service-oriented backend**:
  - API contracts under `pkg/contracts` (protobuf + generated gateway)
  - Business logic under `internal/*` services (catalog, downloads, auth)
  - Data layer via Ent schemas (`internal/repositories/ent/schema`)
- **Operational-first**:
  - health + discovery endpoints
  - security headers and rate limits
  - CI verification script

## Entry Points

- Server: `cmd/marketplace/main.go`
- Offline bundle CLI: `cmd/marketplace-sync/main.go`

## HTTP Surface (High Level)

- `/ui/` UI templates server
- `/api/` gRPC-Gateway REST surface
- `/openapi.yaml`, `/docs`, `/redoc` API documentation endpoints
- `/healthz` health
- `/.well-known/marketplace-endpoints.json` service discovery
- `/api/v1/downloads/*` download session endpoints (direct HTTP handlers)
- `/v1/catalog/snapshots/{locale}/{arch}` snapshot endpoints for disconnected POS

See: `_bmad-output/api-contracts-marketplace.md`.

## Data Architecture

- Core entities include: PluginListing, PluginRelease, VendorOrganization, MerchantOrganization, StoreEntitlement, AuditEvent, RegionConfig, ReviewAssignment.
- Migration strategy is Ent schema create (see `internal/data/database.go` and related Ent client usage).

See: `_bmad-output/data-models-marketplace.md`.

## Deployment

- Deployment manifests exist under `deploy/` (helm + kustomize).
- TLS local-dev is supported (self-signed cert prompt).

## Testing / Verification

- CI uses `scripts/ci/verify.sh` which runs gofmt, vet, test, plus optional gosec/trivy and contract guard rails.

## Open Questions / Risks

- Telemetry handler exists but route registration is marked TODO; confirm canonical telemetry endpoint for POS status reporting.
- Align POS marketplace client endpoints with implemented marketplace REST routes (download ack, telemetry status, revocations).

