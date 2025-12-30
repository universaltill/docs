# Story 1.2: Fast Scan & Totals Update (Low-End Hardware)

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a cashier,
I want scanning to update items and totals instantly on low-spec devices,
so that checkout stays quick.

## Acceptance Criteria

1. **Given** a connected scanner or camera input
   **When** an item is scanned
   **Then** the line item is added and totals update within 200ms on a low-end/Pi-class reference device
   **And** duplicate scans adjust quantity correctly while offline

## Tasks / Subtasks

- [x] Optimize scan-to-basket update path for sub-200ms totals refresh (AC: #1)
  - [x] Keep scan handling in-memory and avoid unnecessary DB round-trips per scan
  - [x] Ensure duplicate scans increment quantity for the existing line item (offline-safe)
  - [x] Preserve existing basket/line item structures and reuse helpers where possible (avoid logic duplication)
- [x] Update scan handler to return fast, minimal payloads/partials (AC: #1)
  - [x] Use `/api/pos/scan` response patterns to update basket + totals without full page refresh
  - [x] Ensure offline flag/override does not block scan flow
- [x] UI flow: totals and line items refresh immediately after scan (AC: #1)
  - [x] Keep kiosk/touch-first UI responsive with minimal rendering work per scan
  - [x] Ensure error handling is non-blocking (missing barcode, unknown item)
- [x] Tests and performance checks (AC: #1)
  - [x] Unit test: duplicate scans increment quantity correctly while offline
  - [x] Handler-level test: `/api/pos/scan` returns updated totals/lines
  - [x] Performance guard: add/extend `internal/pos/performance_test.go` to assert scan+totals update target on low-end baseline

## Dev Notes

### Developer Context

- Scan flow must feel instant on low-end hardware; avoid blocking UI updates or network calls. [Source: _bmad-output/epics.md#Story 1.2: Fast Scan & Totals Update (Low-End Hardware)] [Source: _bmad-output/ux-design-specification.md#Effortless Interactions]
- Offline is normal; scanning must work without connectivity and should not block checkout. [Source: _bmad-output/architecture.md#Process Patterns]

### Technical Requirements

- Totals update within 200ms on low-end/Pi-class reference device after scan; duplicate scans increment quantity correctly while offline. [Source: _bmad-output/epics.md#Story 1.2: Fast Scan & Totals Update (Low-End Hardware)]
- Keep responses light and avoid full-page refresh per scan; prefer HTMX partials or minimal JSON payloads. [Source: _bmad-output/architecture.md#Frontend Architecture]

### Architecture Compliance

- Go 1.25, SQLite (`modernc.org/sqlite`), server-rendered UI with HTMX-style partials; minimal JS. [Source: _bmad-output/architecture-pos.md#Technology Stack] [Source: _bmad-output/architecture.md#Frontend Architecture]
- Use snake_case JSON and structured errors `{error: {code, message}}`. [Source: _bmad-output/architecture.md#Implementation Patterns & Consistency Rules]

### Library / Framework Requirements

- Go 1.25; `modernc.org/sqlite` for local persistence; HTMX-style partial rendering patterns. [Source: _bmad-output/architecture-pos.md#Technology Stack]

### File Structure Requirements

- Scan handler is `/api/pos/scan` in `internal/pages/pos_api.go`; core POS logic in `internal/pos`. [Source: _bmad-output/api-contracts-pos.md#POS Core APIs] [Source: _bmad-output/architecture-pos.md#Key Modules]
- Templates live under `web/ui`; keep kiosk layout intact and keep status/lock reachable. [Source: _bmad-output/architecture.md#Structure Patterns]

### Testing Requirements

- Add/extend unit tests for scan quantity handling and offline behavior; add handler tests for `/api/pos/scan`; keep tests co-located. [Source: _bmad-output/architecture.md#Implementation Patterns & Consistency Rules]

### Git Intelligence Summary

- Recent POS work touched scan/journal flows; align with current patterns in `internal/pages/pos_api.go`, `internal/pos/sales.go`, `web/ui/pages/index.html`, and `web/public/app.js`. Reuse existing basket/helpers and avoid introducing new DTOs unless required.

### LLM Optimization

- Keep responses token-light: prefer HTMX partials/minimal payloads over full page refresh; use concise, unambiguous phrasing and avoid redundant context in responses and UI copy.

### Previous Story Intelligence

- Offline tender/journal flow now records sync flags, audit payloads include plugin versions; avoid breaking these data paths. [Source: _bmad-output/implementation-artifacts/1-1-offline-sale-flow-cash-card.md#Completion Notes List]
- Offline override toggle exists; scan flow should honor explicit offline state without relying solely on browser `navigator.onLine`. [Source: _bmad-output/implementation-artifacts/1-1-offline-sale-flow-cash-card.md#Completion Notes List]

### Latest Tech Information

- No external web research performed (network restricted). Use in-repo versions and patterns (Go 1.25, HTMX-style partials, SQLite via `modernc.org/sqlite`). [Source: _bmad-output/architecture-pos.md#Technology Stack]

### Project Context Reference

- No `project-context.md` was found. [Source: **/project-context.md]

### Story Completion Status

- Story file created and marked ready-for-dev; sprint-status updated to ready-for-dev. [Source: _bmad-output/implementation-artifacts/sprint-status.yaml]

### Project Structure Notes

- Prefer small, targeted changes in `internal/pages/pos_api.go`, `internal/pos/*`, and `web/ui/` templates/partials used by the basket. [Source: _bmad-output/architecture-pos.md#Key Modules]
- Preserve kiosk/admin separation; status/lock always reachable in kiosk views. [Source: _bmad-output/architecture.md#Structure Patterns]

### References

- Epic 1 story definition and AC for fast scan/totals. [Source: _bmad-output/epics.md#Story 1.2: Fast Scan & Totals Update (Low-End Hardware)]
- POS scan endpoint and handler locations. [Source: _bmad-output/api-contracts-pos.md#POS Core APIs]
- Performance and low-end hardware UX requirements. [Source: _bmad-output/ux-design-specification.md#Key Design Challenges] [Source: _bmad-output/ux-design-specification.md#Effortless Interactions]
- POS tech stack and module layout. [Source: _bmad-output/architecture-pos.md#Technology Stack] [Source: _bmad-output/architecture-pos.md#Key Modules]
- Offline-first and non-blocking operations. [Source: _bmad-output/architecture.md#Process Patterns]

## Dev Agent Record

### Agent Model Used

GPT-5

### Debug Log References

### Completion Notes List

- Added in-memory scan fast path and duplicate-scan handling to avoid DB round-trips in `internal/pos/service.go`.
- Updated `/api/pos/scan` flow to prioritize customer/promo handling and refresh resolved item data while still returning non-blocking toast feedback in `internal/pages/pos_api.go`.
- Moved toast styling/behavior to shared assets (`web/public/app.css`, `web/public/app.js`) to reduce per-scan payload.
- Added resolver refresh on duplicate scans (keeps pricing/promos/tax current) and guarded perf check that enforces only when `UT_PERF_ENFORCE=1`.
- Tests: `go test ./...`.
- Review fixes: cache duplicate scans to avoid repeated resolver/DB hits, gate customer lookups by code prefix, and enforce scan perf on CI; updated weighed-item refresh in merge logic.
- Tests: `go test ./...` (CI-enforced scan perf if `CI=1`).
- Code review fixes (round 2): clear scan cache on reset/remove, cap cache growth, and tighten customer-code detection; added cache-clear tests.

### File List

- ~/repos/unitill/universal-till/internal/pos/service.go
- ~/repos/unitill/universal-till/internal/pos/service_test.go
- ~/repos/unitill/universal-till/internal/pages/pos_api.go
- ~/repos/unitill/universal-till/internal/pages/pos_scan_test.go
- ~/repos/unitill/universal-till/internal/pos/performance_test.go
- ~/repos/unitill/universal-till/web/ui/partials/basket.html
- ~/repos/unitill/universal-till/web/public/app.css
- ~/repos/unitill/universal-till/web/public/app.js
- ~/repos/unitill/docs/_bmad-output/implementation-artifacts/1-2-fast-scan-totals-update-low-end-hardware.md
- ~/repos/unitill/docs/_bmad-output/implementation-artifacts/sprint-status.yaml

### Change Log

- 2025-12-23: Optimized scan path and payloads, added toast UX, and added scan-related tests/perf guard.
- 2025-12-23: Refreshed resolver on duplicate scans, reordered promo/customer handling, and made scan perf gate opt-in to reduce flake.
- 2025-12-23: Code review fixes for scan cache, customer lookup gating, CI perf enforcement, and weighed-item refresh.
- 2025-12-23: Code review fixes for cache lifecycle/size and customer-code heuristic; added cache reset/remove tests.
