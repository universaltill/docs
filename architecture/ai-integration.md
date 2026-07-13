# AI in the unitill environment — proposal

Status: **proposal — awaiting Farshid's direction** (ADR-0007 document-first).
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
- **Cost/model.** Default model `claude-opus-4-8` ($5/$25 per MTok). A
  reports question with a few tool round-trips is roughly 5–15K input +
  1–2K output tokens ≈ **$0.05–0.15 per question** — negligible for a
  shopkeeper asking a handful of questions a day. High-volume/background
  tasks (nightly enrichment, forecasting) can use the Batches API (50% off)
  and can be downgraded to a cheaper tier later if volume warrants.

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

## Decision needed from Farshid

1. Green-light increment 1 ("Ask your till") as specced?
2. Where should the API key live — per-till env/settings (proposed), or
   centralized later behind the back-office app?
3. Any red lines on data leaving the till (e.g. exclude customer names from
   tool results — easy to enforce at the repo-tool seam)?
