# ADR-0013: Store enrolment, plugin access tiers, and monetization

- **Status:** Accepted (Farshid, 2026-07-15)
- **Supersedes / relates to:** ADR-0012 (Universal Till ID / Zitadel), ADR-0011
  (multi-till sync), ADR-0006 (plugin trust chain).

## Context

A downloaded till must reach the marketplace to browse and install plugins. The
download-token endpoint requires a `merchant_id`/`store_id`/`device_id`; a fresh
download has none, so install fails with `400`. We seed a shared `merchant-1`
for testing, but that is not a real model.

We need, without breaking the product's promises:

- **Fleet visibility** — how many tills are running, where, on which version.
- A path to a **paid tier** and **multi-store** management.
- Durable **records of installs** (and activity) per store.
- To preserve **offline-first** (a sale never needs the cloud) and the
  **anti-lock-in** ethos ("the POS is truly yours").

Requiring account registration *before the shop can sell* would violate both
promises and add friction at exactly the wrong moment.

## Decision

A three-layer model: **anonymous enrolment → claim → paid.**

### 1. Anonymous device enrolment (automatic, first boot, no login)

On first boot the till generates a stable `device_id` and makes a best-effort
call to the cloud to register as an **anonymous store**, receiving a `store_id`
and a device token. This is:

- **Offline-tolerant** — a background call that retries when online; the till
  works fully without it.
- Enough to **browse the catalog** and **install public/free plugins**.
- The source of **fleet visibility** (count, region by IP, version, last-seen)
  even before anyone signs in or pays.

### 2. Claim (sign in with `id.universaltill.com`)

An anonymous store can be **claimed** by an owner account (Zitadel, ADR-0012),
linking one or more tills to a real identity. Claiming unlocks fleet
management, grouping tills into stores, and multi-store.

### 3. Paid tier (purchase against the claimed account)

Upgrading is a purchase on the claimed account; it unlocks paid features and
premium/cloud plugins via **entitlements**. **Free tier = a single till**;
**multi-till / multi-store cloud sync is the first paid unlock** (LAN sync stays
free per ADR-0011).

### Plugin access tiers

Each listing gains an `access` level, enforced **at download-token issuance**:

| `access`     | Who can install                         | Examples                          |
| ------------ | --------------------------------------- | --------------------------------- |
| `public`     | any enrolled device (device token only) | themes, community integrations    |
| `registered` | claimed store with entitlement          | payments, multi-store, cloud, paid |

This is distinct from the existing `paidListing` flag (price) — `access` is
about *whether an account is required*; a listing can be `registered` + free
(cloud-backed but no charge) or `public` + free.

### Records

Every install/uninstall/update is recorded in the cloud against the store,
reusing the existing **install intents** + **telemetry** + **audit events**.
Anonymous stores are tracked by device; claimed stores roll up under the
account.

## Consequences

- **Offline-first preserved** — sales never touch the cloud; enrolment is
  best-effort and retried.
- **Anti-lock-in preserved** — core POS + public plugins need no account; only
  premium/cloud does.
- **Monetization funnel** — anonymous → claim → pay, with fleet visibility the
  whole way.
- **Anti-abuse** — anonymous enrolment can inflate device counts; paid features
  are gated by real accounts, so the exposure is limited to vanity metrics.
- **Depends on** stable cloud hosting for the marketplace + `id` (they are
  currently on a home lab via dynamic DNS, which corporate/VPN filters block —
  migrate before launch).

## Implementation increments

1. **Anonymous enrolment + public/registered split.** Marketplace:
   `POST /v1/stores/register` (create store, return identity + device token);
   `access` field on listings + enforcement in the download-token service.
   POS: first-run enrolment, persist identity, use it for downloads + telemetry.
   Outcome: browse *and* free-plugin install work for any download.
2. **Claim + fleet view.** Claim an anonymous store via `id.universaltill.com`;
   fleet dashboard (counts, versions, last-seen) in the merchant/admin portal.
3. **Paid tier.** Entitlement enforcement for `registered`/paid listings +
   billing; multi-till/multi-store as the first paid unlock.
