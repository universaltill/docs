---
stepsCompleted: [1, 2]
inputDocuments:
  - "_bmad-output/prd.md"
  - "_bmad-output/architecture.md"
  - "_bmad-output/ux-design-specification.md"
---

# docs - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for docs, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

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

### NonFunctional Requirements

NFR1: Cashier-facing actions (scan→total; pay→receipt) feel instant on low-end/RPi-class hardware; background sync must not block POS UI.
NFR2: POS and installed plugins operate offline with durable local queue/cache and recovery; sync is resumable with conflict surfacing after reconnect.
NFR3: Plugin install/update requires signature/checksum validation and obeys trust policy (e.g., signed-only); revoked plugins are refused/flagged.
NFR4: Transport security via TLS; avoid storing secrets in plain files; keep PCI scope inside payment plugins, not core POS.
NFR5: Minimal PII in POS with locale-aware retention defaults; export/import preserves data integrity.
NFR6: Immutable journal of sales/voids/refunds logging plugin version per transaction; provide basic audit export for pilots.
NFR7: Compatibility across Linux (incl. Pi), macOS, Windows; tolerant of low-spec devices; plugins cached for offline use.
NFR8: Minimal operability/observability: health/status for plugin install/update and sync (queued/in-progress/failed/succeeded) buffered offline.

### Additional Requirements

- Architecture mandates Go + HTMX server-rendered UIs; POS local SQLite, marketplace/backoffice Postgres (SQLite acceptable for dev); REST/gRPC boundary and snake_case JSON.
- Plugin trust pipeline: signing/verification required, revocation honored, rollback/revert paths; layout treated as plugin with revert to last stable layout.
- Offline queue/sync with conflict review; retries with backoff; checkout must stay non-blocking even during sync or installs.
- Kiosk/touch-first UX: full-screen mode, large targets, on-screen keypad, explicit lock/exit always reachable; admin/operator surfaces separated from kiosk.
- Status/telemetry surfaces: clear offline/sync/install signals; plain-language errors with retry/rollback guidance; structured event naming (`domain.action`).
- Hardware handling: printer/scanner/drawer detection with graceful fallback and inline test/feedback; continue selling if devices absent.
- Side-load/install/update path supported for plugins when offline; caching required so plugins remain usable offline once installed.
- Naming/format/process patterns enforced (snake_case APIs, plural REST paths, structured errors `{error: {code, message}}`, plural DB tables, co-located tests).
- Security boundaries: avoid storing secrets in plain files; prefer OS keychain/secure storage where available; sandbox or least-privilege permissions for plugins.
- UI performance/resilience guidelines: minimal animation, small bundles for low-end hardware, calm offline “safe to sell” messaging; layout/plugin apply must not break checkout and must support rollback.

### FR Coverage Map

FR1: Epic 1 – Offline Checkout & Receipts
FR2: Epic 1 – Offline Checkout & Receipts
FR3: Epic 1 – Offline Checkout & Receipts
FR4: Epic 1 – Offline Checkout & Receipts
FR5: Epic 1 – Offline Checkout & Receipts
FR6: Epic 2 – Catalog, Import/Export & Inventory
FR7: Epic 2 – Catalog, Import/Export & Inventory
FR8: Epic 2 – Catalog, Import/Export & Inventory
FR9: Epic 3 – Localization & Currency
FR10: Epic 3 – Localization & Currency
FR11: Epic 4 – Hardware Setup & Reliability
FR12: Epic 1 – Offline Checkout & Receipts
FR13: Epic 5 – Marketplace Browse & Install
FR14: Epic 5 – Marketplace Browse & Install
FR15: Epic 5 – Marketplace Browse & Install
FR16: Epic 5 – Marketplace Browse & Install
FR17: Epic 5 – Marketplace Browse & Install
FR18: Epic 5 – Marketplace Browse & Install
FR19: Epic 5 – Marketplace Browse & Install
FR20: Epic 6 – Plugin Runtime & Permissions
FR21: Epic 6 – Plugin Runtime & Permissions
FR22: Epic 6 – Plugin Runtime & Permissions
FR23: Epic 7 – Publish & Remote Control (CLI/Backoffice)
FR24: Epic 7 – Publish & Remote Control (CLI/Backoffice)
FR25: Epic 7 – Publish & Remote Control (CLI/Backoffice)
FR26: Epic 6 – Plugin Runtime & Permissions
FR27: Epic 6 – Plugin Runtime & Permissions
FR28: Epic 6 – Plugin Runtime & Permissions
FR29: Epic 8 – Observability & Admin Control
FR30: Epic 8 – Observability & Admin Control
FR31: Epic 2 – Catalog, Import/Export & Inventory
FR32: Epic 8 – Observability & Admin Control
FR33: Epic 8 – Observability & Admin Control
Epic 9: Brownfield integration & compatibility (non-FR requirement)

