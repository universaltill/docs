---
stepsCompleted: [1, 2, 3]
inputDocuments:
  - "_bmad-output/planning-artifacts/prd.md"
  - "_bmad-output/planning-artifacts/ux-design-specification.md"
  - "_bmad-output/planning-artifacts/architecture.md"
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

NFR1: Cashier-facing actions (scan to total, pay to receipt) feel instant on low-end/RPi-class hardware; background sync must not block POS UI.
NFR2: POS and installed plugins operate offline with a durable local queue/cache; sync is resumable with conflict surfacing after reconnect.
NFR3: Receipt printing and core checkout functions must work offline.
NFR4: Plugin install/update requires signature/checksum validation and obeys trust policy; TLS for marketplace calls; revoked plugins are refused/flagged; secrets are not stored in plain files; PCI scope remains inside payment plugins.
NFR5: Minimal PII in POS; locale-aware retention defaults; export/import preserves data integrity.
NFR6: Immutable journal of sales/voids/refunds; log plugin version per transaction; provide a basic audit export for pilots.
NFR7: Runs on Linux (incl. Pi), macOS, Windows; tolerant of low-spec devices; plugins cached for offline use; minimal health/status signals for install/update/sync buffered offline and sent when online.

### Additional Requirements

- Use existing brownfield repos; no new starter template is introduced.
- Go server-rendered HTML with HTMX and minimal JS for low-end hardware performance.
- POS local storage uses SQLite; marketplace uses PostgreSQL 18.x.
- Plugin contracts are versioned; plugins never access internal DB directly and must use host APIs.
- Offline-first guarantee: checkout never blocked by network; background sync non-blocking with conflict review.
- Plugin trust model: signed bundles, verification, revocation enforcement, least-privilege permissions; secrets not stored in plain files.
- i18n enforced via locale files only; no hardcoded UI strings.
- Repository-owned SQL with migrations under `internal/db/migrations/`.
- API response format `{data, error}` with snake_case JSON fields and versioned contracts.
- Install/status lifecycle uses standardized states: requested, downloading, installing, active, failed.
- Touch-first, full-screen kiosk UI with large touch targets (44px+).
- Clear offline/sync status chips with “safe to sell offline” messaging; non-blocking flow.
- Explicit lock/exit controls and kiosk/admin separation.
- Trust/signature/revocation cues in UI; plain-language errors with retry/rollback.
- Minimal animation; high-contrast accessible design targeting WCAG AA.
- Prioritize marketplace implementation and its requirements first to enable POS plugin testing early.

### FR Coverage Map

FR1: Epic 3 - Offline checkout and tender flow
FR2: Epic 3 - Scan and fast totals
FR3: Epic 3 - Receipt printing with plugin hooks
FR4: Epic 4 - Offline/online status and sync state
FR5: Epic 4 - Sync control and conflict handling
FR6: Epic 3 - Catalog create/edit
FR7: Epic 3 - Catalog import/export
FR8: Epic 3 - Stock levels and offline reconciliation
FR9: Epic 4 - Language/currency setup
FR10: Epic 3 - Locale-aware currency display
FR11: Epic 3 - Hardware configuration and fallback
FR12: Epic 3 - Cash drawer/printer triggers offline
FR13: Epic 1 - Marketplace browsing and metadata
FR14: Epic 2 - POS install with integrity verification
FR15: Epic 2 - POS install status and version visibility
FR16: Epic 2 - Update/rollback flows
FR17: Epic 2 - Uninstall/disable plugins
FR18: Epic 2 - Side-load offline packages
FR19: Epic 1 - Revocation list surfaced to POS
FR20: Epic 2 - Plugin UI surfaces inside POS
FR21: Epic 2 - Permissions and consent enforcement
FR22: Epic 2 - Transaction logging with plugin version
FR23: Epic 5 - CLI/backoffice publish flow
FR24: Epic 5 - CLI/backoffice install trigger
FR25: Epic 5 - Offline bundle push to tills
FR26: Epic 1 - Trust policy configuration and enforcement
FR27: Epic 1 - Signature/checksum verification
FR28: Epic 2 - POS trust status for installed plugins
FR29: Epic 4 - POS/backoffice install/update health states
FR30: Epic 4 - Telemetry/status buffering and last sync
FR31: Epic 4 - Export/import for portability
FR32: Epic 4 - Admin configuration surfaces
FR33: Epic 4 - System status panel

## Epic List

