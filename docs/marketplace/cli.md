# Marketplace CLI (Plugin Onboarding/Install)

Goal: Provide CLI to add/install plugins via marketplace and unblock plugin testing (FAQ plugin dependency).

Sources:
- ut-market-place README (sync CLI: `cmd/marketplace-sync/main.go`)
- Specs/001-plugin-marketplace tasks (to review for CLI needs)

Open requirements:
- Add/install flow for plugins (merchant/tenant scoped).
- Support offline bundle export/import if leveraging sync CLI.
- Validate manifests against marketplace/pos contracts.
- Emit status/telemetry usable by POS/backoffice.
- Authentication and environment selection (prod/local/mock).
- Consider reusing sync CLI commands (export/import) or extend with install/add commands.

Acceptance targets:
- FAQ plugin installable/testable end-to-end through CLI-assisted flow.
- Marketplace UI/API recognizes installed plugin and surfaces status.

## Proposed CLI commands

Use an env flag to pick target (prod/local/mock) and credentials (client or developer keys):
- `marketplace-cli install --plugin <id>@<version> --merchant <id> [--device <pos-id>]`  
  - Fetch manifest, validate, download bundle, register install intent.
- `marketplace-cli status --plugin <id> --merchant <id> [--device <pos-id>]`  
  - Show install state/health/last heartbeat.
- `marketplace-cli list --merchant <id>`  
  - List installed/available plugins (with trust tiers).
- `marketplace-cli export --plugin <id>@<version> --merchant <id> --out bundle.tar.gz`  
  - Offline bundle for disconnected stores (reuse sync CLI behavior).
- `marketplace-cli import --bundle bundle.tar.gz --merchant <id> [--device <pos-id>]`  
  - Install from offline bundle.

## Flow (install)
1) Auth (client credentials or developer credentials where appropriate).
2) Fetch manifest; validate compatibility/version rules.
3) Download bundle (or accept `--bundle` path for offline install).
4) Register install intent with marketplace (for audit/telemetry).
5) Deliver to POS/backoffice endpoint or push to POS host queue.
6) POS host installs, enforces permissions, and reports status/health back to marketplace.

## FAQ plugin validation (target)
- Command: `marketplace-cli install --plugin ut-faq@<version> --merchant <test-merchant> --device <pos-id> --env local --endpoint http://localhost:8081`
- Validate: install success, manifest accepted, FAQ plugin visible in POS under Help/Support; status reflected in `marketplace-cli status`.

## Telemetry/health expectations
- CLI sends install intent/result to marketplace.
- POS reports install/apply status; marketplace exposes it via status endpoint and CLI.

## Next steps
- Decide whether to extend `cmd/marketplace-sync` or add a new CLI entrypoint.
- Wire install/status endpoints in marketplace API (document in `marketplace/api.md` once fixed).
