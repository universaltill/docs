# Review — inclusive-tax line totals fix (money correctness)

Date: 2026-07-14 · Repo: universal-till. Bug discovered during the P0.1
receipt-printing E2E (printed lines disagreed with the printed TOTAL);
prioritised ahead of P0.3 because it touches the books.

## The bug

`pos.CompleteSale` computed every line's `total_after_tax` as
`net + tax` **unconditionally** (`internal/pos/sales.go`). Correct for
tax-exclusive pricing; wrong under tax-INCLUSIVE pricing (the wizard's
default for GB/IR shops), where the ticket price already contains the tax:

- line `total_after_tax` was inflated by the tax amount (120 → 140),
  disagreeing with the sale header (which was correct: total 120);
- `total_before_tax` held the gross instead of the net;
- **downstream**: `TopItems` revenue (Reports page + ask-your-till tool)
  summed the inflated column — overstating revenue by the tax rate for
  inclusive shops; journal detail and printed receipts showed lines that
  didn't add up to their own total.

The existing test (`TestCompleteSale_InclusiveTaxNoDoubleCount`) checked
only the sale header, never the lines — which is exactly where it hid.

## The fix

- Engine: under `TaxInclusive`, `total_after_tax = lineNet` (the ticket
  price) and `total_before_tax = lineNet − lineTax`. Exclusive unchanged.
- **Migration 012** repairs historical rows. Inclusive sales are
  identified by their header signature `total = subtotal − discount_total`
  (an exclusive sale with tax adds tax_total on top, so it can't match;
  zero-tax sales match but the update is a no-op for them). Repair:
  `after = old before (gross)`, `before = gross − tax_amount`.

## Verification

- Extended the inclusive test to assert line totals; new exclusive-lines
  regression test. Full `go test ./...` + guards green.
- Live: ran the new binary against a copy of the E2E DB carrying 5 bad
  rows — migration repaired all (235 = 120+115 etc.); the consistency
  query `header total == Σ line total_after_tax` returns zero violations;
  a fresh inclusive sale writes 100/120/20 (before/after/tax) correctly.
- Farshid's dev DB self-repairs via migration 012 on next start.
