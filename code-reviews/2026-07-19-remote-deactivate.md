# Review: remote item retire/deactivate (catalog editing step 4)

**Date:** 2026-07-19 · **Repos:** `universal-till` (feat/remote-deactivate),
`ut-market-place` (feat/remote-deactivate)

Fourth slice of cloud catalog editing — `deactivate_item {item_id}`:

- **Till**: hook routes to the existing soft-deactivate paths — an item id
  hits `DeactivateItem` (which also retires the item's variants, exactly as a
  local manager action does); otherwise the id is checked as a variant
  (`GetVariantLabel` existence guard — `DeactivateVariant`'s UPDATE reports
  no error on a miss, so without the guard a bad id would report success) and
  retired alone. Nothing is deleted; reactivation stays a local operation by
  design — the cloud can retire, only the shop can resurrect.
- **Cloud**: `DirectiveTypes["deactivate_item"]`; new last column on the
  Catalog table with a red **Retire** button behind a translated
  `confirm()` (only destructive-leaning action on the page, hence the only
  confirm). History summary = the id. i18n ×9 (2 keys).

Risk: soft-only (is_active=0), fully reversible on the till; re-application
idempotent. Retired items drop out of the next snapshot, so the row removes
itself from the cloud table after the following sync.

Tests: till apply d10 (hook driven, applied) + full pages/cloudsync suites +
guards; mp full `verify.sh` green (type accepted via the generic
required-field validation covered by existing cases).
