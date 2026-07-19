# Review: variants in the catalog snapshot (+ variant price edits)

**Date:** 2026-07-19 · **Repo:** `universal-till` (feat/variants-in-snapshot)
**Queue item:** 2a catalog up-sync "REMAINING: variants in the snapshot".

## What changed

- `pushSnapshotIfChanged` now emits one row per active variant directly under
  its parent item: variant id, composed name ("Coca-Cola — 1.5L"), the
  variant's own price and primary barcode. **No qty on variant rows** — stock
  is item-level (ADR-0011), so repeating the parent qty would double-count the
  shop's stock units; the cloud's sum type-asserts `qty` and simply skips
  missing values, and the table renders a blank Qty cell. Zero cloud-side
  changes needed.
- `CatalogRepo.SetItemPrice` falls through to `item_variants.price` when the
  id isn't an item — the snapshot lists variant ids, so the store page's
  inline price editor now works on variant rows too. Unknown id still reports
  "item not found" in the directive result.
- Test-support items DDL gained `updated_at` (the real migrations have it;
  `SetItemPrice`/`SetItemCostPrice` stamp it — the minimal schema was the
  only place it was missing).

## Risk review

- Snapshot grows by the active-variant count; the cloud caps at 20k rows and
  the hash gate means no extra traffic unless data changed.
- Old cloud renders variant rows as normal items (name/price/barcode, blank
  qty) — degrades fine.
- Variant price update restricted to `is_active = 1` — a remote edit can't
  silently change a retired variant.

## Tests

- Snapshot test: item + variant rows, composed name/price/barcode, no `qty`
  key on the variant row.
- `TestSetItemPriceReachesVariants`: item hit, variant fall-through, unknown
  id error; values verified in both tables.
- Full till suite + data-access guard + i18n guard green.