### Epic 1: Marketplace Catalog, Trust, and Distribution (Priority)
Operators and developers can browse a marketplace catalog, download plugin bundles safely, and rely on trust/verification and revocation signals so pilots can test POS plugin flows early.
**FRs covered:** FR13, FR19, FR27

### Epic 2: POS Plugin Install & Lifecycle (Priority)
Operators can install, update, roll back, disable, or side-load plugins on POS devices, see clear status, and run plugin UI surfaces with enforced permissions and auditing.
**FRs covered:** FR14, FR15, FR16, FR17, FR18, FR20, FR21, FR22, FR28

### Epic 3: Offline-First Checkout & Core POS Operations
Cashiers can complete offline sales quickly with hardware support, receipts, and core catalog/inventory operations that work on low-end devices.
**FRs covered:** FR1, FR2, FR3, FR6, FR7, FR8, FR10, FR11, FR12

### Epic 4: Admin, Configuration, Sync & Portability
Operators can configure devices and locale settings, monitor system status, manage sync states, and export/import core data with reliable offline telemetry.
**FRs covered:** FR4, FR5, FR9, FR26, FR29, FR30, FR31, FR32, FR33

### Epic 5: CLI/Backoffice Plugin Publishing & Distribution
Plugin developers and operators can publish plugins and trigger installs via a CLI/backoffice flow; CLI installation is optional, but the workflow is supported for pilots.
**FRs covered:** FR23, FR24, FR25

## Epic 1: Marketplace Catalog, Trust, and Distribution

Operators and developers can browse a marketplace catalog, download plugin bundles safely, and rely on trust/verification and revocation signals so pilots can test POS plugin flows early.

### Story 1.1: Marketplace Catalog Listing

As an operator,
I want to browse a marketplace catalog with clear plugin metadata,
So that I can find plugins appropriate for pilots.

**Acceptance Criteria:**

**Given** a marketplace endpoint is available,
**When** I request the catalog list,
**Then** each plugin entry includes name, version, description, and compatibility metadata.
**And** the catalog response follows the versioned API contract format.

### Story 1.2: Plugin Bundle Distribution with Integrity Metadata

As a plugin developer or operator,
I want the marketplace to provide downloadable plugin bundles with integrity metadata,
So that POS devices can verify bundles before install.

**Acceptance Criteria:**

**Given** a plugin version is published,
**When** a bundle download is requested,
**Then** the response provides a bundle URL plus checksum and signature metadata.
**And** the marketplace refuses to serve bundles missing required integrity metadata.

### Story 1.3: Revocation and Trust Signals in Marketplace

As an operator,
I want the marketplace to surface revocation and trust signals for plugins,
So that I can avoid installing risky or revoked plugins.

**Acceptance Criteria:**

**Given** a plugin has been revoked or flagged,
**When** I view the plugin in the catalog,
**Then** the response includes revocation status and trust flags.
**And** a revocation list endpoint is available for POS consumption.

## Epic 2: POS Plugin Install & Lifecycle

Operators can install, update, roll back, disable, or side-load plugins on POS devices, see clear status, and run plugin UI surfaces with enforced permissions and auditing.

### Story 2.1: Install Plugin from Marketplace with Verification

As an operator,
I want to install a plugin from the marketplace with integrity checks,
So that only verified bundles are installed.

**Acceptance Criteria:**

**Given** a plugin bundle is selected for install,
**When** the POS downloads the bundle,
**Then** the POS verifies checksum/signature before installation.
**And** invalid bundles are rejected with a clear error state.

### Story 2.2: Plugin Install Status and Version Visibility

As an operator,
I want to see plugin install status and current versions,
So that I can confirm installs succeeded.

**Acceptance Criteria:**

**Given** plugins are installed or installing,
**When** I view the plugin list,
**Then** each plugin shows its current version and status state.
**And** failures include a human-readable message and retry option.

### Story 2.3: Update and Rollback Plugin Versions

As an operator,
I want to update or roll back a plugin version safely,
So that I can recover from faulty updates.

**Acceptance Criteria:**

**Given** an update is available,
**When** I apply the update,
**Then** the POS stages the new version and keeps the prior version until verification completes.
**And** I can roll back to the last known-good version if verification fails.

### Story 2.4: Disable or Uninstall a Plugin

As an operator,
I want to disable or uninstall a plugin,
So that I can remove problematic plugins without breaking POS.

**Acceptance Criteria:**

**Given** an installed plugin,
**When** I disable or uninstall it,
**Then** the plugin is no longer active in the POS UI.
**And** the system records the action with a reason code or note.

### Story 2.5: Side-Load Offline Plugin Package

