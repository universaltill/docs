# Review: Designer tile reorder never persisted (2026-07-13)

Farshid: "when I change the order in designer page, the item order is not
changing in the home page". universal-till main e936674.

Root cause: the Designer's drag&drop JS posts `FormData` — a
multipart/form-data body — but `POST /api/buttons/reorder` only called
`r.ParseForm()`, which does not parse multipart. `codes` was always empty,
the handler returned 400 "codes required", and the `fetch` ignored the
response, so the grid showed the new order while nothing was saved. Every
reorder since the feature shipped (2026-07-10) was silently dropped —
confirmed in the dev DB: 10 of 11 buttons still at `sort_order=0`.

Fix: dispatch on Content-Type (`ParseMultipartForm` for multipart, else
`ParseForm`) — the same class of bug as the 2026-07-10 tender handler
(unconditional JSON decode consumed form bodies); and the Designer now
reloads the grid when the save fails so the DOM never lies. Regression test
`TestReorderAcceptsMultipartFormData` posts real multipart and asserts the
persisted order (urlencoded still covered).

Verified live: multipart reorder → 204 → `shortcut_buttons.sort_order`
updated → home page `/ui/buttons` partial renders the new order.
