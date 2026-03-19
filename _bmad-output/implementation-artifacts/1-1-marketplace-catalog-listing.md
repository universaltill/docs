# Story 1.1: Marketplace Catalog Listing

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an operator,
I want to browse a marketplace catalog with clear plugin metadata,
so that I can find plugins appropriate for pilots.

## Acceptance Criteria

1. Given a marketplace endpoint is available, when I request the catalog list, then each plugin entry includes name, version, description, and compatibility metadata.
2. The catalog response follows the versioned API contract format.

## Tasks / Subtasks

- [x] Define the versioned marketplace catalog contract for Story 1.1 (AC: 1, 2)
  - [x] Add or update the catalog list response contract in `ut-market-place/pkg/contracts/` using snake_case JSON fields and the required `{data, error}` response envelope.
  - [x] Ensure each catalog item exposes at minimum `name`, `version`, `description`, and compatibility metadata needed by the POS to decide whether a plugin is suitable for pilots.
  - [x] Keep the contract versioned and stable for POS and CLI consumers; do not introduce ad hoc response shapes in handlers.

- [x] Implement marketplace catalog listing on the service side (AC: 1, 2)
  - [x] Add or update repository access under `ut-market-place/internal/repositories/ent/` to read published plugin entries and the fields required by the contract.
  - [x] Add service logic under `ut-market-place/internal/services/` that maps persisted plugin data into the versioned contract shape.
  - [x] Filter out incomplete or unpublished records if the service supports draft/published distinctions.

- [x] Expose the catalog listing through the marketplace API layer (AC: 1, 2)
  - [x] Add or update the REST handler under `ut-market-place/internal/api/` for the catalog listing endpoint.
  - [x] Return a success envelope shaped as `{data: ..., error: null}` and a structured error envelope on failure.
  - [x] Keep endpoint naming plural and versioned, aligned with architecture guidance.

- [x] Make the response implementation-safe for later POS install flow (AC: 1)
  - [x] Include compatibility metadata that is explicit enough for later POS-side validation and filtering.
  - [x] Do not defer required metadata into free-form text fields.
  - [x] Avoid coupling the listing response to download, signature, or revocation details that belong to Stories 1.2 and 1.3.

- [x] Add tests that lock the contract and listing behavior (AC: 1, 2)
  - [x] Add service and/or handler tests covering the happy path for catalog listing.
  - [x] Add a test proving the response envelope and field names match the versioned contract.
  - [x] Add edge-case coverage for empty catalog results and records missing required metadata.

## Dev Notes

