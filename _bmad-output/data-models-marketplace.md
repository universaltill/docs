# Data Models — Marketplace (ut-market-place)

Part: `marketplace`  
Repo: `~/repos/unitill/ut-market-place`  
ORM: Ent (`entgo.io/ent`)  
Schema sources: `internal/repositories/ent/schema/*`

## Core Entities (inferred from Ent schemas)

- `PluginListing` — catalog metadata surfaced to merchants (see `schema/pluginlisting.go`)
  - Fields include: slug, display_name, summary, plugin_type, vendor_name, trust_tier, compatibility arches, available_locales, paid_listing, icon_url, etc.
  - Edges: vendor, releases, entitlements
- `PluginRelease` — versioned releases for a listing (schema file present: `schema/pluginrelease.go`)
- `VendorOrganization` — vendor identity/ownership (schema file present: `schema/vendororganization.go`)
- `MerchantOrganization` — merchant org identity (schema file present: `schema/merchantorganization.go`)
- `StoreEntitlement` — entitlement/authorization to install/use plugins (schema file present: `schema/storeentitlement.go`)
- `AuditEvent` — audit log events (schema file present: `schema/auditevent.go`)
- `RegionConfig` — region-specific settings (schema file present: `schema/region_config.go`)
- `ReviewAssignment` — workflow for reviews/trust tiers (schema file present: `schema/reviewassignment.go`)

## Notes / Gaps

- Exact DB engines supported: SQLite and Postgres drivers appear in `go.mod`.
- Migration strategy is Ent schema create (see `internal/data/database.go` calling `client.Schema.Create(ctx)`).
- For plugin publish MVP, confirm which entities are required for upload/publish and which are future (review workflows, compliance tiers).

