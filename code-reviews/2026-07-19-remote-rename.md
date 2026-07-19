# Review: remote item rename (catalog editing step 3)

**Date:** 2026-07-19 · **Repos:** `universal-till` (feat/remote-rename),
`ut-market-place` (feat/remote-rename)

Same shape as `set_price` — third slice of cloud catalog editing:

- **Till**: `CatalogRepo.SetItemName` (items, fall-through to active
  variants, "item not found" on miss); `rename_item {item_id, name}` case in
  `apply()` rejects blank names pre-hook (`str()` trims); wired to the repo.
- **Cloud**: `DirectiveTypes["rename_item"]` + non-blank name validation;
  Name cell on snapshot rows (items AND variants — both carry ids) becomes an
  inline text input + Rename button; history summary `id → name`. i18n ×9.

Risk: rename is cosmetic data (no uniqueness constraint on item names in the
schema); variant rename via fall-through matches the price behaviour. The
next snapshot push reflects the new (composed) name back to the cloud.

Tests: till apply d8 (applied)/d9 (blank fails pre-hook) + full suite +
guards; mp QueueDirective valid/blank cases (valid cancelled for the
exact-list assertion), full `verify.sh` green.
