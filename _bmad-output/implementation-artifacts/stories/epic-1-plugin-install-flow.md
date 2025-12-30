# Epic 1: Plugin Install Flow (Marketplace + CLI + POS)

Status: backlog

## Goal

Unblock plugin enablement end-to-end by defining a clear install flow that works for disconnected/offline scenarios and is verifiable using the FAQ plugin.

## Business Value

- Enables the “everything is a plugin” strategy (tax, payments, integrations, delivery, etc.).
- Removes the current blocker: marketplace has no practical plugin add/install flow; FAQ plugin cannot be tested.
- Establishes a repeatable lifecycle that scales across multiple repos.

## In Scope

- Marketplace install/status APIs and telemetry contract.
- Marketplace CLI commands to drive install and offline bundle workflows.
- POS plugin host integration points for install/apply/status reporting.
- End-to-end validation using FAQ plugin.

## Out of Scope (for this epic)

- Full POS UI redesign (separate epic).
- Full developer publishing portal hardening (future).

## References

- `docs/plugins/lifecycle.md`
- `docs/marketplace/cli.md`
- `docs/marketplace/api.md`
