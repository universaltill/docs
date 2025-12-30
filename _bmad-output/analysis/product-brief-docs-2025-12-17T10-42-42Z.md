---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments:
  - "_bmad-output/analysis/research/market-universal-till-competitive-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/research/technical-universal-till-platform-architecture-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/research/domain-universal-till-tax-compliance-gtm-research-2025-12-17T10-42-42Z.md"
  - "_bmad-output/analysis/brainstorming-session-2025-12-17T00-05-15Z.md"
workflowType: 'product-brief'
lastStep: 5
project_name: 'docs'
user_name: 'Farshid'
date: '2025-12-17T10-42-42Z'
---

# Product Brief: docs

**Date:** 2025-12-17T10-42-42Z
**Author:** Farshid

---

<!-- Content will be appended sequentially through collaborative workflow steps -->

## Executive Summary

Universal Till is an offline-first, open-source point-of-sale platform designed to run on inexpensive and existing hardware (including low-cost devices) and remain usable even with unreliable or no internet. It aims to remove cost and lock-in barriers that prevent many businesses from adopting modern POS systems.

Universal Till’s core is free, with optional paid cloud services later (sync, fleet management, analytics, backups, etc.). The platform is “plugin-first”: taxes, regional compliance, payments, integrations (ERP/accounting/ecommerce), and vertical workflows are implemented as plugins and distributed via a plugin marketplace.

Long-term, Universal Till extends beyond merchant operations into a consumer experience: a mobile app that can discover nearby tills on a map and enable ordering/delivery when relevant plugins are installed. A further long-term vision is a global item identity system (ISBN-like) to reduce duplicated product entry and improve item-level data quality worldwide (not MVP).

---

## Core Vision

### Problem Statement

Many businesses either have no POS system or are stuck on outdated machines because modern POS solutions are expensive, require hardware upgrades, depend on stable internet, and often lock merchants into proprietary ecosystems. Even when businesses adopt a POS, capabilities differ widely, integrations are inconsistent, and exporting data or moving providers can be painful.

### Problem Impact

- Small businesses lose efficiency, inventory accuracy, and reporting capability—or pay high ongoing costs to gain them.
- Hardware-constrained merchants (old tablets, low-cost devices) are excluded from modern POS platforms.
- Ecosystem lock-in makes it harder to switch providers or integrate with accounting/ERP/ecommerce.
- Global expansion is difficult because currencies, languages, and local tax/compliance needs vary dramatically.

### Why Existing Solutions Fall Short

From the current POS market patterns (UK/US/Turkey examples):
- Many POS offerings are tightly coupled to payments/hardware ecosystems and subscription pricing, increasing total cost of ownership.
- Offline capability varies and often degrades key workflows when connectivity is weak.
- Integrations and extensibility are typically controlled by vendor ecosystems; capabilities are uneven and not portable.
- Regional/vertical requirements (tax models, compliance, receipt formats, localized workflows) tend to increase complexity and cost.

### Proposed Solution

Universal Till delivers a free core POS and (future) back office that:
- Runs on cheap and existing hardware, prioritizing offline-first operation.
- Provides a plugin host for POS/back office so “everything is a plugin”: tax/compliance, payments, hardware drivers, and integrations.
- Includes a plugin marketplace for discovery, trust, versioning, and install/update workflows.
- Treats data portability as a core promise: export/import and interoperability to minimize vendor lock-in.

Future expansions:
- Consumer mobile app to discover tills and order via installed plugins (e.g., delivery, restaurant ordering).
- Global unique item identity registry (ISBN-like) to reduce duplicate item entry and improve global item data tracking (explicitly not MVP).

### Key Differentiators

- **Free core + optional paid cloud**: lowers adoption barrier globally while enabling sustainable cloud services later.
- **Runs anywhere + offline-first**: supports businesses with old hardware and unreliable connectivity.
- **Everything is a plugin**: taxes, compliance, payments, integrations, and vertical workflows evolve independently.
- **Marketplace-driven extensibility**: vendors and community can publish capabilities without central bottlenecks.
- **Data portability by design**: users can export/import freely, enabling migration and interoperability.
- **Long-term network effects**: consumer app + global item identity can create compounding value beyond the POS itself.

