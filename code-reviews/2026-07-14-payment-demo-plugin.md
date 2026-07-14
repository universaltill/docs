# Review — ut-plugin-payment-demo v1.0.0 (P1.1 / G23a, fake-card terminal)

Date: 2026-07-14 · Repo: **ut-plugin-payment-demo** (new, ADR-0009
one-repo-per-plugin) · Spec: `architecture/integration-plugin-families.md`
§G23. Farshid: "payment should have some fake cards to test."

## What shipped

- `canonical_type: payment`, `runtime: wasm` — installing adds a **Demo
  Card** tender button; settling publishes `payment.demo.requested`,
  handled in-process by `bin/plugin.wasm` (plain Go wasip1).
- **Deterministic test cards**, encoded in the pence amount (no card-entry
  UI exists; same idea as Stripe's magic amounts): `.13` → DECLINED
  (handler exits non-zero → audited failure), `.99` → TIMEOUT (sleeps past
  the 2s event deadline — the dead-reader path), else → APPROVED with a
  fake `DEMO-xxxxxx` auth code.
- **First marketplace plugin using the WASM host functions**: declares the
  `storage` permission and records every outcome (`txn:<sale_id>` +
  `last_txn`) via `ut.storage_set`; progress logged via `ut.log_write`.
- Standard pipeline: build → validate → package → publish →
  (dev) auto-approve; listing `7db13252-11cd-4494-a049-dd5ecc70b177`,
  `MARKETPLACE_LISTING_ID` + `AUTO_APPROVE` repo vars, secrets from
  kv-unitill-dev. Release v1.0.0 green first run.

## Honest scope note

Payment plugins today are **post-tender event handlers** (the qrpay
model): the sale completes, then the plugin runs. A real terminal needs
authorize-*before*-complete — that's the payment-engine work the first
real terminal plugin (SumUp/Stripe) will force; this plugin fixes the
manifest/event/permission shape it will reuse. Checkout latency stayed
0s even with the "dead terminal", which is the offline-first posture.

## Verification (full live path)

Pipeline green → catalog listing approved+signed → POS one-click install
from the live dev marketplace ("installed Demo Card Terminal v1.0.0",
signature verified, 3 permissions granted) → three tenders on the till:
- amount 120 → **approved**, auth code `DEMO-000120` in plugin storage;
- amount 513 → **declined**, outcome recorded, handler failure audited;
- amount 599 → **timeout**: module killed at the deadline
  (`module closed with exit_code(1)` in the POS log), tender returned in
  0s, dispatch audited.
Sample roster: payment now has demo (wasm+host-fns) alongside qrpay.
