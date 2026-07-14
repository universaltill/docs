# Production roadmap — backlog reordered for "shop-ready, fastest"

Status: **adopted 2026-07-14** (Farshid: "prioritise… make the system ready
for production faster, then start doing them one by one"). Supersedes the
rough G-order for scheduling; the G-numbers keep their specs.

Ordering principle: **what stops a real shop running on this till today
comes first**; then what stops the *next* shop adopting it; then the
platform that opens the ecosystem; then growth features. The bar stays
"real-shop usable, nothing half-wired".

## P0 — blocks daily use in a real shop (do now, in order)

| # | Task | Why it's first |
|---|---|---|
| P0.1 | **Silent receipt printing** (ESC/POS over USB/network, print-test button, auto-print on tender — zero-touch phase C core) | A shop cannot hand customers a browser print dialog; today there is NO printer path at all |
| P0.2 | **Local backup & restore** (nightly local snapshot + one-click restore; cloud backup later per monetization) | A shop that loses its SQLite file loses the business's books — unacceptable risk to go live with |
| P0.3 | **Packaging** (zero-touch phase A: Pi SD image + Windows installer) | "Production" for anyone but us requires installing without a Go toolchain |

## P1 — production hardening + first-shop onboarding

| # | Task | Notes |
|---|---|---|
| P1.0 | **G27 refunds & returns** + **G28 receipt barcode → scan-to-refund** (Farshid 2026-07-14: "I cannot see any refund!!!") | A shop cannot operate without returns; engine support exists, UI doesn't. Barcode on the receipt (ESC/POS `GS k`) is the entry point: scan receipt → sale opens → pick lines → refund. Includes the manager-PIN gate (folds in part of old P1.2) |
| P1.1 | **G23a `ut-plugin-payment-demo`** (fake cards) then **first real terminal** (SumUp sandbox→live) | Cash + standalone card machine works today (quick-tender), so integrated payments are P1 not P0 |
| P1.2 | **Auth leftovers**: self-service PIN change (manager-PIN partial lands with P1.0) | Small; closes the pos-auth spec's out-of-scope list |
| P1.3 | **G9 barcode label printing** | Rides P0.1's printer transport |
| P1.4 | **G22a Loyverse + Square importers** | Onboarding an existing shop = production adoption |
| P1.5 | **G29 receipt designer** (owner styles the receipt: logo, header/footer, shown fields, preview + test print — easy to use) | Over the P0.1 print doc model; `receipt_template` plugins stay the advanced path |

## P2 — committed platform work (opens the ecosystem)

| # | Task | Notes |
|---|---|---|
| P2.1 | **ut-plugin-integration-ai** (AI = opt-in plugin, Farshid direction 2026-07-14; host functions shipped) | Also proves the net:/storage host functions in the wild |
| P2.2 | **Ollama on the homelab server** (CI/ArgoCD service) | Farshid ask; feeds P2.1 |
| P2.3 | **Sync ADR → LAN multi-till + QR pairing** (zero-touch D) + wizard join-shop step | Prereq for G18 standalone back office and the cloud tier |
| P2.4 | **G20 QA pipeline → G21 Universal Till ID → G26 commerce** (this order: QA needs reviewer identity lightly, commerce needs both) | Opens third-party plugins safely + monetized |

## P3 — growth (after the cloud tier exists)

Consumer app track (G16 e-receipts+G1 loyalty first, then G13/G14 discovery,
G15 community loop, G17 voice), G18/G19 back-office & HQ apps, G24/G25
accounting & delivery plugins, G2–G12 remainder, website/docs-site polish.

## Explicitly parked

Anything needing hardware we don't have gets built to the transport seam,
verified with emulators/stubs, and flagged for on-hardware sign-off by
Farshid (printer, real card terminal, Pi image boot test).
