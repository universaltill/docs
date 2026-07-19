# Review: remote item creation (catalog editing step 5)

**Date:** 2026-07-19 · **Repos:** `universal-till` (feat/remote-create-item),
`ut-market-place` (feat/remote-create-item)

Fifth slice — `create_item {name, price_minor, barcode?}`:

- **Till**: `cloudCreateItem` — because directives are at-least-once, the
  create is made **idempotent**: an existing active item with the same exact
  name (`CatalogRepo.FindActiveItemByName`, new single-query method) reports
  "item already exists" as success instead of duplicating. A barcode already
  attached elsewhere fails the directive (visible in the result column)
  rather than stealing it; a barcode that fails to attach after the item was
  created still reports success with the reason appended (item exists,
  barcode didn't — the honest partial state). Item goes through the normal
  `CreateItem` (uuid id, sku defaulted) + `AddBarcode` (primary).
- **Cloud**: `DirectiveTypes["create_item"]="name"` + the same
  `price_minor` int64 ≥ 0 validation as set_price. **Add item** form above
  the Catalog table (name / price in minor units / optional barcode —
  placeholders reuse the table's column headers). History summary
  `name @ price`. One new i18n key ×9.

Risk: creation is soft-reversible (retire button / local edit). Name-based
idempotency means two deliberately identical-named items can't be created
remotely — acceptable; do it on the till, where the full catalog editor
lives. New item appears in the cloud table after the next snapshot push.

Tests: till apply d11 (applied, barcode passed) / d12 (blank name fails
pre-hook) + `FindActiveItemByName` unit test + full suites/guards; mp
QueueDirective valid/missing-price cases; full `verify.sh` green.