## Target Users

### Primary Users

#### 1) “Aylin” — Mobile Seller (markets, pop-ups, street vendors)

- **Context:** Runs a small, mobile business with minimal equipment. Moves between locations and may operate in areas with unreliable connectivity.
- **Typical device:** Android phone or very low-cost Raspberry Pi-based setup.
- **Payments:** Cash + card.
- **Problem experience today:** Many POS tools assume stable internet, modern hardware, or expensive subscriptions. Switching systems risks losing data or requiring reconfiguration.
- **Success looks like:** Can complete sales, issue receipts, track basic inventory, and reconcile cash/card without any internet connection.
- **Must-work-offline:** Full selling flow with zero internet.

#### 2) “Mehmet” — Small Service Provider (appointments + services + products)

- **Context:** Service business (e.g., barber/salon/repair) selling appointments, services, and sometimes retail products.
- **Needs:** Invoices/receipts; tax support should be available but may be optional depending on local rules and business type.
- **Problem experience today:** Juggling scheduling, customer tracking, payments, and reporting across tools (or spreadsheets) creates errors and wasted time.
- **Success looks like:** A single system that tracks customers, appointments, service history, payments, and basic reporting—offline-first.

#### 3) “Sara” — Small Shop Owner (retail with 1k+ SKUs)

- **Context:** Runs a small retail shop with a meaningful catalog (1,000+ items).
- **Hardware:** Barcode scanner, receipt printer, cash drawer.
- **Needs:** Reliable inventory/stock tracking and the ability to continue taking orders/payments without internet.
- **Problem experience today:** Systems can be expensive, require upgrades, or break down when internet is unavailable.
- **Success looks like:** Fast checkout with scanner + printer support; inventory accuracy; offline reliability; easy export/import to avoid lock-in.

#### 4) “Daniela” — Restaurant Operator (table + quick service + delivery)

- **Context:** Operates dine-in and delivery; needs both table service and quick-service patterns.
- **Needs:** KDS / kitchen printing, modifiers, tips, table reservation, tablet/phone ordering, and self-ordering flows.
- **Must-work-offline:** Core operations should continue offline (orders, payments, printing, kitchen workflows).
- **Success looks like:** A stable POS that supports restaurant-specific workflows through plugins—without forcing a full platform switch when adding delivery or self-ordering.

#### 5) “James” — Multi-ecommerce Seller (POS as catalog + multi-channel publishing)

- **Context:** Wants the POS catalog to be the source of truth, then publish to marketplaces (eBay, Amazon, etc.) via plugins.
- **Biggest pain:** Listing sync, inventory sync, order aggregation, and stock management across channels.
- **Success looks like:** “One catalog, many channels” — create/update products once; listings and stock stay consistent; orders flow back into one unified view.

**Proposed ‘aha moment’ for multi-ecommerce sellers:**
- “I update product price/stock once in my POS, and within minutes my eBay/Amazon listings and available inventory are consistent—no overselling, no spreadsheet juggling, and offline sales still reconcile when connectivity returns.”

### Secondary Users

- **Plugin Developers / Integrators:** Build payments, tax, accounting, ecommerce, and restaurant workflow plugins; publish via marketplace with trust tiers.
- **Accountants / Bookkeepers:** Need clean exports, audit trails, and consistent tax handling (often via plugins).
- **Managers / Owners (multi-site):** Want reporting, remote management, backups, sync, and fleet oversight (primarily via paid cloud services later).
- **Consumers (future):** Use a mobile app to discover tills on a map and place orders (delivery/restaurant ordering plugins).

### User Journey

1) **Discovery:** Merchant finds Universal Till because it is free, open-source, offline-first, and runs on cheap hardware.
2) **Onboarding:** Installs on Android/low-cost device; selects language/currency; loads initial catalog; connects basic hardware where available.
3) **Core Usage (offline-first):** Runs daily sales reliably with no internet; prints receipts; manages cash/card; tracks inventory.
4) **Success moment:** Adds one plugin (e.g., tax, payments, ecommerce publishing, restaurant KDS) and immediately expands capability without switching systems.
5) **Long-term:** Adds cloud services when needed (multi-device sync, backups, analytics, remote management); expands plugin set; possibly enables consumer ordering experiences later.

