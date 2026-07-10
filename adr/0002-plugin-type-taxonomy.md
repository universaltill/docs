# 0002 — Plugin type taxonomy (20 canonical types)

**Status:** accepted (2026-07-10, Farshid)

## Decision
`canonical_type` and `entries[].type` share one taxonomy:
`page|button|popup|payment|device|integration|report|pricing|tax|import|export|hardware|background_job|scheduler|receipt_template|customer_facing|auth|notification|delivery|theme`

Single source of truth: `universal-till internal/plugins.CanonicalTypes`,
validated at manifest parse, mirrored by the `plugin_entries.type` CHECK,
pinned by `TestCanonicalTypesMatchTaxonomy`. Semantics table lives in
`reference/plugin-manifest.md`. Adding a type = new ADR + code + CHECK + docs.
