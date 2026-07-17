# Vendor self-serve registration (design, 2026-07-17)

Status: **proposal — build next**. Today a developer needs a manually-granted
Zitadel vendor role (`vendor_maintainer`) before the developer console opens
(requireVendorViewer). Farshid's ask: the console should be for *registered
developers* — which needs a registration path.

## Flow

1. **Request**: a signed-in user (any role) hitting /ui/vendor gets, instead
   of a bare 403, a "Become a developer" page: name/company, contact email,
   what they plan to build. POST stores a `vendor_request` row (new ent
   entity: subject, name, email, pitch, status=pending, timestamps).
2. **Review**: marketplace admins see pending requests on a new
   /ui/admin/vendors page (behind requireAdminViewer) with Approve / Reject.
3. **Grant**: on approve, the marketplace calls the Zitadel management API
   (`users/{id}/grants` add or update `vendor_maintainer` on the marketplace
   project) using a **service credential**. On success the request flips to
   approved; the user gets console access at next sign-in (roles ride the
   id_token).

## The service credential (the real design decision)

The mp needs a Zitadel machine-user PAT with user-grant write on the
marketplace project. Source it like other secrets:
- IaC: a dedicated `marketplace-grants` machine user + PAT in the zitadel
  terraform module (NOT the all-powerful `automation` user — least
  privilege: Org User Grant Manager role only).
- Delivery: PAT → Azure Key Vault (`zitadel-grants-pat`) → k8s secret →
  mp env `ZITADEL_GRANTS_PAT` (+ endpoint config). Feature off when unset
  (self-host stays manual).

## Notes
- Approval is idempotent; rejecting stores a reason shown to the requester.
- Audit both decisions (existing audit event table).
- Vendor org linkage (which VendorOrganization the new developer belongs
  to) starts simple: create/attach an org named from the request; refine
  later.
- Email notifications ride the existing multilingual-email rule when the
  notification system lands; until then the requester sees status on the
  request page.
