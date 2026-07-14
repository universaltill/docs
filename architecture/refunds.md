# Refunds & returns + receipt barcode (P1.0 — G27/G28)

Status: **SHIPPED 2026-07-14** (review code-reviews/2026-07-14-refunds.md). Farshid: "I cannot see any
refund!!! customer should be able to return one or all items" + "the
receipt should have a barcode which lets the cashier read with the
scanner for the refund".

## What exists (build on)

`pos.CompleteSale` already supports `SaleType:"return"` — it restocks
inventory and `OriginalSaleID` writes a `sale_links` row. No UI exposes
any of it.

## Flow

1. **Entry points**: scan the paper receipt at the sale screen (the scan
   handler falls back to receipt-number lookup when no item matches →
   redirects to the refund page) — or the journal detail's Refund button.
2. **`/refund/{receiptNo}`**: shows the original lines with a quantity
   picker per line (default = full remaining), refund method (cash /
   original method), and a **manager PIN** field (same
   `AuthorizeManager` pattern as inventory overrides; PIN owner = audit
   actor).
3. **`POST /api/refund`** validates server-side:
   - remaining refundable per line = sold − already returned (summed
     over `sale_links` children, keyed item+variant+unit price) — the
     **double-refund guard**; requested quantities clamp-checked.
   - amounts recomputed by the engine from the original unit prices, tax
     rates and the original sale's inclusive/exclusive signature; line
     discounts and any whole-sale discount prorated by refunded share.
   - creates the return sale (linked, restocked), audits, **auto-prints
     a refund receipt** that references the original receipt number
     (cash refunds kick the drawer to give money back).
4. Refunded sales show their link in the journal detail both ways.

## Receipt barcode (G28)

Every printed receipt (sale and refund) carries a **CODE128** barcode of
its receipt number (`GS k` 73 with code-set B) + the number printed under
it. Scanning it at the sale screen opens the refund page. Weighed lines
refund by quantity like any other (the qty picker accepts decimals).

## Out of scope (v1)

Exchanges (refund + new sale in one), restocking fees, refunds without a
receipt (manager can find the sale in the journal search instead), refund
to card via terminal (needs G23 real payment plugins — until then "card"
refunds record the method, the merchant actions it on their standalone
terminal).

## Verification

Unit: remaining-quantity math incl. second-refund rejection; barcode byte
sequence. E2E: sale → scan its receipt number → refund page → partial
refund line 1 → stock back, refund receipt printed with barcode + original
reference → second full refund attempt of the same line rejected →
journal shows both sides linked.
