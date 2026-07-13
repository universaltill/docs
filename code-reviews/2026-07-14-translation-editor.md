# Review: translation editor (/translations)

**Date:** 2026-07-14 · **Repo:** universal-till (main) · **Author/Reviewer:** Claude (self-review before commit)

Spec: docs/architecture/translation-editor.md (Farshid 2026-07-13: "a page to
let manager edit translations (all pos and plugins in one place)"). Open spec
question resolved as assumed: en is editable like any other locale.

## What shipped

- **Third translation layer** — `config.I18n` gains `shop` overrides with
  precedence **shop > base locale files > plugin overlays** (`T` and the new
  `SetShopOverrides`); `Entries(locale)` returns the editor's row set: union
  of all known keys with effective value, source layer
  (shop/base/plugin/untranslated) and the fallback-locale reference text.
- **Migration 008** `translation_overrides(locale, key, value, updated_at,
  updated_by; PK(locale,key))` — append-only, embedded.
- **`data.TranslationRepo`** — ListOverrides (the map shape the translator
  consumes), SetOverride (upsert), ClearOverride.
- **Page** `/translations` (manager/admin, same `requireManager` pattern as
  /users; cashiers 403 — verified live): locale picker from
  `i18n.Available()`, 300ms-debounced search, HTMX table partial; per-row
  inline edit + Save; **Reset** appears only on shop-overridden rows and
  deletes the override so the string falls back. Plugin-supplied and
  untranslated rows are labelled. Edits call `SetShopOverrides` immediately —
  no restart. Both writes audited (`translation_override_set` / `_cleared`).
  Link next to Users in the manager session chip. 12 new keys, en + fa.
- Overrides load at startup in pages.Init, so they survive restart.

## Findings (self-review), dispositioned

1. **FIXED** — partial rendered through `httpx.Render` (page pipeline, wants
   a base-layout `content` template) → 500 "no such template"; switched to
   `httpx.RenderPartial` like session_chip/plugin_buttons.
2. **Accepted** — no pagination: ~390 keys render in one table; search is the
   navigation. Revisit if plugin keys grow it past a few thousand.
3. **Accepted** — `q` filter is case-insensitive substring over key,
   effective value and reference; good enough for a shop.

## Verification

- `go build ./... && go test ./...` green (new: shop-precedence + Entries
  union tests in internal/config; repo round-trip incl. upsert + clear in
  internal/data); guard-data-access + guard-i18n green.
- Live on the dev till: page 200 for manager; set en `basket.total` →
  "Grand total" appears on the sale screen immediately; clear → back to
  "Total"; fa override survived a process restart before being cleaned up;
  cashier gets 403 on page and both APIs.
