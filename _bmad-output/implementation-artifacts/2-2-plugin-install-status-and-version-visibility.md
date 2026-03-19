# Story 2.2: Plugin Install Status and Version Visibility

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an operator,
I want to see plugin install status and current versions,
so that I can confirm installs succeeded.

## Acceptance Criteria

1. Given plugins are installed or installing, when I view the plugin list, then each plugin shows its current version and status state.
2. Failures include a human-readable message and retry option.

## Tasks / Subtasks

- [ ] Persist or expose plugin lifecycle status and current version in the POS runtime (AC: 1)
  - [ ] Add or update plugin state structures under `universal-till/internal/plugins/` so each plugin can surface current version plus lifecycle state.
  - [ ] Reuse the lifecycle groundwork from Story 2.1 rather than inventing a parallel status model.
  - [ ] Ensure status remains readable for both in-progress and already-installed plugins.

- [ ] Connect install outcomes from Story 2.1 into status visibility (AC: 1, 2)
  - [ ] Wire successful installs to surface installed version and active/current state.
  - [ ] Wire failed installs to surface a clear failure state and human-readable error message.
  - [ ] Preserve enough detail for a retry action without requiring rollback/version-management logic from Story 2.3.

- [ ] Expose plugin list/status data to the POS operator/admin surface (AC: 1, 2)
  - [ ] Add or update handlers under `universal-till/internal/pages/` to render plugin list data and status.
  - [ ] Update templates under `universal-till/templates/` only as needed to show plugin name, current version, lifecycle state, and failure messaging.
  - [ ] Keep kiosk/admin separation intact; this belongs in operator/admin surfaces, not checkout-critical screens.

- [ ] Add retry affordance for failed installs (AC: 2)
  - [ ] Surface a retry action only for retryable failure states.
  - [ ] Reuse the existing install path from Story 2.1 for retry rather than creating a separate code path.
  - [ ] Keep the retry path plain-language and safe; do not add rollback/version-switch behavior here.

- [ ] Keep status flow aligned to the documented lifecycle and pilot scope (AC: 1, 2)
  - [ ] Use the standardized install states documented in planning artifacts where applicable (`requested`, `downloading`, `installing`, `active`, `failed`).
  - [ ] Show current version for installed plugins and the target/current install state for in-flight operations.
  - [ ] Avoid expanding scope into uninstall, disable, update, rollback, or revocation UX.

- [ ] Add tests for status visibility and failure handling (AC: 1, 2)
  - [ ] Add unit tests for status mapping from install lifecycle state to operator-visible data.
  - [ ] Add handler/template or view-model tests proving version, state, and failure message render correctly.
  - [ ] Add tests showing retry is available only when appropriate and routes back through the standard install flow.

## Dev Notes

