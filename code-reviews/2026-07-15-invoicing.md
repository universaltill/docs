# Code review — G31 invoicing increment 1 (VAT invoices + credit notes)

Date: 2026-07-15 · Repo: universal-till · Branch: feat/g31-invoicing
Spec: docs/architecture/invoicing.md (written first, same session).

## What shipped

- **Migration 016** `invoices`: immutable snapshots (buyer, seller JSON,
  totals, per-rate VAT breakdown JSON), gapless `invoice_no` per series
  pinned by `UNIQUE(series, invoice_no)`, one invoice + at most one
  credit note per sale (`UNIQUE(sale_id, kind)`), FKs to sales/invoices.
- **`InvoiceRepo`** — Create allocates MAX+1 inside the insert tx
  (busy_timeout from the D2b fix makes this safe under concurrency);
  BySale/ByDisplayNo/ByID lookups.
- **Series = the till's receipt prefix** (`INV-000001` on the primary,
  `T2-INV-000001` on a replica) — the same collision-avoidance trick as
  receipts, legally sound as declared per-register series. Numbering test
  pins both series and the duplicate-invoice refusal.
- **Seller identity** = `invoice.seller_*` settings (manager card on
  Settings, audited). Feature fully invisible until the business name is
  set; the settings sync to replicas as shop-wide config (LAN sync).
- **Issue flow**: journal detail of a completed sale gains an
  Issue-invoice form (customer name required, address/VAT optional, any
  operator). Idempotent — re-issuing returns the existing invoice. VAT
  bands aggregate the sale lines' RECORDED `tax_rate_bp`/`tax_amount`
  (the sale's own signature, per the inclusive-totals lesson). Audited
  `invoice_issued`; best-effort thermal print through the existing
  `print.Doc` pipeline (INVOICE headline, seller+buyer blocks, per-rate
  rows, display number as CODE128).
- **Credit notes**: after a completed refund, if the original sale
  carries an invoice and the refund has no credit note yet, one is issued
  automatically in the same series with the invoice's customer snapshot,
  cross-linked via `original_invoice_id`, audited `credit_note_issued`.
- **On-screen invoice** `/invoice/{display_no}`: seller/buyer blocks,
  line table, per-rate VAT table, CODE39 barcode, browser Print — the
  "PDF" of v1. Journal detail links invoice/credit note both ways.
- i18n en+fa (31 keys); `httpx.DefaultLocale()` added for
  request-less rendering (background prints).

## Review notes (self-review)

- Placement decision (host core, plugin presentation later) argued in the
  spec — answers Farshid's "plugin if possible" once.
- The credit note copies the ORIGINAL invoice's customer; a partial
  refund produces a credit note over the refunded amount only (it uses
  the refund sale's lines) — correct per-amount behaviour.
- `GetSaleDetailByID` added as a thin wrapper (invoices store sale ids).
- Not in v1 (spec's "later"): invoice list/search page, PDF/e-invoice,
  A4 printing, saved-customer picker, `receipt_template` plugin layouts.
- Sync note: `invoices` is NOT in the LAN-sync admin bundle (it's
  transactional data, not admin state) and sale journals don't carry
  invoices — a replica's invoices live on that replica, consistent with
  its own series. Cross-till invoice visibility lands with the cloud
  tier; documented here.

## Tests + E2E

- `TestVATBreakdownGroupsByRecordedRate` (mixed 20%/zero-rate lines),
  `TestInvoiceNumberingPerSeries` (gapless per series, replica prefix,
  duplicate-per-sale refused, lookups) — on a real migrated DB.
- Live E2E: journal shows no invoice UI before seller config → configure
  seller → sale → issue → `INV-000001` with correct seller/buyer/VAT
  band (20.00%) on the page → re-issue idempotent → refund → credit note
  `INV-000002` auto-issued with the same customer, cross-linked both
  ways, `invoice_seller_updated`/`invoice_issued`/`credit_note_issued`
  all audited → fa locale renders. Full suite + both guards green.
