# Translation editor — manager page (short spec)

Status: **SHIPPED 2026-07-14** (universal-till main; review record
`code-reviews/2026-07-14-translation-editor.md`). Built as specced; the open
question was resolved as assumed — en is editable like any locale. v2
candidates (export/import of overrides, new-locale creation) remain open.
Original ask (Farshid 2026-07-13): "maybe we should add a page to let manager
edit translations (all pos and plugins in one place)".

## What

A manager/admin page (`/translations`) where the shop edits every visible
string — built-in POS keys and plugin-shipped keys — per locale, in one
place. Shops fix awkward wording, localize plugins that shipped without
their language, and rename things to local trade terms ("basket" → "trolley").

## Design

**Third translation layer.** Today: base `web/locales/*.json` wins over
plugin `locales/*.json` overlays. Add shop overrides ABOVE both:

```
shop override (DB)  >  base locale file  >  plugin overlay
```

- New table `translation_overrides(locale, key, value, updated_at, updated_by)`
  — migration 008, repo `TranslationRepo` (ADR-0005), append-only migration.
- `config.I18n` gains `SetShopOverrides(map[locale]map[key]value)` mirroring
  the existing `SetOverlays`; loaded at Init and after every edit.
- Key inventory for the page = union of: base en.json keys, active plugins'
  overlay keys, and existing DB overrides. Source string shown alongside
  (en value) + current effective value + which layer it comes from.

## Page

- `/translations` (manager/admin role-gated like `/users`): locale picker,
  searchable key table, inline edit, "reset to default" (deletes override).
  Server-rendered HTMX per ADR-0008; RTL-safe (logical CSS).
- Writes audited (`translation_override_set` / `_cleared`).
- Edits apply immediately (reload localizer); no restart.

## Not in scope (v1)

- Adding new locales from this page (language packs remain the mechanism).
- Editing plugin CONTENT bundles (FAQ answers etc.) — those are plugin data,
  versioned and signed; only translator keys are overridable.
- Export/import of overrides (candidate v2 — would also be the path for a
  shop to contribute translations upstream).

## Decision for Farshid

Should overrides apply per-locale only (edit "fa" affects fa), or also allow
editing the en base text (effectively renaming UI concepts shop-wide)? Spec
assumes YES to both — en is just another locale row.
