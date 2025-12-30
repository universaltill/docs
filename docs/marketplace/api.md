# Marketplace API

Source: ut-market-place/docs/api-reference.md (full details to merge).

Includes:
- REST/gRPC endpoints for plugin discovery, auth, install status, telemetry.
- OpenAPI at `/openapi.yaml`; Swagger `/docs`; ReDoc `/redoc`.

Pending actions:
- Import endpoint list and auth model (client credentials).
- Clarify POS/backoffice call flows (install, update, report status).
- Note well-known service discovery endpoint `/.well-known/marketplace-endpoints.json`.
- Add status/telemetry contract for install/reporting.
- Add examples for plugin manifest fetch/download.

Proposed endpoints to align with CLI flow:
- `POST /v1/plugins/{pluginId}/installs` (merchant/device scoped) → registers install intent.
- `GET /v1/plugins/{pluginId}/status?merchant=...&device=...` → returns install/health state.
- `GET /v1/plugins/{pluginId}/manifest` → manifest fetch (with version negotiation).
- `GET /v1/plugins/{pluginId}/bundle?version=...` → bundle download (authz required).
- `POST /v1/plugins/{pluginId}/telemetry` → POS/host status reporting.
