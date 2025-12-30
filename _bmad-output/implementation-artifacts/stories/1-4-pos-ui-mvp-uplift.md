# Story 1.4: POS UI MVP Uplift (Post Plugin-Flow Unblock)

Status: backlog

## Story

As a merchant/cashier,
I want the POS UI to be clear, fast, and consistent with the platform capabilities,
so that the working MVP is usable in real shops while the plugin ecosystem matures.

## Acceptance Criteria

1. A prioritized list of UI issues and improvements is documented (screens/flows, severity, expected behavior).
2. MVP-critical UI improvements are defined with concrete acceptance criteria (navigation, responsiveness, accessibility baseline).
3. UI entrypoints for installed plugins are defined (e.g., Help/Support for FAQ) and reflected in the UI spec.
4. A validation checklist exists for “UI ready for MVP” (manual checks + minimal automated smoke checks where possible).

## Tasks / Subtasks

- [ ] Capture current UI issues and desired outcomes (AC: 1, 2)
  - [ ] Identify top cashier flows (sale, payment, receipt, basic inventory)
  - [ ] Identify visual/interaction inconsistencies
- [ ] Define plugin entrypoint UX patterns (AC: 3)
  - [ ] Define where plugin pages/actions appear in navigation
- [ ] Define validation checklist (AC: 4)
  - [ ] Manual smoke checklist
  - [ ] Minimal automated UI smoke (if present in repo patterns)

## Dev Notes

- This story is intentionally backlog until plugin install flow is working end-to-end.
- POS UI technology: HTML/HTMX in Go edge server (see `docs/architecture.md` and POS repo).

### References

- `docs/pos/ui.md`
- `docs/architecture.md`
- `docs/plugins/faq.md`
