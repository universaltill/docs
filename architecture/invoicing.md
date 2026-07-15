# Invoicing & credit notes (G31)

Status: **spec 2026-07-15**, first increment implemented the same day
(Farshid 2026-07-14: "(VAT) invoices for non-shop/service/B2B users …
should be a plugin if possible").

## Why

Shops selling to businesses (and service trades: barbers, repairs,
trades) must hand over a **VAT invoice**: seller and buyer identified
(names, addresses, VAT numbers), a **sequential invoice number** from a
declared series, issue date, and a per-VAT-rate breakdown of net/VAT/
gross. Receipts don't satisfy this; a card slip certainly doesn't.
Refunding an invoiced sale legally requires a **credit note** that
references the original invoice, from the same series.

## Placement: host core, plugin surface later

Farshid asked for "a plugin if possible". Honest assessment: sequential
numbering, credit-note coupling to the refund flow, and thermal printing
all live in the host's transactional core — the plugin runtime has no
capability to allocate gapless sequences or join the refund transaction,
and granting DB-write host functions to plugins would blow a hole in the
trust model (ADR-0006). So — exactly like payments (engine in the host,
providers as plugins) — **the invoicing engine is host code**; what
becomes pluggable later is the *presentation*: invoice templates ride the
`receipt_template` plugin type, and e-invoice/PDF delivery rides the
cloud tier (G16). Recorded here so the "plugin if possible" question is
answered once.

## Design (increment 1, shipped)

- **Numbering / series.** Gapless sequence per *series*, where the series
  is the till's receipt prefix (`INV-…` on the primary, `T2-INV-…` on a
  replica) — the same trick that keeps receipt numbers collision-free
  across a multi-till shop, and legally sound: jurisdictions accept
  multiple declared series (one per register). Allocation is
  `MAX(invoice_no)+1` per series inside the insert transaction, pinned by
  `UNIQUE(series, invoice_no)`.
- **Data.** Migration `016_invoices.sql`: `invoices(id, series,
  invoice_no, display_no, kind invoice|credit_note, sale_id FK,
  original_invoice_id (credit notes), customer_name/address/vat_no
  snapshot, seller snapshot JSON, net_total/tax_total/gross_total,
  vat_breakdown JSON per rate, issued_at, issued_by)`. Customer fields
  are **snapshots** — an invoice is immutable evidence, never a join.
- **Seller identity.** Settings card (manager): `invoice.seller_name`,
  `invoice.seller_address`, `invoice.seller_vat_no`. The whole feature is
  **invisible until the seller details are configured** (same posture as
  printer/AI: no half-configured surprises). These sync to replicas via
  LAN sync (shop-wide settings), while the series stays per till.
- **Issue flow.** Journal detail / receipt view of a completed sale gains
  "Issue invoice" (any operator — handing a customer an invoice is a
  checkout task): small form (customer name required; address + VAT no
  optional), one invoice per sale (re-showing an issued invoice instead
  of duplicating), audited `invoice_issued`. VAT breakdown is computed
  from the sale lines' recorded `tax_rate_bp`/`tax_amount` — the sale's
  own tax signature, not today's settings (same principle the refund fix
  established).
- **Credit notes.** When a refund completes against a sale that has an
  invoice, a credit note is issued automatically in the same series
  (negative amounts, `original_invoice_id` set, `display_no` cross-
  printed), audited `credit_note_issued`. No invoice → no credit note.
- **Output.** Thermal print via the existing `print.Doc` pipeline
  (INVOICE/CREDIT NOTE headline, seller + buyer blocks, per-rate VAT
  table, display number as CODE128) honoring the shop's receipt design;
  plus an on-screen invoice page (`/invoice/{display_no}`) reachable from
  the journal, browser-printable (the "PDF" of v1 — a real PDF/e-invoice
  exporter is a later increment, likely cloud-side).

## Later increments

- Invoice list/search page + date-range export (accountant handoff).
- PDF + e-invoice delivery (email/G16 app) — cloud tier.
- `receipt_template` plugin type renders custom invoice layouts.
- Customer book integration (pick a saved customer instead of retyping).
- Multi-page A4 printing for long invoices (beyond 80mm).
