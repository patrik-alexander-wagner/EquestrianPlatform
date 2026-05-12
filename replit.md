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
    customers.tsx            - Customer list (read-only)
    horses.tsx               - Horse management (edit only; data sourced from NetSuite)
    stables.tsx              - Stable management (CRUD)
    boxes.tsx                - Box management (CRUD + import)
    items.tsx                - Items list (read-only; sync from NetSuite)
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
- users (role: ADMIN | LIVERY_ADMIN | VETERINARY | STORES | FINANCE), customers (fullname; firstname/lastname kept but empty), horses, stables, boxes
- items (id, netsuiteId, name, unitFactor, price, averageCost, lastPurchasePrice, isInactive, isLiveryPackage) — `department`, `location`, `class`, `status` were removed (unused) and are no longer emitted in NetSuite SO item lines
- livery_agreements (NO horseId — horse linkage is via horse_movements), billing_elements (has its own horseId, userId tracks who created it), invoices (status: APPROVED | PUSHED_TO_ERP; created directly as APPROVED after pre-generation sign-off)
- monthly_billing_approvals (customerId, billingMonth, step[VET|STORES], userId, approved: pre-generation sign-off; unique constraint on customer+month+step)
- horse_ownership (horseId → customerId: tracks which customer owns which horse)
- horse_movements (agreementId, horseId, stableboxId, checkIn, checkOut: tracks horse occupancy per agreement; active movement = no checkOut)
- invoice_validations (legacy audit trail: invoice_id, step, action, user_id, comment, created_at)
- app_settings, agreement_documents, audit_logs

