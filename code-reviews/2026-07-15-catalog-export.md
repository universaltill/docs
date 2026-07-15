# Code review — G22b: catalog CSV export

Date: 2026-07-15 · Repo: universal-till · Branch: feat/g22b-catalog-export
Spec: docs/architecture/integration-plugin-families.md (G22 — export is the
anti-lock-in half of the import that shipped as P1.4).

## What shipped

- `CatalogRepo.ExportRows` — whole catalog (name, SKU, primary-preferred
  barcode, price, category name, description, weighed, summed stock,
  active), active items first.
- `GET /api/catalog/export` (manager-gated, audited `catalog/export`) —
  streams `catalog-<date>.csv` as a download. Column names are taken from
  the importer's own synonym table (`Name, SKU, Barcode, Price, Category,
  Description, Sold by weight, In stock, Active`) so the file **round-trips
  through our importer by design**, not by luck; prices are written as
  plain decimals in the till's currency scale (`minorToDecimal`).
- Export button on the /import page (with "your data is yours" copy) and
  on the catalog page head. i18n en+fa (guard green).

## Review notes (self-review)

- The `Active` column is intentionally exported but ignored by the
  importer (unknown columns are skipped) — it's for spreadsheet users;
  inactive items come back active on re-import, which matches import's
  "create as active" semantics. Documented here, acceptable for v1.
- Stock is exported (sum over locations) but NOT imported (importer has a
  stock synonym but the import path doesn't write inventory) — G22
  follow-up; exporting it now costs nothing and helps migrations away.
- Variants are not exported (one row per item; variants are barely used
  pre-G29) — noted as a limit.
- SQL lives in `internal/data` (guard green); handler reuses the import
  page's manager gate + audit pattern.

## Tests + E2E

- `TestExportCSVRoundTripsThroughImporter` — the exact CSV shape written
  by the handler parses back through `catimport.Parse` with every field
  intact (incl. a weighed item), zero issues.
- `TestMinorToDecimal` — boundary cases incl. negatives and 0/3-decimal
  currencies.
- Live E2E, two processes: till A (50 demo items) → `/api/catalog/export`
  (200, 50 rows + header) → till B with an EMPTIED catalog → import commit
  → "Imported: 50 — Skipped: 0" → barcode `5000000000066` scans and rings
  Apple Juice 1L → second import: "Imported: 0 — Skipped: 50" (idempotent).

## Addendum (same day): stock import shipped

The importer now reads the stock column (`ImportItem.Stock/HasStock`,
blank/unparseable never blocks a row) and the commit path records a
`receive` movement at the default location per created item with
positive stock (same call as the inventory page, reason
"catalog import"). Round-trip test asserts stock; live E2E: till A
exported Apple Juice at 18.0 → emptied till B imported 50 items with 50
receive movements and inventory 18.0. Negative/zero stock intentionally
not carried (an opening receive of ≤0 makes no sense; adjustments are a
till-side action).

## Follow-ups

- Customer + sales-history export (rest of G22's anti-lock-in story).
- Variant rows once variants are actually in use.