## Epic List

### Epic 1: Offline Checkout & Receipts
Sell fully offline with clear sync control; fast scan/pay/print and non-blocking sync.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR12

### Epic 2: Catalog, Import/Export & Inventory
Create/edit products, import/export catalog, and track stock with offline reconciliation and data portability.
**FRs covered:** FR6, FR7, FR8, FR31

### Epic 3: Localization & Currency
Configure language and currency so prices/totals reflect locale.
**FRs covered:** FR9, FR10

### Epic 4: Hardware Setup & Reliability
Set up scanners/printers/cash drawers with graceful fallback.
**FRs covered:** FR11

### Epic 5: Marketplace Browse & Install
Connect to marketplace, browse plugins, install/update/rollback/uninstall, side-load offline, honor revocations.
**FRs covered:** FR13, FR14, FR15, FR16, FR17, FR18, FR19

### Epic 6: Plugin Runtime & Permissions
Expose plugin UIs with enforced permissions/consent; log plugin versions; enforce signatures/trust.
**FRs covered:** FR20, FR21, FR22, FR26, FR27, FR28

### Epic 7: Publish & Remote Control (CLI/Backoffice)
Publish plugins and remotely trigger install/update or push bundles from backoffice/CLI.
**FRs covered:** FR23, FR24, FR25

### Epic 8: Observability & Admin Control
Provide install/sync health/status and admin surfaces for endpoint/lang/currency/devices; system status panel.
**FRs covered:** FR29, FR30, FR32, FR33

### Epic 9: Brownfield Integration & Compatibility
Validate compatibility with existing POS + marketplace + plugins and document integration points.
**FRs covered:** None (brownfield requirement)

## Epic 1: Offline Checkout & Receipts

Sell fully offline with clear sync control; fast scan/pay/print and non-blocking sync.

### Story 1.1: Offline Sale Flow (Cash/Card)

As a cashier,
I want to complete a sale with line items and totals even when offline,
So that checkout never blocks.

**Acceptance Criteria:**

**Given** the POS is offline  
**When** a cashier adds line items and tenders cash or card  
**Then** the sale is recorded locally with correct totals and marked for sync  
**And** the sale appears in the local journal/history immediately

### Story 1.2: Fast Scan & Totals Update (Low-End Hardware)

As a cashier,
I want scanning to update items and totals instantly on low-spec devices,
So that checkout stays quick.

**Acceptance Criteria:**

**Given** a connected scanner or camera input  
**When** an item is scanned  
**Then** the line item is added and totals update within 200ms on a low-end/Pi-class reference device  
**And** duplicate scans adjust quantity correctly while offline

### Story 1.3: Offline Receipt Printing with Plugin Legal Text

As a cashier,
I want to print receipts offline with plugin-provided legal/tax text,
So that customers get compliant receipts even without network.

**Acceptance Criteria:**

**Given** the POS is offline  
**When** a sale is completed  
**Then** a receipt prints with line items, totals, and plugin-supplied legal/tax text  
**And** if the printer is unavailable, the system shows a non-blocking fallback with a reason and a retry option

### Story 1.4: Offline/Online Status & Sync Controls

As an operator,
I want to see offline/online state and control sync (pause/resume/retry),
So that I can manage connectivity safely.

**Acceptance Criteria:**

**Given** the POS is running  
**When** connectivity changes  
**Then** the status indicator updates to offline/online and shows queued count and last sync time  
**And** operators can pause/resume sync and retry sync without blocking checkout

