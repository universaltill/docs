# Zero-touch setup — install, devices, and multi-till pairing (proposal)

Status: **proposal — 2026-07-14** (Farshid: installation must be so easy that
"a person who doesn't know anything about computers just clicks on something";
devices install themselves; a second till joins the shop by "scanning a thing
on the first pos"; "completely so easy for stupids :D").

The bar for every flow below: **no terminal, no config files, no IP
addresses, no manuals.** If a step can't be done by a shop assistant on their
first day, it fails the spec.

Foundations we already have: the POS is ONE static Go binary with all assets
embedded (nothing to install around it); first-boot admin-PIN setup exists;
the sale screen already has camera capture (AI identify); deploy/raspberry-pi
has a working kiosk image recipe; the marketplace install path is one click
and signature-verified.

## Phase B first — guided first-boot wizard (pure POS work, no packaging)

Replace the bare "set admin PIN" first boot with a full-screen wizard, each
step one decision, every step skippable with sane defaults:

1. Language (flag buttons; sets locale + RTL).
2. Country → prefills currency, tax rate/inclusive mode (registry per country).
3. Shop name.
4. Admin PIN (existing setup step, restyled into the wizard).
5. **"New shop or joining one?"** — fork point for pairing (Phase D; greyed
   out with "coming soon" until D ships).
6. Printer (Phase C hook): "plug your receipt printer in now" → auto-detect →
   test page → or Skip.
7. Done → sale screen with demo catalog + a dismissible "add your products"
   hint card.

All server-rendered HTMX (ADR-0008), i18n from step 1's choice onward,
progress dots, big touch targets. Wizard state in settings
(`setup.completed`); an unfinished wizard resumes where it left off.

## Phase A — one-click install per platform

| Platform | Deliverable | Notes |
|---|---|---|
| Windows | Signed installer (.msi, WiX): installs binary as a service + a "Universal Till" shortcut that opens the kiosk browser | The audience Farshid describes mostly has a Windows laptop or an old PC |
| macOS | .pkg with LaunchAgent + app-style launcher | Lower priority |
| Raspberry Pi / dedicated till | **Flashable SD image** (extend deploy/raspberry-pi): flash with Raspberry Pi Imager, boot → till comes up in kiosk mode directly in the wizard | The true "appliance" path; pairs with docs/hardware/diy-pos.md |
| Linux desktop | .deb + curl-install for technical users | Already effectively works |
| Android tablet | WebView wrapper app pointed at localhost or a paired till | Later; roadmap already lists mobile |

CI builds all artifacts on tag (goreleaser fits a single Go binary well);
"Download" page on the website offers exactly one button per platform.
Auto-update: the till checks the release feed and offers "Update" in
Settings — never forced, never during a sale.

## Phase C — devices that install themselves

- **USB (printers/scanners/drawers):** watch for hotplug; look up
  vendor/product ID in a device table; ESC/POS printers are near-generic →
  offer "Receipt printer found — print test page?" toast. Unknown device →
  §j of ai-integration.md (camera + model reads the label; optional).
  Scanners are keyboards (already work) — detect and confirm with a "scan
  this barcode" test screen.
- **Network printers:** mDNS/SSDP scan from the Settings → Devices page;
  list by friendly name; pick → test page. No IP entry ever shown (advanced
  fields behind a "manual" disclosure).
- Device state shown as status chips (never modal blockers — CLAUDE.md).

## Phase D — multi-till pairing: "scan a thing on the first pos"

Joining till (in wizard step 5 → "Join existing shop"):

1. First till: Settings → Tills → "Add a till" shows a **QR code** containing
   `{shop_id, one-time pairing token (5 min), primary's LAN addresses,
   primary's self-signed cert fingerprint}` + the same as a 6-digit code
   fallback (no camera on the new till? type the code; both tills also
   advertise `_unitill._tcp` via mDNS so the join screen can list shops it
   can see).
2. New till scans the QR with its camera (getUserMedia capture already built
   for AI identify — same plumbing + a QR-decode lib).
3. New till connects to the primary over the LAN, pins the cert fingerprint,
   redeems the one-time token → receives shop settings + catalog + a device
   identity (Ed25519 keypair registered with the primary).
4. From then on: LAN sync with the primary (catalog/settings/stock pull,
   sales journal merge; tills keep working offline independently and
   reconcile — same offline-first rules, ADR-0003).

Architecture decision needed BEFORE building D (its own ADR): the local sync
model — recommendation: **primary/replica within a shop** (first till is the
source of truth for catalog/settings; sales append-only merge from all
tills), because it's drastically simpler than peer-to-peer and matches how
shops think ("the main till"). Cloud sync (monetization proposal gate #1)
then syncs the PRIMARY to the cloud for multi-store/back-office — i.e.
**LAN multi-till inside one shop stays free; off-site/multi-store sync is
the paid tier.** (Pricing implication flagged in
monetization-cloud-services.md — needs Farshid's confirmation.)

## Suggested order & effort

1. **B — wizard** (small; all pieces exist) ← start here
2. **A — Pi image + Windows installer** (medium; mostly CI/packaging)
3. **C — USB printer plug-and-play** (medium; also closes the "receipt
   printer path untested" production gap)
4. **D — QR pairing + LAN sync** (large; needs the sync ADR first)

## Decisions for Farshid

1. Confirm phase order (wizard first?).
2. Phase A: which platform matters most for your first real users — Windows
   installer or the Pi appliance image?
3. Phase D pricing: LAN multi-till free / cloud multi-store paid — confirm.
