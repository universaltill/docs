# Code review — item-image sync to replicas (LAN sync D2b follow-up)

Date: 2026-07-15 · Repo: universal-till · Branch: feat/image-sync
Closes the documented D2 limit "item images don't travel".

## What shipped

- Primary: `GET /api/sync/assets` (bearer) — manifest of
  `web/public/assets/items` (relative path + size); `GET
  /api/sync/assets/file?path=` (bearer) serves one file. `safeAssetPath`
  confines everything to the items tree (no `..`, no absolute, no
  backslashes) on BOTH serve and save sides — the replica re-validates
  manifest paths, never trusting the wire even from its own primary.
- Replica: the pull tick calls `syncItemAssets` every 30s (before the
  fingerprint short-circuit — images change without moving the admin
  fingerprint). Missing or size-changed files download to a `.sync-tmp`
  and rename into place (no torn reads by the HTTP server). Failures log
  and wait for the next tick.
- Size is the change detector: content hashing per poll would cost more
  than re-downloading the occasional same-size thumbnail is worth.

## E2E (two processes, separate asset trees)

Replica started with an EMPTY items tree (symlinked web/ui+locales,
private assets dir) → paired + joined → within one tick fetched **101
files across all 50 items, byte-identical** (`cmp` clean). Replacing a
thumb on the primary propagated on the next tick (size-change path).
Traversal request → 400; valid path with bearer → 200; no bearer → 401.
Full suite green.

## Notes

- Plugin FILES still install from the marketplace on each till (correct
  by design — signed bundles, not file copies); this closes the images
  half of the D2 limit only.
- ai_ref training photos ride along automatically (same tree) — the
  camera-identify corpus now survives on whichever till takes over.
