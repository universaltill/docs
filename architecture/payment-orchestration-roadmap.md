# Payment orchestration — implementation roadmap

Status: **plan, 2026-07-17.** Turns [ADR-0016](../adr/0016-payment-orchestration-least-cost-routing.md)
+ [launch-markets](payment-markets-launch-set.md) into phased, buildable work.
Sequenced lowest-friction → highest. Phases D→F can overlap; G (markets) and
H (compliance) run in parallel once B lands.

**Recap of the decided strategy:** we are an **orchestrator, never a payment
provider** (never hold funds). Each provider = a `payment` plugin behind one
interface; the POS shows a **button per provider**. Two modes: **manual**
(cashier picks among provider-locked readers — no new certification, ships now)
and **automatic** (a multi-acquirer device/gateway picks the cheapest — later,
certification-heavy). Launch markets: **UK → GCC (UAE, Bahrain, Qatar, Oman) →
Turkey**.

---

## Phase A — Decisions & agreements _(blockers; no code)_

- **A1** Routing-engine plumbing: write our own provider connections, or rent an
  **orchestration service** (Spreedly / Primer / Gr4vy / ProcessOut — software
  APIs, **not devices**: they maintain ready-made connections to dozens of PSPs
  behind one API). Our orchestrator — the plugins, the POS buttons, the cost
  rules, the routing decisions — is ours **in both cases**; this decides only
  whether its provider plumbing is hand-built or leased. Scope: affects Phase D
  (online automatic routing) onward; Phase C manual mode needs neither.
- **A2** First two providers to route between (e.g. Stripe + SumUp for
  card-present manual; Stripe + Adyen/Checkout for online).
- **A3** GCC regional aggregator that covers UAE+Bahrain+Qatar+Oman + their
  domestic schemes — get current coverage **in writing** (PayTabs / HyperPay /
  Network International / Amazon Payment Services candidates).
- **A4** Turkey: a **GİB-certified fiscal-POS** hardware/partner + iyzico vs
  Craftgate as the routing layer.
- **A5** Commercial: ISV/integration agreements per acquirer; **review PSP
  "no-steering" clauses** before assuming we can route volume away.
- **A6** PCI scope strategy: tokenization / network tokens / P2PE approach that
  keeps our routing layer out of heavy PCI scope.

## Phase B — Foundation _(provider-agnostic; enables everything)_

- **B1** Define the common **`PaymentProvider` plugin interface**
  (`authorize`, `capture`, `refund`, `status`, `supports(card,region)`,
  `quoteCost(...)`), an ADR-0002 `payment`-type contract.
- **B2** Refactor the **existing Stripe plugin** onto that interface (proves the
  contract against real code).
- **B3** POS **payment screen: one button per enabled provider** (method
  selection). Extends the current tender UI; foundation for both modes.
- **B4** **Cost-rules config** per shop (which provider is cheaper for which
  card type/scheme/region) + a place to store it; drives both the manual "cost
  hint" and the automatic router.
- **B5** Keep the **offline-first sale path intact** (ADR-0003): orchestration
  is a network step; cash + queued-card flows unchanged.

## Phase C — Manual multi-provider _(ships now; UK; NO new certification)_

Works today with providers' own already-certified readers (Stripe Terminal,
SumUp, a bank terminal). Highest value-for-effort — a physical shop gets
multi-provider "pick the cheaper" immediately.

- **C1** Add a **second provider plugin** (per A2) so there are ≥2 buttons.
- **C2** **Manual selection UX**: cashier taps the provider; **merchant default**
  + **per-provider cost hint** ("cheapest for debit: SumUp") shown on the screen.
- **C3** Route the sale to the chosen device's plugin; record which provider was
  used on the sale/journal/receipt.
- **C4** **UK pilot** on real hardware (Farshid's shop) with two providers.

## Phase D — Online / card-not-present automatic routing _(UK; pure software)_

First proof of the **automatic** router (the ADR's "prove routing online first").

- **D1** **BIN → scheme/type/region** detection for CNP inputs.
- **D2** **Routing engine**: pick cheapest eligible provider from the cost table,
  with **failover** and **success-rate** awareness (build per A1, or wire the
  chosen orchestration platform).
- **D3** Second **online acquirer** integration (Adyen/Checkout) as a plugin.
- **D4** Pay-by-link / e-commerce surface uses the router.

## Phase E — Card-present automatic LCR _(later; certification-heavy)_

- **E1** Target device: **certified SmartPOS** (PAX/Sunmi) app **or** terminals
  bound to a routing **gateway** (decide with A1/A3).
- **E2** **Per-acquirer certification** (EMV L3 + scheme + host) — one acquirer
  first, then add.
- **E3** **Debit dual-network selection** (standards-native LCR) where cards
  carry two networks.
- **E4** **Tap-to-Pay (PCI MPoC)** as the no-hardware option.
- **E5** **Key injection / estate management** (PAXSTORE or KIF/RKI).

## Phase F — Market rollout _(parallel workstreams once C/D prove out)_

- **F1 UK** — done via C/D (beachhead).
- **F2 UAE** — GCC beachhead via the A3 aggregator; validates Arabic/RTL + a
  domestic scheme (JAYWAN).
- **F3 Bahrain → Qatar → Oman** — same aggregator where it covers them; add each
  central-bank approval + domestic switch (Benefit / NAPS / OmanNet).
- **F4 Turkey** — own track: fiscal-POS (ÖKC/GİB) + Troy + iyzico/Craftgate.

## Phase G — Cross-cutting / compliance _(ongoing)_

- **G1** PCI DSS on the routing layer (minimize via B/A6).
- **G2** Cost-rules **maintenance** (interchange/markup data per market).
- **G3** Per-market **acquirer/aggregator agreements** + central-bank approvals.
- **G4** **Iran / Shetab-Shaparak** as a fully separate future track (sanctions).

---

## Milestone view

1. **M1 — Decisions locked** (Phase A): router build-vs-buy, first two providers,
   GCC aggregator, Turkey partner.
2. **M2 — Foundation + manual mode live in the UK** (B + C): a shop can run two
   providers and pick the cheaper. *No certification, near-term.*
3. **M3 — Automatic online routing** (D): the router proves itself on CNP.
4. **M4 — Card-present automatic LCR** (E) on a certified device.
5. **M5 — Market expansion** (F): UAE → BH/QA/OM → Turkey.

## Notes
- **M2 is the near-term deliverable** and is largely independent of the cloud
  sync tier (manual selection is local; cost hints are config).
- Automatic routing (D onward) is where the paid cloud tier / orchestration
  platform matters (ADR-0013 honest gating).
- Do **not** start Turkey (fiscal-POS) or GCC per-country CB approvals before the
  UK model works — sequence, don't parallelize prematurely.
