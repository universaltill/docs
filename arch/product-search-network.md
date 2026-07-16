# Product-search network ("find it near me") — design stub (BACKLOG)

> Status: **backlog / vision**, not scheduled. Captured 2026-07-16 from Farshid.
> This is a sketch to design against later, not an accepted ADR yet.

## The vision

A shopper opens the Universal Till app or website, searches for an item, and
sees **which nearby stores have it in stock** (and at what price). Every
participating store — a Universal Till, *or a third-party POS / retail system* —
publishes its catalog and live stock into a shared, searchable index. This turns
the install base into a **local-commerce discovery network**: consumer-facing
search on one side, store participation on the other.

Two participant classes:
- **Universal Till stores** — already have identity (ADR-0013 enrolment) and
  already hold catalog + stock locally; opting in is a publish toggle.
- **Third-party stores / POS systems** — subscribe to the network and push their
  items + stock (and optionally other services) through an **open inbound API**,
  so non-UT retailers can be discoverable too.

## How it maps to what we have

- **Store identity & enrolment** — ADR-0013 already gives every store a
  cloud identity + device token. Participation is an opt-in flag on that store.
- **The connector pattern (ADR-0014), reversed** — ADR-0014 has stores push
  sale/stock events *out* to their ERP. Here stores push catalog + stock *in*
  to our index. Same event/connector shape, opposite direction. A third-party
  POS integrates with a small "publish to Universal Till network" connector (or
  a direct REST push), symmetric to how we connect to SAP/Dynamics.
- **Cloud/marketplace tier** — needs the (roadmapped) multi-store cloud: a
  central, geo-indexed search service + public search API. Offline-first still
  holds for selling; this is an *online, best-effort* discovery layer on top.
- **Website + app** — the consumer surface (search box → results ranked by
  distance + availability). The website already exists; the app is the mobile
  surface.

## Open design questions (for the real design later)

- **Stock freshness & trust** — how fresh must stock be to show "in stock"?
  Push-on-change vs periodic snapshot; how to handle stale/oversold; a
  confidence/last-updated signal on results.
- **Onboarding third parties** — an open publish API + schema (items: name,
  barcode/GTIN, price, qty, location) with auth per store; GTIN/barcode as the
  cross-store join key so the same product from different stores collates.
- **Privacy / opt-in** — stores choose what to expose (price? exact qty vs
  in/low/out?); consumer location handling.
- **Geo & ranking** — store locations, distance, availability, price, and
  (later) reservations / click-and-collect.
- **Abuse / quality** — spam listings, fake stock, moderation.
- **Monetization** — free for consumers; for stores: featured placement,
  lead-gen / referral, or a listing fee. Third-party participation could be a
  paid network tier.
- **Data sovereignty** — aligns with the multi-cloud/on-prem sovereign posture;
  cloudless regions (e.g. Iran) may run a regional index.

## Why it's strategic

It flips Universal Till from a per-store tool into a **two-sided network**:
more stores → better search coverage → more shoppers → more reason for stores
(UT and third-party) to join. It also gives non-UT retailers a reason to touch
our platform, a top-of-funnel for POS conversion, and a consumer brand surface.

## Dependencies before this can start

Cloud/marketplace multi-store tier (currently home-lab ddns; needs stable cloud
hosting), store geo/location data, and a public search service + API. Sequence
after the enterprise/ERP-connector and multi-store work.
