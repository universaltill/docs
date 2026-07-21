# Universal Till — Work Queue

_Last updated: 2026-07-18 night. **Phase 2 (Universal Till Cloud, ADR-0018) is LIVE
in code**: heartbeat+health, directives (remote settings/install/remove), install-to-tills
button, catalog/stock up-sync — all merged both sides; mp deploys automatically.
**https://cloud.universaltill.com is LIVE** (Farshid approved the apply 2026-07-18;
DNS + cert + rebrand verified). **⏳ Three Farshid steps** (classifier-blocked for me,
full detail in code-reviews/2026-07-19-multi-host-weblogin.md): ① till release
(`gh workflow run release.yml -f bump=patch` from universal-till) so his shop starts
syncing and install-to-tills applies; ② Zitadel cloud-callback apply — one command,
staged + plan-verified (0 destroys): `cd infra/unitill-infra/zitadel && export
KUBECONFIG=~/.kube/homelab-config && export ARM_ACCESS_KEY="$(az storage account keys
list -g uni-till-platform -n unitillinfra --query '[0].value' -o tsv)" &&
TARGET=zitadel_application_oidc.marketplace_web ./apply-in-cluster.sh apply`;
③ after ②, tell Claude to re-add the reverted AUTH_WEBLOGIN_EXTRA_REDIRECT_URLS env
in homelab-k8s — then login on cloud.* stays on cloud.*. Living checklist,
**ordered by dependency**:
each phase mostly needs the one before it. Within a phase, do 🔴 before 🟡 before 🟢._
_`[ ]` = not started, `[~]` = in progress, `[x]` = done (bottom). **(field)** = Farshid
reported it from real use._

**Dependency flow (the critical path to the shopper platform):**
`fix + enable marketplace auth → cloud sync tier + store registry → e-receipts + loyalty
→ map / nearby search (needs shop density) → price comparison → public web + SEO
→ delivery & bookings`

Two tracks run **independently** of that path and can happen anytime:
**Owner intelligence** (till-local reports/forecasting) and **POS polish** (till fixes).

---

## Phase 0 — Fix & polish what's already live _(no dependencies — do now)_

### 🧾 Till field bugs (Farshid screenshots 2026-07-17 evening)
- [x] 🔴 **Fresh installs panicked on first use (cwd-independent startup)** —
      FIXED 2026-07-21 (`universal-till` `2918d05`, merged PR #38, released
      **v0.2.39**). A cold-start walkthrough (fresh install, no dev tooling,
      launched from outside its own directory — how a real shop owner's
      machine actually looks) found every template/locale/static-asset read
      was CWD-relative with no embedding: `config.NewI18n` hard `log.Fatalf`'d
      on boot; every page render `template.Must(...ParseFiles...)` panicked,
      including the first-boot setup wizard itself; static CSS/JS/logo 404'd
      (login PIN pad needs Alpine.js, one of them). A first review round fixed
      entry points but a second independent review caught checkout was STILL
      broken (basket/journal/receipt render, home button grid) — a stranger
      would get past setup/login only to have the app panic on the first
      barcode scan. Fixed via `go:embed` for `web/ui`, `web/public`,
      `web/locales`, with a disk-then-embedded-default fallback so shop
      customizations (uploaded item images, receipt logo, theme overrides)
      still work unchanged. Live-verified end-to-end from a completely
      unrelated working directory: setup → home → button grid → basket scan,
      including the exact request that used to panic. Review:
      `universal-till/docs/code-reviews/2026-07-21-cwd-independent-startup.md`.
- [x] 🔴 **(field)** **OSK "still not showing"** — diagnosed: his till is on `auto`,
      which hides the keyboard on non-touch machines BY DESIGN (mac answer: Settings →
      Display → On-screen keyboard → **On**). Real fix shipped too: auto now detects
      touch via any-pointer/maxTouchPoints/ontouchstart and enables on first real touch
      (kiosk chromium with a mouse used to defeat it) — v0.2.35.
- [x] 🟡 **(field)** **Settings page unaligned/messy** — responsive card grid + aligned
      form rows, 51 → 26 inline styles, uniform control heights — v0.2.35. (Same
      treatment available for other pages he flags.)
- [x] 🔴 **(field)** **PIN pad rendered inside the header** — expired-session htmx
      fragment loads got a 302 that htmx swapped in place; now 401 + HX-Redirect →
      real navigation to the lock screen (v0.2.25, class-wide for all fragments).
- [x] 🔴 **(field)** **Catalog right panel too long** — sticky + capped height + inner
      scroll (v0.2.26).
- [x] 🟡 **(field)** **Labels print per variant** — Variant dropdown on the labels form;
      prints the variant's name, price and its own barcode (v0.2.26).

### 🏪 Marketplace portal (Farshid field feedback)
- [x] 🔴 **(field)** Fix account role — grant trimmed to `merchant_admin` only (verified
      live; sign out/in to refresh). Admin stays on the dedicated admin@ account.
- [x] 🔴 **(field)** Signed-in **name + role chip** in the nav; Admin/Developer links only
      for holders of those roles.
- [x] 🔴 **(field)** **"My shop"** single back-office (per-store "Tills & details" +
      "Manage plugins"; approvals bind to the browsed store).
- [x] 🔴 **(field)** Real **plugin detail page** (live listing data + working
      approve/unapprove; stub + fake buttons removed).
- [x] 🔴 **(field)** Plugin **descriptions** — real summaries written for all 11 listings
      (data had summary = name). ⚠️ follow-up below: fix plugin manifests too.
- [x] 🔴 **(field)** "My shop" **approve buttons + card clicks fixed** (handler was
      auth-gated out on prod; links pointed at a 404).
- [x] 🔴 **(field)** "Back to marketplace" 404 link fixed.
- [x] 🟡 **(field)** `/ui/admin/reviews`: staff **sessions** can assign/decide without the
      upload token; reviewer prefilled. (Page was live; queue was empty + token-only.)
- [x] 🟡 **(field)** **Developer console** gated to registered developers (vendor role) +
      **API docs linked** (Swagger UI / ReDoc / openapi.yaml with token notes).
- [x] 🔴 **Prod auth — closed deliberately**: `Auth.Disabled` stays true (flipping would
      demand JWTs on /api and break every till — they use store tokens). Per-surface
      enforcement completed instead; last gap closed: anonymous merchant
      entitlement writes now 401 whenever web login exists. **No anonymous writes
      remain; staff/owner UI fully role-gated; fleet untouched.**
- [x] 🟡 Plugin **manifest descriptions** — verified: all 11 manifests ALREADY carry real
      descriptions; the bad summaries were purely the ingest bug (root-cause fixed).
- [x] 🟡 **(field)** **Plugin trust badges + install consent** — SHIPPED BOTH SIDES:
      till (v0.2.27) + marketplace (storefront/portal/detail pills, same mapping).
      REMAINING (separate): "verified" assignment rules ride the vendor-registration
      decision. Original notes:
      🏠 gold official (com.universaltill.*), ✔ verified, ⚠ unverified badges on store
      cards + localized "do you trust this publisher: X?" confirm before downloading/
      installing unverified plugins. REMAINING: matching badge styling on the
      marketplace storefront/portal/detail; "verified" assignment rules (ties into
      vendor registration). Original ask:
      three visible tiers on every plugin card/detail — (1) **official Universal Till**
      plugins get a distinctive "golden house" badge; (2) **verified developers**
      (registered + paid) get a verified badge; (3) **unverified** publishers get an
      untrusted marker AND the till shows an install-time alert: "Do you trust this
      publisher?" with the publisher name before installing. Builds on the existing
      `trust_tier` field + first-party slug prefixes (signing config) + ADR-0006 trust
      chain; needs: tier assignment rules, badge design (storefront + portal + POS
      store cards), and the POS confirm dialog on untrusted installs.
