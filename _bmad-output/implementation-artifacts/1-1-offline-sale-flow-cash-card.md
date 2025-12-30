# Story 1.1: Offline Sale Flow (Cash/Card)

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a cashier,  
I want to complete a sale with line items and totals even when offline,  
so that checkout never blocks.

## Acceptance Criteria

1. **Given** the POS is offline  
   **When** a cashier adds line items and tenders cash or card  
   **Then** the sale is recorded locally with correct totals and marked for sync  
   **And** the sale appears in the local journal/history immediately

## Tasks / Subtasks

- [x] Implement offline sale recording in the POS domain layer (AC: #1)
  - [x] Persist sale, totals, tender type (cash/card), and offline/sync status in local SQLite
  - [x] Reuse existing basket/sale models and persistence helpers if already present (avoid duplicating logic)
  - [x] Ensure a local journal/history entry is created immediately after tender
  - [x] Record plugin version/context per transaction for auditability
- [x] Wire UI/API flow for offline tender (AC: #1)
  - [x] Ensure scan/add item and tender flows work while offline without blocking UI
  - [x] Update UI to show sale completion and local journal entry
- [x] Sync queue integration (AC: #1)
  - [x] Mark sale as queued-for-sync with retry/backoff metadata
  - [x] Ensure background sync does not block checkout
- [x] Tests (AC: #1)
  - [x] Unit tests for sale persistence, totals calculation, and offline sync flags
  - [x] Handler-level test that offline tender creates a journal entry
  - [x] Regression coverage to ensure existing checkout flow remains intact (online/offline)
- [x] Follow-ups (Review)
  - [x] Add retry/backoff persistence for queued sales: increment sync_attempts, store next_attempt/backoff fields, and expose them for sync workers.
  - [x] Harden offline detection: accept explicit offline toggle or server-side reachability check instead of relying only on navigator.onLine/hidden input.
  - [x] Add index on sync queue fields (e.g., sync_status, sync_next_attempt_at) to avoid scans when processing queued sales.

## Dev Notes

- Stack/UX: Go + HTMX server-rendered UI; kiosk full-screen, non-blocking offline flows; touch-first, minimal steps. [Source: _bmad-output/architecture.md#Frontend Architecture] [Source: _bmad-output/ux-design-specification.md#Core User Experience]
- Data: POS local SQLite is the source of truth offline; plugin version should be logged per transaction for audit. [Source: _bmad-output/architecture.md#Data Architecture]
- Offline behavior: sales must queue for sync and never block checkout; retries with backoff; conflicts surfaced after reconnect. [Source: _bmad-output/architecture.md#Process Patterns] [Source: _bmad-output/epics.md#Story 1.1: Offline Sale Flow (Cash/Card)]
- POS structure: core domain in `internal/pos`, handlers in `internal/pages`, migrations under `internal/db/migrations`, templates in `web/ui`. [Source: _bmad-output/architecture-pos.md#Key Modules]
- Versions: Go 1.25; SQLite driver `modernc.org/sqlite` (reuse existing DB setup). [Source: _bmad-output/architecture-pos.md#Technology Stack]
- API/formatting rules: snake_case JSON, structured errors `{error: {code, message}}`, plural REST paths. [Source: _bmad-output/architecture.md#Implementation Patterns & Consistency Rules]
- Hardware/perf: low-end devices; avoid heavy UI blocking or long-running operations in checkout flow. [Source: _bmad-output/ux-design-specification.md#Low-end hardware UX]
- Security: do not persist sensitive card data in core POS; keep PCI scope inside payment plugins. [Source: _bmad-output/architecture.md#Auth & Security]
- No `project-context.md` was found. [Source: **/project-context.md]

### Project Structure Notes

- Align with `universal-till` repo layout and naming conventions (Go packages lower_snake, templates lower_snake.html, tests `*_test.go`). [Source: _bmad-output/architecture.md#Implementation Patterns & Consistency Rules]
- Keep kiosk/admin separation in templates; status/lock always reachable. [Source: _bmad-output/architecture.md#Structure Patterns]

### References

- Epic 1 story definition and acceptance criteria. [Source: _bmad-output/epics.md#Story 1.1: Offline Sale Flow (Cash/Card)]
- Offline-first, queue/sync, non-blocking checkout requirements. [Source: _bmad-output/prd.md#Functional Requirements] [Source: _bmad-output/architecture.md#Process Patterns]
- POS stack and module boundaries. [Source: _bmad-output/architecture-pos.md#Technology Stack] [Source: _bmad-output/architecture-pos.md#Key Modules]
- UX kiosk/offline status guidance. [Source: _bmad-output/ux-design-specification.md#Checkout (Kiosk, Offline-Safe)]

## Dev Agent Record

### Agent Model Used

GPT-5

### Debug Log References

- `go test ./...`
- `go test ./...` (universal-till; required unsandboxed run for IPC bind)
- `go test ./...` (universal-till; follow-ups)

### Completion Notes List

- Added offline sync fields and tender type storage on sales, plus audit payload includes active plugin versions.
- Folded sync fields into `internal/db/migrations/001_init.sql`; removed separate migration file per request.
- Added journal UI/endpoint and OOB refresh after tender; offline flag wired from UI/API and quick tender buttons restored.
- Tests added for offline sync/audit payload and journal rendering; `go test ./...` passes.
- Reviewed `~/repos/unitill/universal-till`: offline tender stores tender_type/offline/sync_status, audit payload includes plugin versions, and journal renders recent sales with OOB update after tender.
- Verified `go test ./...` passes in POS repo (unsandboxed run required for IPC bind).
- Added sync queue helpers (list queued sales, bump attempts) with tests, and indexed `sync_status` + `sync_next_attempt_at`.
- Added explicit offline override toggle that drives tender requests without relying only on navigator state.

### File List

- internal/db/migrations/001_init.sql
- internal/db/migrations/002_migration_x.sql (deleted)
- internal/data/pos_repo.go
- internal/data/pos_repo_sync_test.go
- internal/pos/sales.go
- internal/pos/sales_test.go
- internal/pos/offline_resilience_test.go
- internal/pos/performance_test.go
- internal/pos/shifts_test.go
- internal/pages/pos_api.go
- internal/pages/init.go
- internal/pages/journal_page.go
- internal/pages/journal_test.go
- internal/pages/ui_smoke_test.go
- internal/pages/pos_status_test.go
- internal/ui/journal.go
- web/ui/partials/journal.html
- web/ui/pages/index.html
- web/public/app.js
- web/public/app.css

### QA Results

- [ ] Not Reviewed
- [x] PASS
- [ ] WAIVED
- [ ] CONCERNS
- [ ] FAIL
- [ ] NOT RUN

#### Findings

- No blocking issues. Offline override toggle added (persists in localStorage), server honors explicit offline flag; sync queue gains index and repo helpers for attempts/next-attempt; tests cover queued listing/bump and offline/journal flows. `go test ./...` (POS repo) passes.