- Story 2.2 is the operator confirmation layer for the install flow created in Story 2.1. It should make success and failure visible without redesigning the install core. [Source: _bmad-output/planning-artifacts/epics.md#Story-22-Plugin-Install-Status-and-Version-Visibility]
- Keep scope tight: current version, lifecycle state, human-readable failure, retry option. Do not absorb update/rollback (`2.3`), disable/uninstall (`2.4`), or trust-status display (`2.9`) into this story.

### Technical Requirements

- POS repo target: `universal-till/`.
- Prefer implementation in:
  - `universal-till/internal/plugins/`
  - `universal-till/internal/pages/`
  - `universal-till/templates/`
  - `universal-till/web/locales/` if user-facing strings are added
- No hardcoded user-facing strings. Use locale bundles only. [Source: project-context.md#Critical-Dont-Miss-Rules] [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture]
- Keep operator-visible states aligned with the standardized lifecycle already documented in planning artifacts. [Source: _bmad-output/planning-artifacts/epics.md#Additional-Requirements] [Source: _bmad-output/planning-artifacts/architecture.md#API--Communication-Patterns]
- Failures must be human-readable and actionable, but secrets and sensitive internal details must never be exposed in plain files or logs. [Source: project-context.md#Critical-Dont-Miss-Rules]
- POS remains offline-first. Status display must not require live marketplace connectivity to show the current install state for cached or previously attempted installs. [Source: _bmad-output/planning-artifacts/prd.md#Reliability--Offline]

### Architecture Compliance

- POS domain/plugin lifecycle logic belongs in `universal-till/internal/plugins/`; handlers and templates should be thin adapters on top of that state. [Source: _bmad-output/planning-artifacts/architecture.md#Architectural-Boundaries]
- Kiosk/admin separation must remain intact; plugin management/status belongs in admin/operator views. [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture] [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Navigation-Patterns]
- i18n must be enforced in handlers/templates. No hardcoded labels for status, retry, or errors. [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture]
- Keep data persistence changes within the repo-owned data layer and migrations if state storage must change. [Source: project-context.md#Code-Quality--Style-Rules]

### Library / Framework Requirements

- Stay within the repo’s existing Go toolchain (`go 1.25` / `go 1.25.3` as applicable). Official Go 1.25 release notes confirm the current release line. [Source: project-context.md#Technology-Stack--Versions] [Source: https://go.dev/doc/go1.25]
- POS UI remains server-rendered HTML with HTMX 2.x and minimal JS. If retry is interactive, prefer HTMX-driven server responses instead of adding client-heavy state management. [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture] [Source: https://htmx.org/docs/] [Source: https://htmx.org/migration-guide-htmx-1/]
- POS local storage target is SQLite 3.51.1. Any persisted install state/version fields must respect repo-owned migration rules. [Source: project-context.md#Technology-Stack--Versions]

### File Structure Requirements

- Expected primary files are likely under:
  - `universal-till/internal/plugins/...`
  - `universal-till/internal/pages/...`
  - `universal-till/templates/...`
  - `universal-till/web/locales/...`
  - co-located `*_test.go`
- If status/version visibility requires persistence updates, use `universal-till/internal/db/migrations/` and the established data layer rather than inline SQL elsewhere. [Source: project-context.md#Code-Quality--Style-Rules]
- Keep UI changes lean. This story is visibility and retry wiring, not a full plugin management dashboard redesign.

### Testing Requirements

- Add happy-path and edge-case tests for status visibility and retry behavior. [Source: project-context.md#Testing-Rules]
- Minimum required coverage:
  - installed plugin shows current version and active/current state
  - in-progress install shows an in-flight lifecycle state
  - failed install shows a human-readable message
  - retry action appears only when the failure is retryable
  - retry routes back through the standard install path from Story 2.1
- If templates/handlers change, include backend-led assertions that localized strings and status chips/messages appear correctly.

### Previous Story Intelligence

- Story 2.1 already introduced the install lifecycle and verification failure model. Reuse those states and outcomes instead of building a new status abstraction.
- Story 2.1 intentionally deferred rich status/version visibility so this story could focus on operator confirmation and retry.
- Stories 1.1 and 1.2 remain upstream dependencies only; do not pull marketplace-side UI or contract concerns back into POS status rendering.

### Git Intelligence Summary

- Recent docs repo history is BMAD/setup-heavy and provides no useful precedent for plugin status UX or state wiring. Follow the planning artifacts and previous story instead of local git history.

### Project Structure Notes

- Implementation belongs in sibling POS repo `~/repos/unitill/universal-till/`, not in this docs repo. [Source: _bmad-output/planning-artifacts/architecture.md#Complete-Project-Directory-Structure]
- Plugin lifecycle work maps primarily to `universal-till/internal/plugins`; operator/admin status rendering maps to `universal-till/internal/pages`, `universal-till/templates`, and `universal-till/web/locales`. [Source: _bmad-output/planning-artifacts/architecture.md#Requirements-to-Structure-Mapping]
- This story completes the minimum pilot-loop visibility requirement after `2.1`: the operator can see whether install succeeded and what version is present.

### UX / Product Guardrails

- Use calm, always-visible status patterns and plain-language errors; avoid modal-heavy failure handling. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Feedback-Patterns]
- Keep install/status interactions shallow and non-blocking. Plugin operations must not interfere with checkout. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Journey-Patterns]
- A retry option should be obvious and safe, but rollback and broader plugin management controls belong to later stories. [Source: _bmad-output/planning-artifacts/ux-design-specification.md#PluginLayout-InstallUpdate-Marketplace-or-Side-load]

### References

- [_bmad-output/planning-artifacts/epics.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/epics.md)
- [_bmad-output/planning-artifacts/prd.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/prd.md)
- [_bmad-output/planning-artifacts/architecture.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/architecture.md)
- [_bmad-output/planning-artifacts/ux-design-specification.md](/Users/farshid/repos/unitill/docs/_bmad-output/planning-artifacts/ux-design-specification.md)
- [_bmad-output/implementation-artifacts/2-1-install-plugin-from-marketplace-with-verification.md](/Users/farshid/repos/unitill/docs/_bmad-output/implementation-artifacts/2-1-install-plugin-from-marketplace-with-verification.md)
- [project-context.md](/Users/farshid/repos/unitill/docs/project-context.md)
- https://go.dev/doc/go1.25
- https://htmx.org/docs/
- https://htmx.org/migration-guide-htmx-1/

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- Story context assembled from epic, PRD, architecture, UX, project-context, Story 2.1, git history, and sprint status artifacts.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Story intentionally scoped to install status/version visibility and retry affordance only.
- Lifecycle state model inherited from Story 2.1 to avoid duplicate abstractions.
- Latest technical specifics reused from primary vendor documentation already verified in this planning sequence.

### File List

- /Users/farshid/repos/unitill/docs/_bmad-output/implementation-artifacts/2-2-plugin-install-status-and-version-visibility.md
