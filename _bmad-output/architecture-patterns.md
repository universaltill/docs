# Architecture Patterns (High-Level)

This captures current inferred architecture patterns from the repository structure and documented behavior. It is a starting point for deeper documentation.

## Overall

- **Multi-repo system**: POS, marketplace, and plugins are separate Go repos, with `docs/` acting as the centralized documentation hub.
- **Plugin-first platform direction**: “Everything is a plugin” (tax, payments, integrations, UI pages, hardware drivers).
- **Offline-first**: Core POS must work with no internet; marketplace and plugins must support offline install/caching workflows.

## POS (`universal-till`)

- **Single Go backend** orchestrating UI + local data + plugin runtime (inferred from POS repo structure and specs).
- **UI approach:** Server-rendered HTML templates with HTMX-style partial refresh patterns (found in specs and internal page handlers).
- **Local-first storage**: SQLite-backed.

## Marketplace (`ut-market-place`)

- **Service-oriented backend**: Go service with gRPC + REST gateway.
- **Operational concerns built-in**: observability (Prometheus, OpenTelemetry), auth (JWT), and deployment-oriented docs.
- **Data model management**: Ent ORM suggests schema-driven model and migrations.

## Plugin (`ut-plugin-faq`)

- **Plugin artifact**: built and packaged separately; intended to install via marketplace into POS.
- **I18n/RTL emphasis**: multilingual, offline-capable FAQ UI page plugin.

## Implications for Documentation

- Document and enforce **shared contracts**: manifest schema, compatibility/versioning, trust tiers, telemetry status reporting.
- Clarify **install/update lifecycle**: CLI-assisted flow, offline bundles, and POS apply/report behavior.
