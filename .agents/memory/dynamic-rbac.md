---
name: Dynamic RBAC permission model
description: How permission gating is designed in StableMaster — what is gated, what stays auth-only, and why.
---

# Dynamic RBAC — gating decisions

The app uses a data-driven permission system (action catalog in `shared/permissions.ts`,
`roles` + `role_permissions` tables, `requirePermission(...keys)` middleware that allows if
the role isAdmin OR has any key). See `replit.md` for the full surface.

## Read-endpoint gating decision
- Primary page-data reads ARE gated by their `*.view` key (defense in depth against direct
  API calls): customers, horses, stables, boxes, items, livery-agreements, billing-elements,
  invoices, horse-movements/box-grid, reports/*, agreement document read+download.
- Shared lookup / cross-page helper endpoints stay auth-only ON PURPOSE: e.g. horses/available,
  boxes-with-status, available-boxes, horses-with-owners, horses-with-agreements,
  monthly-billing-approvals, horse-ownership, billed-months, horse-assignment-check, and the
  home dashboard's dashboard-summary / dashboard/kpis.
- **Why:** every non-admin SYSTEM role gets all `*.view` perms by default, so gating reads
  never breaks built-in roles — only admin-created CUSTOM roles with partial views are
  constrained. Helper endpoints are left open so a custom role with one page's view doesn't
  hard-break on cross-domain lookups, and so the home dashboard works for any authenticated user.
- **How to apply:** when adding a new page, gate its primary read by a new `*.view` action and
  add that view to ALL_OPERATIONAL_VIEWS in `shared/permissions.ts` if system roles should see it.
  Leave generic lookups auth-only.

## Env quirk
- The dev server does NOT reliably hot-reload changes to route guards in `server/routes.ts`.
  After editing guards, restart the `Start application` workflow before curl-testing — otherwise
  curl exercises stale middleware and shows wrong (over-permissive) results.

## Notes
- ADMIN role's stored permission set is empty; `isAdmin` bypass grants everything (server `can()`
  and frontend `useCan`). Do not rely on ADMIN having rows in role_permissions.
- There is no DELETE /api/users route; users cannot be removed via the API.
