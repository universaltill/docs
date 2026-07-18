# Review: remote price editing (Universal Till Cloud 2b — catalog editing, step 1)

**Date:** 2026-07-19 · **Repos:** `universal-till` (feat/remote-set-price),
`ut-market-place` (feat/remote-price-edit)
**Queue item:** 2b "Cloud catalog/inventory editing" — first slice: edit an
item's selling price from the cloud's Catalog & stock table.

## Design

New directive type `set_price {item_id, price_minor}` riding the existing
queue → sync → apply → result channel (nothing new in transport or auth):

- **Till**: `CatalogRepo.SetItemPrice` (single-column `base_price` update,
  mirrors `SetItemCostPrice`; raw SQL stays in `internal/data` per the repo
  guard; reports "item not found" when the id doesn't match so the cloud's
  result column says why). `cloudsync.apply` gains the `set_price` case with a
  `num()` payload reader (JSON numbers arrive as float64; string form
  tolerated) and rejects missing/negative amounts *before* touching the hook.
  Wired in pages to the repo method. After a price change the snapshot hash
  differs, so the next tick re-pushes the catalog and the cloud table shows
  the new price without extra plumbing.
- **Cloud**: `DirectiveTypes["set_price"]="item_id"` plus an explicit
  `price_minor` int64 ≥ 0 validation in `QueueDirective` (money = integer
  minor units per the API standard). The form handler parses the input with
  `ParseInt` and leaves the field unset on garbage so validation 400s instead
  of queueing junk. `SnapshotItem` now carries the till-side item `ID`
  (already present in the pushed rows) and the Catalog table's price cell
  becomes an inline mini-form (minor-units input prefilled with the current
  value + "Set price" button); rows from snapshots pushed before ids were
  reported fall back to plain text. `directiveSummary` renders
  `item → amount` for the history table. i18n key ×9.

## Risk review

- Same authorization as every directive (`authorizeMerchant`); no new
  endpoint. Negative/garbage prices rejected on BOTH sides (portal 400, till
  "failed" result). int64 vs float64 duality (pre/post JSON round-trip)
  handled in summary + till reader.
- Old till + new cloud: unknown type → clean "failed: unknown directive
  type" result, visible in history. New till + old cloud: nothing queues it.

## Tests

- till: `set_price` applied via hook (d4) and negative rejected without
  reaching the hook (d5) in the tick test; repo method covered by build +
  data-access guard; full till tests green.
- mp: QueueDirective valid/missing/negative price cases; sync/store tests
  untouched-green; full `verify.sh` green. One test-only stumble: the extra
  queued directive perturbed a later exact-list assertion — fixed by
  cancelling it within the test, which incidentally covers cancel-of-set_price.
