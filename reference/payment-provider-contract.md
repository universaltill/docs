# Payment-provider contract (payment plugins)

The POS-side realization of ADR-0016's `PaymentProvider` interface, mapped to
the WASM plugin world. A payment provider is a **`payment`-type plugin**; the
POS builds its tender UI and payment flow entirely from this contract, so every
provider — Stripe, a bank, QR pay, a demo terminal — plugs in the same way
(one button per enabled provider; ADR-0016 §2a manual mode).

## Manifest

```jsonc
"canonical_type": "payment",
"permissions": ["events:receive", "net:<api-host>", "storage"],
"entries": [{
  "type": "payment",
  "key": "stripe",              // method id — becomes the tender button
  "label": "Card (Stripe)",     // button label
  "sort_order": 4,
  "trigger_event": "payment.stripe.requested"
}],
"settings": [
  {"key": "…_secret_key", "scope": "global"},   // shop-wide (LAN-synced)
  {"key": "…_reader_id",  "scope": "register"}  // per till
],
"hooks": [
  {"event": "payment.stripe.authorize", "action": "….authorize"},
  {"event": "payment.stripe.requested", "action": "….settled"},
  {"event": "payment.stripe.refund",    "action": "….refund"}
]
```

Each active payment entry is synced into `payment_methods`
(`SyncPluginPaymentMethods`) and rendered as a tender button/select option.
Disabling or uninstalling the plugin deactivates the method (history rows
keep it referenced).

## Events (all payloads JSON on stdin; exit 0 = success, non-zero = decline)

| Event | Mode | When | Payload | Meaning |
|---|---|---|---|---|
| `payment.<key>.authorize` | **blocking** | before the sale completes | `method, amount (minor), reference, plugin_id` | Charge/authorize. Non-zero exit declines the tender; the basket is kept. |
| `payment.<key>.requested` | async | after the sale is recorded | `sale_id, method, amount, reference, plugin_id` | Settle notification. Providers should persist `sale_id → provider charge id` (plugin `storage_*`) so refunds can find the money. Failures never affect the sale. |
| `payment.<key>.refund` | **blocking** | before a return is recorded for this method | `method, amount (minor), currency, original_sale_id, original_receipt, plugin_id` | Send the money back on the original charge. Non-zero exit **stops the refund** ("provider refund failed"). Cash / hook-less methods are never gated. |

`amount` is always integer **minor units** (ADR-0004). Partial refunds are
expressed by `amount` < the original charge.

## Provider state

Plugins hold their own state via the `storage_get` / `storage_set` host
functions (per-plugin KV). Convention (as implemented by the Stripe plugin):
`last_txn` = last authorize outcome; `sale_pi:<sale_id>` = provider charge id,
written on the `.requested` event. This is what makes refunds work without any
bus-return channel.

## Host functions available

`log_write`, `settings_get`, `storage_get`, `storage_set`, `http_request`
(gated by `net:<host>` permission). The marketplace scanner allowlists exactly
these — importing anything else fails validation.

## Reference implementation

`ut-plugin-payment-stripe` v1.2.0 implements all three legs (online +
Stripe Terminal card-present authorize, settle-link, partial refunds) and is
the template for new providers (iyzico, bank gateways, …): swap the API host,
auth and request shaping.

## Future (ADR-0016 phases C2/D)

`quoteCost`/`supports` (cost hints for manual mode, automatic routing) are
cloud/router concerns layered on top; they do not change this plugin contract.
