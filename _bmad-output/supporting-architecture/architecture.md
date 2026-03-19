---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - "_bmad-output/prd.md"
  - "_bmad-output/ux-design-specification.md"
  - "_bmad-output/analysis/research/domain-universal-till-tax-compliance-gtm-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/research/market-universal-till-competitive-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/research/technical-universal-till-platform-architecture-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/index.md"
workflowType: 'architecture'
lastStep: 8
status: complete
completedAt: '2025-12-18T22:27:24Z'
project_name: 'docs'
user_name: 'Farshid'
date: '2025-12-18T22:27:24Z'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements (architecture-relevant):**
- Offline-first POS with pluginized capabilities: taxes/payments/integrations/hardware/layouts as plugins; marketplace + CLI + side-load; status + revocation handling; layout is pluggable and revertible.
- Kiosk/touch-first UI (full-screen) with shortcuts, hardware support (scanner/printer/drawer), explicit lock/exit; customer display; receipt/share (print/email/SMS/QR) with offline queue.
- Plugin lifecycle: trust/signature, install/update/rollback, side-load, status strip, telemetry; layout selector/revert; marketplace catalog.
- Sync/queue: offline-safe checkout; background sync with conflict review; non-blocking flows; minimal observability (health/status, events log).
- Multi-language/currency; data portability (export/import catalog/sales/plugins).

**Non-Functional Requirements:**
- Performance on low-end/Pi hardware; minimal animation; large touch targets.
- Offline reliability with durable queue/sync; non-blocking operations.
- Security/trust: signatures/checksums; revocation; least-privilege plugins; avoid storing secrets in plain files.
- Integrity/audit: immutable journal (sales/voids/refunds) with plugin version per transaction.
- Accessibility: WCAG AA-ish; high contrast; keyboard/focus for admin; 44px+ targets.

**Scale & Complexity:**
- Domain: fintech-adjacent (payments/tax via plugins).
- Platforms: Linux/Pi/macOS/Windows now; Android/iOS later via shared Go core.
- Complexity: High (plugin runtime + marketplace + offline sync + multi-platform).
- Cross-cutting: trust/signature pipeline, offline queue/sync, status/telemetry, rollback/revert, hardware fallback, multi-locale/currency, admin vs kiosk separation.

### Technical Constraints & Dependencies
- Go core; POS/backoffice plugin host; marketplace APIs/clients; layout-as-plugin support; kiosk full-screen with always-reachable status/lock; side-load path.

### Cross-Cutting Concerns Identified
- Offline queue/sync and conflict handling.
- Trust/signature/revocation for plugins/layouts; rollback/revert paths.
- Status/telemetry and minimal observability.
- Hardware detection/test/fallback.
- Multi-locale/multi-currency.
- Separation of kiosk (cashier) vs admin/operator surfaces.

## Starter Template Evaluation
- Decision: Use custom architecture (no external starter) because the codebase is Go-based across existing POS/marketplace/plugins and must support offline-first, plugin runtime, marketplace integration, layout-as-plugin, and multi-platform kiosk. A generic starter is not applicable.

## Core Architectural Decisions

### Data Architecture
- POS: SQLite local store (offline-first); migrations via goose/migrate. Include plugin metadata/version per transaction for audit.
- Marketplace/Backoffice: Postgres as primary; SQLite acceptable for local/dev. Migrations managed consistently across services.
- Sync model: queued offline sales/events with conflict resolution path; minimal caching beyond local stores.

### Auth & Security
- POS device/operator roles locally; marketplace auth via tokens; secrets not stored in plain files.
- Plugin trust: signing/verification required; revocation honored; rollback/revert paths.
- Transport: TLS to marketplace services; avoid sensitive payment data in core (leave to payment plugins).
- Sandbox: prefer process isolation per plugin where feasible; otherwise strict permission model and trust policy.

### API & Communication
- POS: HTTP/REST handlers (Go + HTMX server-rendered); standardized error shapes.
- Marketplace: gRPC + REST already present; align POS↔marketplace endpoints for catalog/download/telemetry/revocation.
- No GraphQL required; background sync/queue for offline flows.

