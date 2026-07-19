# Data Model

Persistence for the two services. Both are **generated from schema, not from
hand-written SQL** — always treat the schema files as authoritative; this document
is a readable snapshot.

- **Marketplace:** [ent](https://entgo.io) schemas in
  `ut-cloud/internal/repositories/ent/schema/*.go` → Postgres (prod) /
  SQLite (dev), created via ent auto-migrate.
- **POS:** SQLite, defined in `universal-till/internal/db/migrations/001_init.sql`
  (append-only after first release).

---

## Marketplace entities

All entities use a UUID primary key (`id`) and the shared `mixins.go` timestamps.

### PluginListing
Catalog metadata surfaced to merchants. One per plugin.
`slug` (unique), `display_name`, `summary`, `plugin_type` (canonical taxonomy),
`vendor_name`, `support_email`, `tags[]`, `trust_tier` (default `unverified`),
`min_host_version`, `required_capabilities[]`, `compatible_arches[]`,
`available_locales[]`, `paid_listing` (bool), `icon_url`.
**Edges:** `vendor` (→VendorOrganization), `releases` (→PluginRelease),
`entitlements` (→StoreEntitlement).

### PluginRelease
A versioned release of a listing. The heart of the publish→review→sign flow.
`version`, `channel` (default `stable`), `status` (default `draft`),
`artifact_bucket` / `artifact_object_key` / `artifact_checksum`, `signature`
(Ed25519, set at approval), `manifest` (raw JSON bytes), `release_notes`.
Review workflow: `submitted_at`, `approved_at`/`approved_by`,
`rejected_at`/`rejected_by`/`rejection_reason`,
`revoked_at`/`revoked_by`/`revocation_reason`.
Scan: `scan_results` (JSON), `scan_status` (pending→scanning→passed/failed),
`scanned_at`.
**Edges:** `listing`, `vendor`, `entitlements`.

### VendorOrganization
Plugin author identity. `external_id` (unique, from SSO), `name`, `legal_name`,
`contact_email`, `support_url`, `website_url`, `status`
(pending_verification→verified/suspended/banned). Verification
(`verification_method`, `verified_at`/`verified_by`), developer portal
(`developer_tier`, `submission_quota`, `active_listings`), billing
(`billing_email`, `tax_id`, `payout_method`), `allowed_regions[]`, `metadata`.
**Edges:** `listings`, `submissions` (→PluginRelease).

### MerchantOrganization
Merchant identity (from POS core). `external_id` (unique — **matches the
download-token `merchant_id`**), `name`, `region`, `contact_email`, `metadata`.
**Edges:** `entitlements`, `audit_events`.

### StoreEntitlement
Authorization for a store/register to install a listing. `store_id`,
`register_id`, `scope` (store|register), `status` (default `pending`),
`approved_by`/`approved_at`, `expires_at`, `policy_snapshot` (JSON at approval).
**Edges:** `merchant`, `listing`, `release`. _Gate: the download-token path
requires an approved entitlement._

### ReviewAssignment
Review workflow for a release. `release_id`, `reviewer_id`, `priority`
(P1≤24h/P2≤72h/P3), `status` (assigned→in_review→completed/escalated),
`assigned_at`/`started_at`/`completed_at`, `sla_deadline`, `decision`
(approved/rejected/needs_revision), `comments`, `checklist`, `sla_breached`,
`escalation_count`. **Edge:** `release` (unique, required).

### InstallIntent
POS-reported install lifecycle. `plugin_id`, `version`, `channel`, `merchant_id`,
`device_id`, `state`
(requested→downloading→installing→active→failed/disabled/uninstalled), `error`,
`reported_at`. Fed by `/ui/api/installs/{id}/state`.

### AuditEvent
Append-only audit. `actor_id`/`actor_type`, `subject_type`/`subject_id`,
`action`, `payload` (JSON).

### RegionConfig
Data-residency / compliance per region: `region_code`, `jurisdiction`,
`cloud_provider`, blob bucket/endpoint, `gdpr_compliant`,
`data_localization_required`, allowed/blocked countries, locales, timezones,
`currency_code`, `tax_rules`, DR `backup_region_code`.

### Relationship summary

```
VendorOrganization ─┬─< PluginListing ─┬─< PluginRelease ──1─ ReviewAssignment
                    └─< (submissions)  │        │
                                       │        └─< StoreEntitlement >─ MerchantOrganization
MerchantOrganization ─< AuditEvent
```

---

## POS (universal-till) tables

SQLite, ~33 tables in `001_init.sql`, grouped by domain:

- **Config / identity:** `schema_migrations`, `settings`, `registers`, `users`,
  `stock_locations`.
- **Catalog:** `categories`, `brands`, `items`, `item_barcodes`, `item_images`,
  `item_variants`, `variant_barcodes`, `price_history`, `tax_codes`,
  `promotions`, `customers`, `payment_methods`.
- **Inventory:** `inventory`, `stock_movements`.
- **Sales:** `sales`, `sale_lines`, `payments`, `sale_discounts`, `sale_links`,
  `shifts`.
- **Plugin host:** `plugin_catalog`, `plugins`, `plugin_entries`,
  `plugin_settings`, `plugin_hooks`, `plugin_permissions`, `shortcut_buttons`.
- **Audit:** `audit_log`.

The **plugin host** tables are what the marketplace install writes: `plugins`
(installed plugin + state), `plugin_entries` (registered UI entries, e.g. the FAQ
page), `plugin_permissions`, `plugin_settings`, `plugin_hooks`. Money columns are
integer minor units throughout.
