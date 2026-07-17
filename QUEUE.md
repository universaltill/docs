# Universal Till — Work Queue

_Last updated: 2026-07-17. Living checklist of what's left. Tick items as they land._
_Recently shipped is at the bottom. `[ ]` = not started, `[~]` = in progress._

Legend: 🔴 high / 🟡 medium / 🟢 later. **(field)** = Farshid reported it from real use.

---

## 🏪 Marketplace portal (Farshid field feedback 2026-07-17)

- [ ] 🔴 **(field)** Fix account role — Farshid's login shows the **Admin** button but
      he's a **shop owner, not a marketplace admin**. Reduce his Zitadel grant to
      `merchant_admin` only (drop the staff/vendor roles I over-granted). Confirm
      which account he actually uses (farsid.mirza@gmail.com vs Farshid3003@gmail.com).
- [ ] 🔴 **(field)** Show **who is signed in** at the top (name + role chip); only show
      Admin / Developer links when the role is genuinely held.
- [ ] 🔴 **(field)** Merge **"My shop"** and **"My stores"** into one back-office (two
      menus for the same thing is confusing).
- [ ] 🔴 **(field)** Build the real **plugin detail page** — today it's a stub showing a
      fake "Example Plugin"; its "Approve for stores" button does nothing.
- [ ] 🔴 **(field)** Plugin **cards have no description** — surface each listing's summary.
- [ ] 🔴 **(field)** "My shop": clicking a plugin **doesn't open details**; **Approve
      buttons do nothing** (wire the JS + fix silent auth failures).
- [ ] 🔴 **(field)** "Back to marketplace" link on `/plugins/{id}` → `/plugins` = **404**;
      point it at a real route.
- [ ] 🟡 **(field)** `/ui/admin/reviews` **does nothing** — make the review queue work
      (for the admin account).
- [ ] 🟡 **(field)** **Developer console** should be limited to **registered developers**
      and provide **API docs / OpenAPI** (all endpoints, tokens, auth). The mp already
      serves `/openapi.yaml` + Swagger `/docs` + `/redoc` — wire them in + gate the
      console behind a real developer-registration flow.
- [ ] 🔴 Enable **marketplace auth in prod** (`Auth.Disabled=false`) — re-evaluate after
      the role fix; today `/ui/admin` is open to anonymous (mitigated per-page).

## 🎨 Content & assets (Farshid asks 2026-07-17)

- [ ] 🟡 **(field)** Generate an **icon for every plugin** (set `icon_url`; cards show a
      letter fallback now). ~11 plugins: stripe, qrpay, demo, faq, ai, webhook, nosale,
      themes ×3, language packs ×2.
- [ ] 🟢 **(field)** **Teaching / advertising videos** for the POS. (Can't generate video
      directly — propose: scripted Playwright screen-capture of real flows, animated
      GIF micro-demos per feature, or a reveal.js explainer exported to video.)

## 📊 Reporting, forecasting & alerts (Farshid asks 2026-07-17)

- [ ] 🔴 **Order-ahead forecasting** — use previous years' sales + stock history to
      suggest what to order before seasonal demand (needs multi-year retention,
      per-item time-series, lead times; start with seasonal statistics; any ML stays
      self-hosted / Ollama — no paid AI APIs).
- [ ] 🔴 **Predictions + alerts** — "item runs out in ~N days", reorder-point low-stock
      warnings before stockout, unusual-sales / seasonal-spike alerts. Chips/banners +
      an alerts panel; later multilingual email.
- [ ] 🟡 **More owner reports** — best/worst sellers, dead stock, margins per
      item/category, year-over-year, hourly/weekday patterns for staffing, tax
      summaries. (Ask Farshid which first.) Consider building as reporting-type plugins.

## 🖥️ POS / till

- [ ] 🟡 **Keyboard-layout plugin** — physical keyboard layouts per locale (distinct from
      the on-screen keyboard, which shipped).
- [ ] 🟡 **Windows regular-printing** — plain-text/CUPS-equivalent path on Windows
      (thermal works; regular office printer needs the Windows equivalent of `lp`).
- [ ] 🟡 **WKDownloadDelegate** — arbitrary file downloads inside the mac app (today only
      specific save-to-Downloads endpoints work in the webview).
- [ ] 🟡 **Scope-aware user settings** — the `user` settings scope isn't surfaced in the
      UI anywhere yet.
- [ ] 🟢 Tone down the **registration nag chip** now that registration is optional
      (ADR-0015).
- [ ] 🟢 **Claim by QR on kiosk/Windows/Linux** — the claim link opens the browser on mac
      now, but the Pi kiosk & webview_go shells navigate in place; show a QR on the claim
      panel so the owner claims from their phone.

## 🧪 Field tests pending (need Farshid's hardware)

- [ ] 🔴 **Pi kiosk** boot test (cage + chromium --kiosk on the real Pi).
- [ ] 🟡 **Linux desktop app** on real Linux (amd64/arm64).
- [ ] 🟡 **Windows desktop shell** on a real Windows box (WebView2 vs browser fallback).
- [ ] 🟡 **2-till LAN stock-level sync** on the homelab.
- [ ] 🟡 Re-test **claim flow** after v0.2.19 (external link → browser; code reuse).

