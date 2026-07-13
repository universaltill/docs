# Review: ut-plugin-faq converted to runtime none, Go removed (2026-07-13)

Farshid asked whether the FAQ actually needs Go. It doesn't: the POS
plugin-page engine has rendered the FAQ's localized content bundle
(`content/<locale>.json`) natively since 2026-07-08 — the compiled
`bin/ut-faq` shipped in every artifact was never executed. This was the
tracked known-gap in `architecture/plugin-architecture.md`; closed today.

## What changed (ut-plugin-faq v0.2.0, branch `feature/runtime-none`)

- Removed all Go: `src/` (loader/render/storage/ui/main), `tools/pkgtool`,
  Go unit/integration tests, `go.mod`; plus Go-era helper scripts
  (dev/perf-check/security-audit).
- `manifest.json` moved to the repo root: `runtime:"none"`, no
  `executable`/`entrypoint`/`supported_architectures`; permission slimmed
  to `ui.page` (the old `storage.local.10MB` was for the removed cache).
  Entries/locales/resources unchanged — same listing, same route.
- Content bundles moved `src/faq/content/` → `content/` (all 9 locales).
- Scripts/workflows aligned with the other plugin repos (universal tar.gz,
  validate → package → publish → dev auto-approve). New validate.sh checks
  one page entry with a route and a parseable content bundle per declared
  locale.
- Repo history note: local and remote `001-multilingual-faq-page` had
  diverged since 2026-07-06 (unpushed packaging commits vs a docs PR);
  merged with the conversion superseding both lines.

## Verified live

Repo secrets/vars were never wired on this repo — set now (KV upload token,
AUTO_APPROVE, listing `1295b44c`). Tag v0.2.0 → pipeline green: HTTP 201 →
auto-approved → catalog serves `Universal Till FAQ 0.2.0 page`. POS
`POST /api/plugins/{id}/update`: 0.1.2 → 0.2.0, "Manifest signature
verified", rollback snapshot of 0.1.2 stored, installed tree has NO `bin/`,
plugins row shows `runtime none`, and `/plugin/faq` renders the FAQ as
before. Architecture doc gap line removed; sample roster updated.
