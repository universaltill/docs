# ADR-0014: ERP / external-system integration via connector plugins

- **Status:** Accepted (Farshid, 2026-07-16)
- **Relates to:** ADR-0001 (plugin runtime — WASM in-process, processes for
  hardware), ADR-0002 (20-type taxonomy — `integration`/`import`/`export`),
  ADR-0006 (plugin trust chain / sandbox = storage·http·log), ADR-0003
  (offline-first), ADR-0013 (plugin access tiers / monetization).

## Context

Enterprise prospects (e.g. Ansar Group, running LS Central on Microsoft
Dynamics, plus SAP) will not replace their ERP/merchandising core. To land them
we must **complement** that core: the till runs checkout on the edge and
**feeds sales and stock back** into the customer's system of record, and pulls
catalog/price down from it. The same must hold for the next enterprise
customer with a different ERP.

Two hard constraints:

- **Reusable, not bespoke.** Integrations must be **configurable plugins any
  customer installs**, not per-customer forks. One SAP connector, one
  Dynamics/LS connector, one generic webhook connector — each configured per
  install (endpoint, credentials, field mapping) via plugin settings.
- **Offline-first is sacred (ADR-0003).** Checkout must never wait on, or fail
  because of, an ERP. Integration is asynchronous and best-effort from the
  till's point of view.

The plugin platform already has the pieces: an event bus with a
non-blocking `sale.completed` event, the `plugin_hooks` table, plugin outbound
HTTPS gated by `net:<host>` (ADR-0006), a generic per-plugin **settings editor**,
and the `integration` plugin type. The gap: the POS **never published
`sale.completed`**, so no connector could exist.

## Decision

### Outbound (till → ERP): the `sale.completed` seam

On every completed sale the POS publishes **`sale.completed`** on the plugin
event bus (non-blocking), carrying a **stable, versioned payload** — the
`SaleCompletedEvent` contract: sale id, receipt number, type, currency,
subtotal/discount/tax/total (integer minor units), customer/register/cashier,
**line items** (item id, variant, SKU, name, decimal quantity, unit price,
discount, tax rate + amount, line total) and **payments** (method, amount,
reference). This is the ERP contract; connectors depend on it, so it evolves
additively.

An **integration connector plugin** subscribes to `sale.completed`, transforms
the payload to the target system's shape (SAP IDoc/BAPI/OData, Dynamics/LS
Business Central OData, or plain JSON), and POSTs it to the endpoint from its
**per-install settings**, authenticated with a `net:<host>` permission. Because
dispatch is non-blocking, a slow/absent/offline ERP never touches the tender.

**Offline durability is the connector's job.** A connector queues undelivered
sales in its own plugin storage (ADR-0006 grants `storage`) and retries with
backoff when connectivity returns — the till keeps selling regardless. Sales
already carry a stable id + receipt number, so redelivery is idempotent.

### Inbound (ERP → till): catalog / price / stock

Reuse the existing **catalog import** seam (`internal/catimport`): a connector
(or a scheduled job plugin) pulls products/prices/stock from the ERP and feeds
them through the same idempotent import path the manual CSV import uses.
Catalog is primary-wins per store (ADR-0011); a connector that owns catalog
sets that expectation in its docs.

### The connector catalog (reusable plugins)

Shipped as normal signed marketplace plugins, `type: integration`:

- **Generic webhook connector** — POSTs `sale.completed` JSON to any URL with a
  configurable auth header. Works today for any middleware; the fastest
  "start now" for a customer with an integration bus.
- **SAP connector** — maps to the customer's SAP interface (IDoc/BAPI via a
  gateway, or S/4HANA OData).
- **Microsoft Dynamics 365 / LS Central connector** — Business Central OData.

Each is one plugin reused across customers; all customer-specific values
(endpoint, credentials, company/store codes, tax/GL mapping) live in **plugin
settings**, never in code.

### Monetization (ADR-0013)

Connectors are **`registered`-tier / paid** listings — the enterprise value
capture. The core POS + event seam stay free/open (anti-lock-in); the
integration + support is where enterprise revenue sits. Pricing for enterprise
accounts is value-based, not the low-end SMB price.

## Consequences

- **Offline-first preserved** — publishing is in-process and non-blocking;
  delivery + retry is the connector's concern.
- **Reusable** — the same connector serves every customer on that ERP;
  onboarding a new enterprise is configuration, not a fork.
- **Anti-lock-in preserved** — the payload is an open, documented contract; a
  customer can write their own connector against it.
- **Contract stability matters** — `SaleCompletedEvent` must evolve additively;
  breaking it breaks every deployed connector.
- **Trust** — connectors make outbound calls with real sales data; they are
  signed, permissioned (`net:<host>`, `storage`), and review-gated (ADR-0006).

## Rollout

1. **Publish `sale.completed`** with the full contract. *(done — this ADR)*
2. **Generic webhook connector** plugin (reference implementation + template).
3. **Stock-movement events** (`stock.adjusted`) for inventory sync.
4. **Inbound catalog/price sync** via the import seam + a scheduled connector.
5. **SAP** and **Dynamics/LS Central** connectors for named accounts.
6. **Delivery hardening** — shared offline-queue + retry helper connectors reuse.
