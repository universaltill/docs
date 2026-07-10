# Code review — hold/resume sales, tender tabs, usable catalog & inventory (universal-till)

**Date:** 2026-07-09
**Scope:** hold/resume feature (migration 002, `data.HeldSalesRepo`, `pos` Snapshot/Restore,
`pages/hold_api.go`), tender panel tabs + product tiles (index.html, buttons.html, app.css),
catalog page rewrite (catalog.html, catalog_table.html), inventory page rewrite
(inventory.html, inventory_page.go, POSRepo stock methods), migration 003, vendored JS.

## Hold & resume (new feature)
A customer mid-shop can be parked while the till serves someone else, then resumed.
- `pos.Service.Snapshot()/Restore()` capture the FULL basket state including fields the
  wire format hides (`ItemID/VariantID/TaxRateBP/IsWeighed` are `json:"-"` on BasketLine —
  `SnapshotLine` re-exposes them so pricing/completion behave identically after resume).
- Persisted in new `held_sales` table (migration 002) so held sales survive a till
  restart — offline-first. Repo follows the observability/trace pattern.
- `POST /api/pos/hold` (snapshot→insert→reset, toast), `POST /api/pos/resume` (refuses if
  the current basket has items — no silent merge), `GET /ui/held` (chip strip, refreshes on
  `HX-Trigger: held-changed`). Chips show label (customer name or time) + line count + total.
- Unit tests: JSON round-trip incl. hidden fields, totals equality, HasItems lifecycle.
- Verified live: hold A (2 lines) → serve+tender B → resume A (lines/totals back, row
  deleted); guard toasts for "hold empty" and "resume while busy" both exercised.

## Tender panel: Pay/Split tabs — never scrolls
Scan row (barcode+qty+add) pinned top; held strip; Pay tab = two large Cash/Card buttons +
offline toggle; Split tab = compact 2-col split-tender form (all `split-tender-*` IDs kept —
app.js binds by ID); footer = Hold Sale + New Customer. Panel is `overflow:hidden`; only the
active tab body may scroll. Alpine drives the tabs (`x-data`), `[x-cloak]` added.

## Product tiles
Whole tile is now one `<button>` touch target: thumb, single name, price. Price threaded
through `ShortcutsRepo.LoadButtons` (JOIN items.base_price) → Button → ButtonVM → template.
Demo thumbs regenerated (50): the old ones had the SKU + name baked into the image, which
duplicated the label ("ITM006 / Apple Juice 1L" screenshot).

## Catalog page
Was six raw-UUID forms. Now: searchable item table (client filter reapplied after HTMX
swaps) + one create/edit form that fills on row click; price entered in pounds, converted
to minor units client-side (API contract unchanged — still posts `price` in minor units and
returns the `#catalog-table` partial). Deactivate per row with confirm. Variants/barcodes
in secondary `<details>`, item ID auto-filled from row click. Pointer-typed lookups
(`CategoryID *string` etc.) rendered with `{{ with }}` to avoid `<no value>`.

## Inventory page
Was raw item-uuid/location-uuid text fields. Now: live stock-levels table (new
`POSRepo.ListStockLevels`, low rows flagged), low-stock card, receive/adjust form with an
item picker (datalist name/SKU → hidden `item_id`, custom validity when unresolved),
location select (new `POSRepo.ListStockLocations`), cost in pounds → minor. Manager
override + returns in `<details>`. Row click pre-fills the form.

## Real bug found & fixed: audit FK broke ALL stock receipts
`getSessionUserID` returns hardcoded `"system"` but no such user row existed →
`audit_log.actor_id` FK failed → every stock receipt/adjustment 500'd. Migration 003 seeds
the `system` user (`INSERT OR IGNORE`). Verified: receive +5 and adjust −2 both succeed and
inventory quantity updates.

## Production-readiness: vendored JS
HTMX and Alpine were loaded from unpkg CDN — an offline till would lose its whole UI.
Both vendored under `web/public/vendor/` with `assetv` cache-busting.

## Gates
`go build ./... && go test ./...` green; data-access guard green; all pages 200 live.

## Addendum (2026-07-10): receipt panel bleed + UI scale
- **Bug (user screenshot):** after tender, the receipt swapped into `#basket`
  WITHOUT `class="basket"` → the div lost its grid area and overlapped other
  panels ("things hiding between panels"). Wrapper now emits
  `class="basket receipt-view"`; `.receipt-view` is `display:block;
  overflow-y:auto` so long receipts scroll inside the panel. Receipt inline
  CSS no longer redefines `.btn` (was fighting app.css/themes); barcode
  1.4rem. Verified live: tender → wrapper carries both classes.
- **Feature: `UT_UI_SCALE`** (0.5–2.0, default 1) — scales the root
  font-size (`html style="font-size: …px"` via new `uiscalepx` template func
  + `httpx.InitUIScale`). Viewport offsets converted px→rem and kiosk font to
  .9375rem so the one-screen layout scales coherently. Verified: scale 0.85
  → root 13.6px. Documented in pos.env.dev + Pi service unit.
- Smoke tests updated for the new inventory page headings.
