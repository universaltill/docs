# Build your own Universal Till terminal

A guide to assembling a working POS terminal for the lowest sensible cost,
with a 3D-printable enclosure you print yourself. The Universal Till software
is a local web app the terminal shows fullscreen in a browser (kiosk mode) —
so the compute only has to "run a fullscreen Chromium at the screen's
resolution". That's a very low bar, which is what makes a cheap build viable.

> **Prices below are realistic ranges from general knowledge, not live
> quotes** — used-market and component prices move a lot. Treat them as
> ballpark for planning, and check current listings before buying. All
> prices £ GBP, ex-VAT-ish.

---

## 1. Pick the compute

Ranked cheapest-capable first.

### Option A — used enterprise thin client (cheapest *capable* option) ⭐

A second-hand x86 thin client is the best value: **£15–45 used**, silent or
near-silent, sips power, and runs Debian + Chromium kiosk with zero ARM
caveats. Look for:

| Model | Typical used £ | Notes |
|---|---|---|
| Fujitsu Futro S920 / S740 | £15–30 | Very common, quad-core, 4GB, mSATA/SSD |
| Dell Wyse 5070 | £25–45 | Faster (Pentium/Celeron), 2× DisplayPort |
| HP t630 / t640 | £25–45 | AMD, USB-C on some, tidy BIOS |

Add a cheap SSD if the unit has only tiny eMMC (£10–15 for 120GB). Install
Debian, then follow the same kiosk pattern as the Pi (autologin + Chromium
`--kiosk`). **This is the cheapest route to a genuinely snappy terminal.**

### Option B — Raspberry Pi 4/5 (best fit with the rest of this project) ⭐

The repo already ships a boot-to-POS kiosk for the Pi
(`universal-till/deploy/raspberry-pi/`), and the homelab runs on Pis — so a
Pi terminal matches everything else you own.

| Board | £ new | Verdict |
|---|---|---|
| Pi 4 (2GB) | £35–45 | The sweet spot for a browser POS |
| Pi 5 (4GB) | £55–70 | Snappier, more than enough |
| Pi Zero 2 W | £15–18 | Cheapest, but a full browser POS is sluggish — fine only for a tiny customer-facing display, not the main till |

Add: official PSU (£8–12), SD card or better a USB SSD (£10–15), optional
active cooler on Pi 5 (£5).

### Option C — cheaper ARM SBCs (only if you enjoy tinkering)

Orange Pi / Radxa / Libre Computer boards are sometimes a few pounds cheaper
than a Pi, but software support is patchier (kiosk browser drivers, GPU
acceleration, OS updates). Not worth the hassle for a first build — pick A or
B. If you already have one, it'll work.

**Recommendation:** if you want the absolute lowest cost and a snappy result,
buy a **used Futro S920 / Wyse 5070**. If you want it to match the rest of
your Universal Till setup and the existing kiosk scripts, buy a **Pi 4 (2GB)**.

---

## 2. The rest of the bill of materials

The enclosure in this folder is designed around a **7" HDMI capacitive
touchscreen** + a Pi-class board, because that makes the smallest, cheapest,
tidiest printed terminal. You can scale it up (see §4).

| Part | Cheapest option | £ | Notes |
|---|---|---|---|
| **Touchscreen** | 7" HDMI + USB-touch capacitive panel (Waveshare/Elecrow-style) | £40–70 | 1024×600 is fine; capacitive feels better than resistive. Used 15" POS monitors are ~£20–40 if you print a bigger shell. |
| **Compute** | see §1 | £15–70 | |
| **Receipt printer** (optional to start) | 58mm USB/Bluetooth thermal, or used Epson TM-T20 (80mm) | £20–60 | **ESC/POS** — the format the receipt-printer plugin targets. USB is simplest. |
| **Cash drawer** (optional) | RJ11/RJ12 drawer kicked by the printer's DK port | £25–40 | The printer opens it; no separate driver. |
| **Barcode scanner** (optional) | USB HID handheld scanner | £15–25 | Acts as a keyboard → types the barcode into the scan box. Works today, no driver. |
| Cables, M2.5/M3 screws, heat-set inserts | assorted | £5–10 | Heat-set brass inserts (M3) make a much nicer enclosure than screwing into plastic. |

### Realistic totals

- **Ultra-cheap** (used thin client + used 15" touch monitor + USB scanner,
  printer later): **~£70–120**.
- **Clean compact new build** (Pi 4 + new 7" capacitive panel + 58mm printer
  + scanner): **~£150–230**.
- **Nice 80mm build** (Pi 5 + 10" panel + Epson TM-T20 + cash drawer +
  scanner): **~£300–380**.

