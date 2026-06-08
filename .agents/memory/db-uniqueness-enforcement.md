---
name: DB uniqueness enforcement (constraints vs indexes)
description: When relaxing/removing a uniqueness rule in Postgres, both named constraints AND standalone unique indexes can enforce it — check both.
---

# DB uniqueness can be enforced by a UNIQUE INDEX, not only a named constraint

When asked to allow duplicates that were previously blocked (e.g. enabling multiple
invoices per customer per billing month), removing the Drizzle schema `unique(...)`
constraint + the app-level guard is NOT enough. The live database can also have a
standalone `CREATE UNIQUE INDEX` enforcing the same rule, which is invisible to a
`pg_constraint WHERE contype='u'` check.

**Why:** In this repo the active block was a unique *index*
`idx_invoices_customer_billing_month` on `(customer_id, billing_month)`. The named
table constraint `invoices_customer_month_unique` referenced in the schema did not
actually exist in the DB. Checking only `pg_constraint` reported "already gone" while
inserts still failed with 23505.

**How to apply:** Before concluding a uniqueness rule is removed, run BOTH:
- `SELECT conname FROM pg_constraint WHERE conrelid='<table>'::regclass AND contype='u';`
- `SELECT indexname, indexdef FROM pg_indexes WHERE tablename='<table>' AND indexdef ILIKE '%unique%';`
Drop the stray index with `DROP INDEX IF EXISTS <name>;`. Then reproduce the insert
to confirm it succeeds. `npm run db:push` here is interactive and can prompt to
truncate unrelated tables (e.g. users for a missing sso_id unique) — never truncate;
prefer targeted direct SQL (`ALTER TABLE ... DROP CONSTRAINT` / `DROP INDEX`) for
surgical schema changes, and mirror them in shared/schema.ts so push stays the source
of truth.
