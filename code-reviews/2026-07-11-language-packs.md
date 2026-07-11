# Code review — language packs as plugins (ADR-0010)

**Date:** 2026-07-11

## Engine (universal-till, pushed)
- `canonical_type: "language"` = 21st taxonomy type (ADR-0010 supersedes part
  of 0002; pinned test updated). Asset-only, no entries → plugin_entries CHECK
  untouched.
- `config.I18n` gains thread-safe **overlays**: `SetOverlays` replaces all
  plugin translations atomically; lookup order per locale is base file →
  overlay (base wins on conflict — a plugin cannot hijack core strings);
  `Available()` = merged locale set.
- `Manager.syncLocales` (Init via SetLocalizer + every Reload) scans ACTIVE
  plugins' `locales/*.json` — any plugin may translate its own strings; a
  language pack is just a plugin that is only that.
- Nav switcher renders from `locales` template func instead of hardcoded EN/FA.

## Packs (new repos, pipelines green)
`ut-plugin-language-de` (German, full 164-key translation) and
`ut-plugin-language-es` (Spanish). Validation: manifest.locales must list
files, each must parse and carry ≥20 keys.

## Verified live
Side-load: DE appears in switcher, sale screen/shifts render German,
uninstall removes DE. Marketplace path: pipeline → listing 787d0986 →
merchant approve → till install (signature verified) → `/reports?lang=de`
renders "Berichte / Umsatz pro Tag". Full suite + guard green.
