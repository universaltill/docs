# Review — Universal Till Cloud sync: heartbeat + directives (ADR-0018, Phase 2a)

**Date:** 2026-07-18 · **Repos:** ut-market-place (feat/cloud-sync), universal-till (feat/cloud-sync) → main

## What shipped

The first working slice of the cloud tier: **Farshid's shop can now sync to his
homelab cloud** — fleet state flows up, remote-management commands flow down.

**Cloud (marketplace app):**
- `StoreDirective` ent entity (type/payload/status/result/delivered/resolved).
- `POST /api/v1/stores/sync` — till pushes device reports (name, version,
  platform, **role** primary|replica|backoffice, health map); response carries
  the store's pending directives in the same round-trip. Store-token auth.
- `POST /api/v1/stores/directives/result` — applied|failed + message; scoped
  to the store's own **pending** directives (double reports 404, cross-store
  404 — tested).
- Claims service: `QueueDirective` (validates type + required payload field +
  store existence), `CancelDirective` (pending only), directives + fleet
  health surfaced in `StoreDetail`.
- Store detail page (owner + admin): fleet table gains role/platform/health/
  last-sync; new **Remote management** card — queue a `set_setting`, see the
  directive history with status/result, cancel pending ones. i18n ×9.
- Portal endpoints `/ui/api/merchant/stores/directives{,/cancel}` authorize
  via `authorizeMerchant` (owner session / portal token / open self-host) —
  same posture as entitlement writes.

**Till:**
- New `internal/cloudsync`: 5-minute loop (first tick 90 s after boot).
  Pushes one device report; applies pulled directives; reports each result.
  Unregistered tills no-op; failures retry next tick; nothing touches the
  sale path (ADR-0003).
- Directive application goes through the SAME paths as local actions:
  `set_setting` → settings store + the shared state re-derive closure (now
  extracted from StartSyncPull and reused), `install_plugin` → the
  marketplace installer (download-token + Ed25519 verification unchanged),
  `remove_plugin` → the uninstall path incl. file cleanup + plugin-manager
  reload + menu rebuild.
- Role reporting: `sync.primary_url` set → replica; `display.mode=backoffice`
  → backoffice (the ADR-0018 back-office device pre-wiring).

## Design points

- **Till-initiated only** — the cloud never dials a shop (NAT/offline-first).
- Directives stay `pending` until the till *reports*; delivery alone only
  stamps `delivered_at`. If the result POST fails the till re-applies next
  tick — supported types are idempotent.
- A directive can only do what the owner could do by hand on the till;
  install verification is unchanged.

## Verification

- ut-market-place: verify.sh green (fmt/vet/lint/tests incl. 3 new sync
  handler tests + directives service test).
- universal-till: build + full test suite + data-access & i18n guards green;
  3 new cloudsync tests (round-trip against a fake cloud, role derivation,
  unregistered no-op).
- **Real-binary integration**: booted the actual marketplace, registered a
  store via the API, queued `display.osk=on` through the portal endpoint,
  synced with the till's exact payload shape → directive delivered → result
  posted → admin store page shows **applied**. Owner-scoping confirmed
  (unclaimed store's my-stores page 404s).

## Follow-ups (queued)

- Catalog/inventory snapshot up-sync + problems/logs feed (2a remainder).
- Install-to-shop button on portal plugin cards; back-office display mode
  UI; cloud catalog editing (2b).
- cloud.universaltill.com DNS/ingress + rebrand (2c).
