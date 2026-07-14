# Review — silent receipt printing (P0.1, ESC/POS)

Date: 2026-07-14 · Repo: universal-till · Spec:
`architecture/receipt-printing.md` (written first). First task off the
production roadmap (`architecture/production-roadmap.md`).

## What shipped

- `internal/print`: ESC/POS encoder (init, alignment, bold/double, 42-col
  layout with right-aligned amounts + name wrapping, feed/partial-cut,
  **cash-drawer kick**) over a string-only document model — pages format
  money/labels, print stays byte-testable. Charsets: `utf8` pass-through
  (modern thermals) or `ascii` (diacritic folding, unmappable → `?`).
- Transports: `network` (raw TCP :9100, 5s dial + write deadline) and
  `device` (character device write, e.g. `/dev/usb/lp0`); `off` default.
- `printer.*` settings + manager-only Settings card (mode/address/device/
  charset/auto-print) + **Print test receipt** button; cashiers 403.
- **Auto-print on tender**: goroutine after the sale commits — checkout
  can never wait on the printer; failures audit as `sale/print_failed`
  with the error. Drawer kicks only on cash payments.
- **Reprint** button on journal detail (`POST /api/print/receipt/{no}`,
  audited `receipt_reprint`).
- Built-in printer counts toward the existing on-screen
  "printer unavailable" hint (`printerAvailable`). 16 i18n keys en+fa.

## Findings

1. **Pre-existing totals inconsistency discovered (NOT fixed here)**: on
   the E2E DB, `sales.total` ≠ Σ `sale_lines.total_after_tax` for some
   sales (120 vs 140) while an earlier sale had 235 = 235. The printed
   receipt mirrors the journal's official row (same numbers as the
   journal detail page), so print is consistent with the rest of the
   till — but the tender/engine totals path needs investigation
   (suspect: the known `pos.tax_inclusive` vs `store.tax_inclusive`
   duplicate settings key). Follow-up filed in the task list.
2. Receipts print with latin digits/labels for now — proper RTL/Farsi
   needs bitmap rendering (spec'd as follow-up); `charset=ascii` keeps
   cheap CP437 printers from printing garbage.
3. Payment label uses the raw method id capitalised — fine for
   cash/card, revisit when plugin methods print.

## Verification

- Unit: encoder golden checks (init/cut/kick presence+absence, qty×name
  row right-aligned at width 42, long-name wrap, ascii folding
  "Café Zürich"→"Cafe Zurich" and `£`→`?`, UTF-8 pass-through for Farsi),
  transport config validation, fake TCP printer receives the stream,
  unreachable printer fails fast. Full `go test ./...` + both guards green.
- Live E2E against a fake :9100 printer: settings via API (204) → test
  print delivered (267 bytes) → **cash sale auto-printed** (byte-verified:
  init, drawer kick, item line, bold TOTAL, cut) → printer pointed at a
  dead address → **tender still 200 in 11 ms** and `print_failed` audited
  → reprint from journal delivered → cashier 403 on printer settings.
- ⚠️ On-hardware sign-off pending: Farshid to point mode=network at any
  ESC/POS thermal (or device mode on the Pi) and press "Print test
  receipt".
