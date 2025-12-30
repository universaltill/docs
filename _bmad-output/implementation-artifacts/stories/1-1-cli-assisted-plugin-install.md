# Story 1.1: CLI-Assisted Plugin Install (FAQ Validation)

Status: ready-for-dev

## Story

As a platform developer,
I want a CLI-assisted plugin install flow backed by marketplace APIs and POS plugin-host reporting,
so that plugins can be installed and verified end-to-end (starting with the FAQ plugin) and the marketplace can reflect install health.

## Acceptance Criteria

1. CLI supports installing a plugin by id+version for a merchant (optionally device/POS scoped), against local or production endpoints.
2. CLI supports checking install status/health for that plugin (merchant/device scoped).
3. CLI supports offline workflows using export/import bundles (for disconnected stores).
4. Marketplace records an “install intent” initiated by the CLI, including plugin id/version, merchant, and optional device.
5. POS plugin host can apply the plugin bundle and report status back to marketplace (state + error details on failure).
6. FAQ plugin can be installed and becomes visible under Help/Support in POS (or equivalent UI entrypoint) in a local dev setup.
7. Marketplace (UI or API) surfaces the plugin as installed with “healthy” status after successful install.

## Tasks / Subtasks

- [ ] Define CLI UX and commands (AC: 1, 2, 3)
  - [ ] Confirm subcommands and flags in `docs/marketplace/cli.md`
  - [ ] Define standard output format for `status` (states, timestamps, error codes)
- [ ] Define required marketplace API endpoints and payloads (AC: 4, 7)
  - [ ] Align on endpoints proposed in `docs/marketplace/api.md`
  - [ ] Define auth model (client credentials/dev keys) and env selection
- [ ] Define POS host reporting contract (AC: 5)
  - [ ] Install states: requested → downloading → installing → active → failed → disabled/uninstalled
  - [ ] Telemetry payload fields (pos-id, plugin-id, version, state, error, timestamp)
- [ ] Define local dev validation procedure (AC: 6, 7)
  - [ ] Minimal repro steps and expected outputs
  - [ ] Negative tests (invalid manifest, incompatible version)

## Dev Notes

- Multi-repo work: marketplace repo (`~/repos/unitill/ut-market-place`), POS repo (`~/repos/unitill/universal-till`), FAQ plugin repo (`~/repos/unitill/ut-plugin-faq`).
- CLI proposal and flow are documented in:
  - `docs/marketplace/cli.md`
  - `docs/plugins/lifecycle.md`
  - `docs/marketplace/api.md`
- Current blocker context: “no way to add a plugin yet” (marketplace) and FAQ plugin “waiting for the CLI tool to test”.

### References

- `docs/marketplace/cli.md`
- `docs/marketplace/api.md`
- `docs/plugins/lifecycle.md`
- `docs/plugins/faq.md`
