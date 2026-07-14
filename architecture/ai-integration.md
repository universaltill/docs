# AI in the unitill environment — proposal

Status: **increment 1 (camera identify, §g) SHIPPED 2026-07-13** — universal-till
`internal/ai` + `/api/pos/identify`; review record
`code-reviews/2026-07-13-ai-camera-identify.md`. **Backend is provider-based
and SELF-HOSTED FIRST** (same day, on Farshid's correction — see the
constraint below): primary = Ollama (`UT_AI_ENDPOINT`, open vision model,
runs on a store machine / homelab / shop-provided VM), Claude API =
explicit opt-in only (`UT_AI_PROVIDER=claude`). Data red-line: with the
self-hosted provider nothing leaves the shop's infrastructure at all.
Remaining increments below unchanged.
Task from 2026-07-13: "see how we can add AI to this pos and unitill
environment".

## Constraints that shape every option

- **Offline-first is binding (ADR-0003).** Checkout must never block on the
  network. Therefore AI lives only in back-office/async paths (reports,
  catalog admin, background jobs) and every AI surface must degrade
  gracefully to the non-AI experience when there is no network or no API key.
- **The till is Go.** Anthropic ships an official Go SDK
  (`github.com/anthropics/anthropic-sdk-go`), so the POS host can call the
  Claude API natively — no sidecar needed.
- **Plugins can't do networking yet.** The WASM runtime deliberately has no
  fs/net; the permission-gated HTTP **host function** is a planned follow-up.
  Until it lands, AI-as-a-plugin isn't buildable — AI features go in the host
  first, and migrate into the plugin story later.
- **Repository pattern (ADR-0005).** Any AI feature that reads sales/stock
  data does it through repo methods, never raw SQL — including data handed to
  the model via tool calls.
- **SELF-HOSTED FIRST (Farshid, 2026-07-13 — supersedes the earlier
  "cheap or free" API posture).** Direct quote: *"I want to run a custom ai
  model with llama or something later or a custom model which train with our
  data, not a paid ai."* Every AI feature targets a self-hosted backend:
  an **Ollama server** running an open vision/chat model (`UT_AI_ENDPOINT`),
  on a machine in the store, the homelab, or a VM the shop provides. The
  till itself (Pi-class) stays a thin client — the model runs on whatever
  box the shop points it at. Zero per-call cost, no account, photos and
  item data never leave the shop's infrastructure, and the collected
  `ai_ref` photo corpus doubles as training data for a future **custom
  per-shop model** (fine-tuned open model or embedding matcher). The Claude
  API remains available only as an explicit opt-in provider
  (`UT_AI_PROVIDER=claude`) — never the default, never required. Design
  rule for local models: keep requests small (photo + catalog text, no
  bulk reference images per call). Related-item suggestions use no model
  at all (local SQL co-occurrence).

## Candidate directions, evaluated

| # | Feature | Value for a real shop | Effort | Offline fit |
|---|---------|----------------------|--------|-------------|
| a | **"Ask your till"** — natural-language insights on the Reports page ("how did we sell today?", "what should I reorder?", anomaly callouts) | High — turns the existing reports into answers; the single most demo-able and daily-useful feature | Small–medium (host-side, existing repos become read-only tools) | Perfect: back-office page, hide panel when offline/no key |
| b | **Catalog enrichment** — generate descriptions/categories from product names, or from a photo (vision) when creating items | Medium–high — speeds up onboarding a shop's catalog dramatically | Small (one endpoint on the catalog page) | Good: admin-time action, plain form still works |
| c | **Demand forecasting / reorder suggestions** — nightly batch over sales+stock history writes suggestions to a table; Inventory page shows them | High, but trust builds slowly; needs weeks of history to be credible | Medium (background job + Batches API + UI) | Perfect: fully async, results cached locally |
| d | **AI as a marketplace plugin type** — plugin (integration/background_job) calls Claude via the WASM HTTP host function; API key held by the host, gated by a `net.anthropic` permission | Strategically the best home for ALL of the above (ships via the store, per-shop opt-in, fits trust chain ADR-0006) | Large (requires building the host-function follow-up first) | Inherits host behaviour |
| e | **Voice/assistant on the till** — hands-free operation | Low for now — mic hardware, latency and noise in a shop; checkout must stay offline | Large | Poor for the sale screen |
| f | **Fraud/shrinkage detection** on the audit trail (voids, no-sales, overrides per cashier) | Medium — valuable once multiple staff use PIN login (which just shipped) | Small–medium (piggybacks on (a) or (c)) | Perfect: report-time analysis |

