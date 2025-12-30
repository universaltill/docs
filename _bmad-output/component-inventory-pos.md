# Component Inventory — POS (universal-till)

This is a lightweight component inventory based on package structure and known UI primitives.

## UI / View Models (`internal/ui`)

- `ButtonStore`, `ButtonsHTTP`, `Renderer` (button shortcuts and rendering)
- `BasketView` (basket UI view model)
- `PriceResolverAdapter` (pricing resolver adapter)

## Pages / Routes (`internal/pages`)

Primary page areas:
- Home (`index_page.go`)
- POS / basket (`pos_api.go`, `basket_page.go`)
- Inventory (`inventory_page.go`, `inventory_api.go`)
- Shifts (`shifts_page.go`, `shifts_api.go`)
- Settings (`settings_page.go`)
- Plugins (`plugins_page.go`, `plugin_api.go`, `plugins_store_page.go`)
- Catalog (`internal/pages/catalog/*`)

## Templates / Static Assets (`web/ui`, `web/public`)

- `web/ui/` HTML templates/partials
- `web/public/app.css` includes HTMX loading indicators

## Notes

- POS UI quality is a known gap; this inventory helps scope UI uplift work.
