# Monetization — cloud registration & paid online services (proposal)

Status: **proposal — awaiting Farshid's direction** (ADR-0007 document-first).
Task from 2026-07-13: "pos (store or multi store) can register to the cloud
services and start using the online services such as some special plugins or
ai — find what can I force to the online to push them to a paid version."

## The honest-gating principle (what we can and cannot lock)

The POS core is **MIT and offline-first** — "free forever" is the README's
promise and ADR-0003 makes checkout un-gateable by design. Two consequences:

1. **Client-side locks are worthless.** Anyone can fork the code and delete a
   feature flag. The only enforceable gate is a **service that runs on our
   side**: if the value comes from our server, the fork gets nothing.
2. **The right things to sell are the things that cost us money to run.**
   Sync backends, storage, hosted models, integrations, distribution. That's
   also the version of monetization that doesn't poison the open-source well.

So the strategy: never cripple the local product; make the **connected**
experience the paid one. A single offline till stays fully free — that's the
funnel, not the product.

## Registration = the merchant account we already have

The marketplace already has the account machinery: `MerchantOrganization`,
store/device identity (`UT_MARKETPLACE_CLIENT_ID`/`STORE_ID`/`DEVICE_ID`),
**entitlements** (approve/revoke, fail-closed checks), and per-merchant
**portal tokens** (docs: architecture/marketplace-merchant-auth.md). A
"subscription" is just an entitlement with a billing state attached:

```
Store registers (portal sign-up)         → MerchantOrganization
Subscribes to a tier / buys a plugin     → Entitlement (kind: service|plugin)
Till calls an online service             → bearer portal token → entitlement
                                           check server-side → serve or 402
```

New build needed: self-serve merchant sign-up (portal), a `service`
entitlement kind with period/expiry, and a billing hook (Stripe checkout +
webhook → entitlement state). Everything else — auth, revocation, fail-closed
enforcement — exists and is deployed.

## What to gate online (candidate paid services, ranked)

