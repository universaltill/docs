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

### 🧾 Till field bugs (Farshid screenshots 2026-07-17 evening)
- [x] 🔴 **(field)** **PIN pad rendered inside the header** — expired-session htmx
      fragment loads got a 302 that htmx swapped in place; now 401 + HX-Redirect →
      real navigation to the lock screen (v0.2.25, class-wide for all fragments).
- [x] 🔴 **(field)** **Catalog right panel too long** — sticky + capped height + inner
      scroll (v0.2.26).
- [x] 🟡 **(field)** **Labels print per variant** — Variant dropdown on the labels form;
      prints the variant's name, price and its own barcode (v0.2.26).

### 🏪 Marketplace portal (Farshid field feedback)
- [x] 🔴 **(field)** Fix account role — grant trimmed to `merchant_admin` only (verified
      live; sign out/in to refresh). Admin stays on the dedicated admin@ account.
- [x] 🔴 **(field)** Signed-in **name + role chip** in the nav; Admin/Developer links only
      for holders of those roles.
- [x] 🔴 **(field)** **"My shop"** single back-office (per-store "Tills & details" +
      "Manage plugins"; approvals bind to the browsed store).
- [x] 🔴 **(field)** Real **plugin detail page** (live listing data + working
      approve/unapprove; stub + fake buttons removed).
- [x] 🔴 **(field)** Plugin **descriptions** — real summaries written for all 11 listings
      (data had summary = name). ⚠️ follow-up below: fix plugin manifests too.
- [x] 🔴 **(field)** "My shop" **approve buttons + card clicks fixed** (handler was
      auth-gated out on prod; links pointed at a 404).
- [x] 🔴 **(field)** "Back to marketplace" 404 link fixed.
- [x] 🟡 **(field)** `/ui/admin/reviews`: staff **sessions** can assign/decide without the
      upload token; reviewer prefilled. (Page was live; queue was empty + token-only.)
- [x] 🟡 **(field)** **Developer console** gated to registered developers (vendor role) +
      **API docs linked** (Swagger UI / ReDoc / openapi.yaml with token notes).
- [x] 🔴 **Prod auth — closed deliberately**: `Auth.Disabled` stays true (flipping would
      demand JWTs on /api and break every till — they use store tokens). Per-surface
      enforcement completed instead; last gap closed: anonymous merchant
      entitlement writes now 401 whenever web login exists. **No anonymous writes
      remain; staff/owner UI fully role-gated; fleet untouched.**
- [x] 🟡 Plugin **manifest descriptions** — verified: all 11 manifests ALREADY carry real
      descriptions; the bad summaries were purely the ingest bug (root-cause fixed).
- [x] 🟡 **(field)** **Plugin trust badges + install consent** — SHIPPED BOTH SIDES:
      till (v0.2.27) + marketplace (storefront/portal/detail pills, same mapping).
      REMAINING (separate): "verified" assignment rules ride the vendor-registration
      decision. Original notes:
      🏠 gold official (com.universaltill.*), ✔ verified, ⚠ unverified badges on store
      cards + localized "do you trust this publisher: X?" confirm before downloading/
      installing unverified plugins. REMAINING: matching badge styling on the
      marketplace storefront/portal/detail; "verified" assignment rules (ties into
      vendor registration). Original ask:
      three visible tiers on every plugin card/detail — (1) **official Universal Till**
      plugins get a distinctive "golden house" badge; (2) **verified developers**
      (registered + paid) get a verified badge; (3) **unverified** publishers get an
      untrusted marker AND the till shows an install-time alert: "Do you trust this
      publisher?" with the publisher name before installing. Builds on the existing
      `trust_tier` field + first-party slug prefixes (signing config) + ADR-0006 trust
      chain; needs: tier assignment rules, badge design (storefront + portal + POS
      store cards), and the POS confirm dialog on untrusted installs.
- [ ] 🟢 Self-serve **vendor registration** flow (request + admin approval) — today a
      developer needs a manually-granted vendor role.

### 🎨 Content & assets
- [x] 🟡 **(field)** **Icons for all 11 plugins** — consistent SVG set embedded in the
      marketplace, served at `/ui/assets/icons/{slug}.svg`, wired to storefront/portal/
      detail. **POS store page renders them too** (28px beside the name).
- [ ] 🟢 **(field)** **Teaching / advertising videos** for the POS (can't generate video
      directly — propose scripted screen-capture of real flows, GIF micro-demos per
      feature, or a reveal.js explainer exported to video).