- Story 1.1 is marketplace-first. Keep implementation scoped to browse/list behavior. Bundle download, integrity metadata, and revocation details belong to Stories 1.2 and 1.3, even if the data model is shared across them. [Source: _bmad-output/planning-artifacts/epics.md#Epic-1-Marketplace-Catalog-Trust-and-Distribution]
- The shortest path to pilot readiness is an end-to-end vertical slice: publish plugin, list it, install it, verify it, and show install state. This story only owns the listing step in that sequence.

### Technical Requirements

- Marketplace repo target: `ut-market-place/`.
- Prefer implementation in:
  - `ut-market-place/internal/api/`
  - `ut-market-place/internal/services/`
  - `ut-market-place/internal/repositories/ent/`
  - `ut-market-place/pkg/contracts/`
- Keep marketplace contracts as the source of truth for POS and CLI consumption. [Source: _bmad-output/planning-artifacts/architecture.md#API--Communication-Patterns]
- API responses must use the documented format: success `{data, error}` and structured error payloads with snake_case fields. [Source: _bmad-output/planning-artifacts/architecture.md#Format-Patterns]
- Endpoint naming must stay plural and versioned. Avoid one-off unversioned catalog routes. [Source: _bmad-output/planning-artifacts/architecture.md#Naming-Patterns]
- Marketplace production DB target is PostgreSQL 18.x; SQLite is allowed for dev/test only. Do not choose schema or query behavior that depends on SQLite quirks. [Source: _bmad-output/planning-artifacts/architecture.md#Data-Architecture]
- Secrets must never be stored in plain files. Token-based auth is part of the marketplace/CLI model, but if this endpoint is public for pilots, keep auth behavior aligned with existing marketplace rules rather than inventing a new auth path. [Source: _bmad-output/planning-artifacts/architecture.md#Authentication--Security]

### Architecture Compliance

- Do not place business logic in HTTP handlers; handlers should delegate to service logic. [Source: _bmad-output/planning-artifacts/architecture.md#Architectural-Boundaries]
- Keep data access in the marketplace data layer under Ent-backed repositories. Do not bypass the repository layer from handlers. [Source: _bmad-output/planning-artifacts/architecture.md#Complete-Project-Directory-Structure]
- Preserve repo boundaries: this story should not modify POS runtime code unless a shared contract package forces a coordinated change.
- Compatibility metadata must be explicit and machine-readable because the POS install flow later depends on it for filtering and safe install decisions. This is an inference from FR13 plus the architecture requirement that contracts are the source of truth.

### Library / Framework Requirements

- Go target in project context is `go 1.25` / `go 1.25.3` depending on repo. Stay within the repo's existing `go.mod` and toolchain. Official Go 1.25 release notes confirm the release line is current and backward compatible for almost all programs. [Source: project-context.md#Technology-Stack--Versions] [Source: https://go.dev/doc/go1.25]
- If this story touches any admin-facing HTML, the frontend pattern is server-rendered HTML with HTMX 2.x and minimal JavaScript. Official htmx docs still recommend server responses as HTML, and the 1.x to 2.x migration guide notes extensions moved out of core in 2.x. Do not introduce new client-side framework dependencies. [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture] [Source: https://htmx.org/docs/] [Source: https://htmx.org/migration-guide-htmx-1/]
- Marketplace production target remains PostgreSQL 18.x. The PostgreSQL release archive shows newer 18.x minors exist as of February 26, 2026, so implement against 18.x-compatible SQL/features rather than relying on a specific minor. [Source: _bmad-output/planning-artifacts/architecture.md#Data-Architecture] [Source: https://www.postgresql.org/docs/release/]

### File Structure Requirements

- Expected primary files are likely under:
  - `ut-market-place/pkg/contracts/...`
  - `ut-market-place/internal/services/...`
  - `ut-market-place/internal/api/...`
  - `ut-market-place/internal/repositories/ent/...`
  - co-located `*_test.go`
- If a new schema field or persistence change is required, keep it in the marketplace repo's established data layer and migration conventions. Do not hide schema changes inside handler code.
- Keep reusable helpers local to the relevant marketplace area. Do not create cross-repo utilities for this story.

### Testing Requirements

- Add automated tests for the contract and listing behavior. Backend-led UI/API changes require tests. [Source: project-context.md#Testing-Rules]
- Minimum required coverage:
  - happy path catalog listing returns entries with the required metadata
  - response envelope and field names match the versioned contract
  - empty result set is valid and does not error
  - records missing required metadata are excluded or rejected consistently
- If handler tests exist in repo patterns, prefer contract-level JSON assertions rather than brittle string snapshots.

### Project Structure Notes

- Central docs live in this repo; implementation is expected in sibling repos under `~/repos/unitill/`. Marketplace work belongs in `~/repos/unitill/ut-market-place/`. [Source: _bmad-output/planning-artifacts/architecture.md#Complete-Project-Directory-Structure]
- Marketplace catalog/download/revocation work maps to `ut-market-place/internal/api` and `ut-market-place/pkg/contracts`. [Source: _bmad-output/planning-artifacts/architecture.md#Requirements-to-Structure-Mapping]
- Current sprint tracking shows this story is the first backlog item in the active epic. It is the correct entry point for the plugin test path.

### UX / Product Guardrails

- Operators are browsing for pilot-suitable plugins, so listing data must be concise, clear, and trustworthy rather than overloaded. [Source: _bmad-output/planning-artifacts/epics.md#Story-11-Marketplace-Catalog-Listing]
- If an admin/operator UI is involved, follow the UX guidance for minimal fields, plain-language errors, and visible status feedback. Do not block future POS checkout flows with catalog UI assumptions. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Feedback-Patterns] [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Form-Patterns]
- Trust indicators, progress, and rollback belong more directly to install/update flows. Do not overbuild those concepts into the listing endpoint in this story. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#PluginLayout-InstallUpdate-Marketplace-or-Side-load]

### References

- [_bmad-output/planning-artifacts/epics.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/epics.md)
- [_bmad-output/planning-artifacts/prd.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/prd.md)
- [_bmad-output/planning-artifacts/architecture.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/architecture.md)
- [_bmad-output/planning-artifacts/ux-design-specification.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/ux-design-specification.md)
- [project-context.md](/Users/farshid/repos/unitill/docs/project-context.md)
- https://go.dev/doc/go1.25
- https://htmx.org/docs/
- https://htmx.org/migration-guide-htmx-1/
- https://www.postgresql.org/docs/release/

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- Story context assembled from epic, PRD, architecture, UX, project-context, and current sprint status artifacts.
- `gofmt -w internal/catalog/service.go internal/catalog/service_test.go internal/api/catalogsvc/handler_test.go`
- `go test ./internal/catalog ./internal/api/catalogsvc`
- `go test ./...`

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Story intentionally scoped to catalog listing only, to protect the thin vertical slice for plugin pilot testing.
- Latest technical specifics verified against primary vendor documentation where relevant.
- Added a catalog metadata gate so listings without required summary fields or an approved release version are not surfaced.
- Hardened release lookup in `internal/catalog/service.go` to fall back to a direct approved-release query when eager-loaded release edges are absent.
- Added service and handler coverage for required compatibility fields and incomplete-listing omission.
- Adversarial code review completed with no findings across the changed catalog service and handler files.

### File List

- /Users/farshid/repos/unitill/docs/_bmad-output/implementation-artifacts/1-1-marketplace-catalog-listing.md
- /Users/farshid/repos/unitill/ut-market-place/internal/catalog/service.go
- /Users/farshid/repos/unitill/ut-market-place/internal/catalog/service_test.go
- /Users/farshid/repos/unitill/ut-market-place/internal/api/catalogsvc/handler_test.go
