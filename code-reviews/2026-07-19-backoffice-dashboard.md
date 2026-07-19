# Review: back-office dashboard home (2b remaining item)

**Date:** 2026-07-19 · **Repo:** `universal-till` (feat/backoffice-dashboard)
**Queue item:** 2b back-office mode "REMAINING: richer back-office home
(dashboard instead of plain reports)".

## What changed

New `/backoffice` manager dashboard; `display.mode=backoffice` devices now
land there from "/" (was a bare redirect to /reports). Glance surface only —
heavy analysis stays on /reports:

- KPI cards: today / yesterday / last-7-days revenue + sale counts
  (`POSRepo.DayTotal`, `SalesByDay` — all pre-existing repo methods, no new
  SQL beyond what the repo already had).
- **Low stock** table (top 8 below reorder level, `GetLowStockItems`) with a
  calm all-good state.
- **Recent problems** (top 5 from the same `logging.Recent()` ring that feeds
  the cloud digest) — the manager sees on-device what the cloud sees remotely.
- "Go deeper" links: Reports / Inventory / Settings.
- Server-rendered template per ADR-0008, `money` helper for currency, logical
  CSS only (RTL-safe), i18n ×4 locales (15 keys, guard green).

## Risk review

- Read-only page; no new endpoints beyond the GET. Reachable on any till (not
  just back-office mode) — same posture as /reports, which is not
  manager-gated either; nothing here is more sensitive than /reports.
- Existing behaviour test updated: "/" in backoffice mode now 303s to
  /backoffice (and back to the sale screen in register mode), plus a
  rendered-page assertion on the dashboard's sections.

## Tests

- `TestBackofficeModeRedirectsHome` extended (redirect target + rendered
  dashboard sections). Full till suite, data-access guard, i18n guard green
  (681 keys, 4 locales in sync).
