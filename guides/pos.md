# Using the POS (Universal Till)

The POS is the till application (`universal-till`). It runs offline-first: nothing
here requires the network except talking to the marketplace to get plugins.

## Starting the till

```bash
cd universal-till
go run .
```

The app serves a web UI and self-migrates its SQLite database on first start.
Open the printed local URL in a browser.

## Signing in

Operators sign in with a numeric PIN (see
[`../architecture/pos-auth.md`](../architecture/pos-auth.md)). On the very
first start the login screen asks you to choose the admin PIN. Manage
operators (add cashiers/managers, set PINs, deactivate) on the **Users**
page; the nav shows who is signed in plus a **Lock** button. Manager-gated
actions (e.g. negative-stock override) ask for a manager PIN when a cashier
is signed in. `UT_AUTH=off` disables login for dev tooling only.

## Day-to-day

- **Checkout** — build a sale, take payment, print/issue a receipt. Amounts are in
  minor units internally; the UI shows formatted currency.
- **Catalog** — products and prices.
- **Inventory** — stock levels.
- **Receipts / history** — past sales.
- **Settings** — store/device identity and the marketplace connection (see below).

## Connecting to the marketplace

Plugins come from the marketplace. Configure the connection via environment (see
the config keys in [`../for-developers.md`](../for-developers.md#pos-host-universal-till)):

- `UT_MARKETPLACE_ENDPOINT_URL` — the marketplace API base, **including `/api`**,
  e.g. `https://marketplace.home.taskrunnertech.co.uk/api`.
- `UT_MARKETPLACE_PUBLIC_KEY` — the marketplace signing public key, used to verify
  every plugin before it is installed.
- merchant / store / device identifiers, and an upload token used to report
  install state back to the marketplace.

## Installing a plugin

1. Browse available plugins (the till lists what the store is entitled to).
2. Install. The POS then:
   - requests a **download token**,
   - downloads the signed bundle,
   - **verifies the Ed25519 signature** against the marketplace public key,
   - checks compatibility (`device_arch`, `min_pos_version`) and the executable bit,
   - installs the files under the plugin directory and registers the plugin's
     entries.
3. The plugin's UI entry appears where its manifest says. For the sample FAQ
   plugin this is a **Help / FAQ** page under Help/Support.

If verification or compatibility fails, the install is rejected and the reason is
reported — a plugin is never run unless its signature is valid.

## Using an installed plugin

Installed plugins surface as pages/buttons/etc. per their manifest `entries`.
Open the FAQ plugin from the Help/Support menu to see localized help content
(`en-US`, `fr-FR`, `ar-SA`).

## Troubleshooting

- **Nothing to install / "not entitled"** — the store isn't entitled to the plugin
  in the marketplace; an operator must grant the entitlement.
- **Signature verification failed** — the configured `UT_MARKETPLACE_PUBLIC_KEY`
  doesn't match the key the marketplace signed with.
- **Can't reach marketplace** — checkout still works offline; only plugin
  install/update needs connectivity.
