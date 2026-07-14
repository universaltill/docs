# Item discovery & universal catalog (proposal)

Status: **backlog proposal — 2026-07-14** (Farshid's three requests, cleaned
up). Three features that build on each other, in order: in-app stock search
(G13) → public web discovery (G14) → universal item catalog (G15). All three
ride the cloud tier and the catalog/stock publication opt-in already sketched
in [consumer-app.md](consumer-app.md).

## G13 — "Who has it near me?" search in the consumer app

A shopper searches for an item in the mobile app and sees the **nearest
shops that have it in stock right now**, with price and distance.

- Shops on the cloud subscription opt in to **publish catalog + stock
  levels** to the cloud (per-shop toggle; publishing is the value they get
  for the subscription — honest gating).
- Search matches across all published catalogs; results ranked by distance,
  showing price and a stock indicator (in stock / low / call ahead — exact
  counts stay private if the shop prefers).
- Already listed as "Search & price comparison" in the consumer-app
  proposal; this makes it a first-class backlog item with the stock-sharing
  mechanic spelled out: **subscription = your stock becomes discoverable**.
- Depends on: cloud sync tier, store registry, catalog/stock publication,
  reasonably fresh stock sync (the till already tracks stock levels
  offline; publish on reconnect).

## G14 — The same search on the public web (SEO for offline shops)

Today, googling a product shows only online shops. After this feature,
Universal Till's public web pages rank in that search and answer: **"this
item is available at these physical stores near you."**

- A public web app (universaltill.com or a dedicated domain) with the same
  search as the mobile app — no login needed to search.
- **Crawlable product + shop pages** with `schema.org/Product` +
  `Offer`/`availability` + `LocalBusiness` structured data, so Google can
  surface "in stock nearby" results organically. This is what Google sells
  merchants as *local inventory ads* — we give the organic version to every
  subscribed shop for free. That is a genuinely strong pitch: a village
  shop's stock becomes googleable without them doing anything.
- Same data source as G13 (one publication pipeline, two frontends); the
  web app is also the no-install fallback for shoppers who won't download
  an app.
- Privacy/abuse notes for the spec: shops choose what is public (whole
  catalog vs selected categories), scraping/rate limits, and no shopper
  data on the public side at all.

## G15 — Universal item catalog repository

A shared, community-maintained product database so no shopkeeper ever types
a product description again.

- **Barcode → auto-fill**: when a shop adds a new item, scanning the
  barcode looks up the shared catalog and pre-fills name, description,
  brand, category, image, pack size. Shop just confirms and sets the price.
- **Community contributions**: shops can fix/extend item data (better
  description, photo, translation); moderated edits flow back to the shared
  catalog so every shop benefits — Wikipedia/Open Food Facts model, but for
  general retail.
- **Bootstrap sources**: GS1-registered data where available, open
  databases (Open Food Facts / Open Products Facts for food+some retail),
  plus every catalog our shops publish (G13) becomes seed data. The AI
  camera-identify `ai_ref` photo corpus ties in as image data.
- **On the global unique item number ("ISBN for everything") dream**: this
  already exists — it is the **GS1 GTIN** (the EAN/UPC barcode number),
  assigned starting at manufacturers exactly like ISBN; ISBN itself has
  been a GTIN subspace since 2007. So we do not invent a new worldwide
  numbering scheme (that requires being GS1); instead:
  - GTIN is the **primary key** of the universal catalog;
  - we issue **UT item identifiers** only for the real gap: items with no
    GTIN — local produce, bakery goods, handmade items, market stalls —
    with a namespace that can't collide with GTINs. If the catalog gets
    big enough, that UT namespace *becomes* a de-facto registry for the
    long tail GS1 ignores, which is the realistic version of the dream.
- Depends on: cloud tier, a moderation/trust mechanic (start: manual
  review + reputation later), and the G13 publication pipeline for seed
  data.

## Why this trio matters strategically

G13/G14 are the **network-effect engine** of the consumer app (each shop
makes search better; search visibility pulls in the next shop — the
strongest subscription driver we have designed). G15 lowers onboarding
friction for every new shop (no catalog typing) while making the network's
data quality compound. None of the majors (Square/Toast/Clover/Lightspeed)
offers cross-merchant discovery — they have no incentive to; we do.

## G15 increment 1 — till-side barcode auto-fill (spec, 2026-07-14)

Green-lit by Farshid ("so we can have auto fill. nice. go ahead"). Scope:
the till looks up scanned barcodes in open product databases and pre-fills
the new-item form. No cloud tier, no contribution loop yet.

- **`internal/lookup`** package: queries Open Food Facts, then Open
  Products Facts, then Open Beauty Facts (`/api/v2/product/{barcode}` —
  free, no key, proper User-Agent per their API policy). Barcode must be
  6–14 digits (EAN-8/UPC-A/EAN-13/GTIN-14 plus short internal codes).
  Returns name, brand, quantity, description, image URL, source.
- **`GET /api/catalog/lookup?barcode=…`** → `{data,error}` envelope;
  400 invalid barcode, 404 not in any source, 502 network down. Audited
  (`catalog` / `barcode_lookup`).
- **Catalog page**: barcode field + Auto-fill button on the new-item form.
  Found → fills name/description, remembers the image URL; the barcode
  itself is submitted with the create and **attached as the item's primary
  barcode**, so the item is instantly scannable at the till.
- **Item image**: on create, if the lookup supplied an image URL the server
  downloads it and saves the standard `thumb.png` — host-allowlisted to
  the three Open*Facts image domains (SSRF guard), 5 MB cap, decoded and
  re-encoded like the manual upload path.
- **Offline-first posture**: back-office convenience only; the button
  fails soft with a message. Checkout untouched.
- Later increments (not now): community contribution loop, GTIN-less UT
  identifiers, cloud shared catalog seeded by shop publications.

## Build order & fit with existing plans

1. G15's till-side half (barcode → auto-fill from open databases) can ship
   **early** — it only needs an internet lookup from the catalog page, no
   cloud tier. Big onboarding win, cheap.
2. G13 after the cloud sync tier + store registry (consumer-app bootstrap
   sequence already puts map/search after e-receipts+loyalty).
3. G14 right after G13 — same data, one more frontend + structured data.
4. G15's community-contribution loop last (needs enough shops to moderate
   meaningfully).
