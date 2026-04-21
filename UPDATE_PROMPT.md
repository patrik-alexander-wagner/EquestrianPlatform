# Prompt — Bring StableMaster Up To Date (changes from 13 Apr → 21 Apr 2026)

Copy everything below the `---` line into your other project's chat to apply all of these changes.

---

You are working on **StableMaster** — a horse stable livery management system (React/TypeScript + Express/Node.js + PostgreSQL) for Abu Dhabi Equestrian Club. It manages horses, customers, livery agreements, billing elements, invoices, and box occupancy with role-based access (ADMIN, LIVERY_ADMIN, VETERINARY, STORES, FINANCE).

Apply **every** change in this prompt. Do not skip any. After all edits, restart the server, run a full e2e test of the invoice flow, and run a security scan.

---

## 1. Schema additions (`shared/schema.ts`)

1. **horses table** — replace any `size` column with `passportNumber: text("passport_number")`. Update related forms, imports, and table columns to use Passport Number instead of Size.
2. **billing_elements table** — add `userId: uuid("user_id").references(() => users.id)` so we can record who created each charge.
3. **invoices table** — add a unique constraint on `(customerId, billingMonth)`:
   ```ts
   }, (table) => ({
     uniqueCustomerMonth: unique("invoices_customer_month_unique").on(table.customerId, table.billingMonth),
   }));
   ```
4. **users table** — add `ssoId: text("sso_id")` (nullable, unique) for linking SSO identities by external subject id.

## 2. Migrations (`server/migrate.ts`)

The migration runs at startup, behind an advisory lock. Make sure each block is **idempotent** (column-exists / index-exists checks) so it's safe to run repeatedly.

- Add `user_id` UUID column on `billing_elements` with FK to `users(id)` if missing.
- After ensuring the column exists, **always** run an idempotent backfill:
  ```sql
  UPDATE billing_elements be
  SET user_id = sub.user_uuid
  FROM (
    SELECT DISTINCT ON (al.entity_id)
      al.entity_id AS be_id,
      al.user_id::uuid AS user_uuid
    FROM audit_logs al
    WHERE al.entity_type = 'billing_element'
      AND al.action = 'create_billing_element'
      AND al.user_id IS NOT NULL
      AND al.user_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    ORDER BY al.entity_id, al.created_at ASC
  ) AS sub
  WHERE be.id::text = sub.be_id AND be.user_id IS NULL;
  ```
- Add `sso_id TEXT` to `users` plus a partial unique index `WHERE sso_id IS NOT NULL` if missing.
- Add the `(customer_id, billing_month)` unique index on `invoices` if missing.
- Place backfill steps **before** any "skip migration" early-return so they run on already-migrated databases.

## 3. Auth & bootstrap (`server/seed.ts`)

- `ensureAdminUser()` must **only create** an admin if no admin user exists. Never reset password or role on existing admins.
- In `NODE_ENV=production`, refuse to create the admin if `SEED_ADMIN_PASSWORD` is unset; log an error and skip.
- In development, fall back to `admin123` but print a prominent warning.

## 4. Logging hygiene (`server/index.ts`, `server/routes.ts`)

- Strip the response-body capture from the global `/api` request logger. Log only method, path, status, and duration — **no response body**.
- Remove all `console.log` calls in the NetSuite send-to-netsuite handler that print the raw RESTlet response, response keys, or extracted netsuiteId. Keep the ID-extraction logic.

## 5. Server authorisation (`server/routes.ts`)

Add explicit role guards. `requireAdmin` = ADMIN only. `requireRoles("LIVERY_ADMIN")` = ADMIN + LIVERY_ADMIN.