Compare that to a commercial all-in-one POS terminal (£400–1200+). The
software is free; you're only paying for hardware you'd otherwise rent.

---

## 3. Software (reuse what's already here)

You don't build the software — the terminal just shows the web app fullscreen:

1. Run the Universal Till POS binary on the box (or point the browser at
   another machine on the LAN that runs it).
2. Boot straight into a fullscreen Chromium pointed at the POS.

On a **Pi**, that's already done for you — see
[`universal-till/deploy/raspberry-pi/`](../../universal-till/deploy/raspberry-pi/):
`unitill-pos.service` runs the binary with `UT_KIOSK=1`, `unitill-kiosk.service`
launches Chromium `--kiosk` at `http://127.0.0.1:8080/`.

On a **thin client / any Debian box**, replicate the same two ideas:

```bash
# 1. autologin to a desktop session (raspi-config equivalent: set autologin)
# 2. a user systemd/xdg-autostart entry that runs:
chromium --kiosk --noerrdialogs --disable-infobars \
  --check-for-update-interval=31536000 http://127.0.0.1:8080/
```

Set the screen scale to suit the panel: `UT_UI_SCALE=0.8` for a small 7"
1024×600 panel, `1.0`+ for larger. Kiosk touch targets are already enlarged
when `UT_KIOSK=1`.

---

## 4. The 3D-printed enclosure

The design lives next to this file:

- **[`enclosure.scad`](enclosure.scad)** — a parametric OpenSCAD model of an
  angled desktop terminal: a wedge **base** that holds the board (with vents,
  a cable slot, and standoffs) and a snap/screw-on **screen bezel** that holds
  the panel at a comfortable ~65° viewing angle.

### Print it

1. Install [OpenSCAD](https://openscad.org) (free).
2. Open `enclosure.scad`. Edit the parameters at the top for **your** screen
   and board — they're all labelled (screen width/height/thickness, board
   footprint and mounting-hole pitch, wall thickness, viewing angle). The
   defaults fit a generic 7" HDMI capacitive panel + a Raspberry Pi 4/5.
3. Set `part = "base";` and press **F6** (render) → **Export as STL**. Then
   set `part = "bezel";` and export that too. (`part = "all";` shows both
   positioned together for a preview — don't print that one.)
4. Slice each STL and print:
   - **Material:** PLA is fine indoors; **PETG** if the terminal sits in a
     warm shop window or near the thermal printer's heat.
   - **Layer height:** 0.2mm. **Walls:** 3 perimeters. **Infill:** 15–20%.
   - **Supports:** the base needs supports under the cable slot and the
     rear I/O opening; the bezel prints face-down with no supports.
   - The default footprint fits a **220×220** bed. If your screen is bigger
     than the bed, set `split = true;` to cut the base into two halves that
     bolt together (dowel/screw tabs are generated automatically).
5. **Assembly:** press M3 heat-set inserts into the marked bosses with a
   soldering iron, seat the board on its standoffs, drop the panel into the
   bezel, run the ribbon/HDMI + USB-touch + power through the cable slot, and
   screw the bezel to the base. Stick-on rubber feet on the bottom.

### Customising for a different screen

Every dimension is a variable — change `screen_w`, `screen_h`,
`screen_bezel`, `board = "pi";` (or `"generic"` with your own hole pitch),
and the model regenerates. For a used 15" POS monitor, set `mount = "vesa";`
and the bezel becomes a VESA 75/100 back-plate + stand instead of a full
frame (you keep the monitor's own bezel).

---

## 5. Notes & safety

- **Power:** use the proper PSU for your board; cheap under-rated supplies are
  the #1 cause of flaky Pis. Thin clients ship with their own brick.
- **Heat:** keep the thermal receipt printer's vents clear; print the shell in
  PETG if it's nearby.
- **Cash handling:** the cash drawer opens on the printer's command, so it only
  works when a printer is connected — plan for that if you add a drawer later.
- **Offline-first still holds:** none of this hardware changes the software
  rule that checkout works with no network. A terminal with just compute +
  screen sells all day offline; the printer/scanner/drawer are add-ons.

---

## Shopping checklist (compact new build)

- [ ] Raspberry Pi 4 (2GB) + official PSU + USB SSD (or good SD card)
- [ ] 7" HDMI capacitive touchscreen (1024×600) + its HDMI + USB cables
- [ ] 58mm USB thermal receipt printer (ESC/POS) — optional to start
- [ ] USB HID barcode scanner — optional
- [ ] M3 heat-set inserts (×6) + M3 screws + M2.5 board screws
- [ ] Rubber feet ×4
- [ ] Filament: ~150–250g PLA/PETG for the two printed parts
