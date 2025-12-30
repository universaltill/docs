---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - "_bmad-output/prd.md"
  - "_bmad-output/analysis/product-brief-docs-2025-12-17T10-42-42Z.md"
  - "_bmad-output/ux-design-specification.md"
  - "_bmad-output/analysis/research/domain-universal-till-tax-compliance-gtm-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/research/market-universal-till-competitive-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/research/technical-universal-till-platform-architecture-research-2025-12-17T10-42-42Z.md"
  - "project-context.md"
  - "_bmad-output/architecture.md"
  - "_bmad-output/integration-architecture.md"
  - "_bmad-output/architecture-patterns.md"
  - "_bmad-output/architecture-pos.md"
  - "_bmad-output/architecture-marketplace.md"
  - "_bmad-output/architecture-plugin-faq.md"
  - "docs/architecture.md"
  - "docs/overview.md"
  - "docs/README.md"
  - "docs/pos/ui.md"
  - "docs/pos/data-model.md"
  - "docs/pos/plugin-host.md"
  - "docs/pos/setup.md"
  - "docs/marketplace/overview.md"
  - "docs/marketplace/api.md"
  - "docs/marketplace/cli.md"
  - "docs/marketplace/compliance.md"
  - "docs/marketplace/i18n.md"
  - "docs/marketplace/ops.md"
  - "docs/marketplace/plugin-developer.md"
  - "docs/marketplace/tls-local-dev.md"
  - "docs/plugins/manifest.md"
  - "docs/plugins/faq.md"
  - "docs/plugins/lifecycle.md"
  - "docs/specs/README.md"
workflowType: 'architecture'
project_name: 'docs'
user_name: 'Farshid'
date: '2025-12-30T12:41:15Z'
lastStep: 8
status: 'complete'
completedAt: '2025-12-30T14:55:28Z'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
- Offline-first POS: complete sales offline (scan/add, totals/tax, payments, persist, receipt), with queued sync on reconnect.
- Plugin lifecycle: browse/install/status/update/rollback/side-load, cached for offline use, revocation handling, and clear trust cues.
- Marketplace flows: catalog discovery, download bundles, telemetry/status reporting, CLI-assisted install/publish path.
- Hardware support: scanners, printers, cash drawers with graceful fallback and offline operation.
- Admin/operator controls: endpoint config, trust policies, status/health surfaces, and reconcile after offline periods.
- Multi-language and multi-currency baseline; data portability via export/import.
- Plugin surfaces: UI pages/panels and layout plugins with revert path.

**Non-Functional Requirements:**
- Reliability: offline checkout must never be blocked by network; durable queue/sync with conflict surfacing.
- Performance: kiosk/touch UX must be responsive on low-end hardware; minimal JS/animation.
- Security: plugin signing/verification, revocation list, least-privilege permissions, secrets not in plain files.
- Auditability: immutable journal; plugin version recorded per transaction.
- i18n: no hardcoded UI strings; locale files required; enforce tests/checks.
- Compliance: tax/receipt/legal hooks via plugins; regional rules and data retention.

**Scale & Complexity:**
- Primary domain: offline-first POS + marketplace + plugin ecosystem.
- Complexity level: high.
- Estimated architectural components: POS host + plugin runtime + marketplace service + CLI/sync tooling + plugin repos.

### Technical Constraints & Dependencies

- Go core with server-rendered HTML/HTMX UI.
- Local SQLite for POS; marketplace uses Postgres (SQLite ok for dev).
- Plugin contracts must be versioned; plugins never access internal DB directly.
- Offline-first is non-negotiable; cloud sync optional and non-blocking.
- No plain-text secrets; auditable transitions; repository-owned SQL in repos.

### Cross-Cutting Concerns Identified

- Offline queue/sync integrity and conflict handling.
- Plugin trust/sandboxing and signature verification.
- Marketplace ↔ POS API alignment (catalog, downloads, telemetry, revocations).
- Status/telemetry surfaces across POS and marketplace.
- Hardware IO stability and fallback behavior.
- i18n enforcement across UI and handlers.

## Starter Template Evaluation

### Primary Technology Domain

Go server-rendered web/edge application (HTMX + Go net/http), based on existing POS/marketplace repos and offline-first constraints.

### Starter Options Considered

- mikestefanello/pagoda (full-stack Go starter kit)
- leomorpho/goship (Go + HTMX opinionated boilerplate)
- claider/htmx_go_tailwind_starter (Go + HTMX + Tailwind)
- carsonkrueger/go-htmx-starter (Go + HTMX starter)
- maragudk/gomponents-starter-kit (gomponents + HTMX + Tailwind)
- lordaris/gotth-boilerplate (Go + templ + Tailwind + HTMX)
- ThePrimeagen/htmx-class-template (Go or Rust HTMX template)

