# API Contracts — POS (universal-till)

Part: `pos`  
Repo: `~/repos/unitill/universal-till`  
Entry point: `main.go`

This POS app uses Go `net/http` with `http.ServeMux` (see `internal/pages/init.go`) and serves both HTML pages and JSON/HTML-fragment APIs (often HTMX-friendly).

## HTTP Server Basics

- **Base listen address:** `UT_LISTEN_ADDR` (default `:8080`) (see `internal/config/config.go`)
- **Health:** `/healthz` (see `internal/pages/health_api.go`)

## UI Routes (HTML)

From `internal/pages/init.go` and route registration helpers:

- `/` (home)
- `/designer`
- `/inventory`
- `/shifts`
- `/settings`
- `/plugins`
- `/plugins/store` (marketplace store UI)
- `/catalog`
- `/ui/basket` (basket fragment)
- `/ext/*` (external proxy)

## POS Core APIs

From `internal/pages/pos_api.go`:

- `/api/pos/scan`
- `/api/pos/remove`
- `/api/pos/line`
- `/api/pos/discount`
- `/api/pos/reset`
- `/api/pos/tender`
- `/api/pos/sale/status`
- `/ui/clear-toast` (UI helper)

## Inventory APIs

From `internal/pages/inventory_api.go`:

- `POST /api/inventory/receipt`
- `POST /api/inventory/override`
- `POST /api/inventory/return`
- `GET /api/inventory/low-stock`

## Shifts APIs

From `internal/pages/shifts_api.go`:

- `POST /api/shifts/open`
- `POST /api/shifts/close`
- `POST /api/shifts/adjustment`

## Catalog APIs

From `internal/pages/catalog/handlers.go`:

- `/catalog` (page)
- `/api/catalog/item`
- `/api/catalog/item/update`
- `/api/catalog/item/deactivate`
- `/api/catalog/variant`
- `/api/catalog/variant/deactivate`
- `/api/catalog/barcode`

## Plugin APIs (Local + Marketplace)

From `internal/pages/plugin_api.go` and marketplace store page:

- `/api/plugins/upload` (local upload)
- `/api/plugins/marketplace` (marketplace catalog)
- `/api/plugins/marketplace/install` (install via marketplace)
- `/api/plugins/permissions/grant`
- `/api/plugins/permissions/revoke`
- `/api/plugins/trust`
- `POST /api/plugins/install-from-marketplace`
- `POST /api/plugins/{id}/enable`
- `POST /api/plugins/{id}/disable`
- `POST /api/plugins/{id}/uninstall`
- `POST /api/plugins/{id}/update`
- `POST /api/plugins/{id}/rollback`
- `GET /api/plugins/check-updates`
- `POST /api/plugins/import-from-file`
- `/plugins/store/refresh` (HTMX refresh)

## Notes / Gaps

- Auth model is not documented here (POS appears single-tenant/local for now); security model should be documented before production.
- Some handlers use new Go 1.22+ “METHOD /path” ServeMux patterns (e.g., `POST /api/...`)—ensure deployment Go version compatibility.

