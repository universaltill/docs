# POS Data Model

Source: universal-till/docs/data-model.md (to merge details).

Includes:
- Core entities: products, prices, taxes, customers, sales, inventory, employees.
- Storage: local SQLite/Postgres (per deployment).
- Sync considerations: POS ↔ Back Office ↔ Cloud (to be detailed).
- Tax model is pluggable; regional tax/fees should be handled via plugins and applied to order/receipt flows.
- Multi-currency support required; currency selection should be documented with rounding/tax interactions.

Pending:
- Bring over diagrams/tables from source doc.
- Align with marketplace/plugin manifest requirements where applicable.
- Clarify offline queueing and conflict resolution for sync once cloud/back office details are merged.
