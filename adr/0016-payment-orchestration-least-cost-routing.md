# ADR-0016: Payment orchestration and least-cost routing

- **Status:** Proposed (2026-07-17) — needs Farshid's build-vs-buy + first-two-provider decision before we build.
- **Relates to:** ADR-0002 (plugin taxonomy — `payment` type), ADR-0006 (plugin
  trust chain), ADR-0013 (store tiers / paid cloud), ADR-0003 (offline-first).

## Context

Universal Till already has a Stripe payment plugin (online charges + Stripe
Terminal card-present). Farshid wants more: a device/layer that sends **each
payment to the cheapest eligible provider** (Stripe, Adyen, a local bank, …)
with automatic failover — **without Universal Till becoming a payment provider
or ever holding the shop's money**.

Two things must be separated, because they have completely different difficulty:

1. **The routing logic** — choosing the cheapest provider per transaction.
2. **The physical device** — how a card is captured for card-present sales.

### The device question, answered honestly

A card reader is **not** a dumb peripheral like a barcode scanner. It is a
certified secure device (PCI PTS) whose entire job is to **encrypt the card's
secret data inside itself, for one specific acquirer/gateway**, so that data
**never reaches the POS in the clear** (this is deliberate — it keeps the POS
out of PCI scope). Consequences that decide the architecture:

- You **cannot** have a generic cheap reader where the POS reads the card and
  freely forwards it to "whichever provider is cheapest." The encrypted blob a
  reader produces can only be decrypted by the acquirer whose keys are injected
  in it. A Stripe reader's output is meaningless to Adyen.
- Therefore, for **card-present**, routing among acquirers happens **either**
  (a) at the **gateway the certified terminal is bound to** (server-side, one
  terminal → one gateway → many acquirer connections), **or** (b) on a
  **SmartPOS terminal that is itself certified against multiple acquirers**.
  Each acquirer a device can reach is a **certification project**.
- For **online / card-not-present**, none of this applies — the token/PAN
  arrives in software and can be routed freely. This is why online LCR is easy
  and card-present LCR is hard.

### How the router knows the card without seeing the secret data

Routing needs the card's **metadata**, not its secret. When a card is read, the
certified reader exposes to the POS/SDK **non-sensitive** fields — **scheme**
(Visa/MC/Amex), **funding type** (debit/credit/prepaid), the **BIN** (first
6–8 digits), **issuing country**, and **last 4** — while withholding the full
PAN, expiry, CVV and chip cryptogram. The **BIN** is an industry-standard
lookup (scheme, type, bank, country); it is not the sensitive secret and is
used everywhere for routing/fraud. On EMV chip/contactless the card also
announces its supported networks via **application selection (AIDs)** — a debit
card commonly carries two networks, and picking the cheaper is least-cost
routing native to the EMV standard.

So the routing decision (BIN → scheme/type/region → cost table → cheapest
acquirer) uses only non-sensitive data. The **sealed** transaction is then sent
to the chosen acquirer for authorization — and *that* step is what requires the
device/gateway to be certified/connected to that acquirer (the cost). Hence the
two clean card-present forms: **debit dual-network selection** (card carries
both, terminal picks cheaper) and **gateway-orchestrated** routing.

## Decision

### 1. We are an orchestrator/ISV, never an acquirer or PayFac
Money flows shop → acquirer → bank. Universal Till **never touches funds**,
which keeps us out of acquiring-licence / money-transmission regulation. We
route; we do not settle.

### 2. Routing lives server-side, as a cloud service; providers are plugins
- Each PSP / bank / acquirer is a **`payment` plugin** implementing one common
  **`PaymentProvider` interface** (`authorize`, `capture`, `refund`, `status`,
  `supports(card, region)`, `quoteCost(...)`). The existing Stripe plugin is the
  first implementation.
- A **routing engine** (cloud) selects the provider per transaction from the
  card BIN → scheme / type / region and a **cost-rules table**, with **failover**
  and success-rate awareness. It is part of the paid cloud tier (ADR-0013:
  honest gating — the server genuinely provides the multi-acquirer connections).

### 2a. Two orchestration modes — automatic and manual (Farshid, 2026-07-17)
A merchant reaches "route to the cheapest provider" one of two ways, and the POS
supports both because both are just `payment` plugins with buttons:

- **Automatic** — on a **multi-acquirer device** (SmartPOS/gateway), the device
  reads the card and the routing engine picks the cheapest acquirer with no
  cashier action. Needs per-acquirer certification (the heavier, later path).
- **Manual / assisted** — the merchant has **several ordinary provider-locked
  readers** (Stripe Terminal + SumUp + a bank terminal). The POS shows a **button
  per provider**; the cashier taps the right one and the POS sends the sale to
  that device's plugin. **Each reader is already certified by its own provider,
  so this needs NO new certification from us** — it works today with cheap
  off-the-shelf hardware. Nuance: with locked readers the button is pressed
  *before* the card is read, so selection is the cashier's (the POS can't
  auto-detect the card first); the POS **assists** by showing per-provider cost
  guidance (e.g. "cheapest for debit: SumUp") and a merchant-set default.

