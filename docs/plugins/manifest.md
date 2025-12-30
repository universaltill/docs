# Plugin Manifest

Sources:
- universal-till/specs/000-pos-core-mvp/contracts/plugin-manifest.md
- ut-plugin-faq/specs/001-multilingual-faq-page/contracts/manifest.md
- ut-market-place/contracts (compatibility/versioning)

## Required Fields

- `id` - globally unique plugin identifier
- `name` - human-readable name
- `version` - semantic version
- `capabilities` - declared feature areas (POS UI, POS service hooks, hardware, back office)
- `permissions` - data/hardware scopes required by the plugin
- `min_host_version` - minimum supported POS host version
- `entrypoints` - POS UI routes, service hooks, back office surfaces, hardware drivers

## Optional Fields

- `config_schema` - plugin settings and i18n configuration
- `billing` - optional pricing model and terms
- `compatibility` - supported platforms, trust tiers, and version ranges

## Validation and Compatibility

- Validation errors must be surfaced consistently in CLI, marketplace API, and POS UI.
- Compatibility and versioning rules are authoritative in marketplace contracts.
- Marketplace contracts live in `ut-market-place/pkg/contracts` and `ut-market-place/docs/marketplace.proto`.

## Minimal Schema Sketch (to refine from contracts)

- `id`, `name`, `version`, `min_host_version`
- `capabilities`: pos-ui, pos-service, backoffice-ui/service, hardware drivers
- `permissions`: data/hardware scopes
- `entrypoints`: routes/hooks per surface
- `config_schema`: plugin settings, i18n content, currency options
- `billing` (optional): model, terms
- `compatibility`: versions/platform targets; trust tier metadata
