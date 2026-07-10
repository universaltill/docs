# 0008 — POS UI: server-rendered templates + HTMX/Alpine

**Status:** accepted (long-standing; recorded 2026-07-10)

## Decision
The POS UI is Go html/template rendered server-side, with HTMX for partial
swaps and Alpine for small client state (tabs). No SPA framework, no build
step, no CDN (assets vendored). Screens must work on a small touch till:
one-screen sale layout, panels scroll internally, UI scale via root
font-size (`display.ui_scale` setting / UT_UI_SCALE).
