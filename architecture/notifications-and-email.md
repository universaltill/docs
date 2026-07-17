# Notifications & email (design, 2026-07-18)

Status: **proposal.** Several queued features need to *tell the owner
something* off-till: low-stock/unusual-sales alerts, vendor-registration
decisions, claim confirmations, later e-receipts (shopper platform 3a) and
subscription receipts. Per [[multilingual-everything]]: every message in the
recipient's language.

## Principles
- **Owner alerts originate on the TILL** (it owns the data, offline-first);
  email needs the cloud. So: till computes → pushes an *alert event* to the
  marketplace/cloud when online (best-effort, never blocks anything) → cloud
  delivers email. No SMTP credentials on tills.
- **One delivery service** in the marketplace (it already has Brevo SMTP for
  Zitadel; give the mp its own transactional sender via the same Brevo
  account, key from KV) with: templates per message type × locale
  (en/tr/fa/ar first), per-owner language preference (from their Zitadel
  profile locale, fallback store region), unsubscribe/preferences per
  message category.
- **In-product first**: every email also exists as an in-app notification
  (owner back-office "inbox" card on My shop) — email is the push channel,
  the portal is the record.

## Minimal first increment
1. mp: `notifications` ent entity (owner_subject, type, payload, locale,
   status) + Brevo send worker + templates for TWO types:
   `vendor_request_decision`, `low_stock_digest`.
2. till: daily low-stock digest push `POST /api/v1/stores/notify` (store
   token auth) when running-out count > 0 — reuses the days-left model.
3. My shop: notifications card (list + mark-read).

## Later
E-receipts ride the same pipeline (3a), subscription emails, spike alerts.
