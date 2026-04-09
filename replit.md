# StableMaster - Stable Management & Billing System

## Overview
StableMaster is a web-based stable management system for managing horses, customers, stable infrastructure, livery agreements, billing elements, and invoicing.

## Tech Stack
- **Frontend**: React + TypeScript, Wouter routing, TanStack React Query, Shadcn/UI, Tailwind CSS, Recharts
- **Backend**: Express.js + TypeScript
- **Database**: PostgreSQL with Drizzle ORM
- **Build**: Vite

## Project Structure
```
client/src/
  App.tsx                    - Main app with auth state, sidebar layout, routing
  components/
    app-sidebar.tsx          - Navigation sidebar with logout button
    page-header.tsx          - Reusable page header
    data-table.tsx           - Reusable paginated data table (25 rows/page)
    search-bar.tsx           - Reusable search input
    status-badge.tsx         - Status badge component
  pages/
    login.tsx                - Login page (username/password)
    dashboard.tsx            - Home dashboard with stats
    customers.tsx            - Customer list (read-only + import)
    horses.tsx               - Horse management (CRUD + import)
    stables.tsx              - Stable management (CRUD)
    boxes.tsx                - Box management (CRUD + import)
    items.tsx                - Items list (read-only + import)
    current-agreements.tsx   - Active livery agreements with checkout and edit
    new-agreement.tsx        - New agreement creation (box grid view, with/without horse)
    agreement-history.tsx    - Historical agreements with cancel checkout
    billing-elements.tsx     - Extra billing items per horse
    to-invoice.tsx           - Invoice preparation
    invoices.tsx             - Invoice list (read-only)
    reports.tsx              - Livery reports with charts
    admin-users.tsx          - User management
    admin-settings.tsx       - Livery package + N8N webhook configuration
    admin-audit-logs.tsx     - Audit log viewer (admin-only, paginated)
    horse-movements.tsx      - Stable Management: box grid + move/swap + movement log

server/
  index.ts                   - Express server + session + passport setup
  auth.ts                    - Password hashing (scrypt) and verification
  routes.ts                  - All API routes (/api/*) with auth middleware
  storage.ts                 - Database storage interface (PostgreSQL)
  db.ts                      - Database connection
  seed.ts                    - Seed data

shared/
  schema.ts                  - Drizzle schema (all tables)
```

## Database Tables
- users (role: ADMIN | LIVERY_ADMIN | VETERINARY | STORES | FINANCE), customers (fullname; firstname/lastname kept but empty), horses, stables, boxes, items
- livery_agreements (NO horseId — horse linkage is via horse_movements), billing_elements (has its own horseId), invoices (status: DRAFT | VET_VALIDATION | STORES_VALIDATION | FINANCE_VALIDATION | APPROVED | PUSHED_TO_ERP | REJECTED)
- horse_ownership (horseId → customerId: tracks which customer owns which horse)
- horse_movements (agreementId, horseId, stableboxId, checkIn, checkOut: tracks horse occupancy per agreement; active movement = no checkOut)
- invoice_validations (audit trail: invoice_id, step, action, user_id, comment, created_at)
- app_settings, agreement_documents, audit_logs