### Story 1.5: Cash Drawer & Printer Triggers in Checkout

As a cashier,
I want to trigger the cash drawer and printer during checkout,
So that cash handling and receipts are reliable.

**Acceptance Criteria:**

**Given** a checkout is in progress  
**When** the cashier triggers the cash drawer and printer  
**Then** the drawer opens and the printer fires for the receipt  
**And** if devices are missing, the POS shows a non-blocking error with the missing device name and a suggested next step

## Epic 2: Catalog, Import/Export & Inventory

Create/edit products, import/export catalog, and track stock with offline reconciliation and data portability.

### Story 2.1: Product CRUD (SKU/Barcode/Price/Tax)

As a merchant,
I want to create and edit products with SKU/barcode, price, and tax flags,
So that items are ready for sale.

**Acceptance Criteria:**

**Given** a merchant creates or edits a product  
**When** SKU/barcode, price, and tax applicability are provided  
**Then** the product is saved with unique SKU/barcode validation  
**And** operations work offline and queue for sync

### Story 2.2: Catalog Import (CSV)

As a merchant,
I want to import a CSV catalog,
So that I can bulk load items.

**Acceptance Criteria:**

**Given** a CSV file with products  
**When** the file is uploaded for import  
**Then** rows are validated for required fields, SKU/barcode uniqueness, and errors are reported per row  
**And** a valid import works offline and queues for sync

### Story 2.3: Catalog Export (CSV)

As a merchant,
I want to export my catalog to CSV,
So that I can back up or migrate my data.

**Acceptance Criteria:**

**Given** an existing catalog  
**When** export is triggered  
**Then** a CSV is generated with SKU/barcode, price, and tax fields  
**And** export works offline and provides a downloadable file

### Story 2.4: Stock Tracking with Offline Reconcile

As a merchant,
I want stock to decrement on sale and reconcile after reconnect,
So that inventory stays accurate.

**Acceptance Criteria:**

**Given** inventory exists and sales occur  
**When** a sale is recorded offline  
**Then** stock decrements locally and queues for sync  
**And** on sync, inventory reconciles and flags conflicts; inventory view shows queued vs synced state

## Epic 3: Localization & Currency

Configure language and currency so prices/totals reflect locale.

### Story 3.1: Language Selection

As an operator,
I want to select the POS language,
So that UI strings match the chosen locale.

**Acceptance Criteria:**

**Given** language options are available  
**When** an operator selects a language  
**Then** UI strings update to that language and persist across sessions  
**And** if the selected language pack is missing, the POS shows a non-blocking error and keeps the prior language

### Story 3.2: Currency Configuration with Locale Formatting

As an operator,
I want to set currency and locale formatting,
So that prices and totals display correctly for my market.

**Acceptance Criteria:**

**Given** currency and locale settings  
**When** an operator selects currency/locale  
**Then** prices and totals display with correct currency symbol, decimal/grouping rules  
**And** if an invalid currency/locale is chosen, the POS shows a validation error and retains the previous setting

## Epic 4: Hardware Setup & Reliability

Set up scanners/printers/cash drawers with graceful fallback.

### Story 4.1: Device Detection & Configuration (Scanner/Printer/Drawer)

As an operator,
I want to detect and configure scanner, printer, and cash drawer devices,
So that the POS knows what’s connected.

**Acceptance Criteria:**

**Given** supported hardware is attached  
**When** device detection runs  
**Then** available devices/ports are listed and can be selected/configured per type  
**And** if no devices are found, the POS shows a non-blocking message and allows saving an empty configuration

### Story 4.2: Hardware Test & Fallback Handling

As an operator,
I want to test configured devices and see clear fallbacks if missing or failing,
So that checkout is not blocked.

**Acceptance Criteria:**

**Given** devices are configured  
**When** I run tests for scan/print/drawer  
**Then** each test returns success/failure with plain-language feedback  
**And** missing/failing devices surface non-blocking guidance that includes the device name and last known status, with state recorded for later use

## Epic 5: Marketplace Browse & Install

Connect to marketplace, browse plugins, install/update/rollback/uninstall, side-load offline, honor revocations.

