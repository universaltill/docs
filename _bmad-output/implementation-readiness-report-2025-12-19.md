---
stepsCompleted:
  - step-01-document-discovery
  - step-02-prd-analysis
  - step-03-epic-coverage-validation
  - step-04-ux-alignment
  - step-05-epic-quality-review
  - step-06-final-assessment
filesIncluded:
  - ~/repos/unitill/docs/_bmad-output/prd.md
  - ~/repos/unitill/docs/_bmad-output/architecture.md
  - ~/repos/unitill/docs/_bmad-output/architecture-patterns.md
  - ~/repos/unitill/docs/_bmad-output/architecture-plugin-faq.md
  - ~/repos/unitill/docs/_bmad-output/architecture-pos.md
  - ~/repos/unitill/docs/_bmad-output/architecture-marketplace.md
  - ~/repos/unitill/docs/_bmad-output/integration-architecture.md
  - ~/repos/unitill/docs/_bmad-output/analysis/research/technical-universal-till-platform-architecture-research-2025-12-17T10-42-42Z.md
  - ~/repos/unitill/docs/_bmad-output/epics.md
  - ~/repos/unitill/docs/_bmad-output/implementation-artifacts/stories/epic-1-plugin-install-flow.md
  - ~/repos/unitill/docs/_bmad-output/ux-design-specification.md
---
# Implementation Readiness Assessment Report

**Date:** 2025-12-19
**Project:** docs

## Document Inventory

### PRD
- ~/repos/unitill/docs/_bmad-output/prd.md

### Architecture
- ~/repos/unitill/docs/_bmad-output/architecture.md
- ~/repos/unitill/docs/_bmad-output/architecture-patterns.md
- ~/repos/unitill/docs/_bmad-output/architecture-plugin-faq.md
- ~/repos/unitill/docs/_bmad-output/architecture-pos.md
- ~/repos/unitill/docs/_bmad-output/architecture-marketplace.md
- ~/repos/unitill/docs/_bmad-output/integration-architecture.md
- ~/repos/unitill/docs/_bmad-output/analysis/research/technical-universal-till-platform-architecture-research-2025-12-17T10-42-42Z.md

### Epics & Stories
- ~/repos/unitill/docs/_bmad-output/epics.md
- ~/repos/unitill/docs/_bmad-output/implementation-artifacts/stories/epic-1-plugin-install-flow.md

### UX
- ~/repos/unitill/docs/_bmad-output/ux-design-specification.md

## PRD Analysis

### Functional Requirements

