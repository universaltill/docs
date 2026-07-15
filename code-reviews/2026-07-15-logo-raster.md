# Code review — receipt logo raster (GS v 0)

Date: 2026-07-15 · Repo: universal-till · Branch: feat/logo-raster
The receipt-designer follow-up ("logo raster (GS v 0)" queue item).

## What shipped

- `print.RasterLogo`: image → GS v 0 block. Downscales to the 576-dot
  80mm head (240-row height cap so a bad upload can't feed paper
  forever), nearest-neighbour (logos are flat art), Rec.601 luma with a
  160 threshold, transparency = paper. Nil on undecodable input — a
  receipt without a logo beats no receipt.
- `print.Doc.Logo` — Render() emits the raster centered above the store
  name on EVERY thermal document (receipts, invoices, Z-reports).
- Designer: logo upload/remove (manager, validated by actually encoding
  the file, audited receipt_logo_uploaded/removed, stored at
  web/public/assets/logo/receipt-logo.png) + "print the logo" toggle
  (receipt.show_logo). Test print includes it. i18n en+fa.

## Tests + E2E

- Structural byte tests: GS v 0 header, xL/xH/yL/yH dimensions, exact
  bit pattern for a half-black test image, downscale bounds, garbage→nil,
  Render embeds the block.
- E2E with a fake network printer (nc capture): valid PNG upload ✓,
  garbage 422, test print with the toggle carries a 240×240 raster
  (binary-verified — note to self: xxd's byte pairing hides odd-offset
  matches; search bytes, not hex text), toggle off → no raster.
- ⚠ HARDWARE SIGN-OFF PENDING: Farshid prints a test receipt with the
  logo on the real ESC/POS thermal.
