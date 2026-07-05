# Threat Model

## Project Overview

StableMaster is a production Express + React + PostgreSQL application for managing customers, horses, stables, livery agreements, billing elements, invoices, and NetSuite ERP synchronization. The primary users are authenticated staff with differentiated roles (`ADMIN`, `LIVERY_ADMIN`, `VETERINARY`, `STORES`, `FINANCE`). Production traffic is served by `server/index.ts` and `server/routes.ts`; the browser is untrusted and all authorization decisions must be enforced server-side.

As of Phase 1, the application also serves a Riding School domain (lesson scheduling, bookings, packages — `server/modules/riding-school/*`) and a **Customer Portal** (`server/modules/customer-portal/*`, `client/src/pages/portal/*`): a new, genuinely self-service trust boundary where authenticated non-staff account holders (`users.accountType = "CUSTOMER"`) manage their own family's bookings, riders, and package purchases directly, with no staff review step. This is a materially different threat surface from the rest of the app — every prior user of this system was staff, vetted and provisioned by an admin; customer accounts are provisioned once but then self-serve without further staff oversight per action.

Production assumptions for future scans:
- `NODE_ENV` is `production` in deployed environments.
- Replit deployment terminates TLS for client-to-server traffic.
- Mockup/sandbox-only paths are not production unless production reachability is demonstrated.

## Assets

- **Staff accounts and sessions** — authenticated sessions grant access to billing, customer, and operational records. Compromise allows impersonation and workflow abuse.
- **Customer and horse records** — names, contact details, passport information, box assignments, movement history, and agreement data are operationally sensitive and may contain personal data.
- **Billing and invoice data** — billing elements, invoice totals, approvals, NetSuite payloads, and purchase order numbers directly affect revenue recognition and ERP state.
- **Agreement documents** — uploaded PDF agreements are sensitive contractual records.
- **Application secrets and integration credentials** — `SESSION_SECRET`, database credentials, and `NETSUITE_*` secrets can enable account takeover, data access, or ERP abuse.
- **Audit history** — audit logs are relied on to reconstruct privileged or financially sensitive actions.
- **Rider and family-account data** — a customer's riders (including minors) and their booking history are personal data belonging to a family unit; the master account can act on behalf of every rider under it, so an authorization gap here directly exposes or lets one customer manipulate another family's children's data.
- **Package purchases and credit vouchers** — `rs_package_purchases.lessonsRemaining` and `rs_credit_vouchers` represent real prepaid financial value (lessons paid for in advance); write access to these must be restricted to the owning customer and to the booking/cancellation logic that debits/credits them atomically.

## Trust Boundaries

- **Browser to Express API** — all request parameters, bodies, and client-side role checks are untrusted until validated server-side.
- **Authenticated staff to privileged roles** — `ADMIN`, `LIVERY_ADMIN`, `VETERINARY`, `STORES`, and `FINANCE` have materially different responsibilities; role separation must be enforced on the server.
- **Express API to PostgreSQL** — the server has broad read/write access to operational and billing tables, so route handlers and storage helpers must preserve cross-record integrity rather than trusting client-composed objects.
- **Express API to external services** — the server talks to NetSuite RESTlets for ERP synchronization; account linking and role mapping at this boundary must fail closed. (The prior `aksportal.com` Unified Portal SSO integration has been removed; all staff and customer authentication is now local session-based only.)
- **Production vs dev-only tooling** — `server/vite.ts` and development middleware are dev-only and should not be treated as production-reachable without evidence.
- **Staff identity to Customer Portal identity** — `requireCustomer` (`server/route-helpers.ts`) resolves one `effectiveCustomerId` from either a real `CUSTOMER` account or a `STAFF` account's `linkedCustomerId`. This boundary must never let a staff session act as an *arbitrary* customer (only their own linked one), and must never let a `CUSTOMER` session reach any staff-only route — `accountType` is checked directly rather than through the staff permission catalog (`shared/permissions.ts`), so a `CUSTOMER` account has zero entries in `role_permissions` by construction, not by omission.
- **Customer to customer** — every Customer Portal route must scope reads and writes to the caller's own `effectiveCustomerId`; a rider id, booking id, or package-purchase id supplied by the client is never sufficient on its own to authorize an action on it.

## Scan Anchors

