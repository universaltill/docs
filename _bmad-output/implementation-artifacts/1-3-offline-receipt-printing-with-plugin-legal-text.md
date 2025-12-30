# Story 1.3: Offline Receipt Printing with Plugin Legal Text

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a cashier,
I want to print receipts offline with plugin-provided legal/tax text,
so that customers get compliant receipts even without network.

## Acceptance Criteria

1. **Given** the POS is offline
   **When** a sale is completed
   **Then** a receipt prints with line items, totals, and plugin-supplied legal/tax text
2. **And** if the printer is unavailable, the system shows a non-blocking fallback with a reason and a retry option

## Tasks / Subtasks

- [x] Integrate plugin legal/tax text into receipt generation (AC: #1)
  - [x] Reuse existing plugin hooks/metadata to fetch receipt legal text without introducing new storage (use `internal/data/plugin_repo.go` read paths)
  - [x] Ensure plugin legal text is available offline via cached plugin data and includes plugin version context
  - [x] Merge legal text into receipt output deterministically (per plugin order or configured priority)
- [x] Update receipt printing flow and non-blocking fallback UX (AC: #1, #2)
  - [x] Ensure receipt printing uses offline-safe templates and includes legal text
  - [x] Return a non-blocking response with clear reason + retry action when printer is missing or fails
  - [x] Keep kiosk flow responsive; status/lock remains reachable
- [x] Tests for receipt content and fallback behavior (AC: #1, #2)
  - [x] Unit test receipt assembly includes plugin legal text and handles no-plugin case
  - [x] Handler test for receipt print path (e.g., `POST /api/inventory/receipt`) covering offline + failure fallback
  - [x] UI/UX test or snapshot for non-blocking error + retry copy

## Dev Notes

### Developer Context

- Receipt printing must work offline and never block checkout; receipts include plugin-supplied legal/tax text. [Source: _bmad-output/epics.md#Story 1.3: Offline Receipt Printing with Plugin Legal Text] [Source: _bmad-output/prd.md#Functional Requirements]
- Hardware is optional; missing printers must degrade gracefully with plain-language guidance and retry. [Source: _bmad-output/epics.md#Story 1.3: Offline Receipt Printing with Plugin Legal Text] [Source: _bmad-output/ux-design-specification.md#Effortless Interactions]

### Technical Requirements

- Receipt content must include line items, totals, and plugin legal/tax text; plugin hooks and cached plugin data must work offline. [Source: _bmad-output/prd.md#Functional Requirements] [Source: _bmad-output/data-models-pos.md#Schema Summary (tables)]
- Receipt flow must remain non-blocking and responsive; pay → receipt should feel instant on low-end devices. [Source: _bmad-output/prd.md#Non-Functional Requirements (MVP Focused)] [Source: _bmad-output/ux-design-specification.md#Core User Experience]
- Use structured errors and snake_case JSON for API responses when applicable. [Source: _bmad-output/architecture.md#Implementation Patterns & Consistency Rules]

### Architecture Compliance

- Go 1.25, SQLite (`modernc.org/sqlite`), server-rendered UI with HTMX-style partials; minimal JS. [Source: _bmad-output/architecture-pos.md#Technology Stack]
- Offline-first and non-blocking operations with retry guidance; status/lock always reachable in kiosk views. [Source: _bmad-output/architecture.md#Process Patterns]

### Library / Framework Requirements

- Go 1.25; `modernc.org/sqlite`; HTMX-style partial rendering helpers. [Source: _bmad-output/architecture-pos.md#Technology Stack]

### File Structure Requirements

- Receipt endpoint is `POST /api/inventory/receipt` in `internal/pages/inventory_api.go`. [Source: _bmad-output/api-contracts-pos.md#Inventory APIs]
- Core POS domain logic lives under `internal/pos`; plugin lifecycle/hooks under `internal/plugins`. [Source: _bmad-output/architecture-pos.md#Key Modules]
- Templates and kiosk UI live under `web/ui`; keep status/lock controls reachable. [Source: _bmad-output/architecture.md#Structure Patterns]
 - Plugin data access must go through repo methods in `internal/data/plugin_repo.go` and read existing tables (`plugin_entries`, `plugin_hooks`, `plugin_settings`). [Source: ~/repos/unitill/universal-till/.specify/memory/constitution.md#Repository-Owned SQL] [Source: _bmad-output/data-models-pos.md#Schema Summary (tables)]

### Testing Requirements

- Co-locate Go tests (`*_test.go`) and run `go test ./...` for coverage. [Source: _bmad-output/architecture.md#Structure Patterns] [Source: _bmad-output/architecture-pos.md#Testing]

### Git Intelligence Summary

- Recent commits in this repo are documentation-only; no new POS code patterns surfaced here. [Source: git log]

### LLM Optimization

- Reuse existing plugin hook/data patterns; avoid inventing new receipt storage.
- Keep changes localized to receipt generation + inventory receipt handler to reduce regression risk.

### Integration Point (Concrete)

- Source plugin legal/tax text via existing plugin repo reads (entries/hooks/settings) and pass into receipt render/print path; do not add new tables or write paths for this story. [Source: _bmad-output/data-models-pos.md#Schema Summary (tables)] [Source: ~/repos/unitill/universal-till/.specify/memory/constitution.md#Repository-Owned SQL]

### Out of Scope

- New plugin storage tables or schema changes.
- New plugin permission models or signature flows.
- UI redesigns outside receipt content and non-blocking error copy.

### Previous Story Intelligence

- Offline override exists; do not rely solely on browser online state when deciding receipt flow. [Source: _bmad-output/implementation-artifacts/1-2-fast-scan-totals-update-low-end-hardware.md#Previous Story Intelligence]
- Non-blocking toasts/status patterns were introduced recently; reuse those for printer failure messaging. [Source: _bmad-output/implementation-artifacts/1-2-fast-scan-totals-update-low-end-hardware.md#Dev Notes]
- Offline tender/journal flow logs plugin version; align receipt legal text with the installed plugin version used at sale time. [Source: _bmad-output/implementation-artifacts/1-2-fast-scan-totals-update-low-end-hardware.md#Previous Story Intelligence]

### Latest Tech Information

- No external web research performed (network restricted). Use in-repo versions/patterns. [Source: _bmad-output/architecture-pos.md#Technology Stack]

### Project Context Reference

- No `project-context.md` was found. [Source: **/project-context.md]

### Story Completion Status

- Story file created and marked ready-for-dev; sprint-status updated to ready-for-dev. [Source: _bmad-output/implementation-artifacts/sprint-status.yaml]

### Project Structure Notes

- Prefer small, targeted changes in `internal/pages/inventory_api.go`, `internal/pos/*` receipt helpers, and `web/ui` receipt templates/partials. [Source: _bmad-output/architecture-pos.md#Key Modules]
- Preserve kiosk/admin separation and keep status/lock visible in kiosk UI. [Source: _bmad-output/architecture.md#Structure Patterns]

### References

- Epic 1 story definition and AC for offline receipt printing with plugin legal text. [Source: _bmad-output/epics.md#Story 1.3: Offline Receipt Printing with Plugin Legal Text]
- PRD requirements for offline receipts, plugin legal text, and device fallback. [Source: _bmad-output/prd.md#Functional Requirements]
- POS tech stack and modules. [Source: _bmad-output/architecture-pos.md#Technology Stack] [Source: _bmad-output/architecture-pos.md#Key Modules]
- Offline-first, non-blocking process patterns and structure rules. [Source: _bmad-output/architecture.md#Process Patterns] [Source: _bmad-output/architecture.md#Structure Patterns]
- Receipt/print UX requirements and fallback guidance. [Source: _bmad-output/ux-design-specification.md#Effortless Interactions]

## Dev Agent Record

### Agent Model Used

GPT-5

### Debug Log References

### Implementation Plan

- Load receipt-template entries from plugin metadata and sort deterministically by priority, keeping logic offline-safe.
- Render plugin legal blocks with version context and add a non-blocking printer warning with retry action.
- Remove external receipt font dependency to keep templates offline-safe.

### Completion Notes List

- Added receipt template reads and printer-availability checks via `internal/data/plugin_repo.go`.
- Rendered plugin legal blocks with version context and offline-safe receipt template updates.
- Added non-blocking printer fallback with retry action in receipt UI.
- Tests: `go test ./...`.

### File List

- internal/data/plugin_repo.go
- internal/data/pos_repo.go
- internal/pages/pos_api.go
- internal/pages/receipt_test.go
- internal/pages/ui_smoke_test.go
- web/locales/en.json
- web/locales/fa.json
- web/ui/partials/receipt.html

### Change Log

- 2025-12-24: Integrated plugin legal text into receipts, added printer fallback UI, and added tests.