- [ ] 🟢 Self-serve **vendor registration** flow (request + admin approval) — today a
      developer needs a manually-granted vendor role. 2026-07-19: granted
      `vendor_maintainer` to Farshid's second account (farshid3003@gmail.com,
      created directly in id.universaltill.com) via IaC — `zitadel_user_grant.
      plugin_developer` in infra/unitill-infra/zitadel/marketplace.tf, looked
      up by email (`data.zitadel_human_users`) since no id was captured at
      creation. This manual-grant path is exactly what this item would
      replace.

### 🌍 Localization
- [x] 🟡 **Marketplace storefront i18n** — SHOPPER SURFACES COMPLETE (slices 1+2):
      landing page, portal cards + fragment, detail hero, trust pills, vendor lines —
      9 locales, verified live (TR + FA render confirmed). Staff pages (admin/vendor
      consoles) deliberately English — queued 🟢 if ever needed.
- [x] 🟡 **Language selector link restored on cloud.universaltill.com** — the
      2026-07-15 storefront redesign (commit ad2a6f4) dropped the only nav link to
      `/ui/language`, orphaning it (page still worked, just unreachable). Fixed
      2026-07-20: persistent 🌍 link in the header nav, visible at all viewport
      widths. See `code-reviews/2026-07-20-storefront-language-link.md`.
- [x] 🟢 Other landing pages (`store_detail.html`, `my-stores`, `directory.html`)
      SHIPPED 2026-07-20: each gained a small 🌍 topbar link to `/ui/language`,
      matching the homepage fix. `TestOtherLandingPagesLinkLanguageSelector`
      guards all three.
- [x] 🟡 **Plugin listing auto-translation** (Farshid 2026-07-20: "we dont have
      translation for the modules and their details... developer can put
      everything in it's own language but we translate it and even the guide
      and help of it... user see the translation in the current user setting
      language... button to show the original") — SHIPPED, `ut-cloud` PR #13.
      Implements FR-023 (`specs/001-plugin-marketplace/spec.md`), previously
      unimplemented despite scaffolded-but-unused `MachineTranslator`/
      `LocaleService` stubs. New `description`/`documentation`/`source_locale`
      fields on `PluginListing` (didn't exist before — vendors had no way to
      author a guide at all) + a `PluginListingTranslation` cache table.
      Self-hosted-only machine translation (`internal/platform/translate`,
      Ollama `/api/chat`) — no paid AI API, matches [[ai-self-hosted-only]];
      no-ops (serves original text) when unconfigured. Translates + caches
      lazily on the first view per (listing, locale); every later viewer in
      that locale gets the cached row instantly, never blocking on a live
      translation. `/merchant/plugins/{id}` now shows content in the
      viewer's detected language (same cookie/query/Accept-Language
      mechanism as the rest of the site) with a "show original" toggle
      (`?original=1`). Independent review (different model) caught and fixed
      one HIGH bug pre-merge: comparing the viewer's full BCP-47 tag
      (`en-US`) against `source_locale`'s bare `"en"` default would have
      mistranslated English content for English speakers on every request —
      fixed via the existing `primaryLang()` normalization. Full writeup:
      `ut-cloud/docs/code-reviews/2026-07-20-plugin-listing-machine-translation.md`.
      Deployed: `homelab-k8s` PR #9 wires `UT_AI_ENDPOINT`/`UT_AI_MODEL` at
      the `unitill-cloud` Deployment to the already-running in-cluster Ollama
      (`llama3.2:3b`); verified live — new pod picked up the env vars, ent
      auto-migrate created `plugin_listing_translations` + the new
      `plugin_listings` columns cleanly (no migration errors in pod logs).
      REMAINING 🟢: only the single-listing detail page translates; the
      merchant portal's list/grid view still shows original-language
      summaries (deliberate — translating N listings synchronously on every
      list-page load would be a bad first-load experience; pre-warming the
      list view is a natural fast-follow, not done here).
- [x] 🟡 **Plugin platform taxonomy** (Farshid 2026-07-20: building
      `erp.universaltill` separately, plus an Android POS port planned —
      "in anycase we need platform field... maybe we will have other
      platforms in the future as well") — SHIPPED, ADR-0019, `ut-cloud`
      PR #14. New `PluginListing.platforms []string` (till/android/erp/...),
      defaulted to `["till"]` at the only listing-creation call site (till
      manifest ingest — every listing published today is by definition a
      till plugin). `ListFilters.Platform` + `effectivePlatforms()`/
      `platformSupported()` for catalog filtering; merchant portal DTO +
      detail-page badges. Deliberately scoped to catalog metadata only —
      NOT a plugin runtime compatibility contract for Android/ERP, which
      is a separate design decision for whenever each platform's own
      plugin host runtime gets built (checked `erp/universal-core`: no
      plugin/manifest concept exists there yet, nothing to reconcile).
      Independent review (different model) caught the "empty Platforms
      means till" default being applied inconsistently (2 of 5 read sites
      had it, 3 didn't) — centralized into one shared helper. Full writeup:
      `ut-cloud/docs/code-reviews/2026-07-20-plugin-platform-taxonomy.md`.
      **New backlog item surfaced along the way** (see Spec audit gaps
      below): `ListPlugins`'s `SnapshotVersion` isn't spec-compliant per
      CHK008 (falls back to "now" on an empty filtered page instead of a
      true global max) — pre-existing, not caused by this change, but
      platform filtering makes the empty-result case common instead of
      rare for any `platform=android`/`platform=erp` query.

### 🎨 Content & assets
- [x] 🟡 **(field)** **Icons for all 11 plugins** — consistent SVG set embedded in the
      marketplace, served at `/ui/assets/icons/{slug}.svg`, wired to storefront/portal/
      detail. **POS store page renders them too** (28px beside the name).
- [ ] 🟢 **(field)** **Teaching / advertising videos** for the POS (can't generate video
      directly — propose scripted screen-capture of real flows, GIF micro-demos per
      feature, or a reveal.js explainer exported to video).

### 🖥️ POS / till polish
- [x] 🟡 **(field)** **Variant-specific images** — SHIPPED: 📷 upload per variant in the
      grid, stored `assets/items/{item}/variants/{variant}/thumb.png`, fallback chain
      variant → item → hidden. Follow-ups in the spec: sale-tile/store surfacing of
      variant images; image LAN-sync (item images have the same gap).
- [ ] 🟡 **Keyboard-layout plugin** — design questions written
      (`architecture/keyboard-layout-plugin.md`): scanner-wedge normalization vs
      search transliteration vs OS switching — **awaiting Farshid's pick** (recommend
      scanner normalization in core + transliteration as the plugin).