## Recommendation

**Build (a) "Ask your till" first**, with (f) folded in as one of its
capabilities, then (b). Treat (d) as the destination architecture: building
(a) in the host forces us to design the exact tool surface (read-only repo
tools) that the WASM HTTP host function will later expose to plugins, so
nothing is throwaway.

### Sketch for increment 1 — "Ask your till"

> **SHIPPED 2026-07-14** on the self-hosted provider architecture (Ollama
> tool loop, separate `UT_AI_ASK_MODEL`, read-only tool surface incl. the
> identity-free `till_activity_summary`; manager-gated, audited). See
> `code-reviews/2026-07-14-ask-your-till.md` for the as-built details and
> deviations (non-streaming; claude provider has no ask loop yet).

- `internal/ai` package wrapping the Anthropic Go SDK. Config:
  `UT_AI_API_KEY` (+ optional `UT_AI_MODEL`, default `claude-opus-4-8`).
  No key → the whole feature is invisible; nothing else changes.
- Reports page gains an "Ask" box (HTMX post, async panel). The handler runs
  a **tool-use loop**: Claude gets read-only tools backed by existing repo
  methods — `sales_by_day`, `top_items`, `payment_breakdown`,
  `stock_levels`, `recent_audit_events` — plus the shop's currency/locale in
  the system prompt. Money stays in minor units in tool results; the model
  is told how to format.
- Responses stream (SDK streaming) into the panel; manager/admin role
  required (it exposes revenue data); every question+answer audited.
- Guardrails: tools are read-only by construction (no write repos wired),
  request timeout, per-day question cap in settings.
- Privacy note for the doc/README: questions and the tool results needed to
  answer them leave the till to Anthropic's API — the feature is opt-in by
  key, per shop.

### Later increments

2. **Catalog enrichment (b)** — "Suggest description/category" button on the
   catalog form; optionally vision on the uploaded item photo.
3. **Nightly insights/forecast (c)+(f)** — background job (fits the
   `background_job`/`scheduler` engine work already on the roadmap) using
   the Batches API; writes to an `ai_insights` table the Reports page shows.
4. **Migrate into a plugin (d)** — once the permission-gated HTTP host
   function ships, package the AI features as `ut-plugin-integration-ai`;
   the host function + `net.anthropic`-style permission becomes the general
   mechanism every third-party AI plugin uses.

## Farshid's direction (2026-07-13)

Three wanted capabilities, and how each maps onto the constraints:

### g. Camera item identification ("the barcode isn't working")

Cashier scans, barcode fails or is missing → taps **Identify by camera** →
the till captures a photo (browser `getUserMedia`, works with a normal
webcam/Pi camera) → Claude vision gets the photo **plus the shop's own
catalog** (item names/categories and the reference thumbnails that already
live under `assets/items/<id>/thumb.png`) → returns the top matches with
confidence → cashier confirms one tap → line added.

- **"Training with POS data" without training a model:** every confirmed
  identification saves that photo as an extra reference image on the item
  (`item_images` role `ai_ref`). The next identification includes those
  references, so the shop's recognizer genuinely improves with use —
  per-shop, no fine-tuning, nothing shared between shops.
- **Offline-first:** strictly assistive. The button only appears when
  online + key configured; barcode scan and manual search stay the primary
  path and never wait on it. Cost ≈ 1–3¢ per identification.
- If the item isn't in the catalog at all, the flow becomes "ask and add":
  Claude proposes name/category from the photo → prefilled new-item form
  (this is catalog enrichment (b) triggered from the till).

### h. Related-item suggestions (customer display / self-checkout)

