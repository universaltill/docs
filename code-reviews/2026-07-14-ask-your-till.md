# Review — "Ask your till" (AI increment 3, self-hosted tool loop)

Date: 2026-07-14 · Repo: universal-till · Spec: `architecture/ai-integration.md`
§a sketch, adapted to the self-hosted-first rule ([[ai-self-hosted-only]]).

## What shipped

- `internal/ai/ask.go`: `AskTool` (name/description/JSON-schema/Run),
  `ShopContext`, optional `asker` provider capability, `Service.CanAsk()`,
  `Service.Ask()` (120s budget). System prompt carries shop name, currency
  code + decimals (minor-units rule) and today's date.
- `internal/ai/ollama_ask.go`: standard Ollama `/api/chat` tool loop —
  model requests `tool_calls`, results return as role `tool` messages,
  bounded at 6 rounds. Tool errors go back to the model as text so it can
  recover. **Separate ask model** (`UT_AI_ASK_MODEL`, default `llama3.2`):
  vision models don't do function calling, so camera identify and ask use
  different models on the same Ollama.
- Tool surface (read-only by construction, wired in `pages/ask_api.go`):
  `sales_by_day`, `top_items`, `payment_breakdown`, `stock_levels`,
  `till_activity_summary` (new `POSRepo.AuditActionSummary` — **counts per
  actor/action only, never payloads**, the data red-line).
- `POST /api/reports/ask`: 404 when no capable provider, manager/admin
  only (403), 1–500 char question, audited (`ai`/`ai_ask` with question).
  Answer renders as an HTMX partial into the Reports page's new "Ask your
  till" card (rendered only for managers when `CanAsk`). 6 i18n keys en+fa.

## Deviations from the sketch (noted, deliberate)

1. Sketch predates the self-hosted rule (Anthropic SDK + streaming).
   Implemented on the provider interface with **Ollama primary,
   non-streaming** (HTMX indicator instead); the Claude provider reports
   `CanAsk() == false` until someone wants it.
2. Per-day question cap skipped for the self-hosted backend (no metering
   to protect); reconsider if the claude asker lands.

## Verification

- Unit: full tool-loop against a fake Ollama (tools sent, ask model used,
  tool result round-trips, args parsed), loop bound, unknown-tool
  recovery, `CanAsk` false for disabled/claude. Full `go test ./...` +
  both guards green.
- **Real E2E on a local Ollama (qwen3.6)**: seeded sales through the real
  scan/tender API, asked "What sold best today and how much money did we
  take?" → correct answer in ~25s: Coca-Cola 2 units and **£3.55 total —
  verified against the DB (355 minor units, 2 completed sales)**; the
  model did the minor-units conversion as instructed. Audit row written;
  cashier gets 403 + no panel; instance without UT_AI_ENDPOINT: 404 + no
  panel. README + pos.env.dev document `UT_AI_ASK_MODEL`.
