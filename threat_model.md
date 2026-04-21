# Threat Model

## Project Overview

StableMaster is a production Express + React + PostgreSQL application for managing customers, horses, stables, livery agreements, billing elements, invoices, and NetSuite ERP synchronization. The primary users are authenticated staff with differentiated roles (`ADMIN`, `LIVERY_ADMIN`, `VETERINARY`, `STORES`, `FINANCE`). Production traffic is served by `server/index.ts` and `server/routes.ts`; the browser is untrusted and all authorization decisions must be enforced server-side.

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

## Trust Boundaries

- **Browser to Express API** — all request parameters, bodies, and client-side role checks are untrusted until validated server-side.
- **Authenticated staff to privileged roles** — `ADMIN`, `LIVERY_ADMIN`, `VETERINARY`, `STORES`, and `FINANCE` have materially different responsibilities; role separation must be enforced on the server.
- **Express API to PostgreSQL** — the server has broad read/write access to operational and billing tables.
- **Express API to external services** — the server talks to `aksportal.com` for SSO verification and NetSuite RESTlets for ERP synchronization.
- **Production vs dev-only tooling** — `server/vite.ts` and development middleware are dev-only and should not be treated as production-reachable without evidence.

## Scan Anchors

- **Production entry points:** `server/index.ts`, `server/routes.ts`, `server/storage.ts`, `shared/schema.ts`.
- **Highest-risk code areas:** authentication/bootstrap (`server/index.ts`, `server/auth.ts`, `server/seed.ts`), role-gated billing/invoice flows (`server/routes.ts`, `client/src/pages/to-invoice.tsx`, `client/src/pages/invoices.tsx`), agreement document handling, and NetSuite integration.
- **Privilege boundaries:** public `/sso` and `/api/login`; authenticated `/api/*`; admin-only settings/users/audit endpoints; finance-only ERP endpoints; approval workflow for veterinary and stores roles.
- **Usually dev-only:** `server/vite.ts`, local screenshots/assets, and build-time tooling unless production reachability is demonstrated.

## Threat Categories

### Spoofing

Staff authentication is session-based with local login and an external SSO handoff. The system must only create or elevate sessions after successful credential verification or trusted SSO verification, and bootstrap logic must never leave predictable credentials active in production.

### Tampering

This application allows staff to create agreements, move horses, modify billing elements, generate invoices, and push data to ERP. Those actions directly change financial and operational state, so the server must enforce least privilege for each workflow and must not rely on frontend route hiding or UI button gating.

### Information Disclosure

Customer records, horse passport details, agreement PDFs, billing records, invoice payloads, and audit metadata are sensitive. Endpoints returning those records must be intentionally scoped by role, and logs or error responses must not leak more data than operators need.

### Repudiation

Because privileged users can change pricing, approvals, invoices, and documents, audit trails must remain trustworthy and attributable. Sensitive state changes should be logged with acting user, target object, and timestamp, and unauthorized users must not be able to perform actions outside their role while still appearing legitimate in the logs.

### Denial of Service

The server accepts JSON bodies, imports, and document uploads and performs external service calls. Public auth endpoints must be rate-limited, uploads and payload sizes must stay bounded, and external calls should not let an attacker exhaust server resources or stall critical billing flows.

### Elevation of Privilege

Role separation is a core security property in this project. Lower-privilege staff must not be able to invoke admin, finance, or livery-admin workflows by calling backend endpoints directly, mutating objects they should only view, or exploiting bootstrap shortcuts that create privileged accounts.
