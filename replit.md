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
  App.tsx                    - Main app with sidebar layout and routing
  components/
    app-sidebar.tsx          - Navigation sidebar
    page-header.tsx          - Reusable page header
    data-table.tsx           - Reusable paginated data table (25 rows/page)
    search-bar.tsx           - Reusable search input
    status-badge.tsx         - Status badge component
  pages/
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
    admin-settings.tsx       - Livery package configuration

server/
  index.ts                   - Express server entry point
  routes.ts                  - All API routes (/api/*)
  storage.ts                 - Database storage interface (PostgreSQL)
  db.ts                      - Database connection
  seed.ts                    - Seed data

shared/
  schema.ts                  - Drizzle schema (all tables)
```

## Database Tables
- users, customers, horses, stables, boxes, items
- livery_agreements, billing_elements, invoices

## Key Features
- Currency: AED throughout
- Sidebar navigation matching requirements order
- Pagination (25 rows/page) on all lists
- Search/filter on all list pages
- Excel/CSV import (.xlsx, .xls, .csv) for customers, horses, boxes, items (3-step wizard, batch insert)
- Livery agreement creation via box grid view
- Billing element management for horses with active agreements (unit price + total display)
- Invoice generation per customer with selectable line items (checkboxes + select all)
- Livery packages only billable for months within agreement active period
- Pro-rating by quarter-month for partial months (start/end mid-month)
- Billing month tracking to prevent duplicate livery billing
- PDF invoice generation (jspdf + jspdf-autotable) matching Abu Dhabi Equestrian Club template
- Invoice deletion (temporary feature) with billing element unbilling
- Livery reports with bar charts (by month/customer)
- Livery package configuration in settings
- "Base" field = quantity unit; no seeding on startup

## Dependencies
- jspdf + jspdf-autotable - PDF generation for invoices
- xlsx - Excel/CSV file parsing for imports
