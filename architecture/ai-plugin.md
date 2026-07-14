# ut-plugin-integration-ai — AI as an opt-in plugin (P2.1)

Status: **SHIPPED 2026-07-14** (review code-reviews/2026-07-14-ai-plugin.md; plugin listing 884b3515). Implements the 2026-07-14
direction (ai-integration.md): "using Ollama is a plugin and is not
active by default… run it on a separate machine and connect the till".

## Design

The host's `internal/ai` stays the engine (direction §3); the marketplace
plugin is the **switch and the configuration**:

- **`ut-plugin-integration-ai`** (`canonical_type: integration`,
  `runtime: none` — no code ships; it's an installable feature grant).
  Manifest **settings** (seeded into `plugin_settings` on install):
  `endpoint` (default `http://localhost:11434`), `vision_model`
  (`llama3.2-vision`), `ask_model` (`llama3.2`).
- **Host resolution — per request, no caching**: the AI endpoints/pages
  resolve the service via `aiService(ctx, d)`:
  1. plugin installed + active → Ollama config from its plugin settings
     (a shop points one or many tills at a LAN/homelab model server by
     editing the endpoint setting);
  2. else `UT_AI_*` env (the dev/low-level override, unchanged);
  3. else **disabled — AI is invisible**, the default posture.
  Install/enable/disable/settings changes take effect immediately
  (two tiny queries on AI routes only; nothing on the sale path).
- **Generic plugin settings editor** (this is the reusable piece — G23
  terminal plugins etc. need it too): the manager plugins page gains a
  Settings section per active plugin that has settings rows;
  `POST /api/plugins/{id}/settings` (manager, audited) upserts values.
  New repo methods: `ListPluginSettings`, `UpsertPluginSetting`.

## Claude provider note

`UT_AI_PROVIDER=claude` stays env-only (explicit opt-in to a paid API,
per [[ai-self-hosted-only]]); the plugin only configures self-hosted
Ollama.

## Verification

Host: unit for the resolution order (plugin > env > off); E2E — no
plugin + no env → AI invisible (404s, no UI); install plugin from the
live marketplace → camera/ask features appear with plugin-settings
endpoint; edit endpoint setting → takes effect on next request; disable
plugin → invisible again (env unset). Plugin repo released through the
standard pipeline.
