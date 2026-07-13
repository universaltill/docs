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
| 5 | **Integrations that need a stable public endpoint** | Delivery (Uber Eats), e-commerce (Shopify/eBay), accounting sync (QuickBooks/Xero) need webhooks/relays with public URLs and uptime — a till behind shop NAT can't do that alone. The relay is the service. | Pro / per-integration plugin |
| 6 | **Fleet / remote management** | Multi-till or multi-store owners: remote monitoring (till up? drawer variance? sync lag?), config push, staged plugin/update rollout. Pure server-side dashboard. | Pro / Enterprise |
| 7 | **Cross-store analytics & AI insights** | Single-store reports stay local & free (already shipped). Consolidated multi-store dashboards, trends, forecasts — computed on the sync backend where the data already is. | Enterprise |
| 8 | **Customer-cloud features** | E-receipts, cross-store loyalty, online ordering — inherently multi-party online services. Later; each could be a paid plugin. | Later |
| 9 | **Priority support / SLA** | Classic OSS tier. | All paid tiers |

Recommended build order: **2 (backup — smallest, immediate value) → 1 (sync —
the structural product) → 4 (hosted AI — reuses the provider work just
shipped) → 3 expansion (premium plugin catalog)**; 5–9 follow demand.

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