### 🖥️ POS / till polish
- [x] 🟡 **(field)** **Variant-specific images** — SHIPPED: 📷 upload per variant in the
      grid, stored `assets/items/{item}/variants/{variant}/thumb.png`, fallback chain
      variant → item → hidden. Follow-ups in the spec: sale-tile/store surfacing of
      variant images; image LAN-sync (item images have the same gap).
- [ ] 🟡 **Keyboard-layout plugin** — design questions written
      (`architecture/keyboard-layout-plugin.md`): scanner-wedge normalization vs
      search transliteration vs OS switching — **awaiting Farshid's pick** (recommend
      scanner normalization in core + transliteration as the plugin).
- [ ] 🟡 **Windows regular-printing** — plain-text/CUPS-equivalent path on Windows.
- [x] 🟡 **WKDownloadDelegate** — attachments / undisplayable responses / `<a download>`
      links now save to ~/Downloads with browser-style dedupe (macOS 11.3+ guarded).
      Needs a real-app click test on the next dmg.
- [ ] 🟡 **Scope-aware user settings** — NEEDS DESIGN FIRST (document-first): the wasm
      runtime carries no user identity into plugin evaluation, so a per-user setting has
      no runtime meaning yet. Write the spec (what user-scoped settings mean, how
      settings_get would resolve per-user) before any code.
- [x] 🟢 Registration nag → **quiet outline hint** "Marketplace: not connected" (ADR-0015).
- [x] 🟢 **Claim by QR** — the claim panel now shows a QR of the claim URL; the owner
      scans and claims from their phone (works on kiosk/Windows/Linux shells).

---

## Phase 1 — Owner intelligence _(independent track — needs only sales-history in the till)_

- [~] 🟡 **More owner reports** — SHIPPED: **Slow sellers**, **Dead stock** (tied-up
      value), **Busiest days & hours** (local-time buckets, CSS bars) on the reports
      page under the period selector, **Margins** (cost-price field in the catalog
      panel → revenue−cost card, unknown costs excluded), **Year-over-year KPI** (same
      window one year back; hidden until history exists), **Tax summary per rate**
      (net + tax collected, returns deducted), **variant-level cost editing** (Cost
      column in the variant grid → variant-cost-aware margins). Core report set DONE.
      ALSO FIXED: variant sales now fold into the parent item's sell rate / dead-stock
      / margin queries (an item selling via variants no longer shows as dead).
- [x] 🔴 **Multi-year retention verified** — sales/sale_lines are never pruned (only the
      explicit factory-reset deletes them); SQLite keeps full history, replicas journal
      to the primary, so the primary holds the whole shop's time series. Forecasting can
      query `sales`+`sale_lines` directly (see `ItemDailySellRates` as the pattern).
- [ ] 🔴 **Order-ahead forecasting** — previous years' sales → suggested purchase
      quantities before seasonal demand. Start with seasonal statistics; any ML is
      self-hosted / Ollama (no paid AI APIs). _Needs history retention above._
- [~] 🔴 **Predictions + alerts** — SHIPPED: "Days left" column (28-day rate,
      variant sales folded in), ⚠ ≤7-day warnings, header chips (inventory + reports),
      **reorder suggestions** ("order ~N" to a 14-day cover on running-out rows).
      REMAINING: per-item lead times, unusual-sales + seasonal-spike alerts,
      multilingual email alerts — **increment 1 SHIPPED**: claim captures the owner's
      email as org contact; `Notification` entity + till push endpoint + **My shop
      inbox** (unread badge, refresh-not-duplicate digests, i18n ×9); till pushes a
      **daily low-stock digest** (registered tills, best-effort). The EMAIL
      sender is now BUILT and shipping DORMANT (localized mail to the org's
      claim-captured contact, retry + no-resend semantics) — activation = setting
      NOTIFY_SMTP_*/NOTIFY_FROM on the mp deployment (Brevo creds from KV), done
      deliberately with Farshid since it makes prod send real mail. **Unusual-sales
      alert SHIPPED** (yesterday vs same-weekday 4-week baseline, ≥3-week guard,
      >1.8×/<0.4× incl. zero days; inbox row + mail text ×locales). Then: seasonal
      spikes (with the forecasting arc).

---

## Phase 2 — Cloud foundation _(the gate for the whole shopper platform)_

- [ ] 🔴 **Cloud sync backend / paid cloud tier** — the monetization gate; a shop must be
      cloud-connected for anything shopper-facing to reach it (tills sit behind shop NAT).
- [ ] 🔴 **Subscription select + pay** (Farshid 2026-07-17): NOT implemented — the owner
      back-office needs a plan page (free / paid tiers per ADR-0013), plan selection,
      and actual payment for the subscription (likely Stripe Billing to start), driving
      the entitlements that gate paid features/plugins. Design the plan matrix first.