## Authentication & Authorization
- Session-based auth via passport-local + express-session + connect-pg-simple (PostgreSQL session store)
- Passwords hashed with scrypt (Node.js crypto module)
- All /api/* routes require authentication except /api/login, /api/logout, /api/me
- Login page shown when unauthenticated; sidebar hidden
- Default credentials: admin / admin123 (set via SEED_ADMIN_PASSWORD env var)
- GET /api/users never returns password field (returns id, username, role)
- RBAC with 5 roles: ADMIN, LIVERY_ADMIN, VETERINARY, STORES, FINANCE
  - ADMIN: full access, can perform any action including all sign-offs
  - LIVERY_ADMIN: create/edit billing elements, generate invoices (after sign-off)
  - VETERINARY: toggle VET sign-off on To Invoice page (pre-generation approval)
  - STORES: toggle STORES sign-off on To Invoice page (pre-generation approval)
  - FINANCE: ERP operations (generate SO, send to NetSuite)
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
- Excel/CSV import (.xlsx, .xls, .csv) for boxes (3-step wizard, batch insert); customers/horses/items synced from NetSuite
- Livery agreement creation via box-first grid view (no horse field on agreement; horse check-in via post-save modal using horse_movements)
- Billing element management: shows all horses with their owners; if horse is checked into a stable/box, displays the location; Add button per horse to create adhoc billing elements (no agreement dependency)
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
- Invoice validation workflow (V2 — Pre-Generation Approvals):
  - On the To Invoice page, each customer card has Vet Sign-off and Stores Sign-off toggle buttons
  - VETERINARY role can toggle VET approval; STORES role can toggle STORES approval; ADMIN can toggle both
  - Generate Invoice button is disabled until both VET and STORES are approved for that customer+month
  - Invoices are created directly with APPROVED status (no DRAFT or validation steps)
  - Approvals stored in monthly_billing_approvals table (unique per customer+month+step)
  - Old validation endpoints (send-for-validation, validate) return 410 Gone
  - Legacy validation history still viewable per invoice via clock icon button
- NetSuite SO generation: generates JSON body per invoice with PO number (starting 2026003000, auto-incrementing), saves to invoice record, allows JSON download (FINANCE/ADMIN only)
- NetSuite ID fields on customers, horses, stables, boxes, items — mappable during import
- Reports page with 3 sections:
  - KPI cards (5): Total Revenue, Livery Revenue, Adhoc Revenue, # Livery Horses, # Livery Customers (with month filter)
  - Revenue Breakdown stacked histogram (livery + adhoc), toggleable per month / per customer (sorted by total descending)
  - Bottom lists: Livery Arrivals (by month), Livery Departures (by month), All Customers (columns: customer, horse, # horses, arrival, departure, package)
- Livery package configuration in settings
- Items: unitFactor (renamed from base) = number of pieces in 1 stocked unit (e.g., 7 syringes per box). Items.price = price for 1 stocked unit (e.g., box price). Billing element form takes user input in pieces; stored quantity in billing_elements is pieces / unitFactor (i.e., fractional stocked units), so NetSuite/PDF/invoice rendering naturally use stocked units and box-level unit price (line total / stored qty). Final selling price formula on the form: (items.price / unitFactor) * pieces.
- Item price history: item_prices table tracks all price changes per item (id, item_id, price, is_active, created_at, created_by). Only one active price per item. "Change Price" button in Add Billing Element dialog allows updating item price with history preservation. Existing billing records unaffected.
  - Effective item price = active row in item_prices if one exists, otherwise items.price (the value from NetSuite sync). Storage layer overlays the active item_prices.price onto getItems / getItem / getLiveryPackageItems / getNonLiveryPackageItems results, so all UI surfaces (Items page, Add Billing Element, To Invoice, agreements) see the override automatically. changeItemPrice only writes to item_prices and never mutates items.price; NetSuite sync continues to update items.price as the default fallback.
- Billing elements: price field stores Final Selling Price (total, not per-unit)
- PO number counter stored in app_settings table (key: last_po_number)
- NetSuite RESTlet integration: "Send to NetSuite" button on invoices sends SO JSON directly to NetSuite RESTlet via OAuth 1.0 TBA authentication, stores sent status and NetSuite ID from response
  - Credentials stored in env vars: NETSUITE_ACCOUNT_ID, NETSUITE_RESTLET_URL, NETSUITE_CONSUMER_KEY, NETSUITE_CONSUMER_SECRET, NETSUITE_TOKEN_ID, NETSUITE_TOKEN_SECRET
  - Uses oauth-1.0a package with HMAC-SHA256 signing
- Stable Management — Horse Movements page (/stable-management/horse-movements):
  - Box grid grouped by stable (fieldset/legend) showing 3 states: occupied (green), agreement active but no horse (amber), empty (grey); click any box for centered dialog popup
  - Move horse: closes current movement, creates new in target empty box, updates agreement boxId (transactional)
  - Swap horse: replaces current horse in box with another horse from the same customer (via horse_ownership, transactional)
  - Movement log table: chronological (newest first), filterable by customer or box/stable
  - Empty box click → navigates to new agreement page
  - API: GET /api/box-grid, GET /api/horse-movements/enriched, POST /api/horse-movements/move, POST /api/horse-movements/swap
- Invoice Generation Horse Assignment Pre-check:
  - Before generating an invoice, the system checks that all active agreements for the billing period have at least one horse_movement overlapping (checkIn <= period end AND checkOut null or >= period start)
  - If any agreements lack a horse assignment, a blocking modal appears listing Customer, Box, and Package for each unassigned agreement
  - Pre-check is scoped per customer (not global) and enforced both client-side and server-side (POST /api/invoices returns 400)
  - API: GET /api/horse-assignment-check?billingMonth=YYYY-MM&customerId=UUID
- NetSuite item sync (Items page, top-right "Sync with NetSuite" button, available to all authenticated users):
  - POST /api/items/sync-netsuite calls hardcoded RESTlet https://5834136.restlets.api.netsuite.com/app/site/hosting/restlet.nl?script=2163&deploy=1 via GET with OAuth 1.0 TBA (HMAC-SHA256), reuses NETSUITE_* env vars
  - Upserts items by netsuiteId in a single DB transaction; updates name/price/lastPurchasePrice/unitFactor/isInactive; never touches id or isLiveryPackage; new items default isLiveryPackage=false
  - In-process lock prevents concurrent syncs (returns 409 if one is already running)
  - Frontend shows progress dialog (spinner during sync, then created/updated/total/duration stats; Retry button on error)
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
- RBAC on operational mutations (LIVERY_ADMIN/ADMIN only): livery agreement create/patch/cancel-checkout, horse movement create/patch/move/swap
- Invoice integrity:
  - Server-side proration of livery line items (matches UI getProRateFraction): partial-month agreements are billed daysOverlap/daysInMonth × monthlyAmount; total accumulated raw, rounded once at end
  - Cross-month ad-hoc charges blocked: POST /api/invoices rejects billing elements whose billing_month (or transaction_date prefix) doesn't match invoice billing_month
  - Atomic PO number generation: storage.getNextPoNumber() uses single INSERT ... ON CONFLICT DO UPDATE ... RETURNING (no read-modify-write race)
  - Unique constraint invoices_po_number_unique on invoices.po_number (prevents duplicate PO assignment)

## Dependencies
- jspdf + jspdf-autotable - PDF generation for invoices
- xlsx - Excel/CSV file parsing for imports
- express-rate-limit - Login rate limiting
- helmet - HTTP security headers
