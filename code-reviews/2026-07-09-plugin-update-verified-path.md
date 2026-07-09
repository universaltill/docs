# Code review — plugin Update goes through the verified installer (universal-till)

**Date:** 2026-07-09
**Scope:** `internal/pages/plugin_api.go` (`handleUpdatePlugin`), `internal/pages/plugins_page.go`.

## Defect
The manager page's Update button always returned 404 "Plugin not found in
catalog", and the legacy code path behind it was a security violation:

1. **Broken lookup** — it matched `summary.ListingID == pluginID`, but the URL
   carries the plugin ID (`com.universaltill.theme-…`) while catalog listing
   IDs are UUIDs. Never matched.
2. **Unverified install** — had it matched, it downloaded from catalog
   `ArtifactURL` and ran a raw `extractTarGz` + `PersistManifest` with **no
   Ed25519 signature check**, violating the repo rule that no unverified
   plugin is ever installed.

## Fix
`handleUpdatePlugin` now resolves the listing ID from the install-status
records (marketplace installs persist the listing↔plugin mapping; manual
imports have no listing and get an honest 404) and delegates to the same
`MarketplaceInstaller.Install` used by install-from-marketplace: download
token → checksum → Ed25519 verify → installBundleFile → PersistManifest.
Rollback snapshot of the current version is kept. Status records are written
through the lifecycle (with PluginID so the manager mapping survives), the
plugin manager reloads and the nav rebuilds on success.

Dead code removed: local `extractTarGz` + `mapTrustTier` (only used by the
legacy path) and the unused `installedPluginForSummary` helper.

## Verified live
Themes screen-top and buttons-left v1.0.2 (journal-free layouts) released via
their repo pipelines (tag v1.0.2 → publish → auto-approve, both green);
POS manager flagged `hasUpdate` → `POST /api/plugins/{id}/update` → 200
"updated from 1.0.1 to 1.0.2", `[Verifier] Manifest signature verified` for
both, `/themes/screen-top.css` serves the new grid. Gates green
(build/tests/data-access guard).
