# Data Models — POS (universal-till)

Part: `pos`  
Repo: `~/repos/unitill/universal-till`  
Primary storage: SQLite (`modernc.org/sqlite`)  
Migration source: `internal/db/migrations/001_init.sql`

## Schema Summary (tables)

Core system:
- `schema_migrations` (migration tracking)
- `settings` (global key/value)
- `audit_log` (audit trail)

Catalog / pricing:
- `tax_codes`
- `categories`
- `brands`
- `items`
- `item_variants`
- `item_barcodes`, `variant_barcodes`
- `item_images`
- `price_history`

People / registers / payments:
- `customers`
- `registers`
- `users`
- `payment_methods`

Sales:
- `sales`
- `sale_lines`
- `sale_discounts`
- `payments`
- `sale_links`

Inventory:
- `stock_locations`
- `inventory`
- `stock_movements`

Promotions:
- `promotions`

Plugin system:
- `plugin_catalog` (available marketplace catalog cached locally)
- `plugins` (installed plugins)
- `plugin_entries` (menu pages/buttons/actions/hooks exposed by plugins)
- `plugin_settings` (plugin config values with scope)
- `plugin_hooks` (event/action hooks)
- `plugin_permissions` (grant/deny permissions)

UI shortcuts:
- `shortcut_buttons`

## Notable Constraints / Design

- Uses integer minor units for money fields (e.g., item prices, totals).
- `sales.status` supports states like `open|parked|completed|voided|refunded` (per schema comment).
- Plugin tables encode trust and install state (`plugins.install_state`, `plugins.trust_level`) and a catalog cache for marketplace browsing/install.

## Notes / Gaps

- Additional migrations beyond `001_init.sql` should be inventoried if present.
- Sync model (offline queueing + conflict resolution) is not captured in schema docs yet.

