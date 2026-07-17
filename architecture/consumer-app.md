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
- **Speak your order in your language** (Farshid, 2026-07-14 — G17) — the
  customer speaks the order in their own language (e.g. Farsi, Polish,
  Urdu); the shop receives it translated into the shop's language and
  matched to real catalog items. In the app, speech-to-text is the
  phone's own on-device engine (free, private); translation + item
  matching run server-side (or local Ollama when built into the till's
  self-checkout / customer display — self-hosted per the AI rule, and the
  offline-first sale screen stays untouched: this is an ordering surface,
  not checkout). Removes the language barrier for immigrant communities
  and tourists — an audience the big POS vendors ignore, and a natural
  companion to the till's existing 9-locale/RTL support.
- **Spending history & simple budgeting** — every e-receipt is structured
  data; show per-shop and per-category totals. (Data stays the shopper's.)
- **Household sharing** — share receipts/warranties/gift cards with family.
- **Privacy as a feature** — explicit per-shop opt-in, no ad brokerage, delete
  everything anytime. The credible position given our open-source stance, and
  a contrast to supermarket loyalty schemes.

### Services & bookings (Farshid, 2026-07-17)

The app so far assumes *retail* (find item → buy/collect/deliver). Farshid's
list adds two service verticals that need **availability/scheduling**, not just
a catalog — a distinct capability the big grocery-loyalty apps don't touch, and
a natural fit for the independent barbers, clinics and restaurants Universal
Till targets.

- **Restaurant — order at the table & takeaway ordering.** Scan a table QR →
  the shop's menu (the till catalog, with modifiers) → order lands on the till
  as a normal sale/kitchen ticket (reuses order-ahead G5 + kitchen print; the
  offline sale screen is untouched). Pairs with "speak your order in your
  language" (G17) for tourists/immigrant diners. Pay in-app or at the counter.
- **Table reservations.** Book a table for a time/party size; the shop sets
  its floor/slots/capacity; the reservation shows on the till's booking view.
  No-show and reminder handling via the app.
- **Appointment booking for service shops** (barber, dentist, salon, garage,
  clinic…). The shop publishes **services** (name, duration, price, which
  staff member), working hours and per-staff availability; the shopper picks a
  service + time + (optionally) a specific person and books. On the till side
  the booking becomes a scheduled appointment that converts to a sale when the
  service is delivered. Deposits/prepay via the wallet; reminders + reschedule
  + cancellation windows in the app.
- **Shared scheduling model.** Tables and appointments are the same underlying
  primitive — a **bookable resource** (a table, a chair, a dentist, a bay) with
  a calendar of availability and bookings. Build one scheduling/availability
  service; restaurant tables and service appointments are two configurations of
  it. This is almost certainly a **plugin(s)** on the till (booking/reservation
  type) plus the cloud calendar the app reads/writes — per the plugin-first and
  honest-gating rules (the shop must be cloud-connected for the app to reach its
  calendar).
- **Why it matters:** appointments and reservations give the shopper a reason
  to open the app *between* purchases, and pull in a whole class of merchants
  (services) that a pure retail loyalty app can't serve. Booking is also a
  standalone paid feature for shops that only want scheduling, not a till.

Sequencing: this is a **later phase** — after e-receipts + loyalty + the cloud
tier prove out. Restaurant/table ordering is the closest to existing pieces
(order-ahead + kitchen print already exist); appointment booking is the larger
net-new build (scheduling engine, staff/availability model).

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
