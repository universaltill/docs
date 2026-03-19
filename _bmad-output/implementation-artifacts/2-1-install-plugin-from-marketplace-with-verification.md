# Story 2.1: Install Plugin from Marketplace with Verification

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an operator,
I want to install a plugin from the marketplace with integrity checks,
so that only verified bundles are installed.

## Acceptance Criteria

1. Given a plugin bundle is selected for install, when the POS downloads the bundle, then the POS verifies checksum/signature before installation.
2. Invalid bundles are rejected with a clear error state.

## Tasks / Subtasks

- [x] Implement POS-side marketplace download orchestration for plugin install (AC: 1)
  - [x] Add or update POS marketplace client logic under `universal-till/internal/plugins/marketplace/` to request bundle metadata from the marketplace and then fetch the bundle.
  - [x] Keep the download path explicit and contract-driven; use the marketplace contract from Story 1.2 rather than inventing a local-only metadata format.
  - [x] Cache the downloaded bundle locally in the POS runtime in a way that supports offline operation and later retry/install status work.

- [x] Implement checksum/signature verification before install (AC: 1, 2)
  - [x] Add verification logic under `universal-till/internal/plugins/` that validates the downloaded bundle against the checksum and signature metadata supplied by the marketplace.
  - [x] Enforce signed-bundle trust policy as the default path for marketplace installs.
  - [x] Ensure install is blocked if verification fails at any step.

- [x] Prevent invalid bundles from reaching runtime activation (AC: 2)
  - [x] Return a clear failure state for checksum mismatch, signature failure, missing integrity metadata, or unreadable/tampered bundle content.
  - [x] Do not partially install or activate a plugin when verification fails.
  - [x] Leave the currently running POS state stable after failure.

- [x] Connect verification to the POS plugin lifecycle flow (AC: 1, 2)
  - [x] Route verified bundles into the plugin install path in `universal-till/internal/plugins/` without prematurely implementing rollback/version-management behavior from Story 2.3.
  - [x] Keep status transitions compatible with the standardized lifecycle states documented in architecture and PRD.
  - [x] Prepare enough structure that Story 2.2 can surface install status and version visibility without reworking the install core.

- [x] Expose operator-visible failure feedback for install attempts (AC: 2)
  - [x] If this story touches POS handlers or templates, keep errors plain-language and actionable.
  - [x] Preserve kiosk/admin separation and do not block checkout-critical flows with install UI behavior.
  - [x] Do not overbuild telemetry, retry queues, or rollback UI here; those belong to later stories.

- [x] Add tests that prove only verified bundles install (AC: 1, 2)
  - [x] Add unit tests for happy-path verification using valid checksum and signature metadata.
  - [x] Add edge-case tests for checksum mismatch, bad signature, missing integrity metadata, and tampered bundle payloads.
  - [x] Add lifecycle/install tests proving verification failure prevents activation or persistence as an installed plugin.

## Dev Notes