As an operator,
I want to install or update a plugin from an offline package,
So that I can manage pilots without connectivity.

**Acceptance Criteria:**

**Given** a signed offline bundle is provided,
**When** I side-load it on a POS device,
**Then** the POS verifies integrity and installs it.
**And** the install appears in the plugin status list with its version.

### Story 2.6: Enforce Plugin Permissions and Consent

As an operator,
I want plugins to declare permissions and require consent,
So that plugins only access approved capabilities.

**Acceptance Criteria:**

**Given** a plugin declares required permissions,
**When** I approve or deny them during install,
**Then** the POS enforces least-privilege access at runtime.
**And** denied permissions prevent restricted actions with a clear error.

### Story 2.7: Mount Plugin UI Surfaces

As an operator,
I want installed plugins to expose UI pages inside POS,
So that plugin features are accessible from the POS shell.

**Acceptance Criteria:**

**Given** a plugin provides a UI surface,
**When** the plugin is active,
**Then** the POS shows the plugin surface in its navigation.
**And** the surface respects kiosk/admin separation and i18n rules.

### Story 2.8: Log Plugin Version per Transaction

As an operator,
I want transactions to record the plugin versions involved,
So that audits can trace plugin influence.

**Acceptance Criteria:**

**Given** a plugin participates in a transaction,
**When** the transaction is recorded,
**Then** the plugin version is stored with the transaction record.
**And** the audit export includes plugin version metadata.

### Story 2.9: Display Plugin Trust Status in POS

As an operator,
I want to see trust and verification status for installed plugins,
So that I can identify unsigned or revoked plugins quickly.

**Acceptance Criteria:**

**Given** installed plugins in the POS,
**When** I view plugin details,
**Then** the POS displays signed/unsigned and revocation status.
**And** revoked plugins show a warning and recommended action.

## Epic 3: Offline-First Checkout & Core POS Operations

Cashiers can complete offline sales quickly with hardware support, receipts, and core catalog/inventory operations that work on low-end devices.

### Story 3.1: Offline Checkout with Tender and Receipt Hooks

As a cashier,
I want to complete a sale offline with cash or card tender,
So that sales continue during network outages.

**Acceptance Criteria:**

**Given** the POS is offline,
**When** I complete a checkout with items and tender,
**Then** the sale is saved locally without blocking.
**And** receipt content includes plugin-provided legal/tax text.

### Story 3.2: Fast Scan and Totals on Low-End Hardware

As a cashier,
I want scanned items to update totals instantly,
So that checkout remains fast on low-end devices.

**Acceptance Criteria:**

**Given** a barcode scan input,
**When** an item is added,
**Then** the item appears in the basket and totals update immediately.
**And** the UI remains responsive without blocking animations.

### Story 3.3: Catalog Create and Edit

As a merchant,
I want to create and edit products with price, tax, and SKU/barcode,
So that I can sell new items quickly.

**Acceptance Criteria:**

**Given** the admin catalog view,
**When** I create or edit a product,
**Then** the product stores price, tax applicability, and SKU/barcode.
**And** changes are available for checkout without restart.

### Story 3.4: Catalog Import and Export

As a merchant,
I want to import and export catalog data,
So that I can move data in and out of the POS easily.

**Acceptance Criteria:**

**Given** a CSV file,
**When** I import it into the catalog,
**Then** products are created or updated with a summary of successes and failures.
**And** I can export the current catalog to CSV.

### Story 3.5: Inventory Decrement and Offline Reconcile

As a merchant,
I want inventory to decrement on sale and reconcile when back online,
So that stock levels remain accurate.

**Acceptance Criteria:**

**Given** an item is sold,
**When** the sale is recorded,
**Then** inventory decrements locally.
**And** offline inventory changes are queued for sync and conflict review.

### Story 3.6: Hardware Configuration and Fallback

As an operator,
I want to configure scanners, printers, and cash drawers with fallback,
So that checkout works even when hardware is missing.

**Acceptance Criteria:**

**Given** hardware configuration settings,
**When** devices are present or absent,
**Then** the POS can test device connections and show status.
**And** missing devices do not block checkout.

### Story 3.7: Cash Drawer and Printer Triggers Offline

As a cashier,
I want to trigger the cash drawer and printer during checkout offline,
So that physical workflows still function.

**Acceptance Criteria:**

**Given** an offline checkout,
**When** I complete a cash sale,
**Then** the cash drawer triggers and the receipt prints.
**And** failures provide a retry and manual override path.

### Story 3.8: Locale-Aware Currency Display

