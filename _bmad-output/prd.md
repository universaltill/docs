---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
inputDocuments:
  - "_bmad-output/analysis/product-brief-docs-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/research/domain-universal-till-tax-compliance-gtm-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/research/market-universal-till-competitive-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/research/technical-universal-till-platform-architecture-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/brainstorming-session-2025-12-17T00-05-15Z.md"
  - "_bmad-output/index.md"
documentCounts:
  briefs: 1
  research: 3
  brainstorming: 1
  projectDocs: 1
workflowType: 'prd'
lastStep: 11
project_name: 'docs'
user_name: 'Farshid'
date: '2025-12-17T18:30:20Z'
---

# Product Requirements Document - docs

**Author:** Farshid
**Date:** 2025-12-17T18:30:20Z

## Executive Summary

Universal Till is an offline-first, plugin-driven POS that runs on inexpensive or existing hardware (including Raspberry Pi) and delivers a fast, low-friction checkout experience. The core is free; optional paid cloud services (sync, fleet, analytics, backups) come later. Everything is a plugin—tax/regional rules, payments, hardware drivers, and integrations—distributed through a marketplace with install/publish flows suited for pilots.

We classify this as a desktop/offline app with embedded/IoT hardware considerations and future mobile reach, operating in a fintech-adjacent domain with high complexity due to payments, multi-currency, and compliance needs. The current system is brownfield: a working POS MVP and a marketplace prototype, plus an FAQ plugin awaiting the CLI/install flow. This PRD focuses on elevating POS usability and hardening the plugin install/publish lifecycle.

### What Makes This Special
- **Usability-first POS**: cashiers can complete a sale with near-zero training, even on low-end hardware.
- **Fast on constrained devices**: responsive UI with minimal steps and large touch targets; optimized for unreliable connectivity.
- **Setup to first sale <5 minutes**: defaults, lightweight catalog entry, and guided flows make initial success immediate.
- **Plugin-first everything**: taxes, compliance, payments, integrations, and vertical workflows ship as plugins; marketplace manages discovery, trust, and updates.
- **Offline-first by design**: 95% of sales can be completed fully offline; installed plugins remain usable once cached.
- **Data portability**: export/import is core, reducing lock-in and enabling migration.

## Project Classification
**Technical Type:** desktop_app (offline-first), with secondary iot_embedded + mobile_app considerations  
**Domain:** fintech (payments/tax/compliance touchpoints)  
**Complexity:** high  
**Project Context:** Brownfield — extending an existing POS + marketplace foundation

We’ll align new requirements with the existing architecture and repositories (POS, marketplace, plugins) and keep the CLI/install flow in scope for proving the marketplace-to-POS plugin path.

## Success Criteria

### User Success
- Time-to-first-sale: cashier can complete first sale in <5 minutes from install (setup → first transaction).
- Offline completion: ≥95% of sales can be completed fully offline (cash + card), with receipts and barcode scanning.
- Zero-training checkout: a new cashier can complete a sale without a walkthrough.
- Low-end hardware performance: no perceptible lag on constrained devices; touch targets sized for fast tap.

### Business Success
- 3-month: pilot merchants actively using POS in real workflows; plugin install flow validated end-to-end with multiple plugin types (e.g., UI page/FAQ, tax/compliance, integration).
- 12-month: community traction (GitHub stars/contributors) and active devices/users; measurable pilot retention.
- Marketplace publishing works for pilots (upload/publish into own instance).

### Technical Success
- Offline-first reliability: local queueing/cache so POS and installed plugins work without connectivity; deferred sync succeeds when back online.
- Plugin lifecycle: browse → install → status → (publish for pilots) validated; installed plugins remain usable offline once cached.
- Baseline observability for pilots: minimal health/status signals (even if buffered offline) to confirm flows.

### Measurable Outcomes
- Time-to-first-sale <5 minutes.
- Offline completion rate ≥95% of sales.
- # of distinct plugin types installed end-to-end in pilot (e.g., UI page like FAQ, tax/compliance plugin, integration plugin).
- Pilot adoption: # active pilot merchants at 3 months; retention signal.
- Community: GitHub stars/contributors at 12 months; active devices/users.

