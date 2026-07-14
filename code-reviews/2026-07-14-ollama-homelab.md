# Review — Ollama on the homelab as a GitOps service (P2.2)

Date: 2026-07-14 · Repo: **homelab-k8s** (0d99d01) · Direction:
ai-integration.md 2026-07-14 §4 ("I want to have it on my server as a
service") · Deployed per [[deployment-github-actions-only]]: git push →
ArgoCD sync, no local kubectl apply.

## What shipped

- ArgoCD Application `ollama` (bootstrap/apps, picked up by the root
  app-of-apps): `ollama/ollama` Deployment pinned to the high-RAM node
  (`ram-tier: high` = pi5-main), 15Gi local-path model PVC (Recreate
  strategy — RWO volume), `OLLAMA_KEEP_ALIVE=30m` so the model stays warm
  between questions, readiness on `/api/tags`, memory 2Gi request / 6Gi
  limit.
- Traefik Ingress **https://ollama.home.taskrunnertech.co.uk** with the
  cert-manager `letsencrypt-home` issuer (same pattern as the
  marketplace).
- **Model pull via `postStart`** (async in-container: wait for the
  server, `ollama pull llama3.2:3b`, no-op when current) — self-healing
  on every pod start. First attempt was a PostSync hook Job, which
  **can never fire on this cluster**: Traefik doesn't populate ingress
  `status.loadBalancer` (the marketplace ingress shows the same `{}`),
  so ArgoCD holds every ingress-bearing app "Progressing" forever.
  Caught live after 13 min of no job; worth remembering for any future
  app here that wants sync hooks.
- Till side documented in the app README: install
  `ut-plugin-integration-ai`, set `endpoint` to the URL above,
  `ask_model: llama3.2:3b`.

## Hardware honesty (2× Raspberry Pi cluster)

Small text models only: ask-your-till answers in tens of seconds on the
Pi 5 — usable, not snappy. **Vision (camera identify) does not fit** on
Pi-class hardware; shops wanting it point the plugin's `vision_model`
tills at a PC/mini-PC Ollama. All stated in the manifests + README.

## Notes

- `git add -A` swept a pre-existing uncommitted CLAUDE.md rewrite in that
  repo into the commit (accurate repo docs — MetalLB range, NFS,
  structure); left in place rather than rewriting a pushed shared branch.

## Verification

Push → root app created the Application automatically → pod Ready in
78 s on pi5-main, PVC bound → ingress live: first strict-TLS probe failed
while cert-manager was mid-DNS-01 (secret 41 s old), issued within ~2 min
→ `https://…/api/tags` 200 over valid TLS. Model pull job + a real
generation through the ingress verified (see addendum below).
