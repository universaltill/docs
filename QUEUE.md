# Universal Till — Work Queue

_Last updated: 2026-07-17. Living checklist of what's left, **ordered by dependency**:
each phase mostly needs the one before it. Within a phase, do 🔴 before 🟡 before 🟢._
_`[ ]` = not started, `[~]` = in progress, `[x]` = done (bottom). **(field)** = Farshid
reported it from real use._

**Dependency flow (the critical path to the shopper platform):**
`fix + enable marketplace auth → cloud sync tier + store registry → e-receipts + loyalty
→ map / nearby search (needs shop density) → price comparison → public web + SEO
→ delivery & bookings`

Two tracks run **independently** of that path and can happen anytime:
**Owner intelligence** (till-local reports/forecasting) and **POS polish** (till fixes).

---

## Phase 0 — Fix & polish what's already live _(no dependencies — do now)_

### 🏪 Marketplace portal (Farshid field feedback)
- [ ] 🔴 **(field)** Fix account role — Farshid's login shows the **Admin** button but
      he's a **shop owner, not a marketplace admin**. Reduce his Zitadel grant to
      `merchant_admin` only (drop the staff/vendor roles I over-granted). Confirm which
      account he uses (farsid.mirza@gmail.com vs Farshid3003@gmail.com). **← blocks the
      "enable prod auth" item below.**
- [ ] 🔴 **(field)** Show **who is signed in** at the top (name + role chip); only show
      Admin / Developer links when the role is genuinely held.
- [ ] 🔴 **(field)** Merge **"My shop"** and **"My stores"** into one back-office.
- [ ] 🔴 **(field)** Build the real **plugin detail page** — today it's a stub showing a
      fake "Example Plugin"; its "Approve for stores" button does nothing.
- [ ] 🔴 **(field)** Plugin **cards have no description** — surface each listing's summary.
- [ ] 🔴 **(field)** "My shop": clicking a plugin **doesn't open details**; **Approve
      buttons do nothing** (wire the JS + fix silent auth failures).
- [ ] 🔴 **(field)** "Back to marketplace" link on `/plugins/{id}` → `/plugins` = **404**.
- [ ] 🟡 **(field)** `/ui/admin/reviews` **does nothing** — make the review queue work.
- [ ] 🟡 **(field)** **Developer console** — limit to **registered developers** + provide
      **API docs / OpenAPI** (endpoints, tokens, auth). mp already serves `/openapi.yaml`
      + Swagger `/docs` + `/redoc`; wire them in + gate behind developer registration.
- [ ] 🔴 Enable **marketplace auth in prod** (`Auth.Disabled=false`) — _needs the role fix
      first_; today `/ui/admin` is open to anonymous (mitigated per-page).

### 🎨 Content & assets
- [ ] 🟡 **(field)** Generate an **icon for every plugin** (~11: stripe, qrpay, demo, faq,
      ai, webhook, nosale, themes ×3, language packs ×2). Cards show a letter fallback now.
- [ ] 🟢 **(field)** **Teaching / advertising videos** for the POS (can't generate video
      directly — propose scripted screen-capture of real flows, GIF micro-demos per
      feature, or a reveal.js explainer exported to video).

### 🖥️ POS / till polish
- [ ] 🟡 **Keyboard-layout plugin** — physical layouts per locale (distinct from the OSK).
- [ ] 🟡 **Windows regular-printing** — plain-text/CUPS-equivalent path on Windows.
- [ ] 🟡 **WKDownloadDelegate** — arbitrary downloads inside the mac app.
- [ ] 🟡 **Scope-aware user settings** — the `user` settings scope isn't surfaced yet.
- [ ] 🟢 Tone down the **registration nag chip** (registration is optional, ADR-0015).
- [ ] 🟢 **Claim by QR on kiosk/Windows/Linux** — those shells navigate in place; show a
      QR on the claim panel so the owner claims from their phone.

---

## Phase 1 — Owner intelligence _(independent track — needs only sales-history in the till)_