## Product Scope

### MVP - Minimum Viable Product
- Core offline POS: sale, receipt printing, barcode scanning; minimal catalog/inventory; multi-language/currency baseline.
- Marketplace: browse/install/status + publish to own instance for pilots; plugin caching for offline use.
- CLI/install flow bridging marketplace → POS; end-to-end plugin install for multiple plugin types.

### Growth Features (Post-MVP)
- Marketplace governance (trust tiers, signing/scanning), richer cloud services (sync, backups, analytics), broader plugin ecosystem (payments, tax per region, ERP/accounting/ecommerce), UI polish beyond MVP, restaurant depth via plugins.

### Vision (Future)
- Consumer app (map + ordering), global item identity registry (ISBN-like), full cloud suite, richer restaurant/ecommerce automation.

## User Journeys

### Journey A: Aylin (Mobile Seller) — Offline-first Checkout Anywhere
Aylin sells at pop-up markets using a cheap Android device. She installs Universal Till, picks her language/currency, adds a few items, and pairs a lightweight Bluetooth receipt printer. Even with no signal, she starts selling: scans items (camera or low-cost scanner), adds cash/card payments, and prints receipts. When the market’s Wi‑Fi flickers, sales stay smooth; queued data waits locally. Later, when she’s home on Wi‑Fi, the app syncs sales and plugin telemetry automatically. Her win: no dependency on reliable internet, no costly hardware, zero-training checkout.

### Journey B: Sara (Small Shop, 1k+ SKUs) — Hardware Checkout, Offline Resilience
Sara runs a small shop with a USB barcode scanner, thermal printer, and cash drawer. After install, she imports a CSV catalog (~1k SKUs) and connects her scanner/printer. At checkout, the UI is fast on her older PC; scans feel instant, totals update immediately, and receipts print without delay. If her internet drops, she keeps selling—payments and receipts still work; inventory decrements locally. When connectivity returns, inventory and sales sync; any conflicts are flagged for review. Her win: reliable, low-latency checkout on aging hardware, no downtime from flaky internet.

### Journey C: Marketplace Publisher (Developer) — Publish & Install a Plugin for Pilots
A plugin developer builds a simple FAQ UI plugin. They package it with a manifest, run the CLI to publish into the pilot marketplace instance, and see it appear in the catalog. On a pilot POS, the merchant browses the marketplace, views the plugin details, installs it, and the POS confirms status. The plugin is cached locally, so it keeps working offline once installed. The publisher can update/re-publish a new version; the POS surfaces update availability and status. Their win: a full publish→discover→install→offline-run loop proven for pilots.

### Journey D: Operator/Admin — Manage Plugins and Health for Pilots
An operator/admin configures the marketplace endpoint for a pilot POS, sets plugin trust/policy, and monitors install status. They can trigger installs/updates, see basic health/status signals (even if buffered during offline periods), and confirm that required plugins (e.g., tax or FAQ) are present and healthy. If a POS was offline during an update, it reconciles when back online and reports final status. Their win: confidence that pilots have the right plugins installed and working, even with intermittent connectivity.

### Journey Requirements Summary
- Offline sale flows with receipt/scan survive connectivity loss; defer sync safely.
- Fast, low-friction POS UI on low-end/older hardware; large touch targets, minimal steps.
- Hardware support: scanner, printer, cash drawer; graceful offline behavior.
- Marketplace end-to-end: publish→catalog→install→status→update; plugins cached for offline use.
- Admin/operator controls: set endpoint, trust/policy, view status/health, reconcile after offline periods.

## Domain-Specific Requirements

### Fintech Compliance & Regulatory Overview
Universal Till touches payments, receipts, tax/compliance plugins, and multi-currency. Although core POS can start cash-first, plugin-based payments/tax/compliance demand guardrails: regional laws (US/UK/EU/APAC), PCI DSS for card flows, data protection (GDPR/UK GDPR), and auditability for tax/reporting.

