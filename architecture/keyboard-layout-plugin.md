# Keyboard-layout plugin (design questions, 2026-07-17)

Status: **needs Farshid's answers before build** — the backlog title
("physical keyboard layouts per locale") admits several different products:

1. **Search-field transliteration**: cashier types on a physical QWERTY but
   the shop's catalog is in Farsi/Arabic → map keystrokes in the item-search
   field to the target script (like a browser IME). Per-till setting.
2. **Scanner-wedge normalization**: barcode scanners emulate keyboards and
   mis-type under non-EN OS layouts (classic problem: digits become
   symbols). A layout-aware normalizer on the barcode inputs.
3. **OS-level layout switching**: the till switching the OS keyboard layout
   with the UI language (kiosk-relevant; the OSK already handles on-screen
   layouts per locale).

Recommendation: (2) is the highest-value and most POS-shaped (scanner
correctness); (1) serves multilingual shops; (3) is likely unnecessary now
that the OSK ships layouts. Proposed scope: build (2) in core (barcode
inputs only), offer (1) as the actual "keyboard-layout" plugin
(input-method type). AWAITING Farshid's confirmation of which pain he meant.