| # | Service | Why it's naturally online (honest gate) | Tier fit |
|---|---------|------------------------------------------|----------|
| 1 | **Multi-device / multi-store sync** | Two tills sharing one catalog/stock/journal need a sync backend someone must run. THE structural gate — the moment a shop grows past one till, free-local stops being enough. Back-office (roadmap #2) and HQ (roadmap #3) apps ride on the same backend. | Starter (≤3 devices) / Pro (unlimited) / Enterprise (multi-store + HQ) |
| 2 | **Cloud backup & restore** | Off-site storage costs us money; a shop's sales DB is priceless to them. Automated nightly backup + one-click restore + retention tiers (30 days / unlimited). Cheapest to build (the till already has export). | Starter+ |
| 3 | **Paid & "special" plugins** | Marketplace distribution, signing, review and entitlements are our service. Free plugins stay free; premium plugins (advanced reporting, verticals like appointments, delivery/accounting integrations) are paid listings — 20% commission funds the platform, or first-party plugins priced directly. | à la carte + bundled into tiers |
| 4 | **Hosted AI** | Per [[ai-self-hosted-only]]: shops with their own hardware run Ollama free, forever. But most small shops have no GPU box — offer **unitill-hosted open models** (our Ollama/vLLM on Azure/homelab) as a convenience: same `UT_AI_ENDPOINT` contract, we run the box. We pay for compute → honest subscription. Camera identify, ask-your-till, nightly insights all ride on it. | Pro |
| 5 | **Integrations that need a stable public endpoint** | Delivery (Uber Eats), e-commerce (Shopify/eBay), accounting sync (QuickBooks/Xero) need webhooks/relays with public URLs and uptime — a till behind shop NAT can't do that alone. The relay is the service. Detailed happy-to-pay design below. | Pro / per-integration plugin |
| 6 | **Fleet / remote management** | Multi-till or multi-store owners: remote monitoring (till up? drawer variance? sync lag?), config push, staged plugin/update rollout. Pure server-side dashboard. | Pro / Enterprise |
| 7 | **Cross-store analytics & AI insights** | Single-store reports stay local & free (already shipped). Consolidated multi-store dashboards, trends, forecasts — computed on the sync backend where the data already is. | Enterprise |
| 8 | **Customer-cloud features** | E-receipts, cross-store loyalty, online ordering — inherently multi-party online services. Later; each could be a paid plugin. | Later |
| 9 | **Priority support / SLA** | Classic OSS tier. | All paid tiers |

Recommended build order: **2 (backup — smallest, immediate value) → 1 (sync —
the structural product) → 4 (hosted AI — reuses the provider work just
shipped) → 3 expansion (premium plugin catalog)**; 5–9 follow demand.

## The delivery-integration subscription — designed to be *happily* paid

Farshid (2026-07-14): "if a store wants plugins like Uber Eats or Deliveroo we
should force them to connect to the server and pay a subscription, but cheap…
find a scenario that pushes them to pay but they should be really happy to pay."

The gate is already honest — Uber Eats/Deliveroo integration is **physically
impossible without our server**: the platforms deliver orders by webhook to a
stable public HTTPS endpoint with managed API credentials; a till behind shop
NAT cannot receive them. Nothing is artificially locked; the relay IS the
product. What makes the shop *happy* to pay:

1. **The pain it kills is visceral and daily: "tablet hell."** Without it, a
   shop runs one tablet per platform and re-types every order into the till —
   slow, error-prone, and mis-keyed orders become refunds. With it, orders
   from every platform land directly on the till/KDS, and the menu is synced
   FROM the till's catalog (edit once, updates everywhere). This is exactly
   what Deliverect/Otter sell to enterprises at custom "contact sales"
   pricing; we sell it to small shops at a flat cheap rate.
2. **Anchor the price against what they already pay the platforms.** A shop
   doing £2,000/month through Uber Eats pays ~£500-600 in commission without
   blinking. **£9.99/store/month for ALL delivery platforms bundled** is
   ~0.5% of that — one prevented mis-keyed order (one refund avoided) pays
   for the month. Cheap enough that churn-from-price is near zero, and
   thousands of stores × £10 with near-zero marginal relay cost keeps us far
   from bankruptcy (the relay is stateless webhook forwarding + menu sync;
   one small app instance serves thousands of shops).
3. **The killer value-add only a server can do: availability sync.** Item
   86'd on the till → instantly marked unavailable on every delivery
   platform. That kills the "customer ordered, kitchen is out, platform
   issues refund and penalises the restaurant" cycle — a direct,
   quantifiable saving that shops feel weekly.
4. **A payout reconciliation report** (what the platforms owe vs what the
   till recorded) — a monthly headache turned into one page.
5. **First 50 orders free, no card up front.** The shop experiences the
   relief before paying; costs us pennies.
6. **Fail kind, never hostage.** Subscription lapses → orders keep arriving
   read-only for a 7-day grace with a banner, menu sync pauses. No data held,
   no checkout impact (ADR-0003), cancel monthly. Trust is the moat — we are
   the anti-Toast.

The same template (impossible-without-server + anchored-cheap + one
quantifiable saving + free trial + kind failure) applies to the e-commerce
and accounting relays. Rule of thumb: **charge for connections to the outside
world, never for the till itself.**

## What we deliberately do NOT gate

- Checkout, receipts, catalog, inventory, reports on one till — free forever.
- Locally-installed free plugins and language packs.
- Self-hosted AI via `UT_AI_ENDPOINT` — a shop that runs its own model owes
  us nothing (this credibility is worth more than the lost pennies).
- Data export — no lock-in is a selling point; backup convenience is the
  product, not data hostage-taking.

## Pricing sketch (matches the README table, to be validated)

- **Free (Local):** everything single-till, unlimited devices offline, community support.
- **Cloud Starter (~£5–10/store/mo):** sync ≤3 devices, 30-day backup, e-receipts.
- **Cloud Pro (~£15–25/store/mo):** unlimited devices, unlimited backup, hosted AI,
  fleet dashboard, integration relays.
- **Enterprise (custom):** multi-store HQ, cross-store analytics, SLA.

## Decisions needed from Farshid

1. Confirm the honest-gating principle (sell services, never cripple local).
2. Which first: backup, sync, or hosted AI?
3. Billing rail (Stripe is the default assumption) and price points.
4. Where cloud services run — the homelab is fine for dev, but paid customer
   data needs the Azure side (or another provider) with real SLAs/backups.
