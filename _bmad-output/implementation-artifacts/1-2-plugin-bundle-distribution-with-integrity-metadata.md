# Story 1.2: Plugin Bundle Distribution with Integrity Metadata

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a plugin developer or operator,
I want the marketplace to provide downloadable plugin bundles with integrity metadata,
so that POS devices can verify bundles before install.

## Acceptance Criteria

1. Given a plugin version is published, when a bundle download is requested, then the response provides a bundle URL plus checksum and signature metadata.
2. The marketplace refuses to serve bundles missing required integrity metadata.

## Tasks / Subtasks

- [x] Define the versioned download metadata contract for plugin bundles (AC: 1, 2)
  - [x] Add or update the bundle download response contract in `ut-market-place/pkg/contracts/` with explicit fields for `bundle_url`, checksum, signature, and any required version metadata.
  - [x] Keep all JSON fields in snake_case and return the response through the standard `{data, error}` envelope.
  - [x] Make the integrity fields machine-readable and strict enough for later POS verification logic in Story 2.1.

- [x] Implement marketplace service logic for bundle distribution eligibility (AC: 1, 2)
  - [x] Add or update service logic in `ut-market-place/internal/services/` to resolve a published plugin version into a downloadable bundle plus integrity metadata.
  - [x] Enforce a hard refusal path when required integrity metadata is missing, incomplete, or invalid.
  - [x] Keep unpublished, draft, or malformed bundles out of the download flow.

- [x] Implement repository/data-layer support for integrity-backed bundles (AC: 1, 2)
  - [x] Add or update repository access under `ut-market-place/internal/repositories/ent/` for persisted bundle location and integrity fields.
  - [x] If storage changes are required, keep them in the marketplace repo’s existing migration/data-layer conventions rather than embedding assumptions in handlers.
  - [x] Make sure the data model supports later revocation and trust flows without forcing those features into this story.

- [x] Expose the bundle metadata through the marketplace API layer (AC: 1, 2)
  - [x] Add or update the REST handler under `ut-market-place/internal/api/` for the bundle download metadata route.
  - [x] Use versioned, plural endpoint naming and return structured errors for missing metadata or unavailable bundles.
  - [x] Avoid embedding POS-specific install state logic here; this endpoint only serves the bundle location and integrity inputs required for verification.

- [x] Keep Story 1.2 aligned with the thin plugin pilot slice (AC: 1)
  - [x] Ensure the endpoint serves enough metadata for the POS to verify and download a bundle without inventing rollback, revocation, or permission-consent behavior prematurely.
  - [x] Preserve clear separation from Story 1.1 listing and Story 1.3 revocation/trust signaling.
  - [x] Prefer one canonical bundle format/path that works for the first pilot plugin instead of over-generalizing.

- [x] Add tests that prove secure distribution behavior (AC: 1, 2)
  - [x] Add service and/or handler tests for a valid published plugin version returning bundle URL plus checksum and signature metadata.
  - [x] Add edge-case tests proving bundles with missing integrity metadata are refused.
  - [x] Add tests for unpublished or malformed bundle records returning the documented error envelope.

## Dev Notes