"Customers may need X and forgot" — the right engine for this is the shop's
**own sales history**, computed locally: a nightly job builds an item →
related-items table from co-occurrence in past baskets (plain SQL market-
basket stats). That means suggestions render **fully offline** at sale time
— zero API calls in the checkout path, which is the only acceptable design
under ADR-0003. Claude's role is the nightly polish (curating pairs that
co-occur for boring reasons, phrasing the customer-facing line) via the
Batches API. Surfaces: first the cashier's screen, then a
`customer_facing`-type plugin (the taxonomy already reserves it) for a
customer display; self-checkout reuses the same table when that vertical
arrives.

**SHIPPED (2026-07-14, universal-till) — increment 2, cashier surface:**
`related_items` table (migration 009) holds per-item top-12 neighbours
scored by cosine² (`support² / (baskets_a × baskets_b)` — same ranking as
cosine without sqrt; demotes carrier-bag-style ubiquitous items), computed
from completed sales in the last 180 days with minimum support 2.
`RelatedItemsRepo.Rebuild` runs at startup and every 24 h (tills that
reboot daily get a fresh table each morning). The sale screen shows a
"Customers also buy" chip strip under the basket totals
(`GET /ui/suggestions`, re-fetched on every basket swap); scores are
blended across all basket items, items already in the basket are excluded,
and a tap adds the item through the normal `POST /api/pos/scan` path.
Only active items with a SKU are suggested. Still open from this design:
Claude nightly curation via Batches, and the `customer_facing` display
plugin.

### i. Accounting help for the owner

This is "Ask your till" (a) grown up: the same tool-use loop over the
sales/shifts/tax repos answers "what's my VAT this quarter?", produces
month-end summaries, and drafts export-ready figures. The natural long-term
home is the back-office app (roadmap #2); the Reports-page Q&A ships the
same capability now.

### Revised build order (proposed)

1. **`internal/ai` foundation + camera identify (g)** — the most
   distinctive feature; also forces the vision + catalog-context plumbing.
2. **Related items (h)** — local co-occurrence table + cashier-screen
   suggestions (works with zero AI infra); Claude nightly curation after.
3. **Ask your till / accounting (a+i)** — reuses the foundation from (1).
4. Catalog enrichment (b), nightly forecast (c+f), plugin migration (d) as
   before.

### j. Camera-assisted device onboarding

Farshid, 2026-07-13: "AI should be able to look at the new device by camera
and install it on the pos (do the setting, install the plugin, what else it
need) — is this possible?"

Feasible, with one correction to the design: **the camera is the assistant,
not the detector.** Pointing the camera at a receipt printer/scanner and
having Claude read the make/model off the label works well (vision is good at
labels), but the *exact* signal for "what is plugged in" is USB enumeration —
vendor/product IDs are unambiguous where a photo of a black box is not. The
right flow combines both:

1. **Detect** — till enumerates USB/serial devices (`lsusb`-equivalent);
   camera photo (same capture UI as §g) covers network/Bluetooth devices and
   disambiguates model variants Claude reads off the label.
2. **Match** — Claude maps `{vendor_id, product_id, label text}` → a
   marketplace listing. Prerequisite: device/hardware-type listings need a
   `supported_devices` metadata field (vendor/product IDs, model strings) in
   the marketplace catalog — that's the main new build.
3. **Install** — the existing verified installer path (token → checksum →
   Ed25519 → install) needs nothing new; entitlement/approval rules apply
   unchanged. The trust chain is not bypassed: AI proposes, the existing
   signed-install machinery disposes, and the operator confirms.
4. **Configure** — plugin manifests already declare config; Claude prefills
   (port, baud, paper width) from what it saw; operator confirms; a test
   action (print test page / test scan) closes the loop.

Effort: medium — mostly marketplace metadata + a device-detect endpoint; the
POS-side camera, install and audit plumbing all exist. Natural slot: after
the hardware/device plugin engine work (receipt printer path is still a
production gap; this feature is its onboarding UX). Depends on nothing in
increments 2–3.

## Decision needed from Farshid

1. Confirm the revised order (camera identify first)?
2. Where should the API key live — per-till env/settings (proposed), or
   centralized later behind the back-office app?
3. Any red lines on data leaving the till (item photos and names do; sales
   figures do for (a)/(i); customer names can be excluded at the repo-tool
   seam)?