### Key Domain Concerns
- Regional compliance: tax/VAT/GST handled by plugins; must support locale-specific receipt/legal text and retention rules.
- Security standards: PCI DSS scope for card plugins; secure storage of secrets/keys; transport security; code signing for plugins.
- Audit requirements: immutable sales/void/refund trails; plugin versions logged per transaction; exportable audit logs.
- Fraud prevention: basic anomaly signals (offline/online) for pilots; plugin trust/policy and revocation.
- Data protection: PII minimization, locale-aware data retention, consent/logging for telemetry; secure offline caches.

### Compliance Requirements
- PCI DSS scope isolation for payment plugins; secrets managed via environment/secure store; no card data persistence in core POS.
- Regional tax/compliance delegated to plugins, but core enforces: per-transaction journaling, receipt content hooks, and locale-aware rounding/currency rules.
- GDPR/UK GDPR alignment: minimal PII in POS; configurable retention; export/delete endpoints deferred but planned.
- Signing/verification for plugins to reduce supply-chain risk; revocation list honored by POS/marketplace.

### Industry Standards & Best Practices
- TLS for marketplace interactions; checksum/signature verification on download/install.
- OpenAPI/contracted endpoints between POS and marketplace; clear versioning/compatibility.
- Least-privilege plugin permissions; capability-scoped manifests.

### Required Expertise & Validation
- KYC/AML/payment domain expertise in payment/tax plugins (not core POS).
- Security review for plugin signing/verification and sandboxing.
- Compliance review for receipt/legal text and data retention defaults by region.

### Implementation Considerations
- Offline-first: queue transactions/telemetry; on reconnect, sync with integrity checks and conflict flags.
- Plugin lifecycle: log plugin version + config per transaction; show install/status/update + revocation handling.
- Security architecture: signed manifests, checksums, permission model for plugins; secrets not written to disk.
- Fraud prevention: minimal heuristic signals (e.g., excessive voids/offline retries) buffered offline; surface to operator.
- Audit requirements: immutable journal for sales/voids/refunds; exportable logs per period/locale; receipt/legal text hook points.

## Innovation & Novel Patterns

### Detected Innovation Areas
- Plugin-first POS/back office on low-cost/offline hardware: everything (tax, payments, integrations, vertical flows) is a plugin, not hardcoded.
- Offline-first plugin lifecycle: publish → discover → install → status → cache → offline-run; plugins remain usable offline once installed.
- Marketplace as the orchestration layer for trust/versioning/revocation, decoupled from POS core.
- Data portability + vendor-neutral integrations as a first-class promise (export/import, not lock-in).
- Future network effects: consumer map/ordering via installed plugins; global item identity registry (ISBN-like) for products (post-MVP).

### Market Context & Competitive Landscape
- Most POS vendors tie core features to cloud connectivity, hardware lock-in, or payment lock-in.
- Plugin ecosystems exist but are often tightly coupled; offline resilience is uneven.
- Differentiator here: offline-first plus plugin lifecycle as a primary capability, on cheap hardware.

### Validation Approach
- Prove end-to-end plugin lifecycle in pilots: publish → catalog → install → status → cache → offline-run for multiple plugin types (UI page, tax/compliance, integration).
- Measure offline success: 95%+ of sales offline; time-to-first-sale <5 minutes on low-end hardware.
- Usability: zero-training checkout validation with pilot cashiers; responsiveness checks on constrained devices.

### Risk Mitigation
- Trust/supply chain: signing/verification of plugins; revocation handling; checksum on download/install.
- Offline integrity: durable local queue/cache with recovery and conflict flags on resync.
- Scope guardrails: restaurant depth, consumer app, and global item ID explicitly post-MVP; payments/tax handled via plugins with clear compliance boundaries (PCI/KYC/AML inside plugin scope).

## Desktop App Specific Requirements