### Selected Starter: None (use existing repos)

**Rationale for Selection:**
This is a brownfield system with established repos, architecture decisions, and conventions. Adopting a new starter would conflict with existing POS/marketplace structures and offline-first constraints. We will continue using the current repo structures and documented architecture.

**Initialization Command:**
Not applicable — continue with existing repositories.

**Architectural Decisions Provided by Starter:**

**Language & Runtime:**
Go (existing repos)

**Styling Solution:**
Server-rendered HTML/HTMX with minimal JS (existing repos)

**Build Tooling:**
Go toolchain with repo-specific build scripts (existing repos)

**Testing Framework:**
Go test with existing CI conventions

**Code Organization:**
Existing POS/marketplace/plugin repo structures and documented conventions

**Development Experience:**
Existing local dev scripts and environment config per repo

**Note:** If a new standalone service or demo is needed, revisit starter selection then.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Language/runtime: Go (current stable go1.25.5).
- POS local storage: SQLite (current 3.51.1).
- Marketplace storage: PostgreSQL (current minor 18.1; target 18.x for new deployments).
- Offline-first queue/sync with conflict review; checkout never blocked by network.
- Plugin contracts: versioned APIs, signed bundles, revocation handling, and least-privilege permissions.
- UI architecture: server-rendered HTML with HTMX (current v2.0.7) and minimal JS.
- i18n enforcement: locale files only; no hardcoded UI strings.

**Important Decisions (Shape Architecture):**
- Auth boundaries: POS local roles; marketplace uses token-based auth for POS/CLI.
- Telemetry/status lifecycle: requested → downloading → installing → active → failed; buffered offline.
- Auditability: immutable journal for sales/void/refund with plugin version per transaction.
- Repository-owned SQL with migrations under `internal/db/migrations/`.
- API patterns: REST for POS; marketplace gRPC + REST gateway; versioned contracts as source of truth.
- Plugin sandboxing: prefer process isolation where feasible; otherwise strict permission model.

**Deferred Decisions (Post-MVP):**
- SSO/OIDC for operators and multi-tenant org models beyond local roles.
- Advanced observability (tracing/metrics dashboards) beyond minimal health/logs.
- Cloud-scale sync topology and multi-region data residency strategies.

### Data Architecture

- POS: SQLite 3.51.1 for offline-first local storage; migrations in repo.
- Marketplace: PostgreSQL 18.x (current minor 18.1), SQLite permitted for dev/test.
- Data integrity: integer minor units for money; immutable sales/void/refund journal.
- Sync: append-only queue with conflict review UI; non-blocking background sync.

### Authentication & Security

- POS: local roles; no online dependency for checkout.
- Marketplace/CLI: token-based auth; secrets never stored in plain files.
- Plugin trust: signed bundles required; verification + revocation enforced.
- Permissions: declared capabilities; host enforces least privilege.
- Sandbox: process isolation where feasible; otherwise permission-only with strict audit.

### API & Communication Patterns

- POS: REST endpoints for UI/API handlers.
- Marketplace: gRPC services with REST gateway for POS/CLI consumption.
- Contracts: marketplace contracts as the versioned source of truth.
- Status/telemetry: standardized lifecycle states; buffered offline; opt-in where required.

### Frontend Architecture

- Server-rendered HTML with HTMX v2.0.7; minimal JS for low-end hardware.
- Kiosk/admin separation; status/lock/exit always reachable.
- i18n via locale bundles only; enforced in handlers/templates.

### Infrastructure & Deployment

- POS: local-first runtime; no required cloud dependency.
- Marketplace: containerized service; Postgres in production.
- CI/CD: GitHub Actions (build/test/lint); repo-specific scripts.
- Observability: minimal logs + health endpoints + buffered telemetry.

### Decision Impact Analysis

**Implementation Sequence:**
1) Enforce repo-owned migrations and DB version targets.
2) Align POS ↔ marketplace contracts and status/telemetry lifecycle.
3) Implement plugin signing/verification + revocation checks.
4) Maintain offline-first queue/sync with conflict review.
5) Keep HTMX server-rendered UI with i18n enforcement and kiosk/admin separation.

