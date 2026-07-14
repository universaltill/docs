# Review — barcode label printing (P1.3 / G9)

Date: 2026-07-14 · Repo: universal-till · Spec: `architecture/
receipt-printing.md` § label printing (written first).

## What shipped

- `print.RenderLabel(name, price, code, charset)`: centered name,
  double-height price, CODE128 barcode, cut — one label per copy on the
  existing ESC/POS transports (receipt printer doubles as the label
  printer for small shops; dedicated label-printer transport is the
  follow-up).
- `CatalogRepo.GetItemLabel`: name + base price + the primary barcode
  (falls back to any barcode, then SKU — alphanumeric SKUs are fine in
  CODE128 code-set B).
- `POST /api/print/labels` (item_id, copies 1–50, clamped): any signed-in
  operator — shelf labelling is normal staff work; audited
  (`item`/`labels_printed`). Items with neither barcode nor SKU refuse
  with a clear message.
- Catalog page: "Print labels" details block wired to the existing
  row-click item picker. 6 i18n keys en+fa.

## Notes

- The label prices with `base_price` — the catalog's ticket price. For
  tax-inclusive shops that IS the shelf price; exclusive shops may want
  price-incl-tax on shelf labels → revisit with the receipt designer
  (G29) where "what the label shows" becomes configurable.

## Verification

Unit: label byte structure (init/cut, name, price, `{B<code>`, double
height). Live E2E on the fake printer: 3 copies → exactly 3 cuts, 3×name,
3×barcode, price `£1.20` = the item's base price; a codeless item →
400 with the friendly message; audit row with copies+code. Full suite +
guards green.