Both modes are the same plugin model — the difference is whether the *device* or
the *cashier* chooses the provider. Manual mode ships early (Phase 2); automatic
mode is Phase 3.

### 2b. Product posture: meet the merchant's existing hardware (Farshid, 2026-07-17)

We support **all** of the above at once, per shop — the POS adapts to whatever
payment hardware the merchant already owns rather than forcing a purchase:

| The shop has… | Behaviour | Mode |
|---|---|---|
| A terminal bound to a **routing gateway / orchestration service** | Route **automatically at the gateway** (its rules pick the acquirer) | automatic (server-side) |
| An **open SmartPOS** (PAX/Sunmi class) | Our payment app on the device routes **automatically on-device** (needs Phase-E certs) | automatic (device-side) |
| One or more **normal provider-locked readers** (Stripe, SumUp, bank box) | **Button per provider** on the POS; cashier picks, cost hint guides | manual / assisted |

Selection is **per-shop configuration**, not auto-detection: the merchant or
installer enables the matching `payment` plugins and declares which devices
exist (the existing plugin-settings flow, incl. per-till `register` scope for
reader ids). A shop can mix modes — e.g. a gateway terminal on lane 1 and a
SumUp on lane 2 — because every route is just an enabled payment plugin.

### 3. Device support, phased (this is the answer to "buy hardware per provider?")
- **Phase 1 — online / card-not-present.** Orchestrate e-commerce & pay-by-link
  in pure software. No hardware. Prove routing + failover with a second PSP
  alongside Stripe.
- **Phase 2 — card-present, provider-locked readers + manual selection.** The
  merchant connects one or more providers' own certified readers (Stripe Terminal,
  SumUp, a bank terminal); the POS shows a **button per provider** and the cashier
  picks (mode 2a "manual"). No new certification — the readers are already
  certified by their providers. This is the **early, cheap, ships-now** form of
  least-cost routing across multiple providers.
- **Phase 3 — card-present with LCR.** Either a **certified SmartPOS**
  (PAX/Ingenico/Castles) running the UT payment app that talks to our
  orchestration API and is certified against multiple acquirers, **or** terminals
  bound to a **single orchestration gateway** that routes server-side across many
  acquirers. **Tap-to-Pay on a phone (PCI MPoC)** is the no-hardware low end.
  In all three the card data is encrypted in the device for its bound
  gateway/acquirers — never handled by the POS.

**So: the shop does _not_ need a separate reader per provider _if_ we use a
multi-acquirer SmartPOS or a routing gateway. It _does_ if we stay on
provider-locked readers (Phase 2). What is impossible is a generic cheap reader
that the POS forwards to any provider — that is not how card-present works.**

### 4. Build vs buy the multi-acquirer connections
Build the router ourselves for online (Phase 1). For the multi-acquirer/terminal
side, evaluate sitting on an existing orchestration platform (Spreedly, Primer,
Gr4vy, ProcessOut/Checkout.com) versus our own acquirer integrations. Decide
before Phase 3.

### 5. Sovereign / Iran
International schemes (Visa/Mastercard/EMVCo) are unavailable there; the domestic
**Shetab/Shaparak** network is a **separate provider plugin on a separate
certification track**. The plugin model accommodates it without special-casing.

## Consequences

- **Fits the architecture:** `payment`-type plugins (ADR-0002), signed &
  verified (ADR-0006), orchestration as a paid cloud feature (ADR-0013).
- **Offline-first preserved (ADR-0003):** orchestration is a network operation;
  the offline sale path (cash, queued/again-later card) is untouched, and
  card-present already requires connectivity.
- **New pieces:** the common `PaymentProvider` plugin interface, the cloud
  routing engine, and a cost-rules configuration surface (per shop).
- **Cost reality:** online orchestration is cheap; card-present certification
  cost **scales per acquirer**. Savings for the shop come from acquirer-markup
  differences, debit-network selection (LCR), and local-vs-cross-border routing
  — **interchange itself is fixed** and cannot be undercut.
- **Compliance & commercial:** PCI DSS applies to the routing layer (minimize
  scope via tokenization / network tokens / P2PE); watch PSP **"no-steering"**
  contract clauses; each acquirer needs an **ISV/integration agreement**.
- **We never hold funds**, so we avoid the heaviest licensing — the deliberate
  boundary of this decision.

## Open questions (to resolve before building)
1. Build the router vs adopt an orchestration platform for multi-acquirer.
2. First two providers to route between (Stripe + Adyen? Stripe + a local bank?).
3. ~~Target markets first~~ — **CHOSEN (Farshid, 2026-07-17): UK, UAE, Qatar,
   Bahrain, Oman, Turkey.** Grouped as UK (open) → GCC cluster (one aggregator)
   → Turkey (fiscal-POS track). Detail + per-market schemes/acquirers/regulators
   in [payment-markets-launch-set.md](../architecture/payment-markets-launch-set.md).