**Cross-Component Dependencies:**
- Plugin contracts and trust model affect POS, marketplace, CLI, and plugin repos.
- Telemetry/status lifecycle affects marketplace UI/API and POS install flows.
- Offline queue/sync affects POS data model, UI status surfaces, and marketplace telemetry.

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:**
Naming, API shapes, file placement, DB migrations, plugin lifecycle state names, and error handling patterns.

### Naming Patterns

**Database Naming Conventions:**
- Tables: plural snake_case (e.g., `plugins`, `sales`, `plugin_entries`)
- Columns: snake_case (e.g., `plugin_id`, `created_at`)
- Foreign keys: `<entity>_id` (e.g., `sale_id`)
- Indexes: `idx_<table>_<column>` (e.g., `idx_sales_created_at`)

**API Naming Conventions:**
- REST endpoints: plural, versioned (e.g., `/api/v1/plugins`, `/api/v1/catalog`)
- Route params: `{id}` in docs, `:id` in router if needed (consistent across codebase)
- Query params: snake_case (e.g., `since_version`)
- Headers: `x-` prefixed for custom (e.g., `x-marketplace-api-version`)

**Code Naming Conventions:**
- Go packages: lower_snake (e.g., `plugin_runtime`)
- Go files: lower_snake.go (e.g., `plugin_manager.go`)
- Handlers: `HandleX`
- Services: `XService`

### Structure Patterns

**Project Organization:**
- Tests: co-located `*_test.go`
- DB migrations: `internal/db/migrations/`
- Reusable helpers: `internal/<area>/` (no global utils sprawl)
- Templates: `templates/` or feature-local templates (consistent within repo)

**File Structure Patterns:**
- Config via env + `.env.example`
- Static assets minimal and under `web/public` (POS)

### Format Patterns

**API Response Formats:**
- Success: `{data: ..., error: null}`
- Error: `{error: {code, message}}`
- Dates: ISO8601 strings
- Booleans: true/false, null as JSON null

**Data Exchange Formats:**
- JSON fields snake_case
- Money in integer minor units
- Explicit version fields in plugin/contract payloads

### Communication Patterns

**Event System Patterns:**
- Event names: `domain.action` (e.g., `plugin.installed`)
- Payloads include `version`, `timestamp`, and `source`
- Status lifecycle: `requested → downloading → installing → active → failed`

**State Management Patterns:**
- Background sync and install state must be non-blocking
- Kiosk UI shows status chips/banners; never blocks checkout

### Process Patterns

**Error Handling Patterns:**
- Plain-language user errors; retry/rollback where relevant
- Log structured JSON server-side where feasible
- Never fail checkout for offline/network errors

**Loading State Patterns:**
- Status chips/banners for offline/sync/install
- Avoid modal blockers in kiosk flow

### Enforcement Guidelines

**All AI Agents MUST:**
- Follow naming/format conventions above
- Use repo-owned SQL with migrations
- Keep i18n via locale files; no hardcoded UI strings
- Maintain offline-first guarantees in any flow changes

**Pattern Enforcement:**
- PR review checklist: naming, response shape, i18n, migrations, status lifecycle
- Note deviations in story Change Log or architecture addendum

### Pattern Examples

**Good Examples:**
- `GET /api/v1/plugins` → `{data: {...}, error: null}`
- Migration: `internal/db/migrations/012_add_plugin_revocation.sql`

**Anti-Patterns:**
- CamelCase JSON fields
- Inline SQL in handlers
- Blocking checkout on network failures

## Project Structure & Boundaries

### Complete Project Directory Structure
```
~/repos/unitill/
├── docs/                              # Central docs (this repo)
│   ├── _bmad-output/                  # BMAD outputs
│   ├── _bmad/                         # BMAD workflows and agents
│   ├── docs/                          # POS/marketplace/plugin docs
│   ├── project-context.md             # Non-negotiable rules (bible)
│   └── _bmad-output/planning-artifacts/architecture.md
├── universal-till/                    # POS host (offline-first)
│   ├── cmd/pos/                        # entrypoint
│   ├── internal/
│   │   ├── db/migrations/             # SQL migrations (repo-owned)
│   │   ├── pages/                     # HTTP handlers + HTMX views
│   │   ├── pos/                       # core domain logic
│   │   ├── plugins/                   # plugin runtime + permissions
│   │   ├── plugins/marketplace/       # marketplace client + cache
│   │   └── settings/                  # persisted config
│   ├── templates/                     # server-rendered templates
│   ├── web/public/                    # static assets
│   └── web/locales/                   # i18n bundles
├── ut-market-place/                   # Marketplace service
│   ├── cmd/marketplace/               # server entrypoint
│   ├── cmd/marketplace-sync/          # offline bundle/CLI tooling
│   ├── internal/
│   │   ├── api/                       # REST handlers
│   │   ├── services/                  # business logic
│   │   └── repositories/ent/          # data layer (Ent)
│   ├── pkg/contracts/                 # API contracts (source of truth)
│   ├── deploy/                        # helm/kustomize
│   └── locales/                       # marketplace i18n
├── ut-plugin-faq/                     # Example plugin
│   ├── src/                           # plugin entrypoint + UI
│   ├── assets/                        # localized content
│   └── manifest/                      # plugin manifest
└── ut-plugin-*/                       # additional plugins
```