FR1: Cashiers can complete a sale (cash/card) fully offline, including line items and totals.
FR2: Cashiers can scan items (camera or scanner) and see prices/totals update instantly on low-end hardware.
FR3: Cashiers can print receipts offline; receipts include configurable legal/tax text supplied by installed plugins.
FR4: Operators can view offline/online status and sync state; the system queues sales/telemetry and syncs when online.
FR5: Operators can pause, resume, and retry sync, and see any conflicts flagged after reconnect.
FR6: Merchants can create/edit products with price, tax applicability, and SKU/barcode.
FR7: Merchants can import/export catalog data (e.g., CSV) for portability.
FR8: Merchants can see basic stock levels and decrement inventory on sale; if offline, adjustments queue and reconcile on sync.
FR9: Operators can select language and currency at setup; UI strings reflect the chosen language.
FR10: Prices and totals display in the configured currency with locale-aware formatting.
FR11: Operators can configure barcode scanners, receipt printers, and cash drawers; the system falls back gracefully if devices are absent.
FR12: Cashiers can trigger cash drawer and printer during checkout; if offline, printing still works with cached templates.
FR13: Operators can connect the POS to a marketplace endpoint and browse available plugins with metadata (name, version, description).
FR14: Operators can install a plugin from the marketplace; POS verifies integrity (signature/checksum) and caches it locally.
FR15: Operators can view plugin install status (success/error) and current version.
FR16: Operators can update or roll back a plugin version; updates are staged and confirmed; prior version retained until confirmed healthy.
FR17: Operators can uninstall or disable a plugin.
FR18: Operators can apply an offline plugin package (side-load) to install/update when connectivity is unavailable.
FR19: POS can honor plugin revocation lists from marketplace; revoked plugins surface warnings and can be disabled/uninstalled.
FR20: Installed plugins can expose UI surfaces (e.g., pages/panels) within the POS shell.
FR21: Plugins declare permissions/capabilities; POS prompts/records consent and enforces least privilege.
FR22: POS logs plugin version and relevant context with each transaction where the plugin participates.
FR23: Operators can use a CLI/backoffice flow to publish a plugin into the marketplace instance used by pilots.
FR24: Operators can trigger plugin install/update from CLI/backoffice, and tills can pull/apply when online.
FR25: Operators can push a plugin bundle to a till for offline install/update (side-load path).
FR26: Operators can configure trust/policy for plugins (e.g., signed-only).
FR27: POS verifies plugin signatures/checksums before install/update and refuses if validation fails.
FR28: Operators can view a basic security/trust status for installed plugins (e.g., signed/unsigned, revocation state).
FR29: Operators can see minimal health/status signals for plugin install/updates (queued, in progress, failed, completed).
FR30: POS buffers telemetry/status while offline and sends when online; operators can see last sync attempt/result.
FR31: Operators can export/import core data (catalog, sales, plugins list/versions) to support migration and backups.
FR32: Operators can configure marketplace endpoint, language/currency, and device settings from an admin surface.
FR33: Operators can see a system status panel (online/offline, sync backlog size, plugin state summary).
Total FRs: 33

### Non-Functional Requirements

NFR1: Cashier-facing actions (scan to total; pay to receipt) feel instant on low-end/RPi-class hardware; background sync must not block POS UI.
NFR2: POS and installed plugins operate offline; durable local queue/cache with recovery; sync is resumable with conflict surfacing after reconnect.
NFR3: Receipt printing and core checkout functions must work offline.
NFR4: Plugin install/update requires signature/checksum validation and obeys trust policy (e.g., signed-only).
NFR5: TLS for marketplace calls; refuse/flag revoked plugins.
NFR6: No storing secrets in plain files; keep PCI scope inside payment plugins (core avoids sensitive payment data).
NFR7: Minimal PII in POS; locale-aware retention defaults; export/import preserves data integrity.
NFR8: Immutable journal of sales/voids/refunds; log plugin version per transaction; provide a basic audit export for pilots.
NFR9: Runs on Linux (incl. Pi), macOS, Windows; tolerant of low-spec devices; plugins cached for offline use.
NFR10: Minimal health/status signals for plugin install/update and sync (queued/in-progress/failed/succeeded); buffer offline, send when online.
Total NFRs: 10

### Additional Requirements

- Time-to-first-sale: cashier can complete first sale in <5 minutes from install (setup -> first transaction).
- Offline completion rate >=95% of sales fully offline (cash + card), with receipts and barcode scanning.
- Primary targets: Linux (including Raspberry Pi), macOS, Windows; secondary Android/iOS later via a shared Go business library.
- Marketplace/CLI-driven plugin lifecycle must operate with intermittent connectivity; plugins cached locally.
- Updates should not break offline operation (safe rollback or deferred apply).

### PRD Completeness Assessment

The PRD includes explicit, numbered FRs and a dedicated NFR section, plus domain/compliance constraints and measurable success criteria. Completeness risk is low, but several constraints (success metrics, platform targets, update strategy) live outside the FR/NFR lists and will need explicit coverage in epics and stories.

## Epic Coverage Validation

### Coverage Matrix

