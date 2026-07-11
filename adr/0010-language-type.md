# 0010 — `language` joins the plugin taxonomy (supersedes part of 0002)

**Status:** accepted (2026-07-11)

## Context
Farshid asked for language packs as plugins; the 20-type taxonomy (ADR-0002)
had no slot for them.

## Decision
`canonical_type: "language"` is the 21st type. Language packs are asset-only
(`runtime:"none"`, ADR-0001): they ship `locales/<code>.json` files that the
engine merges into the translator as **overlays** on every plugin lifecycle
change. Base locale files always win on key conflict — a plugin cannot hijack
core strings; overlays add whole new locales and may fill missing keys. The
nav language switcher renders from the merged set. Language packs need no
`entries` rows, so the plugin_entries CHECK is untouched. Any active plugin
may also ship `locales/*.json` to translate its own strings.