- [ ] 🟡 **Shop badges** (Farshid 2026-07-17): shops get visible badges too (e.g.
      registered / claimed / subscribed tiers) — surface in the owner back-office and
      later on the shopper platform's shop pages. Define the badge set with the
      subscription tiers.
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
- [ ] 🟢 **Universal item catalog (G15)** — shared barcode→product repository (community
      loop, cloud). _Increment 1 (till-side barcode auto-fill from Open*Facts) is ALREADY
      SHIPPED — lookup package + /api/catalog/lookup + Auto-fill button all live._

**3c — Transactions & services (needs 3a/3b):**
- [ ] 🟡 **Click & collect / order ahead** + **delivery** (shop's own delivery first,
      courier handoff later) — orders drop onto the till as normal sales.
- [ ] 🟡 **Restaurant: order at table / takeaway** — table-QR → menu → kitchen ticket.
- [ ] 🟡 **Table reservations** — book a table; shows on the till's booking view.
- [ ] 🟡 **Appointment booking for service shops** (barber, dentist, salon, garage…) —
      services + staff + availability. Shared **bookable-resource** scheduling engine for
      tables *and* appointments; likely a booking/reservation-type plugin + cloud calendar.
- [ ] 🟢 **Shop ratings & reviews in the app** (Farshid 2026-07-17): shoppers can rate
      and review shops (and later items); shows on the shop's app/web page. Needs
      moderation + verified-purchase weighting (tie reviews to e-receipts so only real
      customers review); feeds the G14 public pages (schema.org AggregateRating = SEO).
- [ ] 🟢 **Speak your order in your language** (G17), spending history/budgeting, household
      sharing, privacy controls — later polish.

---

## Phase 4 — Adjacent & strategic arcs

- [ ] 🟡 **Android till app** (Farshid 2026-07-17) — the FULL Universal Till running on
      Android-ready POS hardware (PAX/Sunmi SmartPOS class, Android tablets). Distinct
      from the BYOD companion below: this is the till itself as an Android app (Go server
      via gomobile/WebView shell, or the till server + Android webview shell like the
      desktop shells). Also the delivery vehicle for the Phase-E SmartPOS payment app.
- [ ] 🟢 **Mobile light POS** (Android/iOS BYOD register, LAN-paired to primary till) —
      merchant-side companion; mostly independent (LAN pairing exists).
- [ ] 🟢 **Storefront & hardware** — store.universaltill.com selling devices/parts;
      3D-print profiles for DIY POS; pro multilingual website.
- [ ] 🟢 **Integration plugins** — Twilio SMS · SAP · iyzico (Turkey) · Google Calendar ·
      WhatsApp — each built + tested for real once Farshid provides sandbox keys.

## 💳 Payment orchestration + least-cost routing (major arc)

We route each card to the **cheapest eligible provider** — never a payment provider
ourselves, never holding funds. Each provider = a `payment` plugin; POS shows a button
per provider; **manual mode** (cashier picks among provider-locked readers — no
certification, ships now) + **automatic mode** (multi-acquirer device/gateway picks —
later). Full plan: `architecture/payment-orchestration-roadmap.md`; decision:
[ADR-0016](adr/0016-payment-orchestration-least-cost-routing.md); markets:
`architecture/payment-markets-launch-set.md`. Launch: **UK → GCC (UAE/BH/QA/OM) → Turkey.**

**A. Decisions & agreements (blockers, no code):**
- [ ] 🔴 A1 Routing engine plumbing: **write our own provider connections** vs **rent an
      orchestration service** (Spreedly/Primer/Gr4vy — software APIs, NOT devices; they
      maintain ready-made connections to dozens of PSPs). Our orchestrator (plugins,
      buttons, cost rules) exists either way; this only decides what's under its hood.
      Affects Phase D (online auto-routing) only — Phase C manual mode needs neither.
- [ ] 🔴 A2 First two providers to route between (e.g. Stripe + SumUp / Stripe + Adyen).
- [ ] 🟡 A3 GCC aggregator covering UAE+BH+QA+OM + domestic schemes — coverage in writing.
- [ ] 🟡 A4 Turkey: GİB-certified fiscal-POS partner + iyzico vs Craftgate.
- [ ] 🟡 A5 ISV/acquirer agreements + review PSP **"no-steering"** clauses.
- [ ] 🟡 A6 PCI scope strategy (tokenization / network tokens / P2PE).