### Frontend Architecture
- POS/Customer display/backoffice UIs are server-rendered XHTML/HTMX; minimal JS; kiosk full-screen with status strip and lock/exit.
- Marketplace UI: keep server-rendered approach (XHTML) per current stack.
- Layout as plugin supported; status/lock always reachable; bundles kept small for low-end hardware.

### Infrastructure & Deployment
- Local-first for POS; containerized marketplace/backoffice services; dev can run with SQLite; prod favors Postgres for marketplace/backoffice.
- CI/CD: to be defined (default suggestion: GitHub Actions with lint/test/build); environment config via env vars.
- Observability: minimal—logs + status/health; offline buffering of telemetry where applicable.

### Open Items / To Clarify
- Auth: any need for SSO/OIDC beyond local roles + marketplace tokens?
- CI/CD provider preference?
- Plugin sandboxing depth (process isolation vs. trust-only) given hardware constraints.

## Implementation Patterns & Consistency Rules

### Naming Patterns
- DB: snake_case tables/columns; plural tables (e.g., sales, plugins, plugin_layouts); FK columns as `<entity>_id`; indexes `idx_<table>_<col>`.
- API: REST plural (`/api/v1/plugins`, `/api/v1/catalog`, `/api/v1/downloads/{plugin}`); path params `{id}`; JSON fields snake_case; errors `{error: {code, message}}`; dates ISO8601 strings.
- Code/Files: Go packages lower_snake; files lower_snake.go; HTMX templates lower_snake.html; handlers `HandleX`, services `XService`, data structs `X` with JSON snake tags.

### Structure Patterns
- Tests co-located `*_test.go`; shared utils in `internal/<area>/`; templates under `templates/` or feature folders; configs via env + `.env.example`.
- Keep kiosk/admin separation in routing/views; status/lock always present in kiosk templates.

### Format Patterns
- Responses: `{data: ..., error: null}` or `{error: {code, message}}`; no mixed shapes.
- Booleans true/false; null as JSON null; timestamps ISO8601.

### Communication Patterns
- Events/telemetry: names `domain.action` (e.g., `plugin.installed`); payloads include version and timestamp; buffer offline; log lines structured JSON where feasible.
- Status surfaces: offline/sync/install as non-blocking chips/banners; plain language.

### Process Patterns
- Retries with backoff for sync/install; never block checkout on offline or install; rollback to last known-good plugin/layout on failure.
- Plain-language errors with retry/rollback; loading states non-blocking; lock/exit always reachable.

## Project Structure & Boundaries

### Repos and Roles
- `docs/` (this repo): central documentation, PRD, UX, architecture.
- `universal-till/`: POS (Go + HTMX), offline-first, plugin host, kiosk/customer display, local SQLite.
- `ut-market-place/`: Marketplace services (Go; gRPC + REST), catalog, downloads, telemetry, revocation; Postgres/SQLite.
- `ut-plugin-*`: Example plugins (e.g., FAQ) with manifests and entrypoints.

### POS (universal-till) Structure (proposed/align with current)
- `cmd/pos/main.go` (or `main.go`): bootstrap, config (env), HTTP mux, template setup.
- `internal/db/migrations/`: goose/migrate SQL (includes plugin tables, audit fields).
- `internal/pages/` / `internal/handlers/`: HTTP handlers (HTMX pages + API).
- `internal/plugins/`: plugin runtime (manifest validation, cache, permissions), layout/plugin registry.
- `templates/`: HTMX/XHTML views (kiosk, admin/operator, status strip, lock/exit).
- `assets/`: static assets; keep minimal for low-end hardware.
- Tests: co-located `*_test.go`; fixtures under `testdata/`.
- Config: `.env.example`; env var loader.

### Marketplace (ut-market-place) Structure (proposed/align with current)
- `cmd/marketplace/main.go`: service bootstrap; gRPC + REST gateway.
- `internal/api/`: handlers (catalog, downloads, telemetry, revocation).
- `internal/services/`: business logic (catalog, plugin signing/verification hooks).
- `proto/` + generated stubs; `internal/db/migrations/` for Postgres/SQLite.
- `templates/` (if server-rendered XHTML UI is present) for catalog/admin screens.
- Tests: co-located `*_test.go`.
- Config: `.env.example`; env var loader.

