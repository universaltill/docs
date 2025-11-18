# Universal Till – Documentation

Welcome to the official documentation repository for the Universal Till project — a free, open-source, plugin-based, offline-first POS platform designed for global use.

Universal Till supports:
- Raspberry Pi & low-cost tills
- Full offline mode
- Local network (LAN) deployments
- Optional cloud sync
- Plugin-driven extensibility
- Hardware-agnostic integrations
- A global marketplace for apps & add-ons

This documentation explains how to understand, build, and extend Universal Till.

## 📚 Documentation Structure

docs/
  architecture.md        → System architecture & blueprint
  pos/                   → POS app documentation
  backoffice/            → Back Office docs
  plugins/               → Plugin SDK, API, publishing
  marketplace/           → App Store documentation
  cloud/                 → Cloud sync & multi-site services
  developers/            → Onboarding, setup guides

## 🧠 Start Here

Begin with:

👉 docs/architecture.md

It covers:
- Deployment modes
- POS + Back Office separation
- Plugin system
- App Store design
- Local-first philosophy
- Sync model
- Roadmap

## 🛠 Key Components

POS App
- Go runtime
- HTML/HTMX UI
- Local storage
- Plugin-driven

Back Office
- Product & price management
- Device setup
- Reporting
- Plugin management
- LAN or cloud

App Store
- Developer uploads
- Free & paid plugins
- Validation and versioning

Cloud Core (Optional)
- Sync
- Multi-site
- Analytics
- Backups
- Billing

## 🔌 Plugin Architecture

Types:
- POS UI plugins
- POS service plugins
- Hardware drivers
- Back Office UI plugins
- Back Office service integrations

Example plugin manifest (YAML simplified):

id: com.example.psp.stripe
name: Stripe Payments
version: 1.0.0
entrypoints:
  pos-service:
    command: ["./stripe-pos"]
permissions:
  pos:
    - read_basket
config_schema:
  apiKey: string
billing:
  model: subscription

## 🔄 Sync Model

POS to Back Office:
- Sends sales

Back Office to POS:
- Sends products, config, plugins

Cloud mode adds:
- Multi-branch sync
- Global plugin store
- Analytics
- Remote management

## 🤝 Contributing

1. Fork the repo
2. Create a branch
3. Update documentation
4. Submit a pull request

## License

MIT License