| FR Number | PRD Requirement | Epic Coverage | Status |
| --- | --- | --- | --- |
| FR1 | Cashiers can complete a sale (cash/card) fully offline, including line items and totals. | Epic 1 – Offline Checkout & Receipts | ✓ Covered |
| FR2 | Cashiers can scan items (camera or scanner) and see prices/totals update instantly on low-end hardware. | Epic 1 – Offline Checkout & Receipts | ✓ Covered |
| FR3 | Cashiers can print receipts offline; receipts include configurable legal/tax text supplied by installed plugins. | Epic 1 – Offline Checkout & Receipts | ✓ Covered |
| FR4 | Operators can view offline/online status and sync state; the system queues sales/telemetry and syncs when online. | Epic 1 – Offline Checkout & Receipts | ✓ Covered |
| FR5 | Operators can pause, resume, and retry sync, and see any conflicts flagged after reconnect. | Epic 1 – Offline Checkout & Receipts | ✓ Covered |
| FR6 | Merchants can create/edit products with price, tax applicability, and SKU/barcode. | Epic 2 – Catalog, Import/Export & Inventory | ✓ Covered |
| FR7 | Merchants can import/export catalog data (e.g., CSV) for portability. | Epic 2 – Catalog, Import/Export & Inventory | ✓ Covered |
| FR8 | Merchants can see basic stock levels and decrement inventory on sale; if offline, adjustments queue and reconcile on sync. | Epic 2 – Catalog, Import/Export & Inventory | ✓ Covered |
| FR9 | Operators can select language and currency at setup; UI strings reflect the chosen language. | Epic 3 – Localization & Currency | ✓ Covered |
| FR10 | Prices and totals display in the configured currency with locale-aware formatting. | Epic 3 – Localization & Currency | ✓ Covered |
| FR11 | Operators can configure barcode scanners, receipt printers, and cash drawers; the system falls back gracefully if devices are absent. | Epic 4 – Hardware Setup & Reliability | ✓ Covered |
| FR12 | Cashiers can trigger cash drawer and printer during checkout; if offline, printing still works with cached templates. | Epic 1 – Offline Checkout & Receipts | ✓ Covered |
| FR13 | Operators can connect the POS to a marketplace endpoint and browse available plugins with metadata (name, version, description). | Epic 5 – Marketplace Browse & Install | ✓ Covered |
| FR14 | Operators can install a plugin from the marketplace; POS verifies integrity (signature/checksum) and caches it locally. | Epic 5 – Marketplace Browse & Install | ✓ Covered |
| FR15 | Operators can view plugin install status (success/error) and current version. | Epic 5 – Marketplace Browse & Install | ✓ Covered |
| FR16 | Operators can update or roll back a plugin version; updates are staged and confirmed; prior version retained until confirmed healthy. | Epic 5 – Marketplace Browse & Install | ✓ Covered |
| FR17 | Operators can uninstall or disable a plugin. | Epic 5 – Marketplace Browse & Install | ✓ Covered |
| FR18 | Operators can apply an offline plugin package (side-load) to install/update when connectivity is unavailable. | Epic 5 – Marketplace Browse & Install | ✓ Covered |
| FR19 | POS can honor plugin revocation lists from marketplace; revoked plugins surface warnings and can be disabled/uninstalled. | Epic 5 – Marketplace Browse & Install | ✓ Covered |
| FR20 | Installed plugins can expose UI surfaces (e.g., pages/panels) within the POS shell. | Epic 6 – Plugin Runtime & Permissions | ✓ Covered |
| FR21 | Plugins declare permissions/capabilities; POS prompts/records consent and enforces least privilege. | Epic 6 – Plugin Runtime & Permissions | ✓ Covered |
| FR22 | POS logs plugin version and relevant context with each transaction where the plugin participates. | Epic 6 – Plugin Runtime & Permissions | ✓ Covered |
| FR23 | Operators can use a CLI/backoffice flow to publish a plugin into the marketplace instance used by pilots. | Epic 7 – Publish & Remote Control (CLI/Backoffice) | ✓ Covered |
| FR24 | Operators can trigger plugin install/update from CLI/backoffice, and tills can pull/apply when online. | Epic 7 – Publish & Remote Control (CLI/Backoffice) | ✓ Covered |
| FR25 | Operators can push a plugin bundle to a till for offline install/update (side-load path). | Epic 7 – Publish & Remote Control (CLI/Backoffice) | ✓ Covered |
| FR26 | Operators can configure trust/policy for plugins (e.g., signed-only). | Epic 6 – Plugin Runtime & Permissions | ✓ Covered |
| FR27 | POS verifies plugin signatures/checksums before install/update and refuses if validation fails. | Epic 6 – Plugin Runtime & Permissions | ✓ Covered |
| FR28 | Operators can view a basic security/trust status for installed plugins (e.g., signed/unsigned, revocation state). | Epic 6 – Plugin Runtime & Permissions | ✓ Covered |
| FR29 | Operators can see minimal health/status signals for plugin install/updates (queued, in progress, failed, completed). | Epic 8 – Observability & Admin Control | ✓ Covered |
| FR30 | POS buffers telemetry/status while offline and sends when online; operators can see last sync attempt/result. | Epic 8 – Observability & Admin Control | ✓ Covered |
| FR31 | Operators can export/import core data (catalog, sales, plugins list/versions) to support migration and backups. | Epic 2 – Catalog, Import/Export & Inventory | ✓ Covered |
| FR32 | Operators can configure marketplace endpoint, language/currency, and device settings from an admin surface. | Epic 8 – Observability & Admin Control | ✓ Covered |
| FR33 | Operators can see a system status panel (online/offline, sync backlog size, plugin state summary). | Epic 8 – Observability & Admin Control | ✓ Covered |

