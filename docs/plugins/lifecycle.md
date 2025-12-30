# Plugin Lifecycle

Goal: Document end-to-end flow for plugin onboarding/install/update/remove across marketplace, CLI, and POS.

To cover (sources pending):
- Add/install flow: marketplace UI/API + CLI + POS plugin host.
- Status/telemetry reporting back to marketplace.
- Manifest validation and permission enforcement.
- Offline bundle handling (if using sync CLI).
- Everything-as-plugin examples: taxes/compliance modules, payments, ERP/ecommerce/accounting integrations, delivery/ordering flows, hardware drivers.
- Multi-language/multi-currency considerations surfaced via manifest/config.

Acceptance target:
- FAQ plugin installable/testable via defined flow once CLI is in place.

## Proposed install flow (end-to-end)
1) **Marketplace**: Plugin published with manifest, trust tier, and bundle; passes validation.
2) **CLI**: `marketplace-cli install --plugin <id>@<ver> --merchant <id> [--device <pos-id>] --env <env>` registers install intent and pulls bundle (or uses offline bundle).
3) **Delivery**: Bundle delivered to POS/backoffice endpoint or queued; manifest/compatibility checked.
4) **POS Plugin Host**: Installs plugin, enforces permissions, activates; reports status/health/telemetry.
5) **Marketplace**: Exposes install/status via API; CLI `status` reflects POS-reported health.

## Offline/disconnected support
- Use export/import (bundles) for stores without connectivity.
- POS host should cache bundles and retry install/reporting when back online.

## Telemetry/status
- Standard states: requested → downloading → installing → active → failed (with error) → disabled/uninstalled.
- Health pings/reporting surfaced in marketplace and via CLI `status`.

## Removal/update
- `marketplace-cli uninstall --plugin <id> --merchant <id> [--device <pos-id>]` (to define).
- `marketplace-cli update --plugin <id> --version <ver>` for controlled rollouts/rollback.
