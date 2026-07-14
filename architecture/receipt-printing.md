# Receipt printing — silent ESC/POS path (P0.1, zero-touch phase C core)

Status: **SHIPPED 2026-07-14** (universal-till; review code-reviews/2026-07-14-receipt-printing.md; on-hardware sign-off pending). Closes the oldest production gap:
the till has NO printer path — receipts exist only as a browser print view.

## Scope (v1)

- **`internal/print`**: ESC/POS document rendering + transports.
  - Encoder: init, alignment, bold/double-height, 42-column layout for
    80 mm paper, feed, partial cut, cash-drawer kick (pulse on pin 2 — the
    drawer plugs into the printer; no-sale already publishes an event).
  - Document model is plain strings — the caller (pages layer) formats
    money/locale; print stays dumb and testable byte-for-byte.
  - Transports: `network` (TCP :9100, the raw-print standard every
    ethernet/wifi thermal printer speaks), `device` (write to a character
    device — `/dev/usb/lp0` on Linux for USB printers), `off`.
- **Settings** (manager card): mode off/network/device, address or device
  path, auto-print-on-sale toggle, charset. Keys `printer.*` through the
  normal settings path; applied without restart.
- **Print test receipt** button (`POST /api/print/test`) — the moment of
  truth for setup.
- **Auto-print on tender**: completed sale → receipt prints in a
  goroutine. **Never blocks checkout** (ADR-0003 spirit): print failure
  logs + audits (`print_failed`), the sale is already committed.
- **Reprint** from journal detail (`POST /api/print/receipt/{receiptNo}`).

## Character sets (honest v1)

Thermal printers in text mode don't render Farsi/Arabic reliably.
`printer.charset`: `utf8` (default — many modern/cheap printers accept
raw UTF-8) or `ascii` (transliterate, unmappable → `?`). Proper RTL needs
bitmap rendering — explicitly a follow-up, noted for fa shops.

## Follow-ups queued (Farshid, 2026-07-14)

- **Receipt barcode (G28, roadmap P1.0)**: print the receipt number as a
  CODE128 barcode (`GS k`) + human-readable line, so the cashier scans a
  paper receipt to open the sale for a refund.
- **Receipt designer (G29, roadmap P1.5)**: owner-editable receipt —
  logo, header/footer lines, which fields show (SKU, tax breakdown, VAT
  no.), live preview + test print. Must be easy for non-computer people;
  `receipt_template` plugins remain the advanced path.

## Label printing (G9 — SHIPPED 2026-07-14, review code-reviews/2026-07-14-label-printing.md)

Product/shelf labels on the same ESC/POS transport (small shops label with
the receipt printer; dedicated label printers = follow-up transport).

- **Label** = item name, price (double height), CODE128 barcode of the
  item's primary barcode (SKU fallback — alphanumeric is fine on the
  printer), cut per label.
- Catalog page: pick an item (row click, as with images/variants), choose
  copies (1–50), print. Any signed-in operator (labelling shelves is
  normal staff work). `POST /api/print/labels` (item_id, copies), audited.
- Items with neither barcode nor SKU refuse with a clear message.

## Out of scope (later phases)

USB hot-plug auto-detect (full phase C), printer status polling (paper
out), kitchen printers/KDS routing (G3), label printing (G9 — reuses the
transport), image/bitmap receipts (RTL + logos).

## Verification

Encoder unit tests (golden bytes incl. cut/kick), fake TCP :9100 server
receives a complete sale's bytes on tender with auto-print on, test-button
E2E, checkout latency unaffected with printer unreachable (async proof).
On-hardware sign-off: Farshid (any ESC/POS printer; documented in README).
