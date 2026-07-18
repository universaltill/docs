# 0018 — Universal Till Cloud: the web app's real name, scope, and sync model

Status: accepted (2026-07-18, Farshid)

## Context

The web app at marketplace.universaltill.com outgrew its name. Today it holds
the plugin marketplace, store claim/enrolment, the owner's "My shop"
back-office, the notifications inbox, admin and vendor consoles, and the
developer portal; queued on top are subscriptions, multi-store head office,
and remote shop management. Farshid: *"the marketplace is only one of the
things this web app provides… it may be better to call it something like
cloud.universaltill.com"*. He also asked for a **back-office application**
(manage all tills, inventory, etc.) and for Phase 2 to start **using his
homelab as the cloud**, syncing his shop to it.

Constraints already decided elsewhere: tills sit behind shop NAT and must
stay offline-first (ADR-0003); they authenticate with opaque store tokens
(ADR-0013/0015); LAN multi-till sync is primary/replica (ADR-0011); the
cloud tier must be deployable multi-cloud and on-prem (sovereign countries).

## Decision

1. **The product is "Universal Till Cloud" at `cloud.universaltill.com`.**
   One web app, four faces: **Marketplace** (anonymous storefront stays the
   browse surface), **Shop administration** (owner back-office: fleet,
   plugins, settings, catalog/inventory, design, problems/logs), **Platform
   administration** (staff), **Developer portal** (vendors).
   `marketplace.universaltill.com` remains valid indefinitely — the fleet's
   configured endpoint; both hosts serve the same app. New till releases
   default to the cloud host. The `ut-market-place` repo keeps its name for
   now (CI/ACR wiring); renaming it is cosmetic and queued separately.

2. **Sync is till-initiated, never inbound.** The shop's **primary** till is
   the cloud-sync agent (replicas already funnel to it per ADR-0011). On a
   periodic loop it: (a) **pushes state up** — heartbeat/health per device,
   catalog + inventory snapshot, problem/log digest; (b) **pulls directives
   down** — cloud-created commands (install/remove plugin, change setting,
   apply theme/design, …), applies them locally, and reports per-directive
   results. Store-token auth throughout. Checkout never depends on any of
   this; a directive at worst waits for the next poll.

3. **The back-office device is the till binary in back-office mode** — a
   device profile that hides the sale surfaces and leads with the manager
   pages (catalog, inventory, reports, settings). One codebase, one update
   pipeline, LAN-syncs like any replica, appears in the fleet like any
   device. No separate app is built.

4. **The first cloud environment is Farshid's homelab k3s** — the same
   cluster serving the marketplace today. This *is* the sovereign/on-prem
   deployment story proven early: anything that runs on the homelab runs in
   a datacenter in a cloud-less country.

## Consequences

- DNS + ingress gain `cloud.universaltill.com`; branding strings change;
  nothing breaks for fielded tills (old host stays).
- The cloud DB grows device/heartbeat, snapshot, and directive entities;
  the owner portal grows fleet/health/manage pages.
- Remote management is eventually-consistent by design (poll interval), and
  that is acceptable; anything needing real-time later can add long-polling
  without changing the trust model.
- Directives are a new remote-control surface: they are store-scoped,
  owner/staff-authored only, and the till applies them through the same
  validation as local actions (e.g. plugin installs stay Ed25519-verified
  per ADR-0006 — a directive can only trigger an install the till would
  allow by hand).