- **Production entry points:** `server/index.ts`, `server/routes.ts`, `server/storage.ts`, `shared/schema.ts`, `server/modules/riding-school/*`, `server/modules/customer-portal/*`.
- **Highest-risk code areas:** authentication/bootstrap (`server/index.ts`, `server/auth.ts`, `server/routes.ts`, `server/seed.ts`), invoice creation/details and billing-role enforcement (`server/routes.ts`, `server/storage.ts`, `client/src/pages/to-invoice.tsx`, `client/src/pages/invoices.tsx`), agreement document handling, raw horse-movement APIs, NetSuite integration, and every route in `server/modules/customer-portal/routes.ts` (new self-service surface — see ownership-check notes below).
- **Privilege boundaries:** public `/api/login`; authenticated `/api/*`; admin-only settings/users/audit endpoints; finance-only ERP endpoints; approval workflow for veterinary and stores roles; `requireCustomer`-gated `/api/portal/*` (orthogonal to the staff role/permission catalog — see Trust Boundaries).
- **Usually dev-only:** `server/vite.ts`, local screenshots/assets, and build-time tooling unless production reachability is demonstrated.

## Threat Categories

### Spoofing

Staff authentication is session-based with local login only (the prior external SSO handoff to `aksportal.com`'s Unified Portal has been removed). The system must only create or elevate sessions after successful credential verification, and bootstrap logic must never leave predictable credentials active in production.

Customer Portal accounts authenticate through the same session mechanism (no separate, weaker login path was introduced) and are provisioned only by staff via `admin.users` (`POST /api/users` with `accountType: "CUSTOMER"`) — there is no public self-registration surface in Phase 1, which removes a significant spoofing/abuse vector (no attacker-controlled account creation to reach the portal).

### Tampering

This application allows staff to create agreements, move horses, modify billing elements, generate invoices, and push data to ERP. Those actions directly change financial and operational state, so the server must enforce least privilege for each workflow, preserve cross-object invariants, and must not rely on frontend route hiding or UI button gating.

The Customer Portal introduces the same class of risk from the *customer* side: a customer tampering with a `riderId`, `bookingId`, or `packagePurchaseId` in a request to act on data belonging to a different family. Every handler in `server/modules/customer-portal/routes.ts` re-fetches the target row and compares its owning `customerId` against the session's `effectiveCustomerId` before allowing a read or write — ownership must never be inferred from the fact that a client supplied a plausible-looking id.

### Information Disclosure

Customer records, horse passport details, agreement PDFs, billing records, invoice payloads, and audit metadata are sensitive. Endpoints returning those records must be intentionally scoped by role, and logs or error responses must not leak more data than operators need.

Rider names, dates of birth, and booking/attendance history are personal data belonging to a family unit (potentially including minors) — `GET /api/portal/riders`, `/api/portal/bookings`, and `/api/portal/calendar` must only ever return data already scoped to the caller's own `effectiveCustomerId`, never an unfiltered or globally-queryable list.

### Repudiation

Because privileged users can change pricing, approvals, invoices, documents, and horse occupancy records, audit trails must remain trustworthy and attributable. Sensitive state changes should be logged with acting user, target object, and timestamp, and unauthorized users must not be able to perform actions outside their role while still appearing legitimate in the logs.

Customer-initiated actions (booking, cancelling, purchasing a package, adding a rider) are audit-logged the same way as staff actions (`portal_create_booking`, `portal_cancel_booking`, `portal_purchase_package`, etc. in `server/modules/customer-portal/routes.ts`), so a family's self-service history remains reconstructable — this matters particularly for cancellation-credit disputes (did the credit/refund get issued, and for which policy tier).

### Denial of Service

The server accepts JSON bodies, imports, and document uploads and performs external service calls. Public auth endpoints must be rate-limited, uploads and payload sizes must stay bounded, and external calls should not let an attacker exhaust server resources or stall critical billing flows.

Booking is a race-sensitive, concurrency-exposed action once the Customer Portal is live (many family accounts can attempt to book the same popular class simultaneously); `bookLesson` (`server/modules/riding-school/scheduling.ts`) uses `SELECT ... FOR UPDATE` inside a transaction specifically so concurrent booking attempts against the same lesson serialize correctly rather than racing past capacity or deadlocking under load.

### Elevation of Privilege

Role separation is a core security property in this project. Lower-privilege staff must not be able to invoke admin, finance, or livery-admin workflows by calling backend endpoints directly, mutating objects they should only view, or exploiting storage-layer integrity gaps to obtain broader access.

A `CUSTOMER` account must never be able to reach a staff-only (`requirePermission`-gated) route, and a `STAFF` account without `linkedCustomerId` must never be able to reach `/api/portal/*` (both fail closed via `requireCustomer`'s explicit `effectiveCustomerId` check — there is no fallback path that grants portal access without one). Within the portal itself, one customer must never be able to elevate into acting on another customer's riders, bookings, or packages by id manipulation (see Tampering, above).
