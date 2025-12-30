# Legacy Specs (Speckit-era References)

These are historical inputs. Keep for reference but migrate into BMAD story/AC/architecture formats.

Repos:
- universal-till/specs (POS, marketplace, plugin host, perf)
- ut-market-place/specs/001-plugin-marketplace
- ut-plugin-faq/specs/001-multilingual-faq-page

Next steps:
- Map each spec to BMAD stories and acceptance criteria.
- Prune or correct any outdated statements during migration.

## Mapping plan
- POS (universal-till/specs):
  - 000-pos-core-mvp → baseline stories/ACs for core POS.
  - 001-sql-repo-refactor, 002-catalog-pricing, 003-sales-basket, 004-payments-receipts, 005-inventory-returns, 006-shifts-cash, 007-plugin-host, 008-performance-resilience, 009-cloud-marketplace, 010-complete-pending-specs → convert to BMAD stories with clear ACs; mark deprecated items.
- Marketplace (ut-market-place/specs/001-plugin-marketplace) → map plan/data-model/tasks/research/checklists/contracts into stories/ACs and align with CLI/install flow.
- FAQ Plugin (ut-plugin-faq/specs/001-multilingual-faq-page) → map spec/plan/data-model/tasks/contracts into stories/ACs; include i18n/RTL acceptance.

## Migration approach
- For each spec: extract goals, scope, acceptance criteria, and tasks into BMAD story format; flag inconsistencies.
- Note any outdated statements to prune during consolidation into `docs/`.

## Story seeds (BMAD format targets)
- CLI-assisted plugin install (marketplace/POS) with FAQ plugin acceptance.
- Plugin lifecycle documentation finalized (install/update/remove, telemetry, offline).
- POS UI uplift scoped for MVP parity with plugin flow.
- Doc centralization complete (POS/marketplace/plugins) with corrected statements.
- Legacy specs mapped: POS core MVP, plugin host, marketplace 001, FAQ 001.