**B. Foundation (provider-agnostic):**
- [x] 🔴 B1 **Payment-provider contract defined + documented**
      (`reference/payment-provider-contract.md`): payment entries → tender buttons,
      blocking `.authorize`, async `.requested` (settle-link), and the NEW blocking
      **`.refund` leg** — a provider must send the money back or the return is blocked
      (cash unaffected). Much of this existed; refund was the real gap.
- [x] 🔴 B2 **Stripe plugin 1.2.0 on the full contract** — event dispatch, sale→charge
      linking in plugin storage, partial refunds via /v1/refunds. **Proven E2E against
      the real Stripe test API**; published + approved on the marketplace.
- [x] 🔴 B3 POS **button per enabled provider** — verified pre-existing
      (SyncPluginPaymentMethods → payment_methods → tender UI).
- [x] 🔴 B4 **Cost-rules config SHIPPED**: per-provider percent+fixed fees in
      Settings → Payments (bp/minor storage, LAN-synced).
- [x] 🟡 B5 Offline-first sale path untouched (refund gate is per-method, cash never gated).

**C. Manual multi-provider — ships now, UK, no certification (← the near-term win):**
- [ ] 🔴 C1 Add a **second REAL provider plugin** (per A2 — SumUp/Adyen; demo+qrpay+stripe
      already give multiple buttons for the UX, so this is about a second real acquirer).
- [x] 🔴 C2 Manual-selection UX **COMPLETE**: merchant default (preferred provider
      leads the tender UIs) + live **"≈ −fee" hints** on every Pay button computed from
      the basket total and the B4 fee rules — the cashier sees the cheaper provider at
      a glance. Manual least-cost routing (M2) is now fully usable pending C1's second
      real provider (A2 decision) and the C4 shop pilot.
- [ ] 🟡 C3 Record which provider was used on sale/journal/receipt.
- [ ] 🔴 C4 **UK pilot** on real hardware (Farshid's shop) with two providers.

**D. Online / card-not-present automatic routing (UK; pure software):**
- [ ] 🟡 D1 **BIN → scheme/type/region** detection.
- [ ] 🟡 D2 **Routing engine** — cheapest by cost table + failover + success-rate.
- [ ] 🟡 D3 Second **online acquirer** integration (Adyen/Checkout) as a plugin.
- [ ] 🟢 D4 Pay-by-link / e-commerce surface uses the router.

**E. Card-present automatic LCR (later; certification-heavy):**
- [ ] 🟢 E1 Target device: certified **SmartPOS** (PAX/Sunmi) app or gateway-bound terminal.
- [ ] 🟢 E2 **Per-acquirer certification** (EMV L3 + scheme + host) — one, then add.
- [ ] 🟢 E3 **Debit dual-network selection** (standards-native LCR).
- [ ] 🟢 E4 **Tap-to-Pay (PCI MPoC)** — no-hardware option.
- [ ] 🟢 E5 Key injection / estate management (PAXSTORE / RKI).

**F. Market rollout (parallel once C/D prove out):**
- [ ] 🟡 F2 **UAE** — GCC beachhead via the A3 aggregator (F1 UK = done via C/D).
- [ ] 🟢 F3 **Bahrain → Qatar → Oman** — same aggregator + per-country CB approval + switch.
- [ ] 🟢 F4 **Turkey** — own track: fiscal-POS + Troy + iyzico/Craftgate.

**G. Cross-cutting / compliance (ongoing):** PCI DSS on the routing layer · cost-rules
maintenance · per-market agreements/CB approvals · Iran/Shetab as a separate future track.

_Milestones: M1 decisions locked · **M2 foundation + manual mode live in the UK (near-term)** ·
M3 automatic online routing · M4 card-present auto LCR · M5 market expansion._

---

## 🧪 Field tests pending _(ongoing — need Farshid's hardware)_

- [ ] 🔴 **Pi kiosk** boot test (cage + chromium --kiosk on the real Pi).
- [ ] 🟡 **Linux desktop app** on real Linux (amd64/arm64).
- [ ] 🟡 **Windows desktop shell** on a real Windows box (WebView2 vs browser fallback).
- [ ] 🟡 **2-till LAN stock-level sync** on the homelab.
- [ ] 🟡 Re-test **claim flow** after v0.2.19 (external link → browser; code reuse).

---

## ✅ Recently shipped (2026-07-16 → 17)

- [x] **Marketplace portal fix batch** (tasks 1–8 of the ordered queue, 2026-07-17
      evening): role trim, identity chip, one "My shop" back-office, real plugin detail
      page, working approvals, descriptions + icons, staff review sessions, developer
      console gating + API docs, per-surface auth enforcement completed (no anonymous
      writes anywhere; global flag left as designed for the fleet).
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
