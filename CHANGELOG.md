# StableMaster — Change Log

Period covered: **Saturday 11 April 2026 → Tuesday 21 April 2026**

> Note: No work was committed on 11–12 April. The first changes in this window landed on Monday 13 April.

---

## Monday 13 April 2026

- Added filters to the **Current Agreements** page and improved the billing-quantity input.
- Reworked the billing-element creation flow to show a running list as items are added (faster bulk entry).

## Tuesday 14 April 2026

- Replaced the horse **Size** field with **Passport Number** across all forms and data displays.
- Allowed **decimal quantities** when saving billing elements.
- Fixed a server error by ensuring quantity is always sent as a string (matches the numeric DB column type).
- Standardised how horse names are displayed everywhere in the app (no more duplicated "Stable Name (Passport Name)" text).

## Wednesday 15 April 2026

- **Creator tracking on billing elements**: each new charge now records the user who created it, and you can filter the list by creator.
- **Invoice Validation V2 — Pre-Generation Approvals**: invoice generation now requires the Vet and Stores sign-offs *before* the invoice is created. Approval buttons were also relabelled and approved customers are hidden from the to-invoice list.
- Fixed a horse-name duplication bug in some grids.
- Updated validation status button labels for clarity.
- Excluded ADEC's own customers and horses from livery reports.
- Restricted **horse import** to administrators only; allowed **LIVERY_ADMIN** to create and manage horses directly.

## Thursday 16 April 2026

- Preserved the original **transaction date** when batch-saving billing elements (no more being overwritten to today).

## Monday 20 April 2026

### Task #14 — Transactional Invoice Creation + Redesigned PDF
- Invoice creation is now **fully transactional**: if any line item fails, the whole invoice rolls back (no more orphan empty invoices).
- The Sales Order / NetSuite endpoints now refuse to push a zero-line-item invoice.
- Invoices show a **"No line items — regenerate"** badge on any APPROVED/PUSHED orphan rows.
- The invoice PDF was rewritten end-to-end:
  - Defensive against null/missing fields.
  - Async logo loading with proper aspect-ratio handling.
  - Empty-items fallback row instead of crashing.
  - Grey bands replace red bands on the Total Amount card and final totals.
  - Removed the Unit column.
  - Final columns: `# / Ln.Description / Horse / Bill Date / Qty / Amount / Vat Amount / Net Amount`.
- PDF layout polish:
  - Logo repositioned with the issuer address stacked below it (TRN added).
  - Footer expanded with a bank-details column (ADCB IBAN, Account Number, SWIFT, Branch).
  - Logo swapped to the new ADEC artwork; sized using natural image properties so it never stretches.
- Improved error messaging when generating a Sales Order: missing-NetSuite-ID errors now name the specific horse(s) and de-duplicate the same horse appearing on multiple lines.

## Tuesday 21 April 2026

### UX improvements

- **Edit Horse** dialog: status field is now a binary dropdown (Active / Inactive) instead of a free-text input.
- **Horses page**: added a *Display inactives* toggle (off by default) so the list shows only active horses unless you choose otherwise.
- **Edit Horse** dialog: added editable **Stable Name** (the horse's working name) and **Passport Name** (formal/registered name) fields.

### Security hardening (two security scans, 16 findings — all merged)

#### From the first scan
- **Auth bootstrap (#18)**: the admin user is no longer reset on every server restart. In production the seed refuses to run unless an explicit password is supplied; in development a clear warning is printed when the default is used.
- **Logging (#19)**: removed the request/response-body logging that was leaking sensitive data (n8n webhook URLs, NetSuite RESTlet responses, internal IDs).
- **Server authorisation (#20)**: added explicit role checks across many write endpoints (agreement documents upload/delete, n8n webhook GET, customer/stable/box/item master-data writes, horse + horse-ownership writes). Non-finance/non-admin users no longer see ERP fields (`netsuiteId`, `poNumber`, `netsuiteJson`, etc.) on the invoice list.
- **Dependencies (#21)**: pinned `dompurify` to 3.4.0 to close a moderate-severity vulnerability that was reachable through `jspdf`.

#### From the second scan
- **Agreement document access (#23)**: read endpoints (list + download) are now restricted to ADMIN/LIVERY_ADMIN, matching the existing upload/delete protection. UI hides the menu entry for other roles.
- **Billing master-data writes (#24)**: item updates, item-price changes, and ad-hoc billing element create/update/delete are now LIVERY_ADMIN-only. Sidebar entry hidden from other roles; "Add" and "Change Price" buttons hidden in the UI.
- **Horse movement integrity (#25)**: `POST /api/horse-movements` now verifies the agreement exists, the box matches the agreement, and the horse is owned by the agreement's customer. `PATCH` is locked to checkout-only with date validation and prevents reopening of historical movements.
- **Invoice workflow (#26)**:
  - Detail endpoint redacts ERP fields for non-finance roles (matching the list endpoint).
  - DB-level uniqueness constraint on `(customer_id, billing_month)` prevents concurrent duplicate invoices.
  - Server now derives `horseId`, `boxId`, `itemId`, `price`, and `billingMonth` from the database — client values are ignored.
  - Agreement validity (start/end dates, status, no duplicates) is enforced server-side.
  - Ad-hoc billing elements are verified to belong to the same customer and to be unbilled before linking.
  - `totalAmount` is computed server-side from line items.
  - `POST /api/invoices` is restricted to LIVERY_ADMIN.
- **SSO account linking (#27)**:
  - Unknown/missing SSO roles are now rejected (was previously falling open to LIVERY_ADMIN).
  - SSO accounts are linked by external subject id (`sso_id`), not by username — closing an account-takeover path against the local admin.
  - Unique-constraint conflicts during SSO provisioning are caught and logged with a diagnostic error code.

### Data linkage

- **Backfilled `billing_elements.user_id` from audit logs.** The startup migration now always (idempotently) joins `audit_logs` to fill in the creator on any billing element where it's still missing. On the next production deploy, all 42 historical billing elements will be linked back to the user who created them.

---

## Deployments published in this window

- 13 April 2026
- 14 April 2026 (×3)
- 20 April 2026
- 21 April 2026 (×2)