- [ ] 🟡 **More owner reports** — best/worst sellers, dead stock, margins per
      item/category, year-over-year, hourly/weekday patterns, tax summaries. Uses data
      that already exists. (Ask Farshid which first.) Likely reporting-type plugins.
- [ ] 🔴 **Multi-year sales + stock history retention** — _prerequisite for forecasting_;
      confirm the journal/report data is kept long enough and is queryable as a
      per-item/variant time series.
- [ ] 🔴 **Order-ahead forecasting** — previous years' sales → suggested purchase
      quantities before seasonal demand. Start with seasonal statistics; any ML is
      self-hosted / Ollama (no paid AI APIs). _Needs history retention above._
- [ ] 🔴 **Predictions + alerts** — "runs out in ~N days", reorder-point low-stock
      warnings before stockout, unusual-sales / seasonal-spike alerts. Chips/banners +
      an alerts panel; later multilingual email. _Needs history + sell-rate._

---

## Phase 2 — Cloud foundation _(the gate for the whole shopper platform)_

- [ ] 🔴 **Cloud sync backend / paid cloud tier** — the monetization gate; a shop must be
      cloud-connected for anything shopper-facing to reach it (tills sit behind shop NAT).
- [ ] 🔴 **Store registry** — the public directory of cloud-connected shops the app/web
      searches. _Needs the cloud tier._
- [ ] 🟡 **Centralized back-office portal** (ADR-0013 L2/L3) — manage catalog/stock/fleet
      across stores from one console; ties to the paid multi-store licence. Claim flow +
      owner pages are the seed (shipped).
- [ ] 🟢 **Multi-cloud + on-prem sovereign** deployment (cheap/low-txn, cloud-less
      countries e.g. Iran) — the "how" of running the cloud tier where big clouds can't.

---

## Phase 3 — Shopper platform _(needs Phase 2; listed in its own build order)_

Designed in `architecture/consumer-app.md`, `item-discovery-and-universal-catalog.md`,
`arch/product-search-network.md`. Free for shoppers; shops participate via the cloud tier.

**3a — First shippable (works with even one shop):**
- [ ] 🔴 **Consumer mobile app shell (Android + iOS)** — one codebase (Flutter/React
      Native, decide later), talks only to the cloud API. The delivery vehicle for 3a.
- [ ] 🔴 **Paperless e-receipts & invoices in the app** — scan at tender → receipt/VAT
      invoice lands in the app; permanent proof of purchase (warranty/returns).
- [ ] 🔴 **Digital loyalty card + points/rewards wallet** — one QR scanned at any till;
      per-shop programs in one wallet.
- [ ] 🔴 **Coupons/offers, digital punch cards, gift cards & store credit** — per shop.

**3b — Discovery (needs several shops live = density):**
- [ ] 🟡 **Map & nearest shop** — find Universal Till shops nearby; hours, what they sell.
- [ ] 🟡 **Item search across nearby shops (G13)** — "who has it, cheapest, closest"; shop
      opt-in publishes catalog+stock to the cloud. _Then_ price comparison on top.
- [ ] 🔴 **Public web app + SEO discovery (G14)** — same search, **no login**, with
      crawlable pages carrying `schema.org/Product` + `Offer`/`LocalBusiness` structured
      data so **Google surfaces "in stock nearby" physical shops**, not just online ones.
      _Same publication pipeline as G13, one more frontend._
- [ ] 🟢 **Universal item catalog (G15)** — shared barcode→product repository. _Note:_ its
      till-side barcode auto-fill (increment 1) is **independent** and can ship in Phase 0/1.

**3c — Transactions & services (needs 3a/3b):**
- [ ] 🟡 **Click & collect / order ahead** + **delivery** (shop's own delivery first,
      courier handoff later) — orders drop onto the till as normal sales.
