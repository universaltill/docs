# Review — receipt designer (P1.5 / G29 increment 1)

Date: 2026-07-14 · Repo: universal-till · Spec:
`architecture/receipt-designer.md` (written first).

## What shipped

- **`/receipt-designer`** (manager; linked from the Settings printer
  card): form + **live ticket preview** — every keystroke re-renders a
  sample sale as the exact 42-column layout via `print.RenderText`
  (Render's plain-text twin; barcode as a placeholder row). Save persists
  `receipt.*` settings; **Print test** sends the unsaved design to the
  real printer.
- Designable: up to 3 header lines (address/phone/VAT), footer message,
  show SKU per line, show subtotal+tax rows (off = TOTAL only — discount
  stays visible always, money honesty), show the receipt barcode (help
  text warns it's needed for scan-to-refund).
- `buildReceiptDoc` applies the design to every thermal print: sales,
  refunds, reprints. Audited (`settings/receipt/receipt_design_saved`).
  13 i18n keys en+fa.

## Honest scope notes

1. The **on-screen HTML receipt** still uses the standard layout — the
   design currently drives the printed ticket (+ the designer's own
   preview). Wiring header/footer/toggles into the HTML receipt partial
   is the queued follow-up.
2. Logo (ESC/POS raster) and section reordering are spec'd later
   increments; `receipt_template` plugins stay the fully-custom path.

## Verification

- Unit: RenderText carries header/footer/SKU/barcode-placeholder,
  hides subtotal/tax when toggled off (first assertion draft matched the
  receipt-number in the meta line — fixed to assert the placeholder).
- Live E2E: designer page renders; preview endpoint reflects **unsaved**
  values; saved design → a real cash sale's printed bytes carry the
  header lines, VAT line, footer, kept barcode, hidden subtotal/tax,
  kept TOTAL; cashier blocked. Full suite + guards green.
