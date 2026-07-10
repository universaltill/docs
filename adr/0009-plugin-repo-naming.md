# 0009 — One repo per plugin, named `ut-plugin-{type}-{name}`

**Status:** accepted (2026-07-10, Farshid)

## Decision
Every plugin lives in its **own repository** and deploys through its own
release pipeline (tag `v<version>` → validate → package → publish to the
marketplace → optional auto-approve in dev).

Naming: **`ut-plugin-{type}-{name}`** where `{type}` is the plugin's
`canonical_type` from the taxonomy (ADR-0002) and `{name}` is a short
kebab-case identifier. Examples: `ut-plugin-theme-midnight`,
`ut-plugin-payment-qrpay`, `ut-plugin-page-faq`.

Manifest ids follow `com.universaltill.{type}-{name}` for first-party
plugins.

## Consequences
- Existing theme repos already comply.
- `ut-plugin-faq` is grandfathered; rename to `ut-plugin-page-faq` when it is
  next touched (also converting it to `runtime:"none"`, see ADR-0001).
- Local/side-loaded test bundles never substitute for the repo: a plugin is
  "done" only when its repo + pipeline exist and the marketplace serves it.