- `POST /api/livery-agreements/:id/documents` → `requireRoles("LIVERY_ADMIN")`
- `DELETE /api/agreement-documents/:id` → `requireRoles("LIVERY_ADMIN")`
- `GET /api/livery-agreements/:id/documents` → `requireRoles("LIVERY_ADMIN")`
- `GET /api/agreement-documents/:id/download` → `requireRoles("LIVERY_ADMIN")`
- `GET /api/settings/n8n-webhook` → `requireAdmin`
- `POST /api/customers`, `POST /api/customers/import` → `requireAdmin`
- `POST /api/stables`, `PATCH /api/stables/:id` → `requireAdmin`
- `POST /api/boxes`, `PATCH /api/boxes/:id`, `POST /api/boxes/import` → `requireAdmin`
- `POST /api/items/import` → `requireAdmin`
- `PATCH /api/items/:id`, `POST /api/items/:id/change-price` → `requireRoles("LIVERY_ADMIN")`
- `POST /api/horses`, `PATCH /api/horses/:id` → `requireRoles("LIVERY_ADMIN")`
- `POST /api/horses/import` → `requireAdmin`
- `POST /api/horse-ownership` → `requireRoles("LIVERY_ADMIN")`
- `POST /api/billing-elements`, `PATCH /api/billing-elements/:id`, `DELETE /api/billing-elements/:id` → `requireRoles("LIVERY_ADMIN")`
- `POST /api/invoices` → `requireRoles("LIVERY_ADMIN")`

### ERP-field redaction
- `GET /api/invoices` and `GET /api/invoices/:id/details` must strip `netsuiteJson`, `netsuiteId`, `poNumber`, `soGenerated`, `sentToNetsuite`, and the customer's NetSuite ID for any user who is **not** ADMIN or FINANCE.

## 6. Horse-movement integrity (`server/routes.ts`)

- `POST /api/horse-movements`:
  - Verify the agreement exists.
  - Verify `agreement.boxId === request.stableboxId`.
  - Verify the horse is owned by the agreement's customer (`getHorseOwnershipByHorseId`).
- `PATCH /api/horse-movements/:id`:
  - Accept **only** `checkOut`. Reject any other field.
  - `checkOut` must match `YYYY-MM-DD`.
  - Movement must currently be active (no existing `checkOut`).
  - `checkOut >= checkIn`.

## 7. Invoice creation hardening (`server/routes.ts`)

The `POST /api/invoices` handler must **not trust client values** for line items.

- Wrap the create + line-item insertion in a single DB transaction (`createInvoiceWithLineItems`) — rollback on any failure.
- For each agreement-based line item:
  - Re-fetch the agreement from the DB; take `boxId`, `itemId`, and `monthlyAmount` from the DB record.
  - Derive `horseId` from `getActiveMovementByBoxId(agreement.boxId)`.
  - Force `billingMonth` to match the request body.
  - Reject if `agreement.startDate` doesn't cover the billing month or `agreement.endDate` is before it.
  - Reject if `agreement.status` is not `active` or `ended`.
  - Reject duplicate `agreementId` entries within the same request.
- For ad-hoc billing elements: re-fetch from DB, verify customer ownership, verify they are unbilled and not already on an invoice.
- Compute `totalAmount` server-side as the sum of line items; ignore any client-supplied total.
- Catch Postgres `error.code === '23505'` (unique_violation on `invoices_customer_month_unique`) and return a clear 400.
- On the SO/NetSuite endpoints, refuse to push when line-item count is zero.
- Return `lineItemCount` from the invoices list endpoint so the UI can show a "No line items — regenerate" badge for orphan APPROVED/PUSHED invoices.

## 8. SSO security (`server/routes.ts`, `server/storage.ts`)

- Role mapping must be explicit. If the incoming SSO role is missing or not in the allowlist, redirect to `/login?error=sso_role_unknown` and log a warning. Remove any `|| "LIVERY_ADMIN"` fallback.
- Account linking must use the external subject id stored as `sso_id`, **never** by username. Add `getUserBySsoId` to storage and use it as the only lookup.
- During provisioning, wrap `createUser` in try/catch; on Postgres `23505` redirect to `/login?error=sso_username_conflict` with diagnostic context. Re-throw other errors.

## 9. Dependency fix

- Add `dompurify` as a direct dep at `^3.4.0` (transitive via `jspdf` was on a vulnerable 3.3.x range). Use the package management tool — do not edit `package.json` by hand.

## 10. Pre-generation invoice approvals (Invoice Validation V2)

- Add a `monthly_billing_approvals` table: `(id, customer_id, billing_month, step ['VET' | 'STORES'], user_id, approved BOOL, created_at, updated_at)`, unique on `(customer_id, billing_month, step)`.
- Add endpoints `GET/POST /api/monthly-billing-approvals`.
- The to-invoice list must require both VET and STORES approvals before the LIVERY_ADMIN can generate the invoice.
- Hide already-approved customers from the to-invoice list once the invoice is generated.
- Update approval button labels for clarity ("Approve as Vet", "Approve as Stores", etc.).

