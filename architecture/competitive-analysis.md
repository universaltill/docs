# Competitive analysis — successful POS systems: features to adopt, weaknesses to exploit

Status: research summary, 2026-07-14 (web research; sources at the bottom).
Farshid's ask: "find very successful pos systems and find all the features and
problems they have — add the features to our list to implement, and find their
problems and lack of features" (i.e. our differentiators).

## The competitors, one line each

| System | Position | Core strength | Achilles heel |
|---|---|---|---|
| **Square** | Default for small shops | Easiest onboarding, free tier | Rising fees (2.6%+15¢ in-person, 3.3%+30¢ online, 2025); **account freezes/fund holds by opaque algorithm**; support paywalled after 90 days |
| **Toast** | Restaurant market leader | Deep restaurant workflows | **Proprietary hardware lock-in ($5–15k), 2–3yr auto-renew contracts, forced payment processing**, post-term rate hikes; thousands in ETFs |
| **Lightspeed** | Complex retail | Best-in-class inventory (POs, vendors, stock transfers, analytics) | **No true offline mode**; confusing tiered pricing |
| **Shopify POS** | Omnichannel | Unified online+in-store commerce | POS forces an e-commerce subscription — dead weight for a physical-only shop |
| **Clover** | Configurable middle | Rich app marketplace, durable hardware | Steep learning curve; advanced reporting behind pricier tiers; processor tie-ins |
| **Loyverse** | Free-tier rival (closest comp) | Free core POS + KDS + loyalty, bring-your-own processor | Advanced inventory + employee mgmt = $29/mo/store each; not open source; no offline-first guarantee |

Cross-cutting market signals: **90% of restaurants name better integrations
as their top POS priority**; cloud systems that stop when the internet drops
are a named, recurring pain; "tablet hell" (one tablet per delivery platform)
is universally hated; automatic guest/loyalty data capture and
**commission-free online ordering** are the 2026 must-haves.

## Our structural advantages (their problems we already solve)

1. **True offline-first** (ADR-0003) — Lightspeed can't do it, cloud rivals
   degrade badly. Checkout literally never blocks on the network here.
2. **No lock-in of any kind** — MIT license, generic hardware (Pi to old PC),
   bring-your-own payment processor, data export free. The anti-Toast.
   Marketing line writes itself: *no contracts, no proprietary hardware, no
   forced processor, no fund freezes — your till, your money, your data.*
3. **No processing skim** — we never sit in the money flow, so the Square
   fee-creep/fund-freeze failure mode cannot happen to our users.
4. **Free forever core beyond Loyverse's** — their $29/mo add-ons (advanced
   inventory, employees) are free here; plus open source, RTL + per-shop
   translation editor, and a signed plugin marketplace.
5. **Cheap hardware** — £70–380 DIY tiers (docs/hardware/diy-pos.md) vs
   $5–15k Toast fits.

## Feature gaps to adopt (added to the backlog, in rough order)

