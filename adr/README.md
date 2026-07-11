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