## 11. Reports

- Exclude ADEC's own customers and horses from all livery reports.

## 12. Billing-element UX

- Record the creator (`user_id`) on every newly created billing element.
- Allow filtering the billing-elements list by creator.
- Allow **decimal** quantities. Always send quantity to the server as a **string** (numeric Postgres column).
- Preserve the user-entered `transactionDate` when batch-saving (do not overwrite to today).
- Show a running list of items as the user adds them in the create dialog.
- Hide the "Add" billing element button and "Change Price" button for non-LIVERY_ADMIN users.

## 13. Horse pages (`client/src/pages/horses.tsx`)

- Replace the Status text input in the **Edit Horse** dialog with a `Select` containing exactly two options: **Active** / **Inactive**. Default to `active` if status is anything else.
- Add a *Display inactives* toggle (switch) next to the existing search filters. Default `false`. When `false`, hide horses whose status is `inactive` (client-side filter).
- In the Edit Horse dialog, expose two name fields: **Stable Name** (the existing `horseName` field, relabel only) and **Passport Name** (`passportName`, was previously not editable). Send both on PATCH.
- Standardise horse name display across the app — never render "Stable (Passport)" twice in the same string.

## 14. Current Agreements page

- Add filters for customer / horse / status.
- Hide the documents menu entry for users without ADMIN or LIVERY_ADMIN roles.

## 15. Sidebar (`client/src/components/app-sidebar.tsx`)

- Mark the Billing Elements entry as `liveryAdminOnly` so only ADMIN/LIVERY_ADMIN see it.

## 16. Invoice PDF (`client/src/lib/invoice-pdf.ts`)

Rebuild the PDF generator with these properties:
- Defensive against null/undefined fields everywhere.
- Logo loaded async via `loadLogoDataUrl()`. Use the new ADEC logo at `@assets/image_1776675363121.png`. Compute width/height from `doc.getImageProperties(logo)` so the aspect ratio is preserved (target width ≈ 50mm).
- Issuer address stacked **below** the logo, including: `United Arab Emirates`, `Al Mushrif West, Abu Dhabi`, `PO Box 590, Abu Dhabi UAE`, `TRN: 100259446100003`.
- Total Amount card uses a grey band (not red).
- Final totals row also uses a grey band.
- Remove the Unit column. Final columns are: `# / Ln.Description / Horse / Bill Date / Qty / Amount / Vat Amount / Net Amount`.
- If the invoice has no line items, render a single empty placeholder row (don't crash).
- Footer:
  - Left column: ADEC name + address.
  - Middle column: Tel / Fax / website.
  - Right column (new): bank details — `BankName: Abu Dhabi Commercial Bank`, `IBAN: AE630030000131122020002`, `Account Number : 131122020002`, `BIC / SWIFT : ADCBAEAAXXX`, `Branch Name : 105 / AL SALAM STREET`.

## 17. SO generation error messages (`server/routes.ts` + `server/storage.ts`)

- `getInvoiceDetailsForSO` must include each line item's `horseName` (from the horses table).
- `POST /api/invoices/:id/generate-so`: when items or horses are missing NetSuite IDs, return one message per **unique** missing item description and one per **unique** missing horse, naming the horse by name (not by id).

## 18. Invoices page (`client/src/pages/invoices.tsx`)

- Show a "No line items — regenerate" badge on APPROVED/PUSHED invoices whose `lineItemCount === 0`.
- Hide the JSON download button for non-ADMIN/non-FINANCE users.
- Use `poNumber` for display where present, falling back to invoice id.

---

## Verification

After applying all changes:
1. Restart the workflow.
2. Log in as `admin / admin123` and verify:
   - Editing a horse shows binary status, Stable Name, Passport Name.
   - Horses page shows the *Display inactives* toggle (off by default).
   - Generating an invoice for a customer with un-synced horses shows clear per-horse missing-NetSuite-ID errors.
   - The invoice PDF renders the new logo at correct proportions, with TRN and bank details.
   - The invoice flow blocks invoice generation until VET + STORES are approved for the customer/month.
3. Run a security scan and confirm zero new findings in the categories above.
4. Confirm migration logs show the billing-element backfill ran with the expected row count.

Apply the changes; do not ask for confirmation.
