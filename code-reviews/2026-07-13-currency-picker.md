# Review: currency picker, rial/toman, localized digits (2026-07-13)

Farshid: currency should be selectable in Settings; it's not always a
symbol — Iranian prices write ریال/تومان as a word beside the number; and
"when I change the language it should change the number as well". Plus:
rial and toman have no /100 subunit (1 toman = 10 rials). universal-till
main 734788a.

## Design

- `internal/httpx/currency.go`: a registry of currencies with three
  attributes each — Display (symbol or word), Suffix (display after the
  number in logical order — which is visually LEFT of the digits in RTL,
  exactly how rial/toman are written), Decimals (minor-unit exponent:
  GBP=2, IRR/IRT/IQD/AFN/JPY=0). 13 currencies seeded; unknown codes fall
  back to `CODE 1.23`.
- `FormatMoney(minor, locale)`: decimals + placement from the currency,
  thousands grouping, and digit localization from the locale (fa/ur/ps →
  Persian numerals, ar → Arabic-Indic, incl. ٬/٫ separators). The `money`
  template func is now locale-bound in FuncsFor.
- Settings gains a Currency card (picker from the registry) posting to the
  existing /api/settings/save; explicit warning that switching NEVER
  converts stored amounts (minor units stay as entered).
- Client side: `<body data-currency-*>` carries code/decimals/display/
  suffix; `window.utCurrency` centralizes toMinor/toMajor/format and
  replaced 4 hardcoded ×100 / /100 sites (line qty/discount, tender
  formatter, fill-remaining, catalog price form). Money inputs derive
  step/placeholder from decimals (step=1 for toman). The basket total
  carries `data-minor` so tender JS reads raw minor units instead of
  parsing rendered text — which would have broken under Persian digits.

## Verified live

Picker lists rial/toman; GBP basket `£1.20`; switch to IRT → scan renders
`۱۲۰ تومان` under fa (word after number, Persian digits, no decimals) and
`120 تومان` under en; body metadata `data-currency="IRT"
data-currency-decimals="0"`. Unit tests pin GBP/IRR/IRT/JPY/unknown-code
formatting and fa/ar digit mapping. Full suite + both guards green (one
stale httpx test updated — it asserted Latin digits for a fa locale, which
is precisely the bug being fixed).

## Notes / follow-ups

- Switching currency rebuilds the sale engine (existing /api/settings/save
  behaviour), which clears an open basket — acceptable for a settings-page
  action.
- Shifts page £ inputs and a few "£" label texts (inventory cost) still say
  pounds; cosmetic, keyed for later.
- Qty numbers outside money strings stay Latin for now; money amounts are
  the localized ones.
