---
stepsCompleted: [1]
inputDocuments: []
workflowType: 'research'
lastStep: 1
research_type: 'domain'
research_topic: 'Universal Till: tax/compliance complexity + globalization + GTM for free POS + paid cloud'
research_goals: 'Identify domain constraints for global rollout (VAT/sales tax patterns) and translate them into plugin-first requirements and monetization boundaries.'
user_name: 'Farshid'
date: '2025-12-17T10-42-42Z'
web_research_enabled: true
source_verification: true
---

# Domain Research: Tax/Compliance + Globalization + GTM (Free POS, Paid Cloud)

## Narrative Intro

“Global POS for all businesses” is an ambitious goal because taxes, fiscal compliance, and business workflows vary dramatically by jurisdiction and industry. Universal Till’s strategy—make local rules and integrations “plugins”—is the right abstraction. The key is to define the boundary between stable core workflows (sell, pay, receipt, inventory) and region/vertical-specific plugins (tax, fiscal devices, e-invoicing, accounting exports).

This document captures baseline domain realities and turns them into requirements and research follow-ups.

## Table of Contents

1. Tax landscape basics (VAT vs sales tax)
2. Why “tax as plugin” is structurally necessary
3. Compliance considerations that affect architecture
4. GTM implications for free core + paid cloud
5. Open questions / next research

## 1) Tax Landscape Basics (Baseline References)

### VAT/GST is used in most countries; the US is a major exception

- VAT is described as a consumption tax levied at each stage; Wikipedia notes broad global adoption and that the US does not use VAT at the federal level (Source: https://en.wikipedia.org/wiki/Value-added_tax).

### US sales taxes vary by jurisdiction

- US sales tax landscape is commonly described as varying by state and locality (baseline reference: https://en.wikipedia.org/wiki/Sales_taxes_in_the_United_States).

### Turkey tax landscape exists as a distinct system

- Baseline reference for Turkey taxation (Source: https://en.wikipedia.org/wiki/Taxation_in_Turkey).

Note: These are baseline references; production compliance requires official sources per target jurisdiction and vertical.

## 2) Why “Tax as a Plugin” is Structurally Necessary (Analysis)

Because:
- Rules differ by country/state/locality (VAT vs sales tax, exemptions, rounding).
- In many markets, fiscal devices/e-invoicing rules can constrain receipt formatting and transaction logging.
- Businesses need different defaults (restaurants vs retail vs services).

Therefore the core POS should expose stable hooks:
- Line-item tax calculation hook
- Receipt rendering hook
- Reporting/export hook (accounting)
- Audit/logging hook

## 3) Compliance Considerations That Affect Architecture (Requirements)

Minimum requirements for a global-first platform:
- Plugin permission model must allow “tax and compliance plugins” to access transaction context safely.
- Manifest needs to express region applicability (country codes, optionally subregions) and compatibility/versioning.
- Marketplace trust tiers must reflect compliance risk (e.g., “tax plugin” should never be “untrusted” by default for production merchants).

(Related security/update requirements: see technical research references TUF/SLSA/Sigstore/SBOM.)

## 4) GTM Implications for “Free Core + Paid Cloud”

Business logic:
- Free POS core lowers adoption friction and supports hardware-diverse installs.
- Paid cloud services should solve operational pain: multi-device sync, backups, multi-site management, analytics, remote fleet management, hosted marketplace endpoints.

Product packaging suggestion (to validate with market research):
- Core (free): offline-first POS, local back office, plugin host.
  - Marketplace access may be free but gated by trust tier rules.
- Cloud (paid): device/user management, managed sync, hosted marketplace, analytics, compliance reporting, backups.

## 5) Open Questions / Next Research

1. Define MVP jurisdictions for “first-class tax plugins” (even if global vision remains).
2. Identify compliance-heavy verticals to defer vs support in MVP.
3. Determine which cloud services are mandatory for plugin ecosystem health (e.g., telemetry, signing infrastructure).
4. Create a “tax plugin contract” spec: input fields, rounding rules, exemption handling, receipt hooks.
