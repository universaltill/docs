# Architecture Decision Records

Every significant decision gets an ADR **before** the code lands. ADRs are the
policy for humans and AI alike: an AI session (or a developer) must follow
accepted ADRs and must not silently contradict them — changing course means
writing a superseding ADR first.

Format: one file `NNNN-slug.md`, statuses `accepted | superseded by NNNN`.
Keep them short: Context → Decision → Consequences.

| # | Decision |
|---|----------|
| [0001](0001-plugin-runtime-wasm.md) | Plugin runtime: in-process WASM (wazero); processes only for hardware |
| [0002](0002-plugin-type-taxonomy.md) | 20-type plugin taxonomy, single source of truth |
| [0003](0003-offline-first.md) | Offline-first POS: no network on the sale path, vendored assets |
| [0004](0004-money-minor-units.md) | Money = integer minor units via `money.Money` type |
| [0005](0005-data-access-repositories.md) | Raw SQL only in repositories (mechanically enforced) |
| [0006](0006-plugin-trust-chain.md) | Plugin trust chain: publish → scan → review → sign (Ed25519) → entitle → verify |
| [0007](0007-document-first.md) | Document-first workflow: ADR/spec before build, review doc before commit |
| [0008](0008-ui-server-rendered-htmx.md) | POS UI: server-rendered Go templates + HTMX/Alpine, no SPA |
| [0009](0009-plugin-repo-naming.md) | One repo per plugin: `ut-plugin-{type}-{name}` + own pipeline |
| [0010](0010-language-type.md) | `language` plugin type: locale-file overlays, base strings win |
| [0011](0011-multi-till-sync.md) | Multi-till sync: primary/replica per shop, sale journals over LAN HTTP |
| [0012](0012-universal-till-id-zitadel.md) | Universal Till ID: self-hosted Zitadel at id.universaltill.com |
| [0013](0013-store-enrolment-and-plugin-tiers.md) | Store enrolment + plugin access tiers: anonymous → claim → paid |
| [0014](0014-erp-integration-connectors.md) | ERP integration: reusable connector plugins on the sale.completed event |
| [0015](0015-lazy-store-registration.md) | Lazy store registration: enrol on first marketplace use, not at boot |
| [0016](0016-payment-orchestration-least-cost-routing.md) | Payment orchestration + least-cost routing: we route to the cheapest acquirer, never hold funds |
| 0017 | _Moved 2026-07-18: Universal Core (ERP) became a separate product — its ADR now lives at `erp/universal-core/docs/adr/0001-universal-erp-metadata-kernel.md`, renumbered ADR-0001 in that repo._ |
| [0018](0018-universal-till-cloud.md) | Universal Till Cloud (cloud.universaltill.com): marketplace app renamed & scoped as the cloud tier; till-initiated sync + directives; back-office device = till in back-office mode |