### Architectural Boundaries

**API Boundaries:**
- POS ↔ Marketplace: REST (catalog, downloads, revocations, telemetry) via marketplace contracts.
- Marketplace internal: gRPC services + REST gateway for external clients.
- POS local APIs: `/api/pos/*`, `/api/plugins/*`, `/api/catalog/*`.

**Component Boundaries:**
- POS domain logic isolated in `internal/pos`; adapters in `internal/pages`, `internal/plugins`, `internal/settings`.
- Plugin runtime isolated in `internal/plugins` with explicit permission enforcement.
- Marketplace core logic in `internal/services`, data layer in Ent schemas.

**Service Boundaries:**
- POS is local-first single-process edge service.
- Marketplace is a network service; CLI/sync tooling is separate (`cmd/marketplace-sync`).

**Data Boundaries:**
- POS: local SQLite only; no external DB dependency.
- Marketplace: Postgres (SQLite ok for dev); no direct POS DB access by plugins.
- Plugins never read internal DB structures; only via host APIs.

### Requirements to Structure Mapping

**Feature/Epic Mapping (by domain):**
- Offline checkout, inventory, receipts → `universal-till/internal/pos`, `universal-till/internal/pages`
- Plugin lifecycle + permissions → `universal-till/internal/plugins`, `ut-market-place/internal/services`
- Marketplace catalog/download/revocation → `ut-market-place/internal/api`, `ut-market-place/pkg/contracts`
- Telemetry/status reporting → `ut-market-place/internal/api`, `universal-till/internal/plugins/marketplace`
- UX kiosk/admin separation → `universal-till/templates`, `universal-till/web/public`

**Cross-Cutting Concerns:**
- i18n → `universal-till/web/locales`, `ut-market-place/locales`
- Migrations → `universal-till/internal/db/migrations`, `ut-market-place/internal/repositories/ent`
- Trust/signing → `ut-market-place/internal/services`, `universal-till/internal/plugins`

### Integration Points

**Internal Communication:**
- POS handlers call domain services; domain uses DB repositories.
- Plugin runtime exposes hooks/entrypoints to POS UI and services.

**External Integrations:**
- Marketplace APIs for catalog/download/revocation/telemetry.
- CLI/sync tooling for offline bundles.

**Data Flow:**
- POS writes local sales/events → queues for sync → telemetry/reporting to marketplace.
- Marketplace serves snapshots/bundles → POS caches locally for offline use.

### File Organization Patterns

**Configuration Files:**
- `.env.example` in each repo; runtime via env vars.

**Source Organization:**
- Go packages under `internal/`; entrypoints under `cmd/`.

**Test Organization:**
- Co-located `*_test.go` with domain/service code.

**Asset Organization:**
- POS assets under `web/public`; locales under `web/locales`.

### Development Workflow Integration

**Development Server Structure:**
- POS runs locally with SQLite and env config.
- Marketplace runs locally with Postgres or SQLite; CLI/sync tooling optional.

**Build Process Structure:**
- Go build/test per repo; CI via GitHub Actions.