### Project-Type Overview
- Primary targets: Linux (including Raspberry Pi), macOS, Windows. Secondary: Android/iOS later via a shared Go POS business library reused across desktop and mobile shells.
- Form factor: desktop-class app running locally with offline-first behavior; plugin-first architecture.

### Technical Architecture Considerations
- Shared Go business core to be embedded across platforms; UI shell/platform adapters per OS (and later mobile).
- Marketplace/CLI-driven plugin lifecycle must operate with intermittent connectivity; plugins cached locally.

### Platform Support
- OS targets: Linux (incl. Pi), macOS, Windows; plan for Android/iOS clients that embed the same Go business library.
- Hardware: barcode scanners, receipt printers, cash drawers; support common USB/serial/HID device paths; graceful degradation when devices absent.

### System Integration
- Device integration: printer/USB/serial/HID support for scanners, cash drawer signals, and receipt printers.
- Secrets/config: use OS keychain/secure storage where available; avoid storing sensitive data in plain files.
- Logging: local logs kept even when offline; exportable for support.

### Update Strategy
- POS core checks for updates when online; updates should not break offline operation (safe rollback or deferred apply).
- Plugins: marketplace/CLI/backoffice can fetch and stage updates; tills pull/apply when online, but can also accept offline packages (e.g., side-loaded plugin bundles).
- Versioning: retain previous version until new one verified; cache plugins for offline use.

### Offline Capabilities
- Core promise: offline-first; queue sales/telemetry and sync when online; plugins continue working from cache.
- When offline, features that truly require network are disabled or clearly marked; POS remains usable for sales, receipts, scanning, and installed plugin flows that do not depend on live connectivity.
- Clear status messaging: offline indicators and sync state so operators know what is deferred.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy
- MVP approach: Platform + Experience MVP — prove offline-first POS usability plus plugin lifecycle via marketplace/CLI.
- Resource assumptions: small team; bias to reuse Go core across platforms and keep UI lean.

### MVP Feature Set (Phase 1)
- Core user journeys: Aylin (mobile seller offline), Sara (shop with scanner/printer offline), Plugin publisher (publish/install/status/cache), Operator/admin (endpoint/trust/status).
- Must-have capabilities: offline sale/receipt/scan; multi-language/currency baseline; cached plugins; marketplace browse/install/status + publish to own instance; CLI/install flow; clear offline/sync status; secure plugin signing/verification + revocation handling; minimal observability for pilots.

### Post-MVP Features (Phase 2)
- Marketplace governance (trust tiers, signing/scanning depth), richer cloud services (sync, backups, analytics), broader plugin catalog (payments, tax per region, ERP/accounting/ecommerce), UI polish, restaurant depth via plugins.

### Expansion (Phase 3)
- Consumer app (map + ordering), global item identity registry (ISBN-like), fuller cloud suite, richer ecommerce/automation.

### Risk Mitigation Strategy
- Technical: validate plugin lifecycle on low-end hardware; signed plugins and checksums; safe rollback for updates; durable offline queue/cache.
- Market: pilot-first proof (offline reliability + install flow); measure time-to-first-sale and offline rate; ensure multiple plugin types install E2E.
- Resource: keep core thin, rely on plugins for vertical depth; defer heavy restaurant and consumer features to post-MVP.

## Functional Requirements

### POS Core & Offline Operation
- FR1: Cashiers can complete a sale (cash/card) fully offline, including line items and totals.
- FR2: Cashiers can scan items (camera or scanner) and see prices/totals update instantly on low-end hardware.
- FR3: Cashiers can print receipts offline; receipts include configurable legal/tax text supplied by installed plugins.
- FR4: Operators can view offline/online status and sync state; the system queues sales/telemetry and syncs when online.
- FR5: Operators can pause, resume, and retry sync, and see any conflicts flagged after reconnect.

### Catalog & Inventory (MVP Baseline)
- FR6: Merchants can create/edit products with price, tax applicability, and SKU/barcode.
- FR7: Merchants can import/export catalog data (e.g., CSV) for portability.
- FR8: Merchants can see basic stock levels and decrement inventory on sale; if offline, adjustments queue and reconcile on sync.