- Story 1.2 is the second step in the pilot plugin path: catalog listing first, bundle distribution second, POS verification/install after that. Keep scope tight around serving download metadata safely. [Source: _bmad-output/planning-artifacts/epics.md#Epic-1-Marketplace-Catalog-Trust-and-Distribution]
- This story must produce the inputs needed by POS verification in Story 2.1, but it must not implement POS verification itself.

### Technical Requirements

- Marketplace repo target: `ut-market-place/`.
- Prefer implementation in:
  - `ut-market-place/pkg/contracts/`
  - `ut-market-place/internal/services/`
  - `ut-market-place/internal/repositories/ent/`
  - `ut-market-place/internal/api/`
- Marketplace contracts remain the versioned source of truth for POS and CLI consumers. Do not invent handler-only response shapes. [Source: _bmad-output/planning-artifacts/architecture.md#API--Communication-Patterns]
- API responses must use `{data, error}` with snake_case JSON fields. [Source: _bmad-output/planning-artifacts/architecture.md#Format-Patterns]
- Endpoint naming must stay plural and versioned. [Source: _bmad-output/planning-artifacts/architecture.md#Naming-Patterns]
- Plugin trust requires signed bundles, verification, and revocation enforcement. This story only covers serving the signed bundle metadata required for verification. [Source: _bmad-output/planning-artifacts/architecture.md#Authentication--Security]
- FR14 and FR27 require that POS verifies integrity before installation. Therefore this story’s metadata must be explicit and complete enough for downstream checksum/signature validation. [Source: _bmad-output/planning-artifacts/prd.md#Marketplace--Plugin-Lifecycle] [Source: _bmad-output/planning-artifacts/prd.md#Security--Trust-MVP-Level]
- Marketplace production target is PostgreSQL 18.x, with SQLite allowed in dev/test. Keep persistence and query behavior portable across supported environments. [Source: _bmad-output/planning-artifacts/architecture.md#Data-Architecture]

### Architecture Compliance

- Keep business logic in marketplace services, not HTTP handlers. [Source: _bmad-output/planning-artifacts/architecture.md#Architectural-Boundaries]
- Keep persistence access in the Ent-backed data layer under `internal/repositories/ent/`. [Source: _bmad-output/planning-artifacts/architecture.md#Complete-Project-Directory-Structure]
- Preserve repo boundaries: marketplace prepares bundle metadata; POS downloads and verifies; CLI/backoffice publishing is a later concern in Epic 5.
- Choose boring, explicit contract fields over flexible blobs. The POS install path depends on predictable, machine-readable metadata. This is an inference from the architecture rule that marketplace contracts are the source of truth and from the plugin trust model.

### Library / Framework Requirements

- Stay within the repo’s existing Go toolchain (`go 1.25` / `go 1.25.3` as applicable). Official Go 1.25 release notes confirm the release family and compatibility baseline. [Source: project-context.md#Technology-Stack--Versions] [Source: https://go.dev/doc/go1.25]
- If any admin/operator HTML is touched, use server-rendered HTML with HTMX 2.x and minimal JS. Do not add a separate frontend stack. htmx docs continue to center HTML-over-the-wire patterns, and the migration guide documents the 2.x extension split. [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture] [Source: https://htmx.org/docs/] [Source: https://htmx.org/migration-guide-htmx-1/]
- PostgreSQL remains on the 18.x line. Official release pages show later 18.x minors exist, so keep SQL/features compatible with the major line rather than anchoring behavior to 18.1 specifically. [Source: _bmad-output/planning-artifacts/architecture.md#Data-Architecture] [Source: https://www.postgresql.org/docs/release/]

### File Structure Requirements

- Expected primary files are likely under:
  - `ut-market-place/pkg/contracts/...`
  - `ut-market-place/internal/services/...`
  - `ut-market-place/internal/api/...`
  - `ut-market-place/internal/repositories/ent/...`
  - co-located `*_test.go`
- If bundle storage or metadata fields require schema changes, keep them in the marketplace repo’s standard migration or Ent schema path.
- Do not create cross-repo helpers or duplicate contract definitions in POS code during this story.

### Testing Requirements

- Add automated tests for the happy path and refusal path. [Source: project-context.md#Testing-Rules]
- Minimum required coverage:
  - published plugin version returns bundle URL plus checksum and signature metadata
  - missing integrity metadata returns the documented error envelope and does not expose a usable bundle
  - unpublished or malformed records do not leak into the download path
  - contract serialization uses the expected snake_case fields
- Prefer direct contract assertions over brittle raw-string response checks.

### Previous Story Intelligence

- Story 1.1 deliberately kept listing separate from bundle download and trust-specific data. Do not collapse those concerns back together here.
- Story 1.1 established that compatibility metadata belongs in listing for discovery, while download/integrity metadata belongs here for install preparation.
- Maintain the same repo targets and contract-first approach used in Story 1.1 so the dev agent does not scatter marketplace logic.

### Git Intelligence Summary

- Recent docs repo history is minimal and mostly BMAD setup (`5e4b033 using BMAD`, `20febf0 adding readme and architecture`). There is no useful implementation pattern to inherit from recent commits here, so follow the architecture and story guidance rather than local git precedent.

### Project Structure Notes

- Implementation belongs in sibling marketplace repo `~/repos/unitill/ut-market-place/`, not in this docs repo. [Source: _bmad-output/planning-artifacts/architecture.md#Complete-Project-Directory-Structure]
- Marketplace catalog/download/revocation features map to `ut-market-place/internal/api`, `ut-market-place/internal/services`, and `ut-market-place/pkg/contracts`. [Source: _bmad-output/planning-artifacts/architecture.md#Requirements-to-Structure-Mapping]
- Current sprint sequencing is correct for the pilot path: `1.1` listing, `1.2` bundle metadata, then `2.1` POS verification/install.

### UX / Product Guardrails

- Install/update flows should show plain-language status and trust indicators, but this story itself is primarily an API/service contract step. Avoid inventing UI work unless the repo already requires an admin-visible download surface. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#PluginLayout-InstallUpdate-Marketplace-or-Side-load]
- If any error text is surfaced, keep it plain language and actionable. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Feedback-Patterns]
- The goal is to minimize steps to apply plugins while keeping trust verification explicit. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Flow-Optimization-Principles]

### References

- [_bmad-output/planning-artifacts/epics.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/epics.md)
- [_bmad-output/planning-artifacts/prd.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/prd.md)
- [_bmad-output/planning-artifacts/architecture.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/architecture.md)
- [_bmad-output/planning-artifacts/ux-design-specification.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/ux-design-specification.md)
- [_bmad-output/implementation-artifacts/1-1-marketplace-catalog-listing.md](/Users/farshid/repos/unitill/docs/_bmad-output/implementation-artifacts/1-1-marketplace-catalog-listing.md)
- [project-context.md](/Users/farshid/repos/unitill/docs/project-context.md)
- https://go.dev/doc/go1.25
- https://htmx.org/docs/
- https://htmx.org/migration-guide-htmx-1/
- https://www.postgresql.org/docs/release/

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- Story context assembled from epic, PRD, architecture, UX, project-context, Story 1.1, git history, and sprint status artifacts.
- `protoc -I /Users/farshid/repos/unitill/ut-market-place/specs/001-plugin-marketplace/contracts -I /Users/farshid/repos/unitill/ut-market-place/third_party --go_out=paths=source_relative:/Users/farshid/repos/unitill/ut-market-place/pkg/contracts --go-grpc_out=paths=source_relative:/Users/farshid/repos/unitill/ut-market-place/pkg/contracts --grpc-gateway_out=paths=source_relative:/Users/farshid/repos/unitill/ut-market-place/pkg/contracts /Users/farshid/repos/unitill/ut-market-place/specs/001-plugin-marketplace/contracts/marketplace.proto`
- `protoc -I /Users/farshid/repos/unitill/ut-market-place/specs/001-plugin-marketplace/contracts -I /Users/farshid/repos/unitill/ut-market-place/third_party --go_out=paths=source_relative:/Users/farshid/repos/unitill/ut-market-place/pkg/contracts/marketplace/v1 --go-grpc_out=paths=source_relative:/Users/farshid/repos/unitill/ut-market-place/pkg/contracts/marketplace/v1 --grpc-gateway_out=paths=source_relative:/Users/farshid/repos/unitill/ut-market-place/pkg/contracts/marketplace/v1 /Users/farshid/repos/unitill/ut-market-place/specs/001-plugin-marketplace/contracts/marketplace.proto`
- `gofmt -w /Users/farshid/repos/unitill/ut-market-place/internal/api/downloadsvc/service.go /Users/farshid/repos/unitill/ut-market-place/internal/api/downloadsvc/grpc.go /Users/farshid/repos/unitill/ut-market-place/internal/api/downloadsvc/service_test.go /Users/farshid/repos/unitill/ut-market-place/internal/httpapi/handlers/downloads.go /Users/farshid/repos/unitill/ut-market-place/internal/httpapi/handlers/downloads_test.go /Users/farshid/repos/unitill/ut-market-place/cmd/marketplace/main.go /Users/farshid/repos/unitill/ut-market-place/tests/contract/provider_pact_test.go`
- `go test ./internal/api/downloadsvc ./internal/httpapi/handlers`
- `go test ./...`

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Story intentionally scoped to secure bundle distribution and integrity metadata only.
- Story 1.1 separation preserved so discovery and download concerns do not blur.
- Latest technical specifics verified against primary vendor documentation where relevant.
- Added explicit download-contract fields for `merchant_id`, `store_id`, and response `version`, and bound `IssueDownloadToken` to the versioned plural REST route `/v1/downloads/tokens`.
- Replaced placeholder download issuance logic with Ent-backed entitlement checks, approved-release resolution, architecture filtering, and strict checksum/signature/object-key validation.
- Updated the HTTP download metadata route to return `{data, error}` envelopes with snake_case fields including `bundle_url`, `checksum_sha256`, and `signature`, while preserving a legacy route alias.
- Added service and handler tests covering happy path metadata delivery, malformed bundle refusal, unpublished release refusal, and envelope field naming.

### File List

- /Users/farshid/repos/unitill/docs/_bmad-output/implementation-artifacts/1-2-plugin-bundle-distribution-with-integrity-metadata.md
- /Users/farshid/repos/unitill/ut-market-place/specs/001-plugin-marketplace/contracts/marketplace.proto
- /Users/farshid/repos/unitill/ut-market-place/pkg/contracts/marketplace.pb.go
- /Users/farshid/repos/unitill/ut-market-place/pkg/contracts/marketplace.pb.gw.go
- /Users/farshid/repos/unitill/ut-market-place/pkg/contracts/marketplace/v1/marketplace.pb.go
- /Users/farshid/repos/unitill/ut-market-place/pkg/contracts/marketplace/v1/marketplace.pb.gw.go
- /Users/farshid/repos/unitill/ut-market-place/internal/api/downloadsvc/service.go
- /Users/farshid/repos/unitill/ut-market-place/internal/api/downloadsvc/grpc.go
- /Users/farshid/repos/unitill/ut-market-place/internal/api/downloadsvc/service_test.go
- /Users/farshid/repos/unitill/ut-market-place/internal/httpapi/handlers/downloads.go
- /Users/farshid/repos/unitill/ut-market-place/internal/httpapi/handlers/downloads_test.go
- /Users/farshid/repos/unitill/ut-market-place/internal/httpapi/router/router.go
- /Users/farshid/repos/unitill/ut-market-place/internal/catalog/service.go
- /Users/farshid/repos/unitill/ut-market-place/internal/catalog/service_test.go
- /Users/farshid/repos/unitill/ut-market-place/internal/api/catalogsvc/handler_test.go
- /Users/farshid/repos/unitill/ut-market-place/cmd/marketplace/main.go
- /Users/farshid/repos/unitill/ut-market-place/tests/contract/provider_pact_test.go
