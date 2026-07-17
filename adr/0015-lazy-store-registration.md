# ADR-0015: Lazy store registration (registration only when needed)

- **Status:** Accepted (Farshid, 2026-07-17)
- **Supersedes / relates to:** Amends ADR-0013 layer 1 (anonymous enrolment
  is no longer *automatic at first boot*). ADR-0013's three-layer model,
  claim flow, and plugin access tiers are unchanged.

## Context

ADR-0013 layer 1 made anonymous store enrolment **automatic on first boot**:
every till that ever started registered a store org with the marketplace.
Farshid's direction (2026-07-17): **multi-store is a paid-licence feature** —
a shop that doesn't use multi-store or paid cloud services has no need for a
marketplace store account at all. Automatic enrolment therefore registers
stores that serve no purpose:

- Every download, demo, test boot, and CI run mints a store org on prod
  (vanity fleet numbers, table growth, and a misleading picture of adoption).
- It contradicts the anti-lock-in promise in spirit: the product phones home
  and creates a cloud record before the user has asked for anything cloudy.
- The marketplace's free-plugin path already **self-provisions** the merchant
  org at download-token issuance (`downloadsvc` self-serve acquisition), so
  boot-time registration is not even required for free installs to work.

## Decision

**Register lazily — a till creates its store identity only when something
actually needs one:**

1. **First plugin download/install** (`enroll.EnsureRegistered`): the install
   path enrols on demand, then proceeds. Entitlements hang off the store, so
   this is the earliest interaction that genuinely needs the identity.
2. **Operator's explicit choice**: Settings → "Register now"
   (`enroll.RegisterNow`) — unchanged.
3. **Future paid unlocks** (multi-store, paid cloud services): enabling one
   registers first if needed — same `EnsureRegistered` seam.

What still happens at boot:

- A stable `device_id` is minted and persisted (no network).
- The marketplace **signing key** is fetched in the background (required to
  verify any plugin bundle; anonymous GET, creates no record).
- A **replica that joined a shop** (ADR-0011) and inherited the shop's store
  identity still registers itself as a device under that store (one store,
  many devices) — the shop, by having a store identity, already opted in.

Explicit env configuration (`UT_MARKETPLACE_CLIENT_ID` / `_STORE_ID` /
`_DEVICE_ID`) continues to win over everything.

## Consequences

- **No more throwaway store orgs** from boots that never touch the
  marketplace.
- **Fleet visibility narrows** (accepted trade-off): the cloud only sees
  tills that installed a plugin or registered deliberately. Adoption counts
  for "downloads that ran" move to the website download stats.
- A failed lazy registration surfaces through the install flow's own error
  path and is retried on the next attempt — no background register loop.
- The Settings "Register this till" encouragement chip stays (registration
  is still the gateway to claiming, fleet view, and the paid tier), but a
  till ignoring it loses nothing until it wants marketplace/paid features.

## Implementation

- `universal-till internal/enroll`: `Init` no longer starts a store-register
  loop (signing key + replica device registration only);
  new `EnsureRegistered(ctx, cfg, kv)` = register-if-needed + return
  effective config. Install/download handlers call it.
- Marketplace: no change needed (free self-serve provisioning already
  exists; `registered`/paid tiers already deny anonymous/unclaimed stores).
