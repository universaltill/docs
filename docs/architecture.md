# Universal Till – System Architecture & Design Blueprint

## 1. Overview
Universal Till is a **free, open-source, plugin-based, offline-first POS system** designed to run on:
- Raspberry Pi
- Low-cost tills (Chinese OEM devices)
- Local networks without internet
- Cloud or hybrid mode

It includes:
1. POS App  
2. Back Office App  
3. App Store  
4. Optional Cloud Core Services  

POS and Back Office are **plugin-based**, and the system can operate:
- As a **single machine**
- Over a **local network**
- Or in **hybrid cloud mode**

---

## 2. High-Level Architecture

```
+-------------------------------------------------------------+
|                    Universal Till Platform                  |
|          Free • Plugin-Based • Offline-First POS            |
+-------------------------+----------------+------------------+
                          |                |
                   +------+-----+    +-----+------+
                   | Cloud Core |    | App Store  |
                   | (Optional) |    | Marketplace|
                   +------+-----+    +------------+
                          |
          ----------------+------------------------
          |                                      |
+---------+----------+                 +----------+---------+
|     POS App        |                 |   Back Office App  |
|  (Till UI, Plugins)|                 |   (Mgmt UI, Plugins)|
+--------------------+                 +---------------------+
```

---

## 3. Deployment Modes

### 3.1 Single Device Mode (Standalone)
Everything runs on one device:

```
+-------------------------------------------+
| POS App (8080)                            |
| Back Office (9090)                        |
| SQLite/Postgres                           |
| Local Plugin Repo                         |
+-------------------------------------------+
```

### 3.2 Local Network Mode (LAN Only)
Back Office runs as a local server:

```
           +----------------------+
           | Back Office Server   |
           +----------+-----------+
                      |
     -----------------+-------------------------
     |               |                         |
+----+-----+   +-----+-----+           +--------+----+
| POS 1    |   | POS 2     |           | POS 3       |
+----------+   +-----------+           +-------------+
```

### 3.3 Hybrid / Cloud Mode
```
POS <--> Local Back Office <--> Cloud Services (optional)
```

---

## 4. POS Architecture

```
+------------------------------+
|           POS UI             |
|   (HTML/HTMX, themable)      |
+--------------+---------------+
               |
               v
           Edge Server (Go)
               |
               v
       +-----------------------+
       |       POS Engine      |
       +-----------+-----------+
                   |
         +---------+----------+
         | Plugin Runtime     |
         +---------+----------+
                   |
          +--------+----------+
          | Hardware Drivers  |
          +-------------------+
```

**Key features:**
- Offline-first  
- Plugins control payments, UI, workflows, hardware  
- Local SQLite database  
- Ultra-light (<30MB RAM)

---

## 5. Back Office Architecture

```
+------------------------------------------------+
|             Back Office (Go + Web UI)          |
|  - Product & price management                  |
|  - Device management                           |
|  - Sales reports                               |
|  - Plugin management                           |
|  - Plugin configuration                        |
+------------------------------------------------+
```

Runs locally (single box / LAN) or in cloud.

---

## 6. App Store Architecture (Marketplace)

```
+-------------------+       +-----------------------+
| App Store UI      | <---> | Marketplace API       |
+-------------------+       +-----------------------+
                                 |
                                 v
                        +------------------------+
                        | Plugin Registry        |
                        | (Bundles, Manifests)   |
                        +------------------------+
```

### Features:
- Browse/search plugins  
- Developer portal  
- Upload bundles  
- Automated validation  
- Free or paid plugins  
- Revenue sharing  

---

## 7. Unified API (Local or Cloud)

POS expects identical APIs whether talking to:
- Local Back Office  
- Cloud  
- Hybrid environment  

### Core endpoints:
```
GET  /api/v1/config
GET  /api/v1/products
GET  /api/v1/plugins
POST /api/v1/sales/batch
GET  /api/v1/devices/:id
```

---

## 8. Plugin Architecture

### Supported Plugin Types:
| Type | Runs On | Examples |
|------|---------|----------|
| POS UI | POS | custom screen, workflows |
| POS Service | POS | PSP integration |
| Hardware Driver | POS | printer, scanner, scale |
| Back Office UI | Back Office | settings pages |
| Back Office Service | Back Office | ERP sync |

---

## 8.1 Plugin Manifest Example

```yaml
id: com.example.psp.stripe
name: Stripe Payments
version: 1.0.0

entrypoints:
  pos-service:
    command: ["./stripe-pos"]
  backoffice-ui:
    url: "/plugin/stripe"

permissions:
  pos:
    - read_basket
    - open_payment_session

config_schema:
  properties:
    apiKey: { type: string }
  required: ["apiKey"]

billing:
  model: subscription
  price_per_month: 9.99
```

---

## 8.2 POS Plugin gRPC API

```proto
service PosPlugin {
  rpc OnBasketEvent(BasketEvent) returns (BasketUpdate);
  rpc OnPaymentRequest(PaymentRequest) returns (PaymentResponse);
}
```

---

## 9. Multi-Device Sync Architecture

Universal Till uses **local-first with optional cloud sync**.

### POS → Back Office Sync
```
POST /api/v1/sales/batch
```

### Back Office → POS Sync
```
GET /api/v1/config
GET /api/v1/products
GET /api/v1/plugins
```

### Cloud-enabled adds:
- Multi-site sync  
- Central reporting  
- Backups  
- Remote access  

---

## 10. Local-First Configuration Files

### POS Config

```yaml
device_id: POS-001
tenant_id: LOCAL
mode: local
backoffice_url: http://localhost:9090
cloud_url: ""
plugins_dir: /var/lib/universaltill/plugins
database_path: /var/lib/universaltill/local.db
```

### Back Office Config

```yaml
mode: local
db_url: postgres://...
cloud_url: ""
app_store_url: ""
```

---

## 11. Development Roadmap

### Phase 1 – MVP
- POS
- Back Office (local)
- Local product management
- One POS plugin
- Plugin runtime
- Offline-first

### Phase 2 – LAN Mode
- Multi-device sync
- Device registration

### Phase 3 – App Store
- Developer portal
- Plugin publishing
- Local plugin mirror

### Phase 4 – Cloud
- Multi-site sync
- Global analytics
- Billing + subscriptions

---

## 12. Summary

Universal Till provides:
- Free POS  
- Plugin ecosystem  
- Local or cloud mode  
- Hardware-agnostic  
- Developer marketplace  
- Offline capabilities  
- Optional cloud enhancements  

It is designed to outperform both commercial and open-source POS systems through:
- Zero lock-in  
- Local-first independence  
- Plugin-driven extensibility  
- Open-source community  

---

# End of Document
