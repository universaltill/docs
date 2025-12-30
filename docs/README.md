# Universal Till Docs (Central Hub)

This folder centralizes documentation across POS, marketplace, and plugins, replacing scattered Speckit-era docs.

Top-level guides:
- `overview.md` — project overview and sources.
- `architecture.md` — system blueprint; refine with sync and manifest alignment.

Workspace (multi-repo):
- Root: `~/repos/unitill`
- POS: `~/repos/unitill/universal-till`
- Marketplace: `~/repos/unitill/ut-market-place`
- Plugin (FAQ): `~/repos/unitill/ut-plugin-faq`
- Future repos: add additional plugin repos under `~/repos/unitill/ut-plugin-*` and list them here.

POS:
- `pos/setup.md` — env/config and run.
- `pos/ui.md` — UI status and TODOs.
- `pos/plugin-host.md` — plugin host responsibilities (spec-derived).
- `pos/data-model.md` — core entities/storage (to merge details).

Marketplace:
- `marketplace/overview.md` — service entry points and features.
- `marketplace/api.md` — API surfaces (to import).
- `marketplace/cli.md` — plugin onboarding/install CLI (new work).
- `marketplace/plugin-developer.md` — manifest/validation/release.
- `marketplace/i18n.md`, `tls-local-dev.md`, `ops.md`, `compliance.md`.

Plugins:
- `plugins/faq.md` — FAQ plugin (multilingual).
- `plugins/lifecycle.md` — end-to-end plugin flow (to finalize).
- `plugins/manifest.md` — manifest schema alignment.

Legacy:
- `specs/README.md` — Speckit-era specs; map into BMAD stories/ACs.

Next actions:
- Migrate content from source docs/specs into these files (docs-current content has been merged; that folder can now be archived/removed).
- Align with BMAD story/AC/architecture formats; prune incorrect statements.
