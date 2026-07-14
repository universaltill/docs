# WASM host functions — plugin author reference

Since 2026-07-14 (`universal-till` host functions v2, spec in
`architecture/wasm-runtime.md`). Your `runtime: "wasm"` module can import
capabilities from host module **`ut`**. Every call is permission-checked
against your manifest at call time; denials return `-2` and are audited on
the till.

## Declaring permissions

```json
{
  "permissions": ["events:receive", "storage", "net:api.example.com"]
}
```

- `storage` — private key/value store on the till (key ≤ 128 B, value
  ≤ 64 KiB, ≤ 1024 keys). Survives events and updates; deleted on uninstall.
- `net:<host>` — outbound HTTP to exactly that hostname. HTTPS only, except
  plain `http` to `localhost`/`127.0.0.1` (e.g. a self-hosted Ollama on the
  till). Declare one permission per host you need; the merchant sees the
  list at install time. Holding any `net:` permission raises your event
  deadline from 2s to 10s.

## Buffer ABI

Calls that return data write `min(len, dstCap)` bytes into your buffer and
return the **full** length — if the return exceeds your capacity, call again
with a bigger buffer. Negative returns: `-1` not found, `-2` permission
denied, `-3` internal error, `-4` invalid input / over size caps.

## Go bindings (copy-paste)

```go
//go:build wasip1

package main

import "unsafe"

//go:wasmimport ut log_write
func utLogWrite(ptr, n uint32)

//go:wasmimport ut storage_get
func utStorageGet(kPtr, kLen, dstPtr, dstCap uint32) int32

//go:wasmimport ut storage_set
func utStorageSet(kPtr, kLen, vPtr, vLen uint32) int32

//go:wasmimport ut http_request
func utHTTPRequest(rPtr, rLen, dstPtr, dstCap uint32) int32

func ptrOf(b []byte) (uint32, uint32) {
    if len(b) == 0 {
        return 0, 0
    }
    return uint32(uintptr(unsafe.Pointer(&b[0]))), uint32(len(b))
}

// Log writes a line into the POS log, prefixed with your plugin id.
func Log(msg string) { p, n := ptrOf([]byte(msg)); utLogWrite(p, n) }

// StorageSet stores value under key (permission "storage").
func StorageSet(key string, value []byte) int32 {
    kp, kl := ptrOf([]byte(key))
    vp, vl := ptrOf(value)
    return utStorageSet(kp, kl, vp, vl)
}

// StorageGet reads a key; nil + code on failure (-1 = not found).
func StorageGet(key string) ([]byte, int32) {
    kp, kl := ptrOf([]byte(key))
    buf := make([]byte, 64*1024)
    bp, bc := ptrOf(buf)
    n := utStorageGet(kp, kl, bp, bc)
    if n < 0 {
        return nil, n
    }
    return buf[:n], n
}
```

## HTTP request/response shape

Request JSON → `http_request`; response JSON comes back in your buffer
(body capped at 256 KiB):

```json
{ "method": "POST", "url": "https://api.example.com/v1/x",
  "headers": {"Content-Type": "application/json"},
  "body_b64": "<base64 of the request body>" }
```

```json
{ "status": 200, "headers": {"Content-Type": "application/json"},
  "body_b64": "<base64 of the response body>" }
```

The call runs under your event deadline — don't chain many round-trips in
one event. Working end-to-end example: `universal-till`
`internal/plugins/testdata/hostfn_guest/main.go`.