- [ ] 🟡 **Windows regular-printing** — plain-text/CUPS-equivalent path on Windows.
- [ ] 🟡 **(field)** **Settings page layout is broken** (Farshid 2026-07-20, two
      screenshots): several cards (Data Management/backup file table, "All
      settings" key/value table) overflow and get horizontal scrolling instead
      of wrapping/sizing to fit — these boxes should span both grid columns
      (double width), not be squeezed into one. Separately, the Payments
      card's fee inputs (percent + fixed per provider) wrap ugly mid-row for
      some providers (e.g. "Card (Stripe)") while others fit on one line —
      inconsistent, unprofessional. Needs a real CSS/grid pass on
      `universal-till/web/ui/pages/settings.html` (+ its handler
      `internal/pages/settings_page.go`) for clean, consistent card widths
      and a payment-fee-row layout that doesn't wrap. NOT started — logged
      per Farshid's explicit "backlog it, don't fix now."
- [ ] 🟡 **(field)** **Buttons can carry icons** (Farshid 2026-07-18): tender/menu
      buttons show an icon; a plugin can ship its own icon in the manifest and it shows
      on the plugin card AND on the button it contributes.
- [x] 🟡 **WKDownloadDelegate** — attachments / undisplayable responses / `<a download>`
      links now save to ~/Downloads with browser-style dedupe (macOS 11.3+ guarded).
      Needs a real-app click test on the next dmg.
- [ ] 🟡 **Scope-aware user settings** — NEEDS DESIGN FIRST (document-first): the wasm
      runtime carries no user identity into plugin evaluation, so a per-user setting has
      no runtime meaning yet. Write the spec (what user-scoped settings mean, how
      settings_get would resolve per-user) before any code.
- [x] 🟢 Registration nag → **quiet outline hint** "Marketplace: not connected" (ADR-0015).
- [x] 🟢 **Claim by QR** — the claim panel now shows a QR of the claim URL; the owner
      scans and claims from their phone (works on kiosk/Windows/Linux shells).

---

## Phase 1 — Owner intelligence _(independent track — needs only sales-history in the till)_

- [~] 🟡 **More owner reports** — SHIPPED: **Slow sellers**, **Dead stock** (tied-up
      value), **Busiest days & hours** (local-time buckets, CSS bars) on the reports
      page under the period selector, **Margins** (cost-price field in the catalog
      panel → revenue−cost card, unknown costs excluded), **Year-over-year KPI** (same
      window one year back; hidden until history exists), **Tax summary per rate**
      (net + tax collected, returns deducted), **variant-level cost editing** (Cost
      column in the variant grid → variant-cost-aware margins). Core report set DONE.
      ALSO FIXED: variant sales now fold into the parent item's sell rate / dead-stock
      / margin queries (an item selling via variants no longer shows as dead).
- [x] 🔴 **Multi-year retention verified** — sales/sale_lines are never pruned (only the
      explicit factory-reset deletes them); SQLite keeps full history, replicas journal
      to the primary, so the primary holds the whole shop's time series. Forecasting can
      query `sales`+`sale_lines` directly (see `ItemDailySellRates` as the pattern).
- [~] 🔴 **Order-ahead forecasting** — FIRST INCREMENT SHIPPED: "Coming up (based on
      last year)" reports card — same upcoming 28-day window one year ago per item vs
      current stock → suggested top-up; hidden until a shop has year-old data (lights
      up as history ages). REMAINING: multi-year averaging, lunar-holiday shift
      awareness (Ramadan moves ~11 days/yr), category rollups.
- [~] 🔴 **Predictions + alerts** — SHIPPED: "Days left" column (28-day rate,
      variant sales folded in), ⚠ ≤7-day warnings, header chips (inventory + reports),
      **reorder suggestions** ("order ~N" to a 14-day cover on running-out rows).
      REMAINING: per-item lead times, unusual-sales + seasonal-spike alerts,
      multilingual email alerts — **increment 1 SHIPPED**: claim captures the owner's
      email as org contact; `Notification` entity + till push endpoint + **My shop
      inbox** (unread badge, refresh-not-duplicate digests, i18n ×9); till pushes a
      **daily low-stock digest** (registered tills, best-effort). The EMAIL
      sender is now BUILT and shipping DORMANT (localized mail to the org's
      claim-captured contact, retry + no-resend semantics) — activation = setting
      NOTIFY_SMTP_*/NOTIFY_FROM on the mp deployment (Brevo creds from KV), done
      deliberately with Farshid since it makes prod send real mail. **Unusual-sales
      alert SHIPPED** (yesterday vs same-weekday 4-week baseline, ≥3-week guard,
      >1.8×/<0.4× incl. zero days; inbox row + mail text ×locales). Then: seasonal
      spikes (with the forecasting arc).

---

## Phase 2 — Universal Till Cloud _(the gate for the whole shopper platform)_

**Decision landed ([ADR-0018](adr/0018-universal-till-cloud.md), Farshid 2026-07-18):**
the "marketplace" app is really the **cloud tier** → renamed **Universal Till Cloud**
at `cloud.universaltill.com` (marketplace stays as one section; the old host keeps
working for the fleet). Sync is **till-initiated only** (state up, directives down);
the **back-office device = the till binary in back-office mode** (no separate app).
**First cloud env = Farshid's homelab** — his shop syncs to his local cloud NOW.