### Multi-Language & Currency
- FR9: Operators can select language and currency at setup; UI strings reflect the chosen language.
- FR10: Prices and totals display in the configured currency with locale-aware formatting.

### Hardware & Peripheral Support
- FR11: Operators can configure barcode scanners, receipt printers, and cash drawers; the system falls back gracefully if devices are absent.
- FR12: Cashiers can trigger cash drawer and printer during checkout; if offline, printing still works with cached templates.

### Marketplace & Plugin Lifecycle
- FR13: Operators can connect the POS to a marketplace endpoint and browse available plugins with metadata (name, version, description).
- FR14: Operators can install a plugin from the marketplace; POS verifies integrity (signature/checksum) and caches it locally.
- FR15: Operators can view plugin install status (success/error) and current version.
- FR16: Operators can update or roll back a plugin version; updates are staged and confirmed; prior version retained until confirmed healthy.
- FR17: Operators can uninstall or disable a plugin.
- FR18: Operators can apply an offline plugin package (side-load) to install/update when connectivity is unavailable.
- FR19: POS can honor plugin revocation lists from marketplace; revoked plugins surface warnings and can be disabled/uninstalled.

### Plugin Execution & Permissions
- FR20: Installed plugins can expose UI surfaces (e.g., pages/panels) within the POS shell.
- FR21: Plugins declare permissions/capabilities; POS prompts/records consent and enforces least privilege.
- FR22: POS logs plugin version and relevant context with each transaction where the plugin participates.

### CLI / Backoffice Interaction
- FR23: Operators can use a CLI/backoffice flow to publish a plugin into the marketplace instance used by pilots.
- FR24: Operators can trigger plugin install/update from CLI/backoffice, and tills can pull/apply when online.
- FR25: Operators can push a plugin bundle to a till for offline install/update (side-load path).

### Security & Trust (MVP Level)
- FR26: Operators can configure trust/policy for plugins (e.g., signed-only).
- FR27: POS verifies plugin signatures/checksums before install/update and refuses if validation fails.
- FR28: Operators can view a basic security/trust status for installed plugins (e.g., signed/unsigned, revocation state).

### Observability for Pilots
- FR29: Operators can see minimal health/status signals for plugin install/updates (queued, in progress, failed, completed).
- FR30: POS buffers telemetry/status while offline and sends when online; operators can see last sync attempt/result.

### Data Portability
- FR31: Operators can export/import core data (catalog, sales, plugins list/versions) to support migration and backups.

### Admin & Config
- FR32: Operators can configure marketplace endpoint, language/currency, and device settings from an admin surface.
- FR33: Operators can see a system status panel (online/offline, sync backlog size, plugin state summary).

## Non-Functional Requirements (MVP Focused)

### Performance
- Cashier-facing actions (scan → total; pay → receipt) feel instant on low-end/RPi-class hardware; background sync must not block POS UI.

### Reliability & Offline
- POS and installed plugins operate offline; durable local queue/cache with recovery; sync is resumable with conflict surfacing after reconnect.
- Receipt printing and core checkout functions must work offline.

### Security & Trust
- Plugin install/update requires signature/checksum validation and obeys trust policy (e.g., signed-only).
- TLS for marketplace calls; refuse/flag revoked plugins.
- No storing secrets in plain files; keep PCI scope inside payment plugins (core avoids sensitive payment data).

### Data Protection
- Minimal PII in POS; locale-aware retention defaults; export/import preserves data integrity.

### Integrity & Auditability
- Immutable journal of sales/voids/refunds; log plugin version per transaction; provide a basic audit export for pilots.

### Compatibility & Portability
- Runs on Linux (incl. Pi), macOS, Windows; tolerant of low-spec devices; plugins cached for offline use.

### Operability & Observability (MVP)
- Minimal health/status signals for plugin install/update and sync (queued/in-progress/failed/succeeded); buffer offline, send when online.
