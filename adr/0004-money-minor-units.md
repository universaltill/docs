# 0004 — Money is integer minor units (`money.Money`)

**Status:** accepted (2026-07-07)

## Decision
Monetary amounts use `universal-till internal/money.Money` (distinct int64
type, minor units). Raw int64 only at DB/DTO boundaries via
`money.FromMinor`/`.Minor()`. Rates are basis points (int64, not money).
UI enters pounds; conversion to minor units happens client-side or at the
handler boundary — engine and storage never see floats.
