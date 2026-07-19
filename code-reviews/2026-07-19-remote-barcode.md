# Review: remote barcode attach (catalog editing step 6 — arc complete)

**Date:** 2026-07-19 · **Repos:** `universal-till` (feat/remote-barcode),
`ut-market-place` (feat/remote-barcode)

Final slice — `add_barcode {item_id, barcode}`:

- **Till**: the hook routes an item id to `AddBarcode{ItemID}` and anything
  else to `AddBarcode{VariantID}`; `AddBarcode` already owns every safety
  check (availability via `ensureBarcodeAvailable`, existence, active-only,
  upsert-on-same-owner → naturally idempotent on retry). Attached as primary.
- **Cloud**: `DirectiveTypes["add_barcode"]` + non-blank barcode validation;
  the Barcode cell becomes an inline input (prefilled with the current
  primary) + Set barcode button; history summary `id ← barcode`. i18n ×9.

With this, the cloud Catalog table's editing arc is complete: **add item /
rename / set price / set barcode / adjust stock / retire**, plus the Design
picker and settings/plugin directives — all through one validated, audited,
cancellable queue.

Risk: attaching a barcode owned by another item fails cleanly in the result
column (never steals); old barcodes remain as aliases (matches local
behaviour — the barcode list is managed fully on the till).

Tests: till apply d13/d14 (attached / blank fails pre-hook) + suites +
guards; mp validation via required-field + explicit barcode check, full
`verify.sh` green.