## 🛍️ Shopper platform — consumer app + public web (major arc)

The shopper-facing side of Universal Till — the network-effect engine. Designed
in `architecture/consumer-app.md`, `item-discovery-and-universal-catalog.md`,
`arch/product-search-network.md`. Depends on the cloud sync tier + store
registry; build after those. Shops must be cloud-connected to appear (honest
gating → subscription driver).

- [ ] 🔴 **Consumer mobile app (Android + iOS)** — one app across every Universal
      Till shop. One codebase (Flutter/React Native, decide later), talks only to
      the cloud API. Core: e-receipts + loyalty first (works with even one shop).
- [ ] 🔴 **Digital loyalty card + points/rewards wallet** — one QR scanned at any
      till; per-shop programs in one wallet.
- [ ] 🔴 **Paperless e-receipts & invoices in the app** — scan at tender → receipt/
      VAT invoice lands in the app; permanent proof of purchase (warranty/returns).
- [ ] 🔴 **Coupons/offers, digital punch cards, gift cards & store credit** — per shop.
- [ ] 🟡 **Map & nearest shop** — find Universal Till shops nearby; hours, what they sell.
- [ ] 🟡 **Item search across nearby shops + price comparison** ("who has it, cheapest,
      closest") — shop opt-in publishes catalog+stock to the cloud (G13).
- [ ] 🟡 **Click & collect / order ahead** + **delivery** (shop's own delivery first,
      courier handoff later) — orders drop onto the till as normal sales.
- [ ] 🟡 **Restaurant: order at table / takeaway** — table-QR → menu → kitchen ticket.
- [ ] 🟡 **Table reservations** — book a table; shows on the till's booking view.
- [ ] 🟡 **Appointment booking for service shops** (barber, dentist, salon, garage…) —
      services + staff + availability; booking becomes a scheduled sale. Shared
      "bookable resource" scheduling engine for tables *and* appointments; likely a
      booking/reservation-type plugin + cloud calendar.
- [ ] 🟢 **Speak your order in your language** (G17), spending history/budgeting,
      household sharing, privacy controls.
- [ ] 🔴 **Public web app + SEO discovery (G14)** — same nearby-item search as the app
      but **no login required**, with crawlable product/shop pages carrying
      `schema.org/Product` + `Offer`/`availability` + `LocalBusiness` structured data,
      so **Google surfaces "in stock nearby" physical shops** — not just online stores.
      Same publication pipeline as G13, one more frontend.
- [ ] 🟢 **Universal item catalog (G15)** — shared barcode→product repository; till-side
      barcode auto-fill can ship earlier (increment 1), community contribution last.

## ☁️ Cloud / back-office (bigger arcs)

- [ ] 🟡 **Centralized back-office portal** (cloud tier, ADR-0013 L2/L3) — manage
      catalog/stock/fleet across stores from one console; ties to paid multi-store
      licence. Claim flow + owner pages are the seed (shipped).
- [ ] 🟢 **Multi-cloud + on-prem sovereign** deployment story (cheap/low-txn, cloud-less
      countries e.g. Iran).
- [ ] 🟢 **Storefront & hardware** — store.universaltill.com selling devices/parts;
      3D-print profiles for DIY POS; pro multilingual website.
- [ ] 🟢 **Mobile light POS** (Android/iOS BYOD register, LAN-paired to primary till).

## 🔌 Integration plugins (need sandbox accounts from Farshid)

- [ ] 🟢 Twilio SMS · SAP Business Accelerator Hub · iyzico (Turkey) · Google Calendar ·
      WhatsApp — each built + tested for real once Farshid provides sandbox keys.

---

## ✅ Recently shipped (2026-07-16 → 17)

- [x] Help page **feature guide** (expandable per-feature explanations + steps, 4 locales)
- [x] Claim UX fixes: code **reuse** on repeat clicks; desktop webview **pinned to till**
      (external links open the browser) — v0.2.19
- [x] **Claim flow** both sides + back-office pages (My stores, per-store fleet detail,
      admin Stores directory, owner-scoped approvals)
- [x] Zitadel: granted owner account marketplace roles (⚠️ too broad — see top of queue)
- [x] **On-screen keyboard** (touch tills, en/tr/fa/ar) — v0.2.17
- [x] **Stock-level sync** (primary-owned on-hand → replicas) + check-for-updates button
- [x] **Linux desktop app** + **Pi kiosk** packaging
- [x] **Windows desktop shell** (WebView2) — v0.2.14
- [x] **Catalog variant editor** redesign (per-item variants + barcodes)
- [x] Mac app **auto-update** + main-thread launch-crash fix
- [x] **Stripe Terminal** (card-present) + shared/per-till plugin settings
- [x] **Lazy store registration** (ADR-0015) + release pipeline hardening
