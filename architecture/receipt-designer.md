# Receipt designer (G29, roadmap P1.5)

Status: **SHIPPED 2026-07-14 (increment 1)** (review code-reviews/2026-07-14-receipt-designer.md). Farshid: "let the owner design
its own receipt — it should be easy to use."

## Increment 1 — text designer with live preview

- **`/receipt-designer`** page (manager): a form on one side, a **live
  ticket preview** on the other (updates as you type — HTMX post of the
  unsaved values to a preview endpoint rendering a sample sale as a
  42-column text ticket). "Save" persists; "Print test" sends the sample
  to the real printer.
- Designable (settings `receipt.*`):
  - up to 3 **header lines** (address, phone, VAT number…),
  - **footer message** (default "Thank you!"),
  - toggles: show per-line **SKU**, show **subtotal+tax rows** (off =
    just the TOTAL), show the **barcode**.
- Applied everywhere a receipt renders: the thermal print path
  (`buildReceiptDoc`), the reprint/journal path, and the on-screen HTML
  receipt (header/footer lines).
- `print.RenderText(doc)` renders the same 42-col layout as plain text
  (barcode as a placeholder row) — the preview shows exactly what the
  printer will lay out, minus the bars.

## Later increments

Shop **logo** (ESC/POS raster `GS v 0` from an uploaded PNG, 1-bit
dither), per-label content options (G9 tie-in), drag-reorder of sections,
`receipt_template` marketplace plugins as the fully-custom path.

## Verification

Unit: RenderText layout parity, settings round-trip into the doc
(toggles honoured). E2E: save header/footer/toggles → sale auto-print
carries them (bytes), SKU rows appear/disappear per toggle, preview
endpoint reflects unsaved values, cashier blocked.
