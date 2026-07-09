# Code review — one-screen POS layout (universal-till)

**Date:** 2026-07-09
**Scope:** `internal/pages/{init,journal_page}.go`, `web/public/app.css`,
`web/ui/pages/{index,journal}.html`, `web/ui/partials/basket.html`, locales.

## What changed
Reworked the sale screen to behave like a real shop till: a fixed one-screen
layout where **nothing moves** when lines are added.

- `.pos-container` is a viewport-height CSS grid, 2 columns
  (`minmax(330px,420px) 1fr`), areas `"basket products" / "tender products"`.
  Both rows are bounded fractions (`minmax(0,1fr) / minmax(0,1.15fr)`) — an
  `auto` row would let the tall tender card overflow the viewport.
- Every panel gets `min-height:0; overflow-y:auto` — panels scroll internally,
  the page never scrolls (`body.kiosk { overflow:hidden }`).
- Basket is a flex column: `.basket-scroll` (lines) scrolls, `.totals` pinned.
- Journal removed from the sale screen; new `/journal` page + menu item
  (`journal.title` added to en/fa locales).
- HTMX placeholder divs in `index.html` now carry `.basket` / `.products`
  classes so the grid is stable before the partials load (no first-paint jump).
- Compact tiles/inputs sized for small touch screens; kiosk font 15px.

## Review notes
- Grid areas still named (`basket/products/tender/journal`) so theme plugins
  can reposition panels by overriding `grid-template-areas`. Journal area kept
  as `display:none` for backwards-compat with themes that reference it.
- Verified live: 8 scans via `/api/pos/scan` → 5 merged lines all inside
  `.basket-scroll`, totals pinned, tender/products positions unchanged
  (fixed by grid, not content-driven).
- Gates: `go build ./... && go test ./...` pass, data-access guard pass.

## Follow-ups
- Theme repos (screen-top / buttons-left) reference the journal grid area;
  they still render but should be refreshed for the 2-column default.