| # | Feature | Where they have it | Fit for us |
|---|---|---|---|
| G1 | **Loyalty / customer capture** — points or visit-based, automatic capture at tender, repeat-customer insight | Square, Loyverse (free tier!), Toast | Core (customers table exists); cloud tier syncs across stores |
| G2 | **Gift cards & store credit** | All majors | Core feature; offline-safe (local balance, sync reconcile) |
| G3 | **Kitchen Display System** | Toast, Loyverse (free) | Plugin (`customer_facing`/page type exists); pairs with multi-till LAN sync |
| G4 | **Table management / open tabs** | Toast, Lightspeed Restaurant | Restaurant vertical plugin; builds on hold/resume |
| G5 | **Commission-free online ordering** — shop's own ordering page feeding the till | Toast add-on, owner.com's whole pitch | Cloud service (needs public endpoint) → paid tier flagship |
| G6 | **Advanced inventory: purchase orders, vendors, stock transfers, reorder suggestions** | Lightspeed's crown jewel | Core roadmap (roadmap already lists advanced inventory); AI forecast increment ties in |
| G7 | **Employee time clock & scheduling** | Toast, Square add-on ($) | Core-lite (clock in/out on PIN login exists conceptually) + reports |
| G8 | **Customer-facing display** (order + price as it rings) | Clover, Loyverse (free) | `customer_facing` plugin type reserved; also the related-items surface |
| G9 | **Barcode label printing** | Lightspeed, Square retail | Catalog page addition, prints via receipt printer |
| G10 | **E-commerce sync** (Shopify/WooCommerce as optional plugin, not forced bundle) | Shopify (inverted) | Integration plugin + relay; anti-Shopify positioning |
| G11 | **Guest data → e-receipts** (email/SMS receipt captures the customer) | Square's loyalty engine | Cloud tier; feeds G1 |
| G12 | **AI insights/forecasting** | 2026 trend everywhere | Already our AI roadmap (ask-your-till, nightly forecast) |
| G13 | **Consumer stock search** — app shows nearest shop with the item in stock (subscribed shops share stock) | Nobody cross-merchant; supermarket apps per-chain | Consumer app + cloud tier; spec: [item-discovery-and-universal-catalog.md](item-discovery-and-universal-catalog.md) |
| G14 | **Public web discovery / SEO** — googling a product surfaces nearby offline shops that stock it | Google local inventory ads (paid); ours organic+free | Public web app + schema.org structured data; same spec |
| G15 | **Universal item catalog** — barcode → auto-filled item data, community-corrected, GTIN-keyed + UT ids for the GTIN-less long tail | Open Food Facts (food only), GS1 (closed) | Cloud catalog service; till-side auto-fill can ship early; same spec |
| G16 | **Central paperless receipts & invoices** — one loyalty-QR scan at tender and the bill lands in the shopper's app account instead of the printer; full history, returns/warranty/VAT invoices without paper | Square email receipts (email-only, per-merchant); nobody has one cross-shop receipt account | Consumer app + cloud tier; the loyalty scan (G1) and the receipt push share one scan — supersedes G11's email/SMS as the primary path, email/SMS stay as the no-app fallback |
| G17 | **Speak-your-order in any language** — the customer speaks their order in their own language; it reaches the shop translated into the shop's language and matched to catalog items | Nobody; McDonald's trialled English-only voice ordering | Two surfaces: consumer app (phone's on-device speech-to-text, free) and self-checkout / customer-display plugin (local Whisper + Ollama translation — self-hosted per the AI rule); catalog matching can lean on G15's multilingual item data |

Verticals (restaurant KDS/tables, salon appointments) confirm the existing
appointments-plugin plan — Clover's app-marketplace model validates our
marketplace as the delivery mechanism for all of these.

## What we deliberately will NOT copy

- Payment processing as a profit center (their #1 complaint generator).
- Contracts, proprietary hardware, early-termination fees.
- Paywalled support for the free product (community support stays; SLA is the
  paid tier).

## Sources

- https://fitsmallbusiness.com/square-pos-review/ · https://koronapos.com/blog/square-pos-customer-service/ · https://www.cardpaymentoptions.com/credit-card-processors/square-review/
- https://addmi.com/blog/toast-pos-alternatives-restaurants · https://www.sleftpayments.com/learning-hub/toast-pos-raised-fees-options-2026 · https://startupowl.com/reviews/toast
- https://dupple.com/learn/best-pos-systems · https://www.nerdwallet.com/business/software/best/point-of-sale-pos-systems · https://matagora.com/blogs/matagora-blog/shopify-pos-vs-square-clover-lightspeed-what-s-best-for-small-businesses-in-2026
- https://www.squirrelsystems.com/posts/technology/top-pos-features-for-2026-what-modern-operators-expect-from-a-cloud-first-restaurant-platform/ · https://getquantic.com/restaurant-pos-system-features/
- https://www.dataonems.com/post/best-offline-pos-system-for-selling-without-an-internet-connection
- https://www.deliverect.com/en/pricing · https://www.cloudwaitress.com/online-ordering-systems/otter-review/
