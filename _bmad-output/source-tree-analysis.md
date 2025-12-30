# Source Tree Analysis (Annotated)

This file summarizes the directory layout across the multi-repo workspace, highlighting entrypoints, critical folders, and integration points.

## Workspace Root (`~/repos/unitill`)

Key repos:
- `docs/` (documentation hub + BMAD outputs)
- `universal-till/` (POS)
- `ut-market-place/` (marketplace)
- `ut-plugin-faq/` (sample plugin)

## POS Repo: `universal-till/`

High-level:
```
universal-till/
├── main.go                 # POS entrypoint
├── go.mod                  # Go module + deps (SQLite, dotenv, etc.)
├── internal/               # Core application code
│   ├── config/             # Env parsing + i18n loader
│   ├── db/                 # SQLite open + migrations
│   │   └── migrations/     # SQL DDL migrations (001_init.sql, ...)
│   ├── pages/              # HTTP routes (UI + APIs)
│   ├── plugins/            # Plugin manager + marketplace client integration
│   ├── pos/                # POS domain logic (basket/sales/etc.)
│   └── server/             # Server boot + background jobs
├── web/                    # UI templates, static assets, locales
│   ├── ui/                 # HTML templates/partials
│   ├── public/             # CSS, public assets (includes HTMX indicators)
│   └── locales/            # i18n JSON files (en.json, fa.json)
├── specs/                  # Speckit-era specs, plans, tasks (inputs/legacy)
├── scripts/                # smoke tests, mock marketplace, migrations helper
└── docs/                   # additional docs (plugin guidelines, data model, etc.)
```

Integration points:
- Marketplace integration through `internal/plugins/marketplace` and `/plugins/store` UI.
- Plugin lifecycle tables and endpoints suggest install/enable/disable flows exist but need alignment with marketplace publish/install.

## Marketplace Repo: `ut-market-place/`

High-level:
```
ut-market-place/
├── cmd/
│   ├── marketplace/        # server entrypoint
│   └── marketplace-sync/   # sync CLI entrypoint (bundle export/import)
├── internal/
│   ├── httpapi/            # HTTP mux, handlers, security middleware
│   ├── api/                # gRPC service implementations
│   ├── repositories/ent/   # Ent-generated repo + schemas
│   ├── downloads/          # artifact download sessions/tokens
│   ├── auth/               # auth middleware
│   ├── observability/      # OTel + Prometheus
│   ├── telemetry/          # telemetry pipeline
│   ├── reviews/            # trust tier/review workflows
│   └── i18n/               # i18n support
├── pkg/
│   ├── contracts/          # protobuf/gRPC contracts
│   └── manifest/           # manifest schema/validation assets
├── locales/                # locale bundles (en-US, fa-IR, tr-TR, etc.)
├── docs/                   # API reference, security/compliance/ops/TLS
├── specs/001-plugin-marketplace/  # Speckit-era spec package
└── deploy/                 # kustomize/helm deployment assets
```

Integration points:
- `/api/` gRPC-Gateway surface for Catalog/Auth/Download services.
- Discovery endpoint: `/.well-known/marketplace-endpoints.json`.

## Plugin Repo: `ut-plugin-faq/`

High-level:
```
ut-plugin-faq/
├── src/
│   ├── main.go             # placeholder main; registers navigation entry
│   ├── manifest/           # plugin manifest assets
│   ├── ui/                 # UI rendering for FAQ page
│   └── storage/            # local cache abstraction
├── assets/                 # icons/content assets
├── tests/                  # unit/integration tests
└── specs/001-multilingual-faq-page/  # spec package (legacy input)
```

Integration points:
- Intended to install into POS and render under `/plugin/faq` (needs POS plugin SDK wiring).

## Docs Repo: `docs/` (this repo)

High-level:
```
docs/
├── docs/                   # centralized docs structure (POS/marketplace/plugins/specs)
├── docs-current/           # legacy docs (architecture + readme)
├── _bmad-output/           # generated artifacts (product brief, research, doc scan outputs)
└── _bmad/                  # BMAD workflow engine + BMM module
```

