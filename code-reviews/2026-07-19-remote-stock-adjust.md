# Review: remote stock adjustment (catalog editing step 2)

**Date:** 2026-07-19 · **Repos:** `universal-till` (feat/remote-stock-adjust*),
`ut-market-place` (feat/remote-stock-adjust)
**Queue item:** 2b cloud catalog/inventory editing — second slice: adjust an
item's on-hand quantity from the cloud's Catalog table.

*shipped on the same till branch as the wire hook.

## Design

New directive `adjust_stock {item_id, qty_delta, reason?}`:

- **Till**: `cloudAdjustStock` mirrors the inventory page's manual adjustment
  exactly — same `pos.RecordStockMovement` (movement type `adjust`, actor
  `cloud`, default reason "cloud adjustment") and the same
  `publishStockAdjusted` connector event, so ERP connectors see remote
  adjustments identically to local ones. The cloud has no location picker, so
  the movement lands on the location where the item already tracks stock,
  else the shop's first stock location, else a clean "no stock location
  configured" failure in the result column. `apply()` gains an `fnum` reader
  and rejects missing/zero deltas before the hook.
- **Cloud**: `DirectiveTypes["adjust_stock"]="item_id"` + non-zero float
  `qty_delta` validation; form handler parses with `ParseFloat` (unset on
  garbage → 400); history summary renders `item +5` / `item -2.5`. The Qty
  cell on **item rows only** (`{{if and .ID .Qty}}` — variant rows carry no
  qty) shows current qty + a small `+5 / -2` delta input. i18n ×9.

## Risk review

- Full audit trail: every remote adjustment is a stock movement row with
  actor `cloud` and a reason — nothing mutates `inventory` directly.
- Zero delta rejected on both sides; the movement API itself also refuses
  qty 0 (third belt).
- Location inference is deterministic (existing tracking location first);
  a wrong guess is visible in the movement record and correctable locally.
- Re-application after a lost result POST re-runs the movement — the same
  at-least-once semantics every directive has; the movement log makes any
  double-apply visible and reversible. Noted as acceptable for a manual,
  low-frequency operation.

## Tests

- till: apply-level d6 (applied, reason passed) / d7 (zero delta fails
  pre-hook); build + full pages/cloudsync tests + data-access guard green.
- mp: QueueDirective valid/missing/zero delta cases (valid one cancelled to
  keep the exact-list assertion stable); full `verify.sh` green.