### Story 5.1: Connect Marketplace Endpoint & Browse Catalog

As an operator,
I want to set the marketplace endpoint and browse available plugins,
So that I can discover plugins to install.

**Acceptance Criteria:**

**Given** a marketplace endpoint  
**When** the operator configures and saves it  
**Then** the POS lists available plugins with name, version, and description  
**And** if the endpoint is unreachable or invalid, the POS shows a validation error with the HTTP status or connection failure reason

### Story 5.2: Install Plugin with Signature/Checksum Verification & Caching

As an operator,
I want to install a plugin with integrity verification,
So that only validated plugins are cached for offline use.

**Acceptance Criteria:**

**Given** a selected plugin from the catalog  
**When** install is triggered  
**Then** signature/checksum is verified and the plugin is cached locally  
**And** success/failure status is displayed; offline caching ensures the plugin works when offline

### Story 5.3: Update Plugin

As an operator,
I want to update a plugin,
So that I can apply new versions safely.

**Acceptance Criteria:**

**Given** an installed plugin  
**When** update is triggered  
**Then** the new version is staged, applied, and the prior version retained until confirmed healthy  
**And** failure to apply leaves the prior version active with a visible error and retry option

### Story 5.4: Rollback Plugin

As an operator,
I want to roll back a plugin to a prior version,
So that I can recover from a bad update.

**Acceptance Criteria:**

**Given** a plugin with a prior cached version  
**When** rollback is triggered  
**Then** the plugin reverts to the prior version and status reflects the rollback  
**And** if the prior version is unavailable, the POS shows an error and leaves the current version active

### Story 5.5: Uninstall Plugin

As an operator,
I want to uninstall a plugin,
So that I can remove plugins that are no longer needed.

**Acceptance Criteria:**

**Given** an installed plugin  
**When** uninstall is triggered  
**Then** the plugin is removed and no longer available in the POS shell  
**And** if removal fails, the POS shows an error and keeps the plugin enabled until resolved

### Story 5.6: Offline Side-Load Install/Update

As an operator,
I want to apply an offline plugin package,
So that I can install or update without connectivity.

**Acceptance Criteria:**

**Given** an offline package is provided  
**When** the package is applied  
**Then** signature/checksum validation runs and the plugin is installed/updated  
**And** status is shown; plugin remains cached for offline use

### Story 5.7: Revocation Handling & Warnings

As an operator,
I want the POS to honor plugin revocation lists,
So that revoked plugins surface warnings and can be disabled or uninstalled.

**Acceptance Criteria:**

**Given** a revocation list from the marketplace  
**When** a plugin is revoked  
**Then** the POS surfaces a warning and allows disable/uninstall  
**And** further installs/updates of revoked plugins are refused

## Epic 6: Plugin Runtime & Permissions

Expose plugin UIs with enforced permissions/consent; log plugin versions; enforce signatures/trust.

### Story 6.1: Plugin UI Surfaces within POS Shell

As an operator,
I want installed plugins to expose their UI surfaces within the POS shell,
So that users can access plugin features seamlessly.

**Acceptance Criteria:**

**Given** a plugin with UI surfaces is installed  
**When** the plugin is enabled  
**Then** its UI surfaces appear in the POS shell in designated zones  
**And** if a plugin surface fails to load, the POS shows an inline error and keeps core checkout usable

### Story 6.2: Plugin Permissions & Consent Enforcement

As an operator,
I want the POS to enforce plugin-declared permissions with consent,
So that plugins only access approved capabilities.

**Acceptance Criteria:**

**Given** a plugin declares permissions/capabilities  
**When** the plugin is installed or enabled  
**Then** the POS prompts/records consent and enforces least privilege for those permissions  
**And** denied permissions prevent access with a message listing the blocked capability

### Story 6.3: Audit Logging of Plugin Version per Transaction

As an operator,
I want plugin version/context logged per transaction,
So that audits can trace which plugin version was involved.

**Acceptance Criteria:**

**Given** a transaction involves plugin logic  
**When** the transaction is recorded  
**Then** the plugin ID/version is logged with the transaction record  
**And** logs are durable offline and sync later

