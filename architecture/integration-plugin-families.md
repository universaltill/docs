# Integration plugin families (proposal — G22–G25)

Status: **backlog proposal — 2026-07-14** (Farshid: "plugins to import and
export data from and to the famous till and POS systems; real payment,
accounting, delivery integration plugins; payment should have some fake
cards to test").

The 20-type taxonomy already reserves `import`, `export`, `payment`,
`integration` and `delivery` — these families put real plugins behind
those types. The WASM host functions (`net:<host>`, `storage`) are the
platform they run on.

## G22 — POS migration: import/export the famous systems

- **Import** (the switching-cost killer): one plugin per source system
  reading their standard exports — Square, Loyverse, Lightspeed (incl.
  X-Series/Vend), Shopify POS, Clover, Epos Now, Toast. Catalog with
  prices/barcodes/categories first, then customers and stock levels.
  Wizard UX: upload the export file → mapping preview → import report.
- **Export**: the same data out of Universal Till in both a neutral CSV
  set and the competitors' import formats. Anti-lock-in credibility means
  **leaving us must be as easy as joining** — this is a headline feature,
  not an afterthought.
- Start with Loyverse + Square importers (closest competitor + biggest
  installed base); the import wizard core is shared, per-system plugins
  only supply format mappings.

## G23 — Real payment terminal plugins (+ fake cards to test)

- Closes the known production gap "payment is quick-tender stubs". One
  plugin per provider, `payment` type, terminal talked to over LAN/BT/USB
  or provider API: **SumUp, Stripe Terminal, Adyen, Viva Wallet** are the
  realistic first targets (developer-friendly APIs, EU/UK presence).
  Provider choice stays the merchant's — we never become the processor
  (competitive-analysis red line).
- **`ut-plugin-payment-demo` — the fake-card terminal** (build FIRST):
  simulates a card terminal with deterministic test cards —
  `4242…` approves, one number declines, one times out, one requires a
  retry — so shops can train staff, demos work anywhere, and the whole
  tender path gets E2E tests with zero hardware. Also the reference
  implementation for real terminal plugin authors.
- Real providers' sandbox modes (Stripe/SumUp test keys + their published
  test cards) get first-class support in each plugin's settings:
  a "sandbox" toggle so a live shop can trial before going live.

## G24 — Accounting integration plugins

- Xero, QuickBooks, Sage (UK trio) as `integration` plugins: nightly push
  of the day's journal — sales totals, tax breakdown by rate, payment
  method split, shift variances — as proper journal entries, not raw
  transactions. OAuth to the provider; tokens in plugin storage;
  `net:<provider>` permission shows the merchant exactly where data goes.
- Reuses the ask-your-till tool surface's aggregates (sales_by_day,
  payment_breakdown) — same numbers, pushed instead of asked.

## G25 — Delivery platform plugins

- The plugin half of the already-designed delivery relay (monetization
  doc §5, £9.99/store bundle): Uber Eats, Deliveroo, Just Eat plugins
  receive orders via the relay (platforms need a public webhook endpoint —
  that's what the subscription pays for), drop them onto the till as
  normal sales, and sync item availability back (the 86'd-item killer
  feature).
- Order flow is till-local once received — offline rules unchanged.

## Shared mechanics

- All families ship as marketplace plugins through the (G20) QA pipeline;
  permissions make the data flows visible at install.
- Per-provider secrets live in plugin storage, never in env or the repo.
- Each family gets one reference/sample plugin first (demo payment
  terminal, Loyverse importer, one accounting push, one delivery relay
  consumer) to prove the type's engine end-to-end before scaling out.
