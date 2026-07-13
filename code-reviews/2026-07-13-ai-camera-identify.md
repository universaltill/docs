# Review: AI camera identify (increment 1) + RTL receipt print fix

**Date:** 2026-07-13 · **Repo:** universal-till (main) · **Author/Reviewer:** Claude (self-review, findings dispositioned before commit)

Spec: docs/architecture/ai-integration.md §g (camera item identification).
Farshid's direction 2026-07-13: build order confirmed by "continue" — increment 1
first; defaults applied: key = per-till env, model = claude-haiku-4-5, red-line =
only item identity (names/SKUs) and product photos leave the till.

## What shipped

- **`internal/ai`** — Anthropic Go SDK (`anthropic-sdk-go` v1.57.0) wrapper.
  `UT_AI_API_KEY` (no key → whole feature invisible), `UT_AI_MODEL` (default
  `claude-haiku-4-5`). `Identify()` sends the till photo + catalog context
  (id/sku/name JSON in the system prompt) + up to 60 reference images
  (latest cashier-confirmed `ai_ref` per item, else catalog thumb), with a
  prompt-cache breakpoint on the last stable block and a structured-output
  JSON schema (`matches[{item_id, confidence}]`, `suggested_name`).
  Hallucinated item_ids are filtered against the catalog after parsing.
- **`POST /api/pos/identify`** — multipart photo (≤4MB, must decode as
  JPEG/PNG) → candidates with sku/name/price/thumb (`{data,error}`,
  snake_case). Reference thumbs are re-encoded to ≤160px JPEG q70
  (`golang.org/x/image/draw`) — full-size thumbs were ~3.8MB → now ~hundreds
  of KB per request. 45s timeout; failure → 502 and the cashier falls back
  to scan/search. Audited (`ai_identify`).
- **`POST /api/pos/identify/confirm`** — saves the confirmed photo as
  `web/public/assets/items/<id>/ai_ref/<ns>.jpg` (pruned to newest 5),
  item_id traversal-guarded + existence-checked, audited
  (`ai_identify_confirmed`). This is the per-shop "gets better with use"
  loop — no fine-tuning, nothing shared between shops.
- **Sale screen UI** — 📷 button in the scan row, rendered only when the
  server has a key AND shown only while online (`online`/`offline` events);
  overlay with getUserMedia preview → capture (client-bounded to 1024px
  JPEG) → candidate buttons (thumb + name + price) → tap adds the line via
  the normal `/api/pos/scan` path (SKU exact match) and fires the confirm
  upload. All strings through `T` (10 new keys, en + fa); CSS logical
  properties only.
- **RTL receipt print fix** (Farshid: "print in rtl language is not
  aligned") — `@media print` now takes the receipt out of the sale-screen
  grid (`.pos-container` → block, heights auto, `overflow: visible`,
  kiosk-header hidden). Previously the fixed-height kiosk grid pinned the
  receipt to a narrow side column — the opposite side in RTL — and
  `body.kiosk overflow:hidden` clipped past one page.

## Offline-first / ADR compliance

- ADR-0003: checkout never blocks on AI — button hidden offline, endpoints
  strictly assistive, all failures degrade to scan/search. Verified: with no
  key the sale screen contains zero AI markup and `/api/pos/identify` 404s.
- ADR-0005: no SQL added outside internal/data (guard green). Catalog
  context reuses `POSRepo.SearchActiveItems`; prices via
  `POSRepo.ResolveCurrentPrice`.
- Money: prices returned as minor units + server-formatted display string.

## Findings (self-review), dispositioned

1. **FIXED** — `readPhoto` copied the 4MB body via `strings.NewReader(string(raw))`;
   now `bytes.NewReader(raw)`.
2. **FIXED (design)** — first structural test sent ~5MB of base64 thumbs per
   request; added server-side downscale to 160px JPEG (test:
   `TestLoadRefJPEGDownscales`).
3. **Accepted** — `ai_ref` photos live on disk next to thumbs rather than in
   an `item_images` table; matches the existing image convention
   (`assets/items/<id>/thumb.png`), pruned to 5 per item. Revisit if images
   ever need DB metadata.
4. **Accepted** — identify sends up to 60 refs even for large catalogs
   (>60 items get text-only context). Phase 2 (local embedding matcher) will
   replace this selection entirely.

## Verification

- `go build ./... && go test ./...` green; guard-data-access + guard-i18n green.
- Live (dev till, PIN login): no key → button absent, endpoint 404. Fake key →
  button + overlay render, identify request exercises the full path (catalog +
  refs gathered, API called, graceful 502 on auth failure). Real-key end-to-end
  pending Farshid setting `UT_AI_API_KEY` (no key available on this machine).
- Unit tests: default-model/disabled-service (internal/ai), ref downscale +
  ai_ref pruning (internal/pages).

## Same session (separate concerns)

- **ut-plugin-faq v0.2.1** — "FAQ doesn't change language" was NOT a POS bug:
  locale resolution correctly picked `fa-IR.json`/`es-ES.json`, but every
  non-English bundle was English placeholder text ("How do I access the FAQ?
  (fa-IR)"). Wrote 6 real Q&As genuinely translated in all 9 locales,
  released v0.2.1 through the pipeline (green), updated on the till
  (signature verified), verified fa/es/en render translated content.
