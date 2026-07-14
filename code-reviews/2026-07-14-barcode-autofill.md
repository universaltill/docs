# Review — catalog barcode auto-fill from open product databases (G15 increment 1)

Date: 2026-07-14 · Repo: universal-till · Spec:
`architecture/item-discovery-and-universal-catalog.md` (§ increment 1)

## What shipped

- `internal/lookup`: client for the Open Food Facts v2 API shape, tried in
  order across Open Food Facts → Open Products Facts → Open Beauty Facts.
  Custom User-Agent (their API policy), 6s timeout, 1 MB response cap,
  barcode = 6–14 digits only.
- `GET /api/catalog/lookup?barcode=…` → `{data,error}`; 400 invalid,
  404 not found anywhere, 502 all sources unreachable. Audited
  (`catalog`/`barcode_lookup`, payload `{found, source}`).
- Create path (`POST /api/catalog/item`) extensions: optional `barcode`
  field is attached as the item's **primary barcode** after create;
  optional `imageUrl` is downloaded server-side and saved as the standard
  `thumb.png`.
- Catalog page: barcode input + Auto-fill button on the item form. A
  scanner's terminating Enter triggers the lookup (not a form submit).
  Fills name/description, matches brand against the existing brands
  datalist by name, remembers the image URL, then focuses the price
  field. 6 i18n keys en+fa.

## Security review

- **SSRF**: `imageUrl` is client-supplied → `FetchImage` requires https
  and a hostname ending in one of the three Open*Facts domains; userinfo
  spoof (`https://good.host@evil`) covered by test. 5 MB cap; image is
  decoded and re-encoded PNG (never stored raw).
- Lookup endpoint sits behind the normal auth middleware; barcode is
  digit-validated before any outbound request and path-escaped anyway.

## Findings / accepted trade-offs

1. **Mixed miss+outage reads as 404**: if source A answers "unknown" but
   source B is down, we return not-found rather than 502. Accepted — the
   dominant DB is source A, and the failure mode is just "fill manually".
2. **Barcode attach failure after create returns 400** ("item created,
   but barcode attach failed") — the item exists at that point; the
   message is honest and the shop can attach via the barcodes form.
   Accepted over wrapping create+attach in one transaction (attach goes
   through the same `pos.AddBarcode` op the barcodes form uses).
3. **Image download is best-effort** (logged, never fails the create) —
   cosmetic asset only.
4. Pre-existing, not introduced here: catalog.html JS has some hardcoded
   English strings ('Edit: ', '✓ saved'); new JS strings all go through
   `T`. Cleanup candidate for a later i18n pass.

## Verification

- Unit: `internal/lookup` (validation, source fall-through, not-found vs
  transport error, allowlist incl. spoofs); handler tests (400 envelope,
  create-with-barcode attaches primary). Full `go test ./...`,
  data-access guard, i18n guard: green.
- Live E2E on scratch DB (:8091, UT_AUTH=off): real OFF lookup of
  5449000000996 → Coca-Cola with image URL; create with barcode+imageUrl
  → `item_barcodes` primary row, 300×400 thumb.png downloaded;
  **`POST /api/pos/scan` with the barcode rings the new item** —
  scan-to-sellable proven; audit rows present; page renders the auto-fill
  UI in en and fa.
