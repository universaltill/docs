# Universal Till consumer app — one app for every shop (proposal)

Status: **backlog proposal — 2026-07-14** (Farshid: "one mobile app that works
with all these stores… loyalty card, points, paperless invoices, map, search
and item find, different prices, nearest shop, and what else you can add").

## Why this is strategically different

Square/Toast/Clover sell software to *merchants*; none of them gives shoppers
a reason to prefer their merchants. One consumer app across every Universal
Till shop is a **network effect**: each new shop makes the app more useful to
shoppers, and a used app makes Universal Till more attractive to the next
shop. Small independents get, collectively, the app none of them could build
alone — their answer to supermarket loyalty apps.

It is also the strongest possible driver for the paid cloud tier: a shop must
be **cloud-connected to appear in the app** (technically unavoidable — the
app can't reach a till behind shop NAT), so every consumer feature below
pulls shops into the subscription funnel, following the honest-gating rule
(monetization doc): the server genuinely provides the connection.

## Feature set

Farshid's list:
- **Digital loyalty card** — one QR/barcode in the app, scanned at any till
  (ties into backlog G1 customer capture; the till side already scans codes).
- **Points & rewards** — per-shop programs collected in one wallet; shop
  configures earn/redeem rules on the till.
- **Paperless invoices / e-receipts** — scan the app QR at tender → receipt
  lands in the app (now first-class backlog item **G16**; G11's email/SMS
  becomes the no-app fallback). One scan does double duty: loyalty capture
  AND receipt delivery — the till simply skips printing (shopper's choice,
  per sale). Central account = full cross-shop purchase history; returns
  and warranty claims without paper; VAT invoices for business customers.
  **The receipt can never be lost** (Farshid, 2026-07-14): paper receipts
  get thrown away, and thermal print fades to blank within months — right
  when a warranty claim needs it. An account receipt is permanent proof
  of purchase for the life of the product: warranty, returns, insurance
  claims, expense reports. This is the headline benefit to market G16 on.
- **Map & nearest shop** — find Universal Till shops around you; hours,
  contact, what they sell.
- **Search & price comparison** — find a product across nearby shops, compare
  prices, see stock ("who has it, cheapest, closest"). Shop opt-in publishes
  catalog+stock to the cloud. Now specced as G13 (plus the public-web/SEO
  variant G14 and the universal item catalog G15) in
  [item-discovery-and-universal-catalog.md](item-discovery-and-universal-catalog.md).

Additions (mine):
- **Click & collect / order ahead** — reuses commission-free online ordering
  (G5); the order drops onto the till like any sale. The strongest reason a
  shopper opens the app weekly.
- **Delivery** (Farshid, 2026-07-14) — order from a nearby shop for delivery.
  Phase 1: the shop's OWN delivery (shop sets radius/fee/hours; order lands
  on the till, driver managed by the shop) — commission-free, the
  anti-Uber-Eats pitch for shops that already deliver locally. Phase 2:
  optional courier handoff via the delivery-relay integrations for shops
  without drivers. Either way the order is a normal till sale — offline
  rules unchanged.
- **Gift cards & store credit in the wallet** (G2) — buy, send as a gift,
  redeem by QR.
- **Offers & digital punch cards** — shops push a coupon/offer to customers
  who opted in; classic "10th coffee free" without the paper card.
- **Shopping list** — checks item availability/prices at nearby shops as you
  build the list.
- **Spending history & simple budgeting** — every e-receipt is structured
  data; show per-shop and per-category totals. (Data stays the shopper's.)
- **Household sharing** — share receipts/warranties/gift cards with family.
- **Privacy as a feature** — explicit per-shop opt-in, no ad brokerage, delete
  everything anytime. The credible position given our open-source stance, and
  a contrast to supermarket loyalty schemes.

## Architecture sketch (build later, after the cloud sync tier)

- Depends on: cloud sync backend (monetization gate #1), merchant/store
  registry, e-receipt push, catalog/stock publication (opt-in per shop).
- App: one codebase (likely Flutter or React Native — decide later), talking
  to the cloud API only — never directly to tills.
- Till side: QR scan at tender links the sale to an app identity (existing
  customer-barcode scan path is the hook); receipt + points pushed via cloud.
- Consumer identity: phone/email account, per-shop consent records.
- Bootstrap sequence: e-receipts + loyalty first (works with even ONE shop),
  map/search once tens of shops are live, price comparison last (needs
  density to be honest).

## Monetization posture

Free for shoppers, always. For shops, participation rides the cloud tier;
engagement features (offers/punch cards, click & collect) sit in Pro. No ads,
no selling shopper data — the app exists to make the shops sticky, not to be
a revenue stream itself.