### Missing Requirements

None identified. All PRD FRs are mapped in the epics document.

### Coverage Statistics

- Total PRD FRs: 33
- FRs covered in epics: 33
- Coverage percentage: 100%

## UX Alignment Assessment

### UX Document Status

Found: ~/repos/unitill/docs/_bmad-output/ux-design-specification.md

### Alignment Issues

- UX specifies on-screen keypad, explicit lock/exit, and auto-lock/auto-logout flows for shared kiosks; these UX requirements are not explicitly called out in the PRD.
- UX details layout-as-plugin behaviors (layout selector, apply/revert UX) that are not explicitly enumerated in the PRD FR list.
- Architecture mentions customer display and receipt share (print/email/SMS/QR) in requirements overview; UX doc does not include corresponding UI flows.

### Warnings

- None critical; UX and architecture are largely consistent, but the PRD should confirm the kiosk lock/auto-logout and layout-plugin UX requirements if they are mandatory for MVP.

## Epic Quality Review

### 🔴 Critical Violations

None found. Epics are user-value oriented and no forward dependencies are explicitly referenced.

### 🟠 Major Issues

None identified after updates:
- Brownfield integration epic now added (Epic 9) with explicit POS + marketplace + plugin coverage.
- Story 5.3 split into update/rollback/uninstall.
- Story 8.3 split into endpoint, language/currency, and devices.

### 🟡 Minor Concerns

- Remaining stories may still need explicit error paths or measurable criteria where wording is subjective (e.g., "clear" or "readable"). Spot-check these during story refinement.

## Summary and Recommendations

### Overall Readiness Status

READY (with minor refinements recommended)

### Critical Issues Requiring Immediate Action

- None.

### Recommended Next Steps

1. Final spot-check for residual subjective AC language and add measurable thresholds where needed.
2. Ensure Epic 9 outputs (audit checklist, smoke plan, migration notes) are explicitly produced as artifacts.
3. Confirm the smoke test scripts referenced in Epic 9 remain current as repos evolve.

### Final Note

This assessment identified prior gaps that have been addressed; proceed to implementation after minor AC refinements.

**Assessor:** Winston (Architect)  
**Date:** 2025-12-19
