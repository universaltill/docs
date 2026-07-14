# Review — catalog import: Loyverse/Square/generic CSV (P1.4 / G22a)

Date: 2026-07-14 · Repo: universal-till · Spec:
`architecture/catalog-import.md` (written first).

## What shipped

- `internal/catimport`: DB-free CSV parser. Format detected from the
  header row (Loyverse/Square/generic); column synonyms map headers
  case-insensitively (incl. `Current Quantity [Location]`-style, GTIN/
  EAN/UPC as barcode); Excel BOM stripped; ragged rows tolerated; prices
  parsed via the shop currency's decimals (symbols/thousands stripped,
  0-decimal currencies honest); Sheets' `.0`-suffixed barcodes
  normalised, non-digit/wrong-length barcodes dropped; Square variation
  names append to the item name ("Croissant Large"), "Regular" doesn't.
- `/import` page (manager, linked from Catalog): upload → **Preview**
  (recognised format, ready/skipped counts, per-row status; writes
  nothing) → **Import**. Rows whose barcode or SKU already exists are
  skipped server-side — **re-importing is idempotent**. Missing
  categories auto-created (`EnsureCategory`); barcode attached primary
  (instantly scannable). Result summary + audit
  (`catalog`/`import` with format/created/failed counts).
- Repo: `BarcodeExists` (items+variants), `SKUExists`, `EnsureCategory`.

## Bug caught live (fixed)

`EnsureCategory`'s INSERT named an `is_active` column the real
`categories` table doesn't have — and the import swallowed the error, so
new categories silently didn't attach (existing ones matched fine, which
masked it). Fixed the INSERT and made category failure a visible row
status instead of best-effort silence.

## Verification

Unit: three format fixtures (mapping, weighed flag, issues), price
parsing incl. `£4,250.00` and 0-decimal, barcode normalisation, headerless
rejection. Live E2E: Loyverse file → preview 2 ready/2 skipped with
nothing saved → import 2 created (weighed flag, price minor units,
barcode attached, **scans at the till**) → re-import 0/4 skipped →
Square file → categories Coffee/Bakery auto-created, variation naming,
GTIN scannable; unauthenticated upload refused. Full suite + guards green.

## Next G22 increments

Export (neutral CSV + competitor formats — the anti-lock-in half),
customers, opening stock from recognised stock columns, more source
systems via `import`-type plugins.