- [ ] 🟡 **Restaurant: order at table / takeaway** — table-QR → menu → kitchen ticket.
- [ ] 🟡 **Table reservations** — book a table; shows on the till's booking view.
- [ ] 🟡 **Appointment booking for service shops** (barber, dentist, salon, garage…) —
      services + staff + availability. Shared **bookable-resource** scheduling engine for
      tables *and* appointments; likely a booking/reservation-type plugin + cloud calendar.
- [ ] 🟢 **Speak your order in your language** (G17), spending history/budgeting, household
      sharing, privacy controls — later polish.

---

## Phase 4 — Adjacent & strategic arcs

- [ ] 🟢 **Mobile light POS** (Android/iOS BYOD register, LAN-paired to primary till) —
      merchant-side companion; mostly independent (LAN pairing exists).
- [ ] 🟢 **Storefront & hardware** — store.universaltill.com selling devices/parts;
      3D-print profiles for DIY POS; pro multilingual website.
- [ ] 🟡 **Payment orchestration + least-cost routing** (Farshid's real hardware idea) —
      NOT becoming a payment provider: a router that sends each card to the **cheapest
      eligible acquirer** (by BIN/scheme/region + failover), keeping the shop's money flow
      shop→acquirer→bank so we never hold funds / avoid acquiring licences. Fits plugin-
      first: each PSP/bank = a payment plugin behind one interface (Stripe plugin exists),
      a routing engine picks the cheapest. **Path:** (1) online/CNP routing first — pure
      software, add a 2nd PSP + cost-rules engine; (2) card-present later on a certified
      SmartPOS (PAX/Ingenico), certifying one acquirer then adding more (each = a cert
      project); start with debit dual-network LCR. Savings = acquirer markup + debit
      network + local-vs-cross-border (interchange itself is fixed). Caveats: PCI DSS on
      the routing layer (tokenize to reduce scope), PSP "no-steering" clauses, ISV/
      acquirer agreements. Build vs buy: Spreedly/Primer/Gr4vy/ProcessOut vs own router.
      Iran = separate Shetab/Shaparak track. **Next: decide build-vs-buy + first 2 PSPs,
      then an ADR.**
- [ ] 🟢 **Integration plugins** — Twilio SMS · SAP · iyzico (Turkey) · Google Calendar ·
      WhatsApp — each built + tested for real once Farshid provides sandbox keys.

---

## 🧪 Field tests pending _(ongoing — need Farshid's hardware)_

- [ ] 🔴 **Pi kiosk** boot test (cage + chromium --kiosk on the real Pi).
- [ ] 🟡 **Linux desktop app** on real Linux (amd64/arm64).
- [ ] 🟡 **Windows desktop shell** on a real Windows box (WebView2 vs browser fallback).
- [ ] 🟡 **2-till LAN stock-level sync** on the homelab.
- [ ] 🟡 Re-test **claim flow** after v0.2.19 (external link → browser; code reuse).

---

## ✅ Recently shipped (2026-07-16 → 17)

- [x] Help page **feature guide** (expandable per-feature explanations + steps, 4 locales)
- [x] Claim UX fixes: code **reuse** on repeat clicks; desktop webview **pinned to till**
      (external links open the browser) — v0.2.19
- [x] **Claim flow** both sides + back-office pages (My stores, per-store fleet detail,
      admin Stores directory, owner-scoped approvals)
- [x] Zitadel: granted owner account marketplace roles (⚠️ too broad — see Phase 0)
- [x] **On-screen keyboard** (touch tills, en/tr/fa/ar) — v0.2.17
- [x] **Stock-level sync** (primary-owned on-hand → replicas) + check-for-updates button
- [x] **Linux desktop app** + **Pi kiosk** packaging
- [x] **Windows desktop shell** (WebView2) — v0.2.14
- [x] **Catalog variant editor** redesign (per-item variants + barcodes)
- [x] Mac app **auto-update** + main-thread launch-crash fix
- [x] **Stripe Terminal** (card-present) + shared/per-till plugin settings
- [x] **Lazy store registration** (ADR-0015) + release pipeline hardening
