# Variant images (design, 2026-07-17)

Status: **spec — ready to build.** Farshid: "the variant can have different
images" (sizes/flavours look different).

## Storage
- Today: one image per item at `assets/items/{itemID}/thumb.png` (uploaded via
  the catalog panel or fetched by barcode auto-fill).
- Add: `assets/items/{itemID}/variants/{variantID}/thumb.png` — same pipeline
  (decode → re-encode → thumb), same SSRF/size guards if URL-sourced.

## Fallback chain (everywhere an image shows)
variant image → parent item image → letter/placeholder. One helper
(`imgv`-style URL builder) so sale buttons, catalog rows, panel, store and
(later) shopper surfaces behave identically.

## UI
- Variant grid row gains a small image cell: current thumb (or item
  fallback, dimmed) + upload control posting to
  `POST /api/catalog/variant/image` (variant_id + file), mirroring the item
  image endpoint incl. auditing.
- Sale screen: variant-specific buttons (where variants render as separate
  buttons) use the chain automatically.

## Sync
Item images ride LAN sync today? VERIFY — if images sync via the admin
bundle/snapshot, variant images must join the same mechanism; if they don't,
note the limitation in both cases (images are per-till until image sync is
designed).

## Out of scope now
Image galleries (multiple per variant), shopper-app image CDN.