**Deployment Structure:**
- POS deployed on devices (edge).
- Marketplace deployed as service (container/K8s).
```

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
All key decisions align: Go + server-rendered HTMX + SQLite for POS + Postgres for marketplace + offline-first queue/sync. Versioned plugin contracts and i18n enforcement are compatible with the chosen stack and repo layout.

**Pattern Consistency:**
Naming, response formats, migrations, and status lifecycles align across POS/marketplace/plugin components. No conflicting conventions identified.

**Structure Alignment:**
The multi-repo structure supports offline-first POS, marketplace services, and plugin repos with clear boundaries and integration points.

### Requirements Coverage Validation ✅

**Functional Requirements Coverage:**
Offline checkout, plugin lifecycle, marketplace catalog/download/telemetry, hardware support, admin controls, and i18n are all supported in the architecture.

**Non-Functional Requirements Coverage:**
Performance on low-end hardware, security/trust (signing/revocation), auditability, and offline resilience are addressed.

### Implementation Readiness Validation ✅

**Decision Completeness:**
Critical decisions and versions documented; patterns and boundaries are clear.

**Structure Completeness:**
All major repos, directories, and integration points defined.

**Pattern Completeness:**
Naming, response shapes, error handling, and offline behavior are documented.

### Gap Analysis Results

**Important Gaps:**
- Clarify POS ↔ marketplace endpoint alignment for download/ack and telemetry status routes.
- Specify plugin sandboxing depth (process isolation vs permission-only) per platform constraints.
- Document exact install intent/status API contracts for CLI-assisted flow.

**Nice-to-Have:**
- Add explicit sequence diagrams for plugin install/update/rollback.
- Expand observability beyond minimal health/logs if required for production ops.

### Validation Issues Addressed

- Noted the remaining integration contract gaps and sandboxing depth as follow-ups; non-blocking for current implementation with explicit tracking.

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**✅ Architectural Decisions**
- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed

**✅ Implementation Patterns**
- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**✅ Project Structure**
- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High

**Key Strengths:**
- Offline-first guarantees are explicitly enforced.
- Plugin trust + lifecycle requirements are central.
- Strong consistency rules reduce agent drift.

**Areas for Future Enhancement:**
- Detailed contract alignment for telemetry/install endpoints.
- Explicit sandboxing model per platform.

### Implementation Handoff

**AI Agent Guidelines:**
- Follow decisions and patterns exactly.
- Respect repo boundaries and contracts.
- Enforce i18n and offline-first constraints.

**First Implementation Priority:**
Align POS ↔ marketplace API contracts and status/telemetry lifecycle before adding new features.

## Architecture Completion Summary

### Workflow Completion

**Architecture Decision Workflow:** COMPLETED ✅
**Total Steps Completed:** 8
**Date Completed:** 2025-12-30T14:55:28Z
**Document Location:** _bmad-output/planning-artifacts/architecture.md

### Final Architecture Deliverables

**📋 Complete Architecture Document**

- All architectural decisions documented with specific versions
- Implementation patterns ensuring AI agent consistency
- Complete project structure with all files and directories
- Requirements to architecture mapping
- Validation confirming coherence and completeness

**🏗️ Implementation Ready Foundation**

- Architectural decisions made across core domains
- Implementation patterns defined to prevent agent conflicts
- Architecture components specified and bounded
- Requirements fully supported

**📚 AI Agent Implementation Guide**

- Technology stack with verified versions
- Consistency rules that prevent implementation conflicts
- Project structure with clear boundaries
- Integration patterns and communication standards

### Implementation Handoff

**For AI Agents:**
This architecture document is the complete guide for implementing docs. Follow all decisions, patterns, and structures exactly as documented.

**First Implementation Priority:**
Align POS ↔ marketplace API contracts and status/telemetry lifecycle before adding new features.

**Development Sequence:**

1. Set up development environments per repo.
2. Align POS ↔ marketplace contracts and telemetry endpoints.
3. Implement plugin trust/signing + revocation checks.
4. Maintain offline-first queue/sync with conflict review.
5. Build features following established patterns.

### Quality Assurance Checklist

**✅ Architecture Coherence**

- [x] All decisions work together without conflicts
- [x] Technology choices are compatible
- [x] Patterns support the architectural decisions
- [x] Structure aligns with all choices

**✅ Requirements Coverage**

- [x] All functional requirements are supported
- [x] All non-functional requirements are addressed
- [x] Cross-cutting concerns are handled
- [x] Integration points are defined

**✅ Implementation Readiness**

- [x] Decisions are specific and actionable
- [x] Patterns prevent agent conflicts
- [x] Structure is complete and unambiguous
- [x] Examples are provided for clarity

### Project Success Factors

**🎯 Clear Decision Framework**
Every technology choice was made collaboratively with clear rationale, ensuring all stakeholders understand the architectural direction.

**🔧 Consistency Guarantee**
Implementation patterns and rules ensure that multiple AI agents will produce compatible, consistent code that works together seamlessly.

**📋 Complete Coverage**
All project requirements are architecturally supported, with clear mapping from business needs to technical implementation.

**🏗️ Solid Foundation**
The architecture provides a production-ready foundation aligned to current repo conventions and offline-first constraints.

---

**Architecture Status:** READY FOR IMPLEMENTATION ✅

**Next Phase:** Begin implementation using the architectural decisions and patterns documented herein.

**Document Maintenance:** Update this architecture when major technical decisions are made during implementation.