**2a — Sync foundation (in progress — Farshid's shop ↔ homelab cloud):**
- [x] 🔴 **Till → cloud heartbeat + health** — SHIPPED (both sides, 2026-07-18): till
      pushes device state (version/platform/role incl. backoffice, db size, uptime)
      every 5 min; store detail page shows fleet health + last-sync. Lands on his
      till with the next release; cloud side deploys automatically.
- [x] 🔴 **Directives channel** — SHIPPED: cloud queues `set_setting`/`install_plugin`/
      `remove_plugin`; till pulls on the sync loop, applies via the SAME local paths
      (installs stay Ed25519-verified), reports applied/failed; portal shows history +
      cancel. Proven end-to-end against the real binaries. Remote settings form live
      on the store detail page.
- [x] 🔴 **Catalog + inventory snapshot up-sync** — SHIPPED: till pushes active items
      (name, price, barcode, on-hand qty) on the sync tick, hash-gated so only changes
      transmit; cloud stores one snapshot per store (4MB/20k caps) and renders a
      "Catalog & stock" card+table on the store page. This is also the feed the
      Phase-3 shopper search will read. 2026-07-19: variants SHIPPED — one row per
      active variant (own id/price/barcode, composed name, no qty to avoid
      double-counting), and the inline price editor works on variant rows
      (`SetItemPrice` falls through to `item_variants`); review
      `code-reviews/2026-07-19-variants-in-snapshot.md`.
- [x] 🟡 **Problems & logs surface** — SHIPPED 2026-07-19: till keeps a ring of recent
      warn/error log lines (`logging.Recent()`, zero call-site changes) + failed
      plugin installs, reports them as a digest in the heartbeat (capped, truncated,
      replace-on-report so resolved problems clear); store page shows a fleet-wide
      **Problems & logs** card (device/when/level/message, newest first). Review:
      `code-reviews/2026-07-19-problems-feed.md`. 2026-07-19: persistent problem
      history SHIPPED — new `ProblemEvent` entity persists every occurrence at
      heartbeat time (survives the live feed's replace-on-report clearing),
      deduped on (device, reported_at, message) with a DB-level unique index
      backing the app-level check against racing heartbeat retries, capped at
      500 rows/store; collapsible "Problem history" section on the store page.
      Also fixed a till-side timestamp precision bug the dedup surfaced
      (`universal-till` `RFC3339`→`RFC3339Nano`). Review:
      `ut-market-place/docs/code-reviews/2026-07-19-persistent-problem-history.md`
      + `universal-till/docs/code-reviews/2026-07-19-problem-digest-timestamp-precision.md`.
      REMAINING 🟢: printer-fault events when hardware plugins report them.
- [x] 🟡 **Backoffice role/mode design (Farshid design ask, 2026-07-19)** —
      **Farshid decided 2026-07-19: agreed with Claude's rec** — single source
      of truth stays the primary/replica database (ADR-0011, unchanged), and
      backoffice becomes a manager/admin ROLE GATE, not a device lock.
      SHIPPED: `/backoffice` previously had NO auth gate at all (any operator,
      even a cashier, could view the manager dashboard by navigating there).
      Added the same `isManagerOrAuthOff` gate settings/reports already use.
      Independent review caught a self-lockout regression this introduced — a
      cashier session on an already backoffice-mode till would've hit a
      dead-end 403 at "/" — fixed by making the home-page redirect itself
      role-aware (falls through to the normal sale screen for non-managers)
      and gating the display-mode setter to managers too. Review:
      `universal-till/docs/code-reviews/2026-07-19-backoffice-role-gate.md`.
      REMAINING 🟢: setup-wizard question (only till / till+backoffice / only
      backoffice-kiosk) — a UX nicety over the existing Settings toggle, not
      needed for the role-gate itself to work correctly.

**2b — Remote management UI (needs 2a):**
- [x] 🔴 **Fleet page in My shop** — SHIPPED 2026-07-19: the Devices table
      already had name/id/role/platform/version/last-seen; added the two
      missing pieces. Health chip is driven by the existing Problems digest
      (a device with a current unresolved problem shows "Attention needed",
      amber) rather than the raw health map, which today only reports
      uptime/db size with no natural healthy/unhealthy threshold. Pending
      directives is a fleet-wide badge on the heading, backed by a
      dedicated count query (not derived from the capped 20-row Directives
      list, so it can't disagree with the real total). Independent review
      caught nothing blocking; a real bug was found and fixed during
      implementation — `{{call .T ...}}` inside `{{range .Store.Devices}}`
      silently truncated the page (`.` is the device inside a range, not
      the page root) — two existing render tests caught it, fixed with
      `$.T`. Verified live twice: once against a locally-seeded instance
      (curled the rendered HTML), and again by confirming via direct DB
      query that Farshid's real production till currently carries a real
      warning (`cloudsync: tick failed (will retry)`, transient, from an
      earlier deployment restart window) — same data shape as the local
      verification, so the same code path is confirmed correct for it too
      (couldn't screenshot production directly — the page correctly
      requires authentication). Review:
      `code-reviews/2026-07-19-fleet-page-health-directives.md`.
- [x] 🔴 **"Install to shop" from the cloud** — SHIPPED: entitled plugin cards + the
      detail page carry an **Install to tills** button that queues the directive for
      the browsed store; e2e spec covers approve → install → pending-on-store-page.
      Paid installs still ride the subscriptions arc below. 2026-07-19: Farshid
      reported "not working" — his shop's till predates cloudsync; needs the till
      release (header step ①). Till now picks up queued directives ~15 s after boot
      and every 2 min while running (was 90 s / 5 min). **2026-07-19 night: step ①
      DONE** — Farshid reported still not working, root cause confirmed: the last
      published release (v0.2.36, 2026-07-18) predates cloudsync entirely (38
      commits / the whole feature unreleased). Cut v0.2.37 (Farshid approved);
      all build jobs green (Linux/Windows/macOS). Farshid updated his till to
      v0.2.37 and **confirmed install-to-tills now works end-to-end** — item
      fully closed. **Farshid decision: remote install is a PAID-tier feature**
      — gate `install_plugin`
      directives when the subscription tiers land (task #42).
- [x] 🟡 **Remote settings & design/theme** — SHIPPED 2026-07-19: the till reports its
      active theme + available themes (built-in and plugin-contributed) in the
      heartbeat; the store page renders a **Design** picker from what the fleet
      actually has and applies via the existing `set_setting theme` directive
      (queue/cancel/history free). Generic key/value settings form already existed.
      Review: `code-reviews/2026-07-19-remote-theme-picker.md`. REMAINING 🟢: install
      a theme *plugin* from the picker in one step (today: install plugin, then pick).
- [~] 🟡 **Cloud catalog/inventory editing** — STEPS 1+2 SHIPPED 2026-07-19: inline
      **price editing** (`set_price`, works on items AND variants) and inline
      **stock adjustment** (`adjust_stock` +/- delta on item rows; same movement
      record + connector event as a local adjustment, actor `cloud`, full audit
      trail). Reviews: `code-reviews/2026-07-19-remote-price-edit.md`,
      `…-remote-stock-adjust.md`. STEPS 3+4 also shipped same day: **inline rename**
      (`rename_item`, items + variants, `…-remote-rename.md`) and **Retire**
      (`deactivate_item`, confirm-guarded soft retire, cloud can retire / only the
      shop resurrects, `…-remote-deactivate.md`). STEP 5: **Add item** form
      (`create_item {name, price_minor, barcode?}`, idempotent by name so retries
      can't duplicate, taken barcodes fail cleanly, `…-remote-create-item.md`).
      STEP 6: **barcode editing** (`add_barcode`, AddBarcode owns all safety,
      `…-remote-barcode.md`). **ARC COMPLETE** — the Catalog table manages add /
      rename / price / barcode / stock / retire inline, all through the validated,
      audited, cancellable directive queue. REMAINING 🟢: variant creation only.
- [x] 🟡 **Back-office mode in the till** — SHIPPED: Settings → Display → **Device
      profile** (manager-only): back-office makes `/` land on Reports (sale screen
      unreachable); per-till setting; fleet view shows the `backoffice` role. Replicas
      no longer push duplicate catalog snapshots. _This IS the "back-office
      application"_ — any till/tablet becomes the manager station.
      2026-07-19: richer home SHIPPED — `/backoffice` manager dashboard
      (today/yesterday/week KPIs, low stock, recent problems, deep links);
      review `code-reviews/2026-07-19-backoffice-dashboard.md`.

**2c — Naming & platform (parallel):**
- [x] 🔴 **cloud.universaltill.com** — **LIVE 2026-07-18** (Farshid approved the apply):
      `https://cloud.universaltill.com/ui/` answers 200 with a valid cert and the
      "Universal Till Cloud" title. Getting there surfaced that terraform CI only ran
      the parent root — the website root (all universaltill.com DNS) was never in CI;
      fixed with a plan/apply matrix + a `root` dispatch input, plus imports of the six
      pre-backend Key Vault secrets so a platform apply can never rotate live creds
      again (review: `code-reviews/2026-07-18-terraform-multi-root-ci.md`).
      REMAINING 🟢: ① zitadel terraform root still has no CI (needs the machine-user
      PAT as a repo secret). (imports.tf deleted after
      adoption; multi-host login for cloud.* is CODED + merged — header steps ②③
      finish it: Zitadel callback apply, then re-add the reverted env. Review:
      `code-reviews/2026-07-19-multi-host-weblogin.md`.)
- [x] 🟡 **Org-wide ut-* repo rename** (Farshid 2026-07-19): `ut-market-place`→
      `ut-cloud`, `docs`→`ut-docs`, `infra`→`ut-infra`, `website`→`ut-website` on
      GitHub + local dirs + remotes; Go module path + ~190 imports renamed;
      15 living docs updated (dated `code-reviews/*.md` left as historical
      record). Turned out **repo rename is NOT purely cosmetic**: it broke
      Azure AD OIDC federated identity — `ut-cloud` and `ut-infra`'s GitHub
      Actions couldn't auth to Azure at all (`AADSTS700213`) until the
      `unitill-gh-oidc` app registration's federated-credential subjects were
      updated to match the new repo names. Also: this org has GitHub's
      "immutable ID" OIDC subject format enabled, so the correct subject is
      `repo:universaltill@<org_id>/<repo>@<repo_id>:...`, not the plain-name
      form — easy to get subtly wrong. Fixed via `az ad app
      federated-credential update` (imperative — the CI service principal
      has Azure RM access but no Microsoft Graph read/write, so adding this
      to the CI-planned `unitill-infra` root as Terraform would break `plan`
      for everyone touching that root). REMAINING 🟢: bring these 4
      federated credentials under Terraform properly — needs either a
      higher-privileged execution path (like the in-cluster Zitadel apply
      pattern) or granting the CI SP Graph permissions (Farshid decision).
      Verified: full `verify.sh` green in `ut-cloud`, protobuf codegen
      regenerated via `protoc` (not hand-patched — the embedded
      FileDescriptorProto is a length-prefixed byte blob), contract guard
      satisfied, CI/E2E green, `build-and-push` confirmed landing
      `ut-cloud:latest` in ACR post-fix. **FULLY COMPLETE 2026-07-19 night**:
      homelab-k8s image cutover verified end-to-end (till heartbeat
      confirmed advancing against the new pod). Deeper "rename everything"
      pass per Farshid: `cmd/marketplace`→`cmd/cloud`, `cmd/marketplace-sync`
      →`cmd/cloud-sync`, gRPC proto package `marketplace.v1`→`cloud.v1`
      (regenerated via protoc, contract-guard'd as v0.0.3 — confirmed safe:
      real clients use REST via grpc-gateway, unaffected by the proto
      package name; the raw gRPC port isn't exposed outside the cluster),
      `deploy/helm` + `deploy/kustomize` (confirmed dead/unused — real
      deploys go through this homelab-k8s repo), dev DB/cert filenames,
      OTel meter name, NATS connection label, `OBS_SERVICE_NAME` default,
      `TestMarketplaceProviderPacts`→`TestCloudProviderPacts`. Two CI-only
      breaks caught and fixed (shell scripts `e2e/run-mp.sh` +
      `scripts/ci/install-e2e.sh` still built `./cmd/marketplace` — missed
      by source-level search since they're invoked BY workflows, not
      workflow YAML themselves; full install-e2e pipeline verified passing
      locally before re-push). **Deliberately NOT renamed** (documented
      inline in code): the Pact Broker `Provider: "ut-marketplace"` string
      (external identity — renaming would orphan published consumer
      pacts); the JWT `iss`/`aud` claims tied to the still-live
      `marketplace.universaltill.com` domain (baked into every issued
      merchant token — same deferred domain-consolidation question, not a
      naming concern); `cfg.Marketplace.PublicKey` + "Plugin Marketplace" /
      "Universal Till Marketplace API" user-facing titles (the plugin-
      marketplace FEATURE name, distinct from "cloud" the platform);
      `specs/001-plugin-marketplace/` directory (historical spec numbering).
      **Two pre-existing anomalies discovered along the way** (not caused
      by this rename, flagging for Farshid): (1) `cmd/cloud/var/data/marketplace.db`
      (was `cmd/marketplace/var/data/...`) is a SQLite file accidentally
      checked into git despite `.gitignore`'s `var/*` rule — looks like it
      was force-added once; left untouched, worth deleting from history if
      it's not meant to be tracked. (2) the OIDC federated-credential gap
      above.
      REMAINING: 🟢 items above (federated creds under Terraform, printer-
      fault events, etc.) — unrelated to this rename. **Explicitly
      deferred/gated, not started**: k8s namespace rename + Postgres/blob
      PVC data migration (needs a deliberate maintenance window, not a
      same-day rush); retiring `marketplace.universaltill.com` DNS (every
      till in the field defaults to that exact URL,
      `packaging/pos.env.example` — would go dark with no visible error;
      needs a coordinated till-release + fleet-adoption window first, per
      the same caution as the earlier install-to-tills domain work above).
      **UPDATE 2026-07-20 (Farshid: "Full Stage E now"), steps 1+2 done**:
      `cloud.universaltill.com` promoted to the canonical OIDC redirect/
      post-logout host in `homelab-k8s` (`marketplace.universaltill.com`
      demoted to the EXTRA/alias host — both already registered on the
      Zitadel app, config-only swap, verified live: correct `redirect_uri`
      per host, till heartbeat advancing post-rollout). `universal-till`
      v0.2.38 released: new installs default `UT_MARKETPLACE_ENDPOINT_URL`
      to `cloud.universaltill.com/api` (existing tills untouched — this is
      the packaged template, not a runtime default). **Still NOT done**
      (unchanged from above): the JWT `iss`/`aud` on merchant device tokens
      (still `marketplace.universaltill.com` — changing it invalidates
      every live token fleet-wide, a separate and much higher-risk step
      than the OIDC login host); DNS/ingress retirement itself (both hosts
      still served indefinitely).
      **UPDATE 2026-07-20 (Farshid: "finish it, even the namespace, in aks"
      — clarified: no AKS exists, this is the homelab k3s cluster), k8s
      namespace rename DONE**: new `unitill-cloud` namespace/Application in
      `homelab-k8s`, every resource renamed (Deployment/Service/PVCs/
      SecretProviderClass/synced-secret — Key Vault secret NAMES unchanged,
      that's a separate Azure action). Staged additively first (no Ingress,
      no live traffic) to verify the fresh Postgres/blob came up healthy;
      data migrated via `pg_dump`/`pg_restore` + a tar-stream blob copy with
      the old namespace still serving traffic; full parity check before
      cutover (13/13 table row counts matched, blob file checksums matched
      exactly — zero diff). Ingress cutover was an atomic single commit
      (added to `unitill-cloud`, removed from `unitill-marketplace` in the
      same commit) to avoid two Ingress objects racing for the same
      hostnames. Verified live: all 4 hostnames 200, correct per-host OIDC
      `redirect_uri`, sync API endpoint reachable (400 on an empty test
      payload, not a connection failure). Till heartbeat check was
      inconclusive — the till hadn't synced since 12:08:53Z, *before* the
      cutover even started (confirmed via the frozen old-namespace DB), so
      the till process itself appears to not be running right now,
      unrelated to the migration.
      **UPDATE 2026-07-20 (Farshid: "delete the old namespace"), fully
      done**: `unitill-marketplace` namespace + git manifests
      (`kubernetes/apps/unitill-marketplace/`,
      `kubernetes/bootstrap/apps/unitill-marketplace.yaml`) deleted after
      one more health check on `unitill-cloud` (all 4 hostnames 200, data
      present). ArgoCD pruned the Application object once the manifest was
      removed from git, but that alone did **not** cascade-delete the
      namespace's resources (no resource finalizer) — `kubectl delete
      namespace unitill-marketplace` was needed as the actual cleanup step.
      Confirmed gone, `unitill-cloud` fully unaffected. Stage D is now
      completely closed out.
      **UPDATE 2026-07-20, remaining 🟢 items closed out**: **federated
      creds under Terraform** — the 4 `unitill-gh-oidc` federated-identity-
      credential subjects codified as `azuread_application_federated_
      identity_credential` in `ut-infra` (`unitill-infra/github-oidc.tf`),
      imported cleanly (only diff was the previously-blank `description`).
      Still needs a Graph-permissioned identity to apply (CI SP has none —
      same gap as the existing `kv_csi` object-id workaround); applied
      manually this time. **The JWT `iss`/`aud` on merchant device
      tokens** — turned out the earlier caution ("invalidates every live
      token fleet-wide") didn't hold: traced the code and found
      `validateToken` never checks `iss`/`aud`, and `GenerateMerchantToken`
      has zero callers anywhere in the workspace — the till fleet's real
      bearer token comes from the unrelated `merchantauth` opaque-token
      system via `POST /api/v1/stores/register`. Renamed to
      `cloud.universaltill.com` / `cloud-api`
      (`ut-cloud/docs/code-reviews/2026-07-20-jwt-issuer-audience-rename.md`
      has the full trace). **Still open, unrelated to this rename**:
      DNS/ingress retirement of `marketplace.universaltill.com` itself
      (kept alive indefinitely — every till in the field may still default
      to it until upgraded past v0.2.38); bringing the federated-credential
      apply under CI properly.
      **Bonus find while chasing the Zitadel terraform root's own transport
      gap**: the plain `Ingress` for `id.universaltill.com`'s
      `service.serversscheme: h2c` annotation never actually gave the
      backend leg real HTTP/2 — a genuine gRPC request through it landed on
      Zitadel's REST layer (plain JSON 404). Fixed with a Traefik-native
      `IngressRoute` alongside it (`homelab-k8s`, `kubernetes/apps/zitadel/
      deployment.yaml`); verified live with a real `terraform plan` against
      the public endpoint (clean, no in-cluster Job needed anymore — see
      `ut-infra/unitill-infra/zitadel/README.md`'s Transport caveat).
- [ ] 🔴 **Subscription select + pay** (Farshid 2026-07-17): plan page (free/paid tiers
      per ADR-0013), selection + payment (likely Stripe Billing), driving entitlements
      that gate paid features/plugins **and paid plugin installs from the portal**.
      Design the plan matrix first.
      2026-07-19 addendum (Farshid): free dev registration in the cloud; a PAID
      dev tier earns plugins a **badge**. Claude's caution, agreed direction —
      the badge must be an identity/trust marker (paid = verified publisher,
      like Docker's "Verified Publisher"), layered ON TOP of, never INSTEAD
      of, the mandatory scan/sign/verify pipeline (ADR-0006 — never weaken).
      A free-tier dev's plugin is unbadged but still fully scanned/signed —
      "unverified" in this plan must mean unbadged, not unscanned.
- [ ] 🟡 **Shop badges** (Farshid 2026-07-17): registered/claimed/subscribed tiers on
      the back-office and later shopper surfaces. Define with the subscription tiers.
- [x] 🔴 **Store registry** — SHIPPED 2026-07-19: public `/ui/directory` listing
      (name + region) of shops on Universal Till Cloud. Opt-in, not opt-out — a
      claimed store isn't listed until the owner toggles "list this store" on
      the store detail page (`storedetail.directory_listed`). Merged PR #6
      (`feat/store-directory`), independent review clean, verified live in
      production 2026-07-20 (page renders, correct empty state, healthz both
      hostnames 200, till heartbeat advancing past the new pod's start time).
      Next layer (app/web search, richer shop profile) still open — this ships
      the directory list itself, not discovery/search UX yet.
- [ ] 🟡 **Multi-store head office** (ADR-0013 L2/L3) — one console across stores; ties
      to the paid multi-store licence. My-shop pages + 2b are the seed.
- [ ] 🟢 **Multi-cloud + on-prem sovereign** deployment — the homelab deployment IS the
      on-prem proof; document + generalize it (cheap/low-txn, cloud-less countries).

---

## Phase 3 — Shopper platform _(needs Phase 2; listed in its own build order)_

Designed in `architecture/consumer-app.md`, `item-discovery-and-universal-catalog.md`,
`arch/product-search-network.md`. Free for shoppers; shops participate via the cloud tier.

**3a — First shippable (works with even one shop):**
- [ ] 🔴 **Consumer mobile app shell (Android + iOS)** — one codebase (Flutter/React
      Native, decide later), talks only to the cloud API. The delivery vehicle for 3a.
- [ ] 🔴 **Paperless e-receipts & invoices in the app** — scan at tender → receipt/VAT
      invoice lands in the app; permanent proof of purchase (warranty/returns).
- [ ] 🔴 **Digital loyalty card + points/rewards wallet** — one QR scanned at any till;
      per-shop programs in one wallet.
- [ ] 🔴 **Coupons/offers, digital punch cards, gift cards & store credit** — per shop.

**3b — Discovery (needs several shops live = density):**
- [ ] 🟡 **Map & nearest shop** — find Universal Till shops nearby; hours, what they sell.
- [ ] 🟡 **Item search across nearby shops (G13)** — "who has it, cheapest, closest"; shop
      opt-in publishes catalog+stock to the cloud. _Then_ price comparison on top.
- [ ] 🔴 **Public web app + SEO discovery (G14)** — same search, **no login**, with
      crawlable pages carrying `schema.org/Product` + `Offer`/`LocalBusiness` structured
      data so **Google surfaces "in stock nearby" physical shops**, not just online ones.
      _Same publication pipeline as G13, one more frontend._
- [ ] 🟢 **Universal item catalog (G15)** — shared barcode→product repository (community
      loop, cloud). _Increment 1 (till-side barcode auto-fill from Open*Facts) is ALREADY
      SHIPPED — lookup package + /api/catalog/lookup + Auto-fill button all live._

**3c — Transactions & services (needs 3a/3b):**
- [ ] 🟡 **Click & collect / order ahead** + **delivery** (shop's own delivery first,
      courier handoff later) — orders drop onto the till as normal sales.
- [ ] 🟡 **Restaurant: order at table / takeaway** — table-QR → menu → kitchen ticket.
      2026-07-20 (Farshid): the **digital menu** itself — scan the table's QR
      code, see the menu, in the **consumer app** and also on the **public
      website** (same web app as the customer app, not a separate build).
      Menu items carry rich data: ingredients, calories, etc. (allergen info
      is the obvious related need once ingredients exist — worth asking
      Farshid when scoping). Ties to G14 (public web + SEO) and the
      catalog/snapshot work already shipped (2a) for the underlying item
      data. NOT started — needs scoping (is this its own menu-item schema
      extension, or does it reuse the existing plugin/catalog item model
      with new optional fields?).
- [ ] 🟡 **Table reservations** — book a table; shows on the till's booking view.
- [ ] 🟡 **Appointment booking for service shops** (barber, dentist, salon, garage…) —
      services + staff + availability. Shared **bookable-resource** scheduling engine for
      tables *and* appointments; likely a booking/reservation-type plugin + cloud calendar.
- [ ] 🟢 **Shop ratings & reviews in the app** (Farshid 2026-07-17): shoppers can rate
      and review shops (and later items); shows on the shop's app/web page. Needs
      moderation + verified-purchase weighting (tie reviews to e-receipts so only real
      customers review); feeds the G14 public pages (schema.org AggregateRating = SEO).
- [ ] 🟢 **Speak your order in your language** (G17), spending history/budgeting, household
      sharing, privacy controls — later polish.

---

## Phase 4 — Adjacent & strategic arcs

- [ ] 🟡 **Android till app** (Farshid 2026-07-17) — the FULL Universal Till running on
      Android-ready POS hardware (PAX/Sunmi SmartPOS class, Android tablets). Distinct
      from the BYOD companion below: this is the till itself as an Android app (Go server
      via gomobile/WebView shell, or the till server + Android webview shell like the
      desktop shells). Also the delivery vehicle for the Phase-E SmartPOS payment app.
      2026-07-21 addendum (Farshid, via a shop-owner friend's real-world feedback):
      cafes overwhelmingly prefer **Android and iPad tablets over a computer**, and
      many payment providers' Tap-to-Pay integrations key off the **device's own
      NFC radio** (ties directly to E4 Tap-to-Pay/PCI MPoC below — the tablet's NFC
      IS the reader, no separate hardware). Decision: **build the iOS/iPadOS till app
      alongside the Android one**, not Android-only — same "full till as a native
      app" shape (Go server + native/WebView shell, same pattern as the existing
      Windows/Mac/Linux desktop shells and gomobile approach), just on iOS/iPadOS
      instead of a second desktop OS. NOT started — needs scoping alongside the
      existing Android item (shared server core, per-platform shell + App Store
      distribution/signing questions unique to iOS).
- [ ] 🟢 **Mobile light POS** (Android/iOS BYOD register, LAN-paired to primary till) —
      merchant-side companion; mostly independent (LAN pairing exists).
- [ ] 🟢 **Storefront & hardware** — store.universaltill.com selling devices/parts;
      3D-print profiles for DIY POS; pro multilingual website.
- [ ] 🟢 **Integration plugins** — Twilio SMS · SAP · iyzico (Turkey) · Google Calendar ·
      WhatsApp — each built + tested for real once Farshid provides sandbox keys.

## 💳 Payment orchestration + least-cost routing (major arc)

We route each card to the **cheapest eligible provider** — never a payment provider
ourselves, never holding funds. Each provider = a `payment` plugin; POS shows a button
per provider; **manual mode** (cashier picks among provider-locked readers — no
certification, ships now) + **automatic mode** (multi-acquirer device/gateway picks —
later). Full plan: `architecture/payment-orchestration-roadmap.md`; decision:
[ADR-0016](adr/0016-payment-orchestration-least-cost-routing.md); markets:
`architecture/payment-markets-launch-set.md`. Launch: **UK → GCC (UAE/BH/QA/OM) → Turkey.**

**A. Decisions & agreements (blockers, no code):**
- [ ] 🔴 A1 Routing engine plumbing: **write our own provider connections** vs **rent an
      orchestration service** (Spreedly/Primer/Gr4vy — software APIs, NOT devices; they
      maintain ready-made connections to dozens of PSPs). Our orchestrator (plugins,
      buttons, cost rules) exists either way; this only decides what's under its hood.
      Affects Phase D (online auto-routing) only — Phase C manual mode needs neither.
- [ ] 🔴 A2 First two providers to route between (e.g. Stripe + SumUp / Stripe + Adyen).
- [ ] 🟡 A3 GCC aggregator covering UAE+BH+QA+OM + domestic schemes — coverage in writing.
- [ ] 🟡 A4 Turkey: GİB-certified fiscal-POS partner + iyzico vs Craftgate.
- [ ] 🟡 A5 ISV/acquirer agreements + review PSP **"no-steering"** clauses.
- [ ] 🟡 A6 PCI scope strategy (tokenization / network tokens / P2PE).

**B. Foundation (provider-agnostic):**
- [x] 🔴 B1 **Payment-provider contract defined + documented**
      (`reference/payment-provider-contract.md`): payment entries → tender buttons,
      blocking `.authorize`, async `.requested` (settle-link), and the NEW blocking
      **`.refund` leg** — a provider must send the money back or the return is blocked
      (cash unaffected). Much of this existed; refund was the real gap.
- [x] 🔴 B2 **Stripe plugin 1.2.0 on the full contract** — event dispatch, sale→charge
      linking in plugin storage, partial refunds via /v1/refunds. **Proven E2E against
      the real Stripe test API**; published + approved on the marketplace.
- [x] 🔴 B3 POS **button per enabled provider** — verified pre-existing
      (SyncPluginPaymentMethods → payment_methods → tender UI).
- [x] 🔴 B4 **Cost-rules config SHIPPED**: per-provider percent+fixed fees in
      Settings → Payments (bp/minor storage, LAN-synced).
- [x] 🟡 B5 Offline-first sale path untouched (refund gate is per-method, cash never gated).

**C. Manual multi-provider — ships now, UK, no certification (← the near-term win):**
- [ ] 🔴 C1 Add a **second REAL provider plugin** (per A2 — SumUp/Adyen; demo+qrpay+stripe
      already give multiple buttons for the UX, so this is about a second real acquirer).
- [x] 🔴 C2 Manual-selection UX **COMPLETE**: merchant default (preferred provider
      leads the tender UIs) + live **"≈ −fee" hints** on every Pay button computed from
      the basket total and the B4 fee rules — the cashier sees the cheaper provider at
      a glance. Manual least-cost routing (M2) is now fully usable pending C1's second
      real provider (A2 decision) and the C4 shop pilot.
- [ ] 🟡 C3 Record which provider was used on sale/journal/receipt.
- [ ] 🔴 C4 **UK pilot** on real hardware (Farshid's shop) with two providers.

**D. Online / card-not-present automatic routing (UK; pure software):**
- [ ] 🟡 D1 **BIN → scheme/type/region** detection.
- [ ] 🟡 D2 **Routing engine** — cheapest by cost table + failover + success-rate.
- [ ] 🟡 D3 Second **online acquirer** integration (Adyen/Checkout) as a plugin.
- [ ] 🟢 D4 Pay-by-link / e-commerce surface uses the router.

**E. Card-present automatic LCR (later; certification-heavy):**
- [ ] 🟢 E1 Target device: certified **SmartPOS** (PAX/Sunmi) app or gateway-bound terminal.
- [ ] 🟢 E2 **Per-acquirer certification** (EMV L3 + scheme + host) — one, then add.
- [ ] 🟢 E3 **Debit dual-network selection** (standards-native LCR).
- [ ] 🟢 E4 **Tap-to-Pay (PCI MPoC)** — no-hardware option.
- [ ] 🟢 E5 Key injection / estate management (PAXSTORE / RKI).

**F. Market rollout (parallel once C/D prove out):**
- [ ] 🟡 F2 **UAE** — GCC beachhead via the A3 aggregator (F1 UK = done via C/D).
- [ ] 🟢 F3 **Bahrain → Qatar → Oman** — same aggregator + per-country CB approval + switch.
- [ ] 🟢 F4 **Turkey** — own track: fiscal-POS + Troy + iyzico/Craftgate.

**G. Cross-cutting / compliance (ongoing):** PCI DSS on the routing layer · cost-rules
maintenance · per-market agreements/CB approvals · Iran/Shetab as a separate future track.

_Milestones: M1 decisions locked · **M2 foundation + manual mode live in the UK (near-term)** ·
M3 automatic online routing · M4 card-present auto LCR · M5 market expansion._

---

## 🧪 Field tests pending _(ongoing — need Farshid's hardware)_

- [ ] 🔴 **Pi kiosk** boot test (cage + chromium --kiosk on the real Pi).
- [ ] 🟡 **Linux desktop app** on real Linux (amd64/arm64).
- [ ] 🟡 **Windows desktop shell** on a real Windows box (WebView2 vs browser fallback).
- [ ] 🟡 **2-till LAN stock-level sync** on the homelab.
- [ ] 🟡 Re-test **claim flow** after v0.2.19 (external link → browser; code reuse).

---

## Spec audit gaps (2026-07-20)

Spec-vs-implementation audit across all 12 spec-kit directories (ut-cloud, universal-till,
ut-plugin-faq): read each spec.md/tasks.md, then verified the corresponding code (grepped
for stub/TODO markers, checked real call sites, didn't trust checkboxes or comments).
Naming drift ("marketplace"→"cloud") is NOT reported below — only genuine functional gaps.
Most specs (000–006, 008, ut-cloud i18n excluded as already tracked) checked out clean;
the gaps below are real. Not on the critical path — pick up opportunistically.

### 🏪 ut-cloud — spec 001-plugin-marketplace
- [x] 🔴 **Vendor releases/rollback portal shows fake data** — FIXED 2026-07-20
      (`ut-cloud` `1c2db8c`, merged PR #15). list/details/rollback now hit real
      DB queries; rollback actually revokes the current approved release on
      that channel so an older approved version becomes newest-approved again
      (every reader already treats "newest approved" as current — no separate
      push needed). Found + fixed along the way: a template name collision
      (`plugins/list.html` vs `releases/list.html`) meant the release list was
      never reachable regardless of handler data; removed 3 dead action buttons
      posting to unregistered routes + a fictional malware-scan section (this
      repo's scanner is structural/manifest validation only, not AV). Independent
      review caught 2 HIGH pre-merge: `ExecuteRollback` wasn't channel-scoped
      (could revoke an unrelated beta release on a stable rollback), and the
      rollback-execute endpoint only required vendor role, not staff.
- [ ] 🟡 **Device telemetry ingestion never persists / no dashboards** —
      `ReportPluginStatus` validates but never writes to DB (`// TODO: Persist
      telemetry`); `GetDeviceTelemetry`/`GetMerchantTelemetry`/`GetPluginTelemetry`/
      `DetectAnomalies` all return hardcoded placeholders; the REST handler
      (`internal/api/telemetrysvc/handler.go`) doesn't even decode the request body.
      Neither that handler package nor the gRPC `TelemetryService` is wired into
      `cmd/cloud/main.go` — zero call sites outside their own package despite
      T032/T034 marked done. Source: FR-014.
- [ ] 🟡 **Resumable/checksummed downloads are mocked** —
      `internal/downloads/resume_manager.go` (T031) is dead code with zero external
      call sites; `ValidateChunkChecksum` always returns `true` regardless of input.
      The live-routed endpoint (`internal/httpapi/handlers/downloads.go:185`) is
      explicitly commented `// best-effort; resume is mocked` and always returns the
      literal string `"download-chunk"` ignoring byte range/checksum; `/api/v1/
      downloads/status` always returns a hardcoded "active" response. Source: FR-011,
      SC-002 (99.5% resumable-download completion — unmeasurable, the path doesn't
      exist).
- [ ] 🟡 **Download ack doesn't close the loop** — `AckDownload`
      (`internal/api/downloadsvc/service.go:304`) validates token/checksum but never
      records success metrics, never marks the release installed in telemetry, never
      invalidates the token (so tokens aren't enforced single-use), and
      checksum-mismatch alerting is a TODO. Source: FR-012.
- [x] 🟡 **`ListPlugins`'s `SnapshotVersion` isn't spec-compliant** — FIXED
      2026-07-21 (`ut-cloud` PR #16). New shared `globalCatalogVersion()`
      computes the true max `updated_at` across ALL `plugin_listings`/
      `plugin_releases` (via `Order(ByUpdatedAt desc).First()`, indexed),
      used by both `ListPlugins` and `SnapshotWriter.Build` — a zero-result
      filtered page no longer gets a version that increments on every call.
      Two independent reviews caught and fixed along the way: a missing
      `updated_at` index on both tables (the new query would've full-scanned
      on every catalog read), and a clock-source mismatch where the offline
      snapshot writer's empty-catalog fallback always used real `time.Now()`
      while the live path used its injectable clock. Review:
      `ut-cloud/docs/code-reviews/2026-07-21-catalog-snapshot-version-chk008.md`.

### 🔌 universal-till — spec 009-cloud-marketplace + 010-complete-pending-specs
_(both specs describe the same underlying gaps — 010 was meant to close what 009 left
open, and didn't)_
- [ ] 🟡 **Dev-mode marketplace override has no validation/health-check/fallback** —
      setting `DevOverrideURL` routes traffic there unconditionally;
      `internal/plugins/marketplace/client.go` never checks `cfg.DevMode`, never
      validates scheme/host/port, never health-checks reachability, and has no
      fallback-to-cloud-on-timeout or self-signed-cert handling — the opposite of the
      spec'd safety net for a dev-only escape hatch. Source: 009 FR-015 (US6) / 010
      FR-004, FR-005 (T039-T041 unchecked, confirmed absent from code).
- [ ] 🟡 **No marketplace audit trail/filter UI, no permission or telemetry-opt-in
      badges** — `authorizer.go`'s `AuditLog()` only logs to stdout, never writes to
      the `audit_log` table; no `AuditRepo` exists; no page renders/filters an audit
      trail; `plugin_settings.html` has no telemetry opt-in toggle; `plugins_store.html`
      shows trust badges (official/verified/unverified) but not permission/
      manager-approval badges. Manager-PIN install gating itself does work
      (`authorizer.go` `requireManagerPIN`). Source: 009 FR-009 (US5) / 010 FR-006,
      FR-007, SC-002.
- [ ] 🟡 **Plugin marketplace telemetry never actually sends** — `TelemetryClient`
      (`internal/plugins/telemetry_client.go`) is fully built (Start/TrackInstall/
      TrackUpdate/TrackStatusUpdate/TrackBrowse) but has zero call sites — never
      instantiated. The scheduler's telemetry job is a literal stub:
      `internal/server/server.go:76-89` logs `"[Scheduler] telemetry job triggered
      (stub)"` with `// TODO: Implement telemetry reporting in T024`. Source: 009
      FR-013.
- [ ] 🟢 **Hardware (process-based) plugins have no boot-time auto-start** —
      `Supervisor.AutoStartPlugins()` (`internal/plugins/supervisor.go:292`, T023) is
      fully implemented but never called outside tests; only WASM plugins auto-start
      today (`Wasm.Sync()`). Doesn't affect any currently-shipped plugin (all WASM) but
      would block a future process-based hardware plugin from starting on boot.
      Source: 007-plugin-host.

### ❓ ut-plugin-faq — spec 001-multilingual-faq-page
- [ ] 🟡 **FAQ keyword search never built** — `contentBundle` in
      `universal-till/internal/pages/plugin_page.go` doesn't parse the `keywords`
      field at all, and `plugin_content.html` has only category accordions, no search
      input, despite tasks.md's T023 ("search/filter... >95% relevance") marked done.
      Source: FR-005, SC-003.
- [x] 🟡 **FAQ checksum field is always empty** — FIXED 2026-07-21. `ut-plugin-faq`
      (`9c9cc92`, v0.2.3): new `scripts/checksum.py` populates a real checksum for
      all 9 locale bundles via byte-level placeholder substitution (the field is
      self-referential, so it zeroes its own value to a same-length placeholder
      before hashing rather than canonicalizing JSON); wired into `validate.sh`
      so future edits can't drift. `universal-till` (PR #39, `3a87b05`):
      `loadContentBundle` now verifies it, refusing a mismatched bundle (falls
      through to the existing content fallback) rather than rendering possibly
      corrupted content; absent field = nothing to verify (back-compat). Cross-
      checked the Go and Python implementations against all 9 real bundles.
      Reviews: `ut-plugin-faq/docs/code-reviews/2026-07-21-content-checksum.md`,
      `universal-till/docs/code-reviews/2026-07-21-faq-content-checksum-verification.md`.
      REMAINING 🟢: on a checksum failure the till gives up rather than trying
      another candidate locale file the same plugin ships; **not yet tagged/
      released** on the FAQ plugin (v0.2.3 built and validated locally, tagging
      triggers a live marketplace publish — held back pending confirmation).
- [ ] 🟡 **FAQ e2e tests are boilerplate, not real coverage** —
      `tests/e2e/example.spec.ts` hits route `/faq` and posts to a nonexistent API;
      the actual registered route is `/plugin/faq` (per manifest.json). No locale/
      RTL/fallback/search test exists, despite T011-T013/T029-T032 marked done (T022
      "locale render tests LTR+RTL+fallback" is honestly left unchecked, consistent
      with this gap). Translations themselves are genuine (verified real Persian text
      in `fa-IR.json`, RTL flag set) — this is purely a test-coverage gap. Source:
      tasks.md T022, T029-T032.
- [ ] 🟢 **FAQ locale-fallback notice + version/last-updated metadata missing** —
      `loadContentBundle()` silently falls back to `en-US` with no signal reaching the
      template (no "shown in English" notice per US2 Acceptance Scenario 2);
      `version`/`last_updated` fields aren't parsed into `bundleView()` either, so
      staff can't see content recency. Source: spec.md edge cases, FR-007.

---

## ✅ Recently shipped (2026-07-16 → 17)

- [x] **Marketplace portal fix batch** (tasks 1–8 of the ordered queue, 2026-07-17
      evening): role trim, identity chip, one "My shop" back-office, real plugin detail
      page, working approvals, descriptions + icons, staff review sessions, developer
      console gating + API docs, per-surface auth enforcement completed (no anonymous
      writes anywhere; global flag left as designed for the fleet).
- [x] Help page **feature guide** (expandable per-feature explanations + steps, 4 locales)
- [x] Claim UX fixes: code **reuse** on repeat clicks; desktop webview **pinned to till**
      (external links open the browser) — v0.2.19
- [x] **Claim flow** both sides + back-office pages (My stores, per-store fleet detail,
      admin Stores directory, owner-scoped approvals)
- [x] Zitadel: granted owner account marketplace roles (⚠️ too broad — see Phase 0)
- [x] **On-screen keyboard** (touch tills, en/tr/fa/ar) — v0.2.17
- [x] **Stock-level sync** (primary-owned on-hand → replicas) + check-for-updates button
- [x] **Linux desktop app** + **Pi kiosk** packaging
- [x] **Windows desktop shell** (WebView2) — v0.2.14
- [x] **Catalog variant editor** redesign (per-item variants + barcodes)
- [x] Mac app **auto-update** + main-thread launch-crash fix
- [x] **Stripe Terminal** (card-present) + shared/per-till plugin settings
- [x] **Lazy store registration** (ADR-0015) + release pipeline hardening