## Authentication & Authorization
- Session-based auth via passport-local + express-session + connect-pg-simple (PostgreSQL session store)
- Passwords hashed with scrypt (Node.js crypto module)
- All /api/* routes require authentication except /api/login, /api/logout, /api/me
- Login page shown when unauthenticated; sidebar hidden
- Default credentials: admin / admin123 (set via SEED_ADMIN_PASSWORD env var)
- GET /api/users never returns password field (returns id, username, role)
- RBAC with 5 roles: ADMIN, LIVERY_ADMIN, VETERINARY, STORES, FINANCE
  - ADMIN: full access, can perform any action at any step
  - LIVERY_ADMIN: create/edit invoices, send for validation
  - VETERINARY: approve/reject at VET_VALIDATION step
  - STORES: approve/reject at STORES_VALIDATION step
  - FINANCE: approve/reject at FINANCE_VALIDATION step, ERP operations (generate SO, send to NetSuite)
- Admin-only routes: GET/POST/PATCH /api/users, DELETE /api/stables/:id, DELETE /api/boxes/:id, DELETE /api/invoices/:id, POST /api/settings/*, GET /api/audit-logs
- ERP routes (generate-so, send-to-netsuite) restricted to FINANCE + ADMIN via requireRoles middleware
- Frontend: Administration sidebar section hidden for non-ADMIN users; admin routes redirect non-admins to dashboard
- /api/me returns { id, username, role }
- Users page (admin-only): create users with role, edit user roles
- SSO via Unified Portal: GET /sso?token=xxx → server verifies token with POST to aksportal.com/api/sso/verify-token → finds/creates local user by username → establishes Passport session → redirects to /
  - Role mapping: "superadmin"/"admin" → "ADMIN", "livery_admin" → "LIVERY_ADMIN", "veterinary" → "VETERINARY", "stores" → "STORES", "finance" → "FINANCE", unknown → "LIVERY_ADMIN"
  - SSO errors redirect to /login?error=missing_token|invalid_token|sso_failed
  - Login page reads ?error= query param and displays human-readable SSO error messages

## Key Features
- Currency: AED throughout
- Sidebar navigation matching requirements order
- Pagination (25 rows/page) on all lists
- Search/filter on all list pages
- Excel/CSV import (.xlsx, .xls, .csv) for customers, horses, boxes, items (3-step wizard, batch insert)
- Livery agreement creation via box-first grid view (no horse field on agreement; horse check-in via post-save modal using horse_movements)
- Billing element management for horses with active agreements (unit price + total display) + "Bill Non-Livery Customer" for customers without agreements
- Billing month auto-derived from transaction date (YYYY-MM format)
- To-invoice page filters billing elements by selected billing month
- Agreement document management: PDF upload/download/delete on current agreements page (base64 storage)
- New agreement form: searchable customer/horse dropdowns, monthly price override
- Invoice generation per customer with selectable line items (checkboxes + select all)
- Livery packages only billable for months within agreement active period
- Pro-rating by exact days for partial months (e.g. start on 2nd of 31-day month = 30/31 * monthlyAmount)
- Checkout sets endDate only (status stays "active"); agreement visible in Current Agreements until end of checkout date, then disappears; box/horse freed after endDate passes; To Invoice still shows pro-rated livery until billed
- Billing month tracking to prevent duplicate livery billing
- PDF invoice generation (jspdf + jspdf-autotable) matching Abu Dhabi Equestrian Club template
- Invoice deletion (temporary feature, ADMIN only) with billing element unbilling
- Invoice validation workflow: DRAFT → VET_VALIDATION → STORES_VALIDATION → FINANCE_VALIDATION → APPROVED → PUSHED_TO_ERP
  - LIVERY_ADMIN creates invoice (DRAFT), sends for validation
  - VETERINARY approves/rejects at VET step
  - STORES approves/rejects at STORES step
  - FINANCE approves/rejects at FINANCE step; on approval triggers automatic ERP push
  - ADMIN can approve/reject at any step
  - Rejection at any step returns invoice to DRAFT
  - All validation actions recorded in invoice_validations table with user, step, action, comment, timestamp
  - Validation history viewable per invoice via clock icon button
- NetSuite SO generation: generates JSON body per invoice with PO number (starting 2026003000, auto-incrementing), saves to invoice record, allows JSON download (FINANCE/ADMIN only)
- NetSuite ID fields on customers, horses, stables, boxes, items — mappable during import
- Reports page with 3 sections:
  - KPI cards (5): Total Revenue, Livery Revenue, Adhoc Revenue, # Livery Horses, # Livery Customers (with month filter)
  - Revenue Breakdown stacked histogram (livery + adhoc), toggleable per month / per customer (sorted by total descending)
  - Bottom lists: Livery Arrivals (by month), Livery Departures (by month), All Customers (columns: customer, horse, # horses, arrival, departure, package)
- Livery package configuration in settings
- Items: unitFactor (renamed from base) = quantity unit for pricing; price formula: selling_price = (price / unitFactor) * quantity
- Item price history: item_prices table tracks all price changes per item (id, item_id, price, is_active, created_at, created_by). Only one active price per item. "Change Price" button in Add Billing Element dialog allows updating item price with history preservation. Existing billing records unaffected.
- Billing elements: price field stores Final Selling Price (total, not per-unit)
- PO number counter stored in app_settings table (key: last_po_number)
- NetSuite RESTlet integration: "Send to NetSuite" button on invoices sends SO JSON directly to NetSuite RESTlet via OAuth 1.0 TBA authentication, stores sent status and NetSuite ID from response
  - Credentials stored in env vars: NETSUITE_ACCOUNT_ID, NETSUITE_RESTLET_URL, NETSUITE_CONSUMER_KEY, NETSUITE_CONSUMER_SECRET, NETSUITE_TOKEN_ID, NETSUITE_TOKEN_SECRET
  - Uses oauth-1.0a package with HMAC-SHA256 signing
- Stable Management — Horse Movements page (/stable-management/horse-movements):
  - Box grid grouped by stable showing occupied (green) and empty boxes; click occupied box for detail panel
  - Move horse: closes current movement, creates new in target empty box, updates agreement boxId (transactional)
  - Swap horses: closes both movements, creates new swapped movements, updates both agreements (transactional)
  - Movement log table: chronological (newest first), filterable by customer or box/stable
  - API: GET /api/box-grid, GET /api/horse-movements/enriched, POST /api/horse-movements/move, POST /api/horse-movements/swap
- N8N webhook integration (legacy): configurable webhook URL in Settings still available

## Input Validation
- All POST routes use Zod schema validation via `validateBody()`
- All PATCH routes use `.partial()` Zod schemas to validate incoming fields
- Invoice creation validates liveryItems array entries against `insertBillingElementSchema` (horseId is nullable for "without horse" agreements)
- DELETE routes for stables and boxes check item existence before deleting (return 404 if not found)

## Security
- SESSION_SECRET must be set as environment variable for stable sessions (warning logged if missing)
- NetSuite webhook responses are validated before marking invoices as sent
- Dependencies: minimatch@^10.2.3, rollup@4.59.0 (pinned for security)
- Rate limiting: /api/login limited to 5 attempts per minute per IP (express-rate-limit)
- Security headers: helmet middleware (CSP disabled in dev, enabled in production)
- Session cookie: name "sm.sid", sameSite "strict", httpOnly, secure in production
- PDF upload validation: server checks base64 magic bytes (JVBERi = %PDF), max 20 docs per agreement
- Audit logging: critical actions logged to audit_logs table (user, action, entity, details, timestamp)
  - Actions logged: create/delete user, create/checkout agreement, create/delete invoice, create/delete billing element, upload/delete document, update settings
  - Audit logs viewable at /admin/audit-logs (admin-only)

## Dependencies
- jspdf + jspdf-autotable - PDF generation for invoices
- xlsx - Excel/CSV file parsing for imports
- express-rate-limit - Login rate limiting
- helmet - HTTP security headers