- Story 2.1 is the bridge from marketplace distribution into actual POS install. It is the first point where the plugin test loop becomes real. [Source: _bmad-output/planning-artifacts/epics.md#Story-21-Install-Plugin-from-Marketplace-with-Verification]
- Scope discipline matters: this story verifies and installs a marketplace plugin. It does not own full install status UX (`2.2`), rollback/version management (`2.3`), disable/uninstall (`2.4`), or revocation handling (`1.3` / later POS trust flows).

### Technical Requirements

- POS repo target: `universal-till/`.
- Prefer implementation in:
  - `universal-till/internal/plugins/marketplace/`
  - `universal-till/internal/plugins/`
  - `universal-till/internal/pages/` only if an install-trigger handler or error surface is required
  - `universal-till/templates/` only if a minimal operator/admin view must change
- POS must consume marketplace contracts as the source of truth for download metadata. Do not duplicate or reinterpret the contract ad hoc. [Source: _bmad-output/planning-artifacts/architecture.md#API--Communication-Patterns]
- FR14 and FR27 require checksum/signature verification before installation and refusal on validation failure. [Source: _bmad-output/planning-artifacts/prd.md#Marketplace--Plugin-Lifecycle] [Source: _bmad-output/planning-artifacts/prd.md#Security--Trust-MVP-Level]
- POS runs offline-first and must cache plugins locally for offline use; installing from marketplace cannot introduce a hard online dependency into checkout flows. [Source: project-context.md#Critical-Dont-Miss-Rules] [Source: _bmad-output/planning-artifacts/prd.md#Reliability--Offline]
- Secrets must never be logged or stored in plain files. [Source: project-context.md#Critical-Dont-Miss-Rules]
- Keep data and state explicit enough for later lifecycle states such as `requested`, `downloading`, `installing`, `active`, and `failed`. [Source: _bmad-output/planning-artifacts/epics.md#Additional-Requirements]

### Architecture Compliance

- POS domain logic belongs in `universal-till/internal/plugins/` and adjacent plugin marketplace client code, not in templates or handler glue. [Source: _bmad-output/planning-artifacts/architecture.md#Architectural-Boundaries]
- POS ↔ Marketplace communication is REST and contract-driven. Marketplace internal gRPC details must not leak into POS install code. [Source: _bmad-output/planning-artifacts/architecture.md#API-Boundaries]
- Plugins never access internal DB structures directly; installation must preserve host-controlled boundaries and permission enforcement. [Source: _bmad-output/planning-artifacts/architecture.md#Data-Boundaries]
- POS is local-first single-process edge runtime. Keep install flow resilient to network interruption and avoid designs that block the rest of the POS. [Source: _bmad-output/planning-artifacts/architecture.md#Service-Boundaries]

### Library / Framework Requirements

- Stay within the repo’s existing Go toolchain (`go 1.25` / `go 1.25.3` as applicable). Official Go 1.25 release notes confirm the current release line. [Source: project-context.md#Technology-Stack--Versions] [Source: https://go.dev/doc/go1.25]
- If this story touches operator/admin HTML, use server-rendered HTML with HTMX 2.x and minimal JS. Do not add a SPA-style client flow for plugin installation. [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture] [Source: https://htmx.org/docs/] [Source: https://htmx.org/migration-guide-htmx-1/]
- POS local storage target is SQLite 3.51.1. If install state persistence changes are required, keep them aligned with repo-owned migrations and data-layer conventions. [Source: project-context.md#Technology-Stack--Versions] [Source: _bmad-output/planning-artifacts/architecture.md#Data-Architecture]

### File Structure Requirements

- Expected primary files are likely under:
  - `universal-till/internal/plugins/marketplace/...`
  - `universal-till/internal/plugins/...`
  - `universal-till/internal/pages/...`
  - `universal-till/templates/...`
  - co-located `*_test.go`
- If install state persistence or cache metadata requires schema updates, use `universal-till/internal/db/migrations/` and the repo-owned data layer. Do not hide SQL in unrelated packages. [Source: project-context.md#Code-Quality--Style-Rules]
- Keep reusable helpers local to the plugin runtime or marketplace client area. Do not create global utility sprawl.

### Testing Requirements

- Add happy-path and edge-case tests for verification and install behavior. [Source: project-context.md#Testing-Rules]
- Minimum required coverage:
  - valid bundle with valid checksum/signature installs successfully
  - checksum mismatch fails before install
  - bad or missing signature fails before install
  - missing marketplace integrity metadata fails safely
  - failed verification does not activate or persist the plugin as installed
- If handlers/templates are touched, add backend-led UI assertions for the visible error state rather than only testing the service layer.

### Previous Story Intelligence

- Story 1.2 defined the download metadata contract and required explicit machine-readable integrity fields. Reuse that contract exactly rather than re-deriving bundle metadata inside POS code.
- Story 1.2 intentionally kept POS install logic out of marketplace code. Maintain that separation here: POS consumes bundle metadata, downloads the artifact, verifies it, and decides install outcome.
- Story 1.1 and 1.2 together establish the thin pilot path order: discover plugin, fetch download metadata, then verify/install.

### Git Intelligence Summary

- Recent docs repo commits are mostly BMAD scaffolding and provide no useful implementation precedent for POS plugin install behavior. Follow the architecture, project-context, and story sequence instead of local git patterns.

### Project Structure Notes

- Implementation belongs in sibling POS repo `~/repos/unitill/universal-till/`, not in this docs repo. [Source: _bmad-output/planning-artifacts/architecture.md#Complete-Project-Directory-Structure]
- Plugin lifecycle and permissions map primarily to `universal-till/internal/plugins`, while marketplace client/cache work maps to `universal-till/internal/plugins/marketplace`. [Source: _bmad-output/planning-artifacts/architecture.md#Requirements-to-Structure-Mapping]
- This story depends on the marketplace outputs from `1.2` but should not block on broader marketplace revocation or CLI flows.

### UX / Product Guardrails

- Install/update behavior should show calm, plain-language state and clear failure feedback. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Feedback-Patterns]
- Non-blocking operation is a hard rule: plugin install activity must not make checkout unsafe or unusable. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Journey-Patterns]
- If an install flow UI is surfaced, keep it shallow: trust/signature indicator, progress, and clear failure state are enough for this story. Retry, rollback, and richer state presentation belong primarily to later stories. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#PluginLayout-InstallUpdate-Marketplace-or-Side-load]

### References

- [_bmad-output/planning-artifacts/epics.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/epics.md)
- [_bmad-output/planning-artifacts/prd.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/prd.md)
- [_bmad-output/planning-artifacts/architecture.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/architecture.md)
- [_bmad-output/planning-artifacts/ux-design-specification.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/ux-design-specification.md)
- [_bmad-output/implementation-artifacts/1-2-plugin-bundle-distribution-with-integrity-metadata.md](/Users/farshid/repos/unitill/docs/_bmad-output/implementation-artifacts/1-2-plugin-bundle-distribution-with-integrity-metadata.md)
- [project-context.md](/Users/farshid/repos/unitill/docs/project-context.md)
- https://go.dev/doc/go1.25
- https://htmx.org/docs/
- https://htmx.org/migration-guide-htmx-1/

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- Story context assembled from epic, PRD, architecture, UX, project-context, Story 1.2, git history, and sprint status artifacts.
- `gofmt -w /Users/farshid/repos/unitill/universal-till/internal/config/config.go /Users/farshid/repos/unitill/universal-till/internal/plugins/oauth/token_client.go /Users/farshid/repos/unitill/universal-till/internal/plugins/manifest_verifier.go /Users/farshid/repos/unitill/universal-till/internal/plugins/marketplace/client.go /Users/farshid/repos/unitill/universal-till/internal/plugins/marketplace/client_test.go /Users/farshid/repos/unitill/universal-till/internal/plugins/installer_marketplace.go /Users/farshid/repos/unitill/universal-till/internal/plugins/installer_marketplace_test.go /Users/farshid/repos/unitill/universal-till/internal/pages/plugin_api.go`
- `go test ./internal/plugins/marketplace ./internal/plugins/oauth ./internal/plugins ./internal/pages`
- `go test ./...`

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Story intentionally scoped to POS download, verification, and safe install gating only.
- Cross-repo boundary between marketplace metadata production and POS verification preserved.
- Latest technical specifics reused from primary vendor documentation already verified in this planning sequence.
- Updated the POS marketplace client to consume Story 1.2’s `/v1/downloads/tokens` contract and decode the `{data,error}` envelope with machine-readable checksum and signature fields.
- Added a dedicated marketplace installer flow in `internal/plugins/` that requests download metadata, downloads the bundle, verifies checksum and manifest signature, checks compatibility/executable presence, persists the catalog row, and only then activates installation state.
- Rewired the marketplace install page handler to use the installer service instead of the older direct `artifact_url` catalog shortcut.
- Added focused tests proving successful verified install plus refusal on missing integrity metadata and signature mismatch, with no plugin persisted on failure.

### File List

- /Users/farshid/repos/unitill/docs/_bmad-output/implementation-artifacts/2-1-install-plugin-from-marketplace-with-verification.md
- /Users/farshid/repos/unitill/universal-till/internal/config/config.go
- /Users/farshid/repos/unitill/universal-till/internal/plugins/oauth/token_client.go
- /Users/farshid/repos/unitill/universal-till/internal/plugins/manifest_verifier.go
- /Users/farshid/repos/unitill/universal-till/internal/plugins/marketplace/client.go
- /Users/farshid/repos/unitill/universal-till/internal/plugins/marketplace/client_test.go
- /Users/farshid/repos/unitill/universal-till/internal/plugins/installer_marketplace.go
- /Users/farshid/repos/unitill/universal-till/internal/plugins/installer_marketplace_test.go
- /Users/farshid/repos/unitill/universal-till/internal/pages/plugin_api.go
