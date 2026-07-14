# Catalog import — Loyverse / Square / generic CSV (G22a, roadmap P1.4)

Status: **SHIPPED 2026-07-14** (review code-reviews/2026-07-14-catalog-import.md). The switching-cost killer: an
existing shop brings its catalog over in minutes. Built into the till
(back-office page); the per-system `import` plugin type stays the
extension path for exotic formats.

## Scope (increment 1 — items in)

- **`internal/catimport`**: CSV parser with per-format header mappings.
  Format auto-detected from the header row: **Loyverse** item export,
  **Square** catalog export, or **generic** (any CSV with recognisable
  name/price/sku/barcode/category/description columns — header synonyms,
  case-insensitive). Prices parsed with the shop's currency decimals.
- **`/import` page** (manager): upload the export file → **preview**
  (parsed rows + per-row issues: missing name/price, barcode/SKU already
  in the catalog) → **import**. Nothing is written at preview.
- Import creates items (name, price, description, weighed flag), attaches
  the barcode as primary, auto-creates missing categories, and **skips**
  rows whose barcode or SKU already exists (idempotent — re-running an
  import cannot duplicate). Result: created / skipped-with-reason
  summary. Audited (`catalog`/`import`, counts + format).
- Export (the anti-lock-in half) and customers/stock history: next
  increments; stock quantities land when present as an opening-stock
  movement only if a stock column is recognised (best-effort).

## Verification

Unit: format detection + row mapping for Loyverse/Square/generic
fixtures, price parsing (decimals, currency symbols, thousands),
duplicate skipping. E2E: upload a Loyverse-style CSV → preview counts →
import → items scannable at the till → re-import skips everything.
