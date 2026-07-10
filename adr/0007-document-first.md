# 0007 — Document-first workflow

**Status:** accepted (2026-07-10, Farshid)

## Decision
1. **Decide → write → build.** Any significant/architectural choice gets an
   ADR here *before* implementation. AI sessions must follow accepted ADRs;
   contradicting one requires a superseding ADR first.
2. **Specs for features.** Non-trivial features start from a short spec
   (goal, UX, data, API) in `docs/` — the feature PR/commit links it.
3. **Review docs before commit.** Every substantive change lands with a
   review record in `docs/code-reviews/<date>-<topic>.md` (what/why/verified).
4. **Docs move with code.** A change that alters behaviour updates the
   affected reference/guide in the same working session.

## Consequences
Slightly slower starts, much cheaper handovers (human or AI). The CLAUDE.md
files in each repo point here so the policy is loaded into every AI session.
