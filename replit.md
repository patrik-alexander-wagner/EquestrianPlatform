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
    current-agreements.tsx   - Active livery agreements with checkout
    new-agreement.tsx        - New agreement creation (box grid view)
    billing-elements.tsx     - Extra billing items per horse
    to-invoice.tsx           - Invoice preparation
    invoices.tsx             - Invoice list (read-only)
    reports.tsx              - Livery reports with charts
    admin-users.tsx          - User management
    admin-settings.tsx       - Livery package + N8N webhook configuration
    admin-audit-logs.tsx     - Audit log viewer (admin-only, paginated)

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
- users (with role column: "admin" | "user"), customers, horses, stables, boxes, items
- livery_agreements, billing_elements, invoices, app_settings, agreement_documents, audit_logs

## Authentication & Authorization
- Session-based auth via passport-local + express-session + connect-pg-simple (PostgreSQL session store)
- Passwords hashed with scrypt (Node.js crypto module)
- All /api/* routes require authentication except /api/login, /api/logout, /api/me
- Login page shown when unauthenticated; sidebar hidden
- Default credentials: admin / admin123 (set via SEED_ADMIN_PASSWORD env var)
- GET /api/users never returns password field
- RBAC: users have role ("admin" or "user"); admin-only routes protected by `requireAdmin` middleware
- Admin-only routes: GET/POST /api/users, DELETE /api/stables/:id, DELETE /api/boxes/:id, DELETE /api/invoices/:id, POST /api/settings/*, GET /api/audit-logs
- Frontend: Administration sidebar section hidden for non-admin users; admin routes redirect non-admins to dashboard
- /api/me returns { id, username, role }
- SSO via Unified Portal: GET /sso?token=xxx → server verifies token with POST to aksportal.com/api/sso/verify-token → finds/creates local user by username → establishes Passport session → redirects to /
  - Role mapping: "superadmin" → "admin", unknown roles → "user"
  - SSO errors redirect to /login?error=missing_token|invalid_token|sso_failed
  - Login page reads ?error= query param and displays human-readable SSO error messages

## Key Features
- Currency: AED throughout
- Sidebar navigation matching requirements order
- Pagination (25 rows/page) on all lists
- Search/filter on all list pages
- Excel/CSV import (.xlsx, .xls, .csv) for customers, horses, boxes, items (3-step wizard, batch insert)
- Livery agreement creation via box grid view
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
- Invoice deletion (temporary feature) with billing element unbilling
- NetSuite SO generation: generates JSON body per invoice with PO number (starting 2026003000, auto-incrementing), saves to invoice record, allows JSON download
- NetSuite ID fields on customers, horses, stables, boxes, items — mappable during import
- Livery reports with bar charts (by month/customer)
- Livery package configuration in settings
- Items: unitFactor (renamed from base) = quantity unit for pricing; price formula: selling_price = (price / unitFactor) * quantity
- Billing elements: price field stores Final Selling Price (total, not per-unit)
- PO number counter stored in app_settings table (key: last_po_number)
- N8N webhook integration: configurable webhook URL in Settings, "Send to NetSuite" button on invoices sends SO JSON via POST to N8N webhook, stores sent status and optional NetSuite ID from response

## Input Validation
- All POST routes use Zod schema validation via `validateBody()`
- All PATCH routes use `.partial()` Zod schemas to validate incoming fields
- Invoice creation validates liveryItems array entries against `insertBillingElementSchema`
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
