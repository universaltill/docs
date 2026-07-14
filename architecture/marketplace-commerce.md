# Marketplace commerce — provider registration, paid plugins, subscriptions (proposal — G26)

Status: **backlog proposal — 2026-07-14** (Farshid: "for pushing plugins to
the market they need to register in unitill as a plugin provider; if they
sell the plugin or a subscription, a percentage goes to Universal Till —
so the marketplace needs to support selling and subscribing plugins").

## What already exists (build on, don't duplicate)

- Listings carry a `paid_listing` flag; the self-serve acquire flow grants
  free listings instantly and refuses paid ones
  (`ErrPaidListingRequiresApproval`) — the exact seam a checkout slots into.
- Entitlements + merchant orgs + portal tokens = who-owns-what is solved;
  a purchase just creates an approved entitlement.
- Monetization doc gate (3) already fixes the split: **20% commission** to
  Universal Till, only on paid plugins — free plugins stay free to publish
  and install forever.

## Provider (developer) registration — publishing gate

- Publishing to the marketplace requires a **plugin provider account**:
  a Universal Till ID (G21) with the `plugin-developer` role, plus a
  provider profile (legal name, support contact, payout details when
  selling). Uploads authenticate as the provider — retiring the shared
  admin upload bearer.
- Registration is free; agreeing to marketplace terms (QA pipeline G20,
  revocation policy, revenue split) is part of signup.
- Provider identity shows on listings ("by <provider>", verified badge
  after first QA pass) — the trust chain gets a human owner.

## Selling models

1. **One-off purchase** — buy once, entitlement forever (updates included).
2. **Subscription** — monthly/yearly; entitlement lives while paid.
   Lapse follows the house rule: grace period, feature stops, **data is
   never hostage** (same posture as the delivery relay design).
3. Free remains the default and needs no payment setup at all.

## Money flow

- **Stripe Connect** (destination charges): merchant pays, Stripe splits —
  provider gets their share, Universal Till keeps the commission
  automatically; Stripe handles provider payouts, KYC and card data, so
  the marketplace never touches card numbers. VAT via Stripe Tax.
- Webhook → entitlement: payment success creates/renews the approved
  entitlement; subscription cancellation/failure revokes on schedule.
  POS install path is unchanged — it already checks entitlements.
- Refund window per marketplace terms; refund revokes the entitlement.

## Order of work

1. Provider registration + authenticated uploads (needs G21's IdP; also a
   G20 prerequisite — reviewers need someone accountable to talk to).
2. One-off purchases behind the paid-listing seam.
3. Subscriptions + lapse/grace handling.
4. Provider dashboard (sales, payouts, installs) on the portal.
