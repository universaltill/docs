# 0019 — Plugin platform taxonomy

Status: accepted (2026-07-20, Farshid)

## Context

The marketplace is about to serve plugins for more than the till binary:
Farshid is building `erp.universaltill` as a separate app/repo (own memory
store, ADR-0017 now lives there as its ADR-0001), and an Android version of
the POS is planned, with more platforms likely later. A plugin listing
today has no way to say which app(s) it's meant for — `PluginListing.
plugin_type` (ADR-0002) is a *capability* taxonomy (payment, theme,
integration, report, …), not a *platform* one, so it can't be repurposed
for this.

Farshid: *"they plugins should have a property to say this is a till plugin
or erp plugin"* — then, on reflection: *"in anycase we need platform field
as we want to implement an android version of the code as well right?
maybe we will have other platforms in the future as well."*

## Decision

1. **New field `platforms []string`** on `PluginListing`, orthogonal to
   `plugin_type`. Plural/list, not a single value: a plugin built against a
   sufficiently portable interface can legitimately target more than one
   platform (e.g. a WASM UI plugin that runs on both till and Android)
   without needing duplicate listings — mirrors the existing
   `compatible_arches []string` pattern in the same schema.
2. **Starting taxonomy: `till`, `android`, `erp`.** Open the same way
   ADR-0002 treats `plugin_type` — a small canonical list validated at
   write time, extended by adding a value + updating validation + docs,
   not a closed enum requiring a schema migration per platform.
3. **Scope: catalog/browse metadata only.** This field lets the store
   label, filter, and badge listings by platform. It does **not** define
   or guarantee runtime compatibility — each platform's app (till,
   Android, ERP, …) owns its own plugin host/manifest contract. The
   till's is already contract-guarded cross-repo
   (`internal/signing.CanonicalManifest` ↔ `universal-till/internal/
   plugins.Manifest`, including the till-specific `min_pos_version`).
   Android/ERP either reuse that shape or define their own — that's a
   separate design decision per platform when its plugin host runtime
   actually exists, not something this taxonomy field resolves.

## Consequences

- Catalog queries/filters gain a `platforms` dimension (`ListFilters`,
  storefront/portal browse UI) so a till install flow doesn't surface
  ERP-only or Android-only listings and vice versa.
- Existing listings need a default: till is the only platform that exists
  today, so backfilling `platforms = ["till"]` for everything already in
  the catalog is correct and requires no vendor action.
- Nothing about install/signing/trust (ADR-0006) changes — the platform
  field filters what's *offered*, not how a plugin that's offered is
  verified once selected.
- When ERP's or Android's plugin host runtime is designed, whether it
  reuses the till's manifest shape (extending the cross-repo contract
  guard to a third/fourth repo) or defines its own compatible variant is
  an open question for that point, not decided here.
