# Architecture

Sources merged so far:
- docs-current/architecture.md (system blueprint)
- universal-till/docs/arch/mapping.md (additional mapping guidance, to review/merge)

## High-Level Components
- POS App (Go edge server + HTML/HTMX UI; offline-first, plugin runtime, local DB)
- Back Office (management UI/services; plugin-aware)
- Marketplace (app store for plugins; API/UI)
- Optional Cloud Core (sync, multi-site, analytics, backups, billing)
- Plugin Ecosystem (POS/backoffice/hardware/integration plugins)
- Future Mobile App (map of tills; ordering/delivery flows via plugins)

## Deployment Modes
- Standalone: POS + Back Office on one device (SQLite/Postgres, local plugin repo)
- LAN: Back Office as local server; multiple POS on network
- Hybrid/Cloud: POS ↔ Local Back Office ↔ Cloud services; marketplace reachable

## Plugin Architecture (POS/Back Office)
- POS plugin runtime with entrypoints for UI/services/hardware drivers.
- Plugin manifests define id, version, entrypoints, permissions, config schema, billing model.
- Plugin host responsibilities: lifecycle (install/update/remove), permission enforcement, manifest validation.
- Everything-is-a-plugin: taxes, payments, hardware drivers, integrations (ERP/ecommerce/accounting), discount, delivery/ordering flows.
- Marketplace provides discovery, trust tiers, validation; POS/backoffice consume manifests/bundles and report status.
- Legacy manifest shape (from docs-current): see `docs/plugins/manifest.md` for the current schema; legacy examples included entrypoints (pos-service/backoffice-ui), permissions, config_schema, billing, and gRPC hooks.

## Marketplace Role
- Discovery, developer upload, validation, trust tiers, multi-version support.
- Needs CLI-assisted onboarding/install flow (pending).
- Provides APIs/REST/gRPC for POS/backoffice to fetch manifests/bundles and report status.

## Sync Model (POS ↔ Back Office ↔ Cloud)
- Local-first: POS queues sales/events; back office provides products/config/plugins; cloud is optional.
- POS → Back Office: e.g., `POST /api/v1/sales/batch`.
- Back Office → POS: e.g., `GET /api/v1/config`, `GET /api/v1/products`, `GET /api/v1/plugins`.
- Cloud-enabled: multi-site sync, central reporting, backups, remote access; same API shape where possible.

## Configuration Examples (legacy defaults)
- POS config (local-first): device_id, tenant_id, mode, backoffice_url, cloud_url, plugins_dir, database_path.
- Back office config: mode, db_url, cloud_url, app_store_url.
- See `docs/pos/setup.md` for current env/config details; these legacy keys were captured from docs-current for compatibility review.

## Platform & Deployment Notes
- Platform targets: Raspberry Pi/low-cost tills, Linux, macOS, Windows; future Android/iOS via shared Go core.
- Deployment: standalone (single box), LAN (back office server + multiple POS), hybrid/cloud (POS ↔ local back office ↔ cloud services/marketplace).

## Roadmap (legacy snapshot for context)
- Phase 1: POS + local back office, one POS plugin, plugin runtime, offline-first.
- Phase 2: LAN mode and device registration.
- Phase 3: App store (developer portal, upload/validation, local plugin mirror).
- Phase 4: Cloud (multi-site sync, analytics, billing/subscriptions).
- Use PRD and BMAD stories for the authoritative plan; this snapshot is retained from docs-current for historical intent.

## Open Items to Refine
- Sync model details (POS ↔ Back Office ↔ Cloud) from docs-current/architecture.md.
- Align plugin manifest contracts across POS and marketplace.
- Document security/i18n/compliance constraints (see marketplace docs).
- Add sequence diagrams for plugin install flow once CLI is defined.
- Detail platform support matrix: Raspberry Pi/low-cost tills today; Android/iOS via future mobile app.
- Clarify free core vs paid cloud services (sync, analytics, multi-site, backups, billing).
