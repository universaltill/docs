# Payment orchestration — launch markets (companion to ADR-0016)

Status: **launch set chosen by Farshid, 2026-07-17.** Reference/decision-support
for [ADR-0016](../adr/0016-payment-orchestration-least-cost-routing.md). Coverage,
licences and partnerships change — **verify current status with each partner
before committing**; this is the strategic shape, not a contract.

## The chosen markets

**Turkey · United Kingdom · UAE · Qatar · Bahrain · Oman.**

They fall into three groups by how much work each is:

| Group | Markets | Character |
|---|---|---|
| **A. Open market** | UK | Open acquirers + orchestrators, Tap-to-Pay, no domestic-scheme lock, no fiscal-device mandate. **Easiest — start here.** |
| **B. GCC cluster** | UAE, Qatar, Bahrain, Oman | Each has a domestic debit switch + Visa/MC; central-bank approval required; **one regional aggregator lights up several at once.** Arabic/RTL already supported in the till. |
| **C. Fiscal-regulated** | Turkey | Visa/MC + domestic **Troy**; **mandatory fiscal-POS (ÖKC/GİB) integration** — the biggest structural constraint of the six. |

## Per-market detail

### 🇬🇧 UK — the beachhead
- **Schemes:** Visa, Mastercard, Amex.
- **Acquirers:** Worldpay, Barclaycard, Adyen, Stripe, Checkout.com, Global
  Payments, Dojo, Teya.
- **Orchestrators:** Spreedly, Primer, Gr4vy, ProcessOut.
- **Regulator:** FCA; PSD2/SCA-equivalent.
- **Hardware:** PAX / Sunmi; **Tap-to-Pay on iPhone & Android** available (skip
  hardware certification entirely at first).
- **Gotcha:** none major. This is where we prove the whole model.

### 🇦🇪 UAE — the GCC beachhead
- **Schemes:** Visa, Mastercard + **JAYWAN** (new national scheme, Al Etihad
  Payments).
- **Acquirers/processors:** **Network International** (dominant), Magnati,
  Checkout.com, Telr, PayTabs, Amazon Payment Services.
- **Regulator:** Central Bank of UAE — PSP approval / local partnership needed.
- **Note:** most developed GCC payment infrastructure → do GCC here first.

### 🇶🇦 Qatar
- **Schemes:** Visa, Mastercard + **NAPS/QATCH** (QCB domestic switch).
- **Processors/fintech:** QNB, Commercial Bank, QPAY, Skipcash, Dibsy.
- **Regulator:** Qatar Central Bank — strict; foreign PSPs need QCB approval /
  local partner.

### 🇧🇭 Bahrain
- **Schemes:** Visa, Mastercard + **Benefit** (domestic debit + BenefitPay).
- **Acquirers:** Credimax (BBK), Eazy Financial Services, Benefit.
- **Regulator:** Central Bank of Bahrain — **progressive, has a regulatory
  sandbox + open-banking mandate** (easiest GCC regulator to work with).

### 🇴🇲 Oman
- **Schemes:** Visa, Mastercard + **OmanNet** (CBO domestic switch).
- **Processors/fintech:** Bank Muscat, NBO, **Thawani** (payment gateway).
- **Regulator:** Central Bank of Oman.

### 🇹🇷 Turkey — highest complexity (despite being a first choice)
- **Schemes:** Visa, Mastercard + **Troy** (domestic), BKM interbank.
- **Acquirers/banks:** Garanti BBVA, İşbank, Yapı Kredi, Akbank, QNB Finansbank.
- **Orchestrators/gateways:** **iyzico** (PayU), **Craftgate** (orchestration),
  PayTR, Param, Sipay.
- **Regulator:** BDDK/TCMB.
- **⚠️ Fiscal-POS mandate:** retail POS must integrate with a GİB-certified
  fiscal unit (**ÖKC / "Yeni Nesil"**); devices need fiscal certification
  (Beko, Hugin, Ingenico TR, Verifone, Profilo). This constrains which hardware
  we can ship and adds a certification/partner step the others don't have.
- **Upside:** the till already speaks Turkish; Farshid has ties here.

## Strategy that falls out of this

1. **GCC = one integration, four countries.** Don't integrate four central banks
   separately. Partner with a **regional aggregator that already holds the GCC
   licences + domestic-scheme certs** — candidates: **PayTabs, HyperPay, Amazon
   Payment Services, Network International, Geidea, Telr** (several cover UAE +
   Qatar + Bahrain + Oman). One or two integrations cover Group B.
2. **UK = open acquirers + Tap-to-Pay.** Adyen/Stripe/Checkout for online,
   Tap-to-Pay or PAX/Sunmi for card-present. No aggregator lock-in needed.
3. **Turkey = fiscal-POS partner + local orchestrator** (iyzico/Craftgate). Treat
   it as its own workstream because of the ÖKC requirement.
4. **Hardware:** one/two global SKUs (**PAX / Sunmi**) for UK + GCC; Turkey may
   need a GİB-certified device. Same UT payment app across all, regionally
   certified/configured.

## Suggested sequence (lowest friction → highest)

1. **UK** — prove orchestration + LCR end-to-end (online first, then Tap-to-Pay).
2. **UAE** — GCC beachhead via a regional aggregator; validates Arabic/RTL + a
   domestic scheme (JAYWAN).
3. **Bahrain → Qatar → Oman** — same aggregator where it covers them; add
   per-country central-bank approval + domestic switch (Benefit/NAPS/OmanNet).
4. **Turkey** — in parallel as its own track (fiscal-POS + Troy + iyzico/Craftgate).

## Open items before build (feed ADR-0016)
- Confirm which **regional aggregator** actually covers all four GCC targets +
  their domestic schemes (get current coverage in writing).
- Confirm UK first acquirer(s): Adyen vs Stripe vs Checkout for online; Tap-to-Pay
  enablement partner.
- Turkey: identify a **GİB-certified fiscal-POS** hardware/partner + whether
  iyzico or Craftgate is the routing layer.
- Decide **build our own router vs orchestration platform** (Spreedly/Primer/
  Gr4vy) for the UK/online layer.