### Story 6.4: Signature/Trust Status Surface

As an operator,
I want to view signature/trust status for installed plugins,
So that I can see which plugins are verified or revoked.

**Acceptance Criteria:**

**Given** plugins are installed  
**When** viewing plugin details  
**Then** signature/verification and revocation state are displayed (e.g., signed/unsigned, revoked)  
**And** untrusted or revoked plugins are marked with a warning and an action (disable/uninstall)

## Epic 7: Publish & Remote Control (CLI/Backoffice)

Publish plugins and remotely trigger install/update or push bundles from backoffice/CLI.

### Story 7.1: Publish Plugin to Marketplace via CLI/Backoffice

As a publisher,
I want to publish a plugin to the configured marketplace,
So that it appears in the catalog for pilot installs.

**Acceptance Criteria:**

**Given** a plugin bundle with manifest and signature  
**When** the publisher runs the publish action (CLI/backoffice)  
**Then** the plugin is uploaded, validated, and listed in the marketplace catalog  
**And** validation errors include specific fields (e.g., missing manifest, invalid signature) and do not publish the plugin

### Story 7.2: Remote Trigger Install/Update from Backoffice

As an operator,
I want to trigger plugin install or update from backoffice/CLI,
So that tills pull/apply the change when online.

**Acceptance Criteria:**

**Given** an installed plugin and target tills  
**When** install/update is triggered remotely  
**Then** tills pull/apply when online, with status surfaced for success/failure  
**And** prior version remains until the update is confirmed healthy

### Story 7.3: Push Offline Bundle to Till

As an operator,
I want to push a plugin bundle directly to a till,
So that the till can install/update offline.

**Acceptance Criteria:**

**Given** a plugin bundle and target till  
**When** the bundle is pushed  
**Then** the till can install/update offline with signature/checksum validation  
**And** status is reported back when connectivity returns

## Epic 8: Observability & Admin Control

Provide install/sync health/status and admin surfaces for endpoint/lang/currency/devices; system status panel.

### Story 8.1: Plugin Install/Update Health & Status

As an operator,
I want to see health/status for plugin installs/updates,
So that I know whether actions succeeded or failed.

**Acceptance Criteria:**

**Given** plugin installs/updates occur  
**When** viewing status  
**Then** states like queued, in-progress, failed, succeeded are shown with timestamps  
**And** failure reasons are displayed without blocking checkout

### Story 8.2: Buffered Telemetry/Status for Offline Periods

As an operator,
I want telemetry/status buffered offline and sent when online,
So that I can see recent results after reconnect.

**Acceptance Criteria:**

**Given** the POS was offline during installs/sync  
**When** connectivity returns  
**Then** buffered telemetry/status is sent and last attempt/result is visible  
**And** checkout actions remain enabled while buffering telemetry/status

### Story 8.3: Admin Settings Surface - Marketplace Endpoint

As an operator,
I want an admin surface to configure the marketplace endpoint,
So that I can manage plugin discovery and installs.

**Acceptance Criteria:**

**Given** admin access  
**When** opening settings  
**Then** the marketplace endpoint can be viewed/edited and saved  
**And** if the endpoint is invalid/unreachable, the POS shows a validation error and keeps the previous value

### Story 8.4: Admin Settings Surface - Language/Currency

As an operator,
I want an admin surface to configure language and currency,
So that I can manage locale settings centrally.

**Acceptance Criteria:**

**Given** admin access  
**When** opening settings  
**Then** language and currency can be viewed/edited and saved  
**And** invalid values show a validation error and keep the previous settings

### Story 8.5: Admin Settings Surface - Devices

As an operator,
I want an admin surface to configure device settings,
So that I can manage scanners/printers/drawers in one place.

**Acceptance Criteria:**

**Given** admin access  
**When** opening settings  
**Then** device configurations can be viewed/edited and saved  
**And** if a device test fails, the POS shows a non-blocking error with the device name and preserves the last working config

### Story 8.6: System Status Panel (Online/Offline, Sync Backlog, Plugin State)

As an operator,
I want a system status panel,
So that I can see online/offline state, sync backlog, and plugin state summary.

