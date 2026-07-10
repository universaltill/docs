# docs — rules for working in this repo

The documentation repo is the **source of truth for decisions**.

- `adr/` — Architecture Decision Records. **Binding** for humans and AI:
  never contradict an accepted ADR; write a superseding ADR first
  (ADR-0007 document-first).
- Significant features start with a short spec here before implementation.
- Every substantive change in any repo lands with a review record in
  `code-reviews/<date>-<topic>.md`.
- Behaviour changes update the affected reference/guide in the same session.
- Plugin repos: one per plugin, `ut-plugin-{type}-{name}` (ADR-0009).