## Success Metrics

### User Success Metrics (Offline-First + Run-Anywhere)

- **Offline core actions supported:** Users can (1) complete a sale offline, (2) scan barcodes, and (3) print receipts without internet connectivity.
- **Offline completion rate target:** **95%** of sales can be completed fully offline (with deferred sync when connectivity is available).
- **Time-to-first-sale target:** A cashier can complete the first sale in **< 5 minutes** after install (including minimal setup).

### Ecosystem Success Metrics (Plugins + Marketplace)

- **End-to-end plugin lifecycle proof:** Install **a few plugins of different types** (e.g., UI page plugin like FAQ, tax plugin, integration plugin) from marketplace **end-to-end** in a local dev environment.
- **Reliability signal:** Installed plugins remain usable during offline operation once installed/cached.

### Business Objectives

- **3-month objective:** Secure pilot merchants actively using the POS in real workflows (focus: offline reliability + basic POS tasks).
- **12-month objective:** Demonstrate community and adoption growth via GitHub stars, contributors, and active devices/users.

### Key Performance Indicators

- **Pilot adoption:** Number of pilot merchants onboarded and active at 3 months.
- **Activation:** % of new installs completing first sale in < 5 minutes.
- **Offline reliability:** % of sales completed fully offline (target 95%).
- **Ecosystem proof:** # of distinct plugin types successfully installed end-to-end via marketplace flow.
- **Community growth:** GitHub stars and contributor count at 12 months.
- **Usage:** Active devices/users at 12 months.

## MVP Scope

### Core Features

**Core POS (offline-first, runs-anywhere):**
- Complete a sale fully offline (cash + card as applicable).
- Scan barcodes (hardware support baseline).
- Print receipts (hardware support baseline).
- Product/catalog management sufficient for day-to-day selling.
- Basic inventory tracking sufficient for small shops (1k+ SKUs support is a target).
- Multi-language + multi-currency baseline configuration.

**Plugin-first foundation:**
- POS/back office are designed to be extended via plugins (tax/local rules via plugins, integrations via plugins).
- Offline operation remains functional after plugins are installed/cached.

**Restaurant depth:**
- Restaurant-specific depth (KDS, modifiers, tips, reservations, self-ordering) is intentionally deferred to plugins; MVP only needs core POS primitives that restaurants can build on.

**Marketplace (MVP capabilities):**
- Browse plugin catalog (discovery).
- Install plugins end-to-end.
- View install status/health (status + error surfaced).
- Upload/publish a plugin release into the project’s own marketplace instance for pilot use (MVP-friendly).

### Out of Scope for MVP

Deferred explicitly:
- Consumer map app and consumer ordering experiences.
- Global unique item identity registry (ISBN-like).
- Full cloud suite (multi-site sync, advanced analytics, hosted fleet management) beyond any minimal infrastructure needed to support marketplace operations.
- Full restaurant suite (KDS, table reservations, tablet/phone ordering, self-ordering) as built-in features.
- Full ecommerce multi-channel automation beyond early plugin scaffolding.

### MVP Success Criteria

MVP is considered successful if:
- Pilot merchants are onboarded and actively using the POS in real workflows.
- Plugin marketplace flow is validated end-to-end (browse → install → status) with multiple plugin types.
- Offline success metrics are met (95% sales fully offline; time-to-first-sale < 5 minutes).

### Future Vision

Post-MVP evolution:
- Expand plugin ecosystem breadth (tax/compliance per region, payments, ERP/accounting/ecommerce integrations).
- Mature marketplace governance (trust tiers, security scanning, signing, telemetry, offline bundle workflows).
- Introduce paid cloud services where they create clear operational value (sync, backups, analytics, remote management).
- Build consumer experiences (map discovery + ordering) enabled by merchant-installed plugins.
- Explore a global item identity system (ISBN-like) as a separate long-term initiative with dedicated governance (not MVP).