**Acceptance Criteria:**

**Given** the POS is running  
**When** viewing system status  
**Then** online/offline state, sync backlog size, and plugin state summary are displayed  
**And** the panel renders within 1s on low-end hardware and does not block checkout

## Epic 9: Brownfield Integration & Compatibility

Ensure existing POS/marketplace/plugins remain compatible and integration points are verified.

### Story 9.1: Existing System Compatibility Audit

As an operator,
I want a documented compatibility audit against the existing POS, marketplace, and plugin repos,
So that we do not break current pilot workflows.

**Acceptance Criteria:**

**Given** access to the current POS, marketplace, and plugin repositories (`~/repos/unitill/universal-till`, `~/repos/unitill/ut-market-place`, `~/repos/unitill/ut-plugin-faq`)  
**When** compatibility audit runs  
**Then** a checklist of integration points is produced covering:
- Marketplace REST endpoints in `~/repos/unitill/ut-market-place/docs/openapi.yaml` (`/v1/auth/merchant-token`, `/v1/auth/refresh-token`, `/v1/auth/revoke-token`, `/v1/catalog/plugins`, `/v1/catalog/plugins/{plugin_id}`, `/v1/downloads/{plugin_id}/url`, `/v1/downloads/{plugin_id}/verify`)
- Marketplace gRPC services in `~/repos/unitill/ut-market-place/docs/marketplace.proto` (CatalogService.ListPlugins, DownloadService.IssueDownloadToken/AckDownload/GetRevocations, TelemetryService.ReportPluginStatus, AuthService.GenerateMerchantToken/RefreshToken/RevokeToken)
- POS ↔ plugin host gRPC contracts in `~/repos/unitill/ut-market-place/docs/plugin_host.proto` (PluginLifecycle.Start/Stop/HealthCheck, PluginEvents.OnSaleCompleted/InvokeHook) and `~/repos/unitill/universal-till/proto/plugin.proto` (PluginHost.Subscribe/Acknowledge)
- Plugin manifest schema and fields in `~/repos/unitill/ut-plugin-faq/src/manifest/manifest.json` and `~/repos/unitill/ut-plugin-faq/specs/001-multilingual-faq-page/contracts/manifest.md` (id, version, canonical_type, capabilities, permissions, locales, supported_architectures, min_host_version, resources)
- POS marketplace configuration in `~/repos/unitill/universal-till/docs/marketplace-config.md`
**And** any breaking changes are listed with proposed mitigations

### Story 9.2: Brownfield Integration Smoke Tests

As a developer,
I want a minimal smoke test plan that validates key brownfield integrations,
So that we can detect regressions early.

**Acceptance Criteria:**

**Given** the existing systems and the new changes in `~/repos/unitill/universal-till`, `~/repos/unitill/ut-market-place`, and `~/repos/unitill/ut-plugin-faq`  
**When** the smoke test plan is executed  
**Then** core flows are validated end-to-end using existing scripts/tests:
- Marketplace browse/install (e.g., `~/repos/unitill/universal-till/scripts/smoke-marketplace/` and `~/repos/unitill/universal-till/test_marketplace_integration.sh`)
- Offline sale flow (e.g., `~/repos/unitill/universal-till/scripts/smoke-offline-sale/`)
- Plugin run/render (e.g., `~/repos/unitill/ut-plugin-faq/tests/integration/faq_page_test.go`)
**And** failures include a repro with steps and logs plus rollback guidance

### Story 9.3: Compatibility Data Migration/Schema Notes

As a developer,
I want compatibility notes for any data model changes,
So that existing data and plugins can migrate safely.

**Acceptance Criteria:**

**Given** proposed schema or data model changes in POS (`~/repos/unitill/universal-till/internal/data/` or `~/repos/unitill/universal-till/docs/data-model.md`) or marketplace (`~/repos/unitill/ut-market-place/internal/repositories/migrate/sql/` or `~/repos/unitill/ut-market-place/internal/repositories/ent/schema/`)  
**When** changes are documented  
**Then** a migration/compatibility note exists for each change with the impacted tables and entities listed  
**And** it specifies fallback or rollback steps for brownfield pilots