As an operator,
I want prices to display in the configured currency and locale,
So that totals are clear to staff and customers.

**Acceptance Criteria:**

**Given** a configured locale and currency,
**When** prices and totals render,
**Then** formatting matches locale rules.
**And** the POS uses locale files with no hardcoded UI strings.

## Epic 4: Admin, Configuration, Sync & Portability

Operators can configure devices and locale settings, monitor system status, manage sync states, and export/import core data with reliable offline telemetry.

### Story 4.1: Admin Settings for Endpoint, Locale, Devices, and Trust Policy

As an operator,
I want an admin settings surface for marketplace endpoint, language, currency, devices, and trust policy,
So that I can configure POS for pilots.

**Acceptance Criteria:**

**Given** the admin settings view,
**When** I update marketplace endpoint, locale, device, or trust policy settings,
**Then** the POS saves and applies the configuration.
**And** trust policy (e.g., signed-only) is enforced for subsequent installs.

### Story 4.2: Offline/Online Status and Sync Queue Visibility

As an operator,
I want to see offline/online status and sync queue size,
So that I understand system state at a glance.

**Acceptance Criteria:**

**Given** the POS status strip or panel,
**When** network state changes,
**Then** the UI reflects offline/online state with a non-blocking status chip.
**And** sync backlog size is visible.

### Story 4.3: Sync Control and Conflict Handling

As an operator,
I want to pause, resume, and retry sync with conflict review,
So that I can manage data integrity after outages.

**Acceptance Criteria:**

**Given** a queued sync backlog,
**When** I pause or resume sync,
**Then** the POS respects the control without blocking checkout.
**And** conflicts surface in a review queue after reconnect.

### Story 4.4: Telemetry Buffering and Last Sync Status

As an operator,
I want telemetry/status to buffer offline and show last sync results,
So that I can confirm reporting without always being online.

**Acceptance Criteria:**

**Given** the POS is offline,
**When** telemetry events are generated,
**Then** they are queued locally for later delivery.
**And** the last successful sync timestamp is visible in status views.

### Story 4.5: System Status Panel

As an operator,
I want a system status panel summarizing plugin state and sync health,
So that I can assess readiness quickly.

**Acceptance Criteria:**

**Given** the system status panel,
**When** I open it,
**Then** it shows plugin state summary and sync health indicators.
**And** it includes offline-safe guidance for next actions.

### Story 4.6: Export and Import Core Data

As an operator,
I want to export and import core data for portability,
So that I can migrate or back up pilot installations.

**Acceptance Criteria:**

**Given** the data export tool,
**When** I export catalog and sales data,
**Then** files are produced in a portable format.
**And** import validates data and reports any errors.

### Story 4.7: POS/Backoffice Install and Update Status Tracking

As an operator,
I want install/update status tracked in POS and backoffice (when multi-device),
So that I can monitor plugin rollout without relying on marketplace storage.

**Acceptance Criteria:**

**Given** a plugin install or update request,
**When** the POS processes the lifecycle,
**Then** it records states as requested, downloading, installing, active, or failed.
**And** backoffice aggregations (if enabled) reflect device status without storing it in the marketplace.

## Epic 5: CLI/Backoffice Plugin Publishing & Distribution

Plugin developers and operators can publish plugins and trigger installs via a CLI/backoffice flow; CLI installation is optional, but the workflow is supported for pilots.

### Story 5.1: Publish Plugin to Marketplace via CLI/Backoffice

As a plugin developer,
I want to publish a plugin to the marketplace via CLI or backoffice,
So that pilots can discover it in the catalog.

**Acceptance Criteria:**

**Given** a valid plugin bundle and manifest,
**When** I run the publish command or backoffice action,
**Then** the marketplace registers a new plugin version.
**And** the catalog shows the new version with metadata.

### Story 5.2: Trigger POS Install/Update from CLI/Backoffice

As an operator,
I want to trigger plugin install or update from CLI/backoffice,
So that I can manage pilot fleets without manual POS access.

**Acceptance Criteria:**

**Given** a target POS device is registered,
**When** I issue an install or update command,
**Then** the request is queued and visible in install status telemetry.
**And** the POS applies the request when it is online.

### Story 5.3: Push Offline Bundle to Till

As an operator,
I want to push a plugin bundle to a till for offline install,
So that pilots can update without connectivity.

**Acceptance Criteria:**

**Given** a signed plugin bundle,
**When** I deliver it to a till via offline media or local transfer,
**Then** the POS recognizes it as a valid install/update package.
**And** the POS records the installation outcome for later sync.
