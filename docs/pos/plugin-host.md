# POS Plugin Host

Sources to merge:
- universal-till/specs/007-plugin-host/* (spec/plan/tasks/quickstart/contracts)
- universal-till/specs/000-pos-core-mvp/contracts/plugin-manifest.md

Responsibilities (from specs):
- Install/update/remove plugins; validate manifests.
- Enforce permissions and sandboxing for POS UI/service/hardware plugins.
- Expose plugin lifecycle APIs/events to POS.
- Support offline-first behavior; handle local bundle cache and updates when online.

Pending documentation:
- Manifest schema alignment with marketplace contracts.
- Install flow (target: CLI-assisted marketplace flow).
- Runtime isolation model and logging/telemetry expectations.
- Permission model for access to POS data/hardware.
