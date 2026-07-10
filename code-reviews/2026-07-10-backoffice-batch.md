# Code review — journal details, catalog images, designer DnD, shifts, reports (universal-till)

**Date:** 2026-07-10 (Farshid's 10-item list, items 1/2/6/7/8)

## Journal sale details (item 2)
`POSRepo.GetSaleDetail(receiptNo)` (header + lines + payments) → `/journal/{receipt}`
page; journal rows clickable; journal page lists 100 recent (partial keeps 5 on the
sale-screen fragment). 404 for unknown receipts.

## Catalog item images (item 1)
`POST /api/catalog/item/image` (multipart ≤10MB): item_id validated against the DB via
new `CatalogRepo.ItemExists` (no SQL in handler), rejects path chars (`/\.`), decodes
PNG/JPEG (rejects garbage), re-encodes to `web/public/assets/items/<id>/thumb.png` —
the exact convention tiles/designer already read. Catalog table shows thumbs
(onerror-hidden); "Item image" form fills from row click. Verified: upload 200 + file
on disk, traversal 400, non-image 400.

## Designer (item 6)
Stale Themes section removed (Settings owns themes). Tiles are HTML5 drag&drop;
`POST /api/buttons/reorder` persists order via `ShortcutsRepo.UpdateOrder`
(migration 004 `sort_order`). LoadButtons orders by sort_order; SaveButtons keeps
slice order; AddButton appends at MAX+1. Verified live: reorder 204 → sale screen
tile order changed.

## Shifts (item 8)
Page rebuilt around the actual state: open-shift status card + close form (counted £
→ minor client-side) + adjustment/payout in details; otherwise an open form pinned to
reg-default. History table with counted/expected/**variance** (computed in repo).
New `POSRepo.CurrentOpenShift`/`ListRecentShifts`. Verified live: open £100 → cash
sale £4.08 → close £104.08 → "Expected £101.44, Variance £2.64" (expected excludes
change correctly), history row shows variance.

## Reports (item 7)
`/reports` + menu: period picker, KPI cards (revenue/sales/tax), sales-by-day, top
items by revenue, payments by method (`SalesByDay`/`TopItems`/`PaymentBreakdown`,
completed sales only, applied = amount − change). Verified with 30-day live data.

## Also
- FAQ-plugin question answered: manifest says runtime "go" + entrypoint but the POS
  renders the content bundle itself — binary is legacy scaffolding; plan: convert FAQ
  to runtime none and build a dedicated executable sample instead.
- ui test schema updated for sort_order. Gates green (full suite + guard).

## Addendum 3 (2026-07-10): multi-agent review of HEAD~8..HEAD — findings applied
9 verified findings (5 finder angles + verification). All fixed & pushed:
Deps.State data race (StateMu + CurrentState/UpdateState, race-tested);
journal-detail i18n; shifts register picker; tender rejects invalid JSON (400);
plugin payment method type from config (json_valid-guarded — empty config had
broken plugin init at boot, caught live); scroll lock via body.sale-screen
class; single payment-methods query on the sale screen; renderCatalogTable
helper (8 duplicates); test plugin_entries schema completed.
External (Codex) finding on ut-plugin-theme-buttons-left "journal grid slot":
checked — /journal page has no .pos-container (plain cards), so the theme's
grid template does not apply there; no regression. Noted to keep theme docs
explicit that pos-container grids only affect the sale screen.