### Plugin Repos (ut-plugin-*)
- `manifest.yaml` (or similar): id, version, entrypoints, permissions, config schema.
- `cmd/<plugin>/main.go` or equivalent entrypoint.
- Assets/templates if UI plugin; docs/README per plugin.
- Tests co-located.

### Integration Boundaries
- POS ↔ Marketplace endpoints: catalog list, download URL, telemetry/status, revocation list; POS uses REST; marketplace serves REST/gRPC.
- Plugin lifecycle: POS marketplace client + side-load path; signing/verification enforced; layout plugins supported with revert.
- Sync/queue: POS background sync to backoffice/marketplace; conflict review surface.
- Auth boundaries: local POS roles vs marketplace token auth; secrets not persisted in plain files.
- Data boundaries: POS local SQLite vs marketplace Postgres/SQLite; plugin metadata/version logged per transaction for audit.

### Config / Env / Docs
- `.env.example` per repo; runtime via env vars.
- Migrations stored in repo (`internal/db/migrations/`).
- Docs: keep architecture/UX/PRD in `docs/`; per-repo README links back here.

## Architecture Validation Results

### Coherence Validation ✅
- Decisions align: Go + HTMX (server-rendered), SQLite/Postgres, REST/gRPC, plugin runtime, offline queue/sync, kiosk UX, and naming/format rules (snake_case, plural REST, structured errors) are consistent.
- Patterns support decisions: responses, events, retries/rollback, status surfaces, and file/naming rules match the stack.
- Structure matches architecture: repos/dirs cover POS, marketplace, plugins, migrations, templates, and config.

### Requirements Coverage Validation ✅
- Functional: offline checkout; plugin lifecycle (install/update/side-load, status/revocation, layout as plugin); marketplace endpoints; sync/queue with conflict review; status/telemetry; hardware setup/fallback; multi-lang/currency; data portability; customer display; lock/exit; receipt/share.
- Non-functional: low-end performance; offline reliability; trust/signatures/revocation; audit/journal with plugin version; accessibility (WCAG AA-ish: contrast, 44px targets); minimal animation; multi-platform noted (Linux/Pi/macOS/Windows; Android/iOS later).

### Implementation Readiness ✅
- Decisions, patterns, and structure documented; integration boundaries clear (POS↔marketplace endpoints; plugin lifecycle; data boundaries; auth boundaries).
- Consistency rules should keep agents aligned (naming, formats, process patterns).

### Gaps/Risks
- Auth: clarify if SSO/OIDC is needed beyond local roles + marketplace tokens.
- Plugin sandboxing depth: process isolation vs trust-only given hardware constraints.
- CI/CD provider preference: not specified.
- Marketplace frontend stack noted as XHTML; ensure docs reflect current tech.
- Observability minimal by design; confirm if more is needed for production.

## Architecture Completion Summary

### Workflow Completion
- Architecture Decision Workflow: COMPLETED ✅
- Total Steps Completed: 8
- Date Completed: 2025-12-18T22:27:24Z
- Document Location: _bmad-output/architecture.md

### Final Architecture Deliverables
- 📋 Complete Architecture Document with decisions, patterns, structure, and validation
- 🏗️ Implementation-ready foundation covering offline-first POS, plugin lifecycle, marketplace integration, layout-as-plugin, kiosk UX
- 📚 AI agent implementation guide: stack, consistency rules, project structure, integration patterns

### Implementation Handoff Guidance
- First priorities: honor architecture.md for all work; keep POS on SQLite offline; marketplace on Postgres (SQLite ok for dev); enforce plugin signing/verification/revocation; maintain naming/format/process patterns; kiosk/admin separation; status/lock reachable.
- Development sequence: set env/config per repo; run migrations; align POS↔marketplace endpoints; implement plugin lifecycle + layout-as-plugin with revert; preserve offline queue/sync with conflict review; keep bundles light for low-end hardware.

### Quality Assurance Checklist
- Coherence ✅ decisions/patterns/structure aligned
- Coverage ✅ FR/NFR support documented
- Consistency ✅ naming/format/process rules defined
- Boundaries ✅ POS/marketplace/plugins/data/auth/UX boundaries defined
