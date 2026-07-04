# Equestrian Platform — Build Roadmap

**Purpose of this document:** a self-contained technical brief for whoever builds this next
(human engineer or AI coding agent — Claude Code, Antigravity, Replit Agent, etc.). It describes
the current codebase, the target end state, and three build phases. Anyone starting from this
doc should read the "Current State" section first and treat it as ground truth — do not assume
greenfield.

---

## 0. Current State (do not rebuild this — extend it)

Repo: Express 5 + TypeScript API, React 18 + Wouter + TanStack Query + Shadcn/UI frontend,
Drizzle ORM on PostgreSQL, session auth (Passport local + `connect-pg-simple`), single-tenant,
single portal, staff-only. It runs the **livery business only**: customers, horses,
stables/boxes, livery agreements, ad-hoc billing elements, invoices, and a NetSuite ERP push
(OAuth 1.0 TBA RESTlet integration). No scheduling, no customer-facing identity, no riding-school
domain exists today.

Key files a builder must read before touching anything:
- `shared/schema.ts` — all Drizzle table definitions (19 tables today).
- `shared/permissions.ts` — the permission **action catalog**: every gated capability is a
  `resource.verb` string (e.g. `agreements.create`), grouped, with a default-role mapping. This
  is a dynamic, DB-backed RBAC system (`roles` + `role_permissions` tables) — not a hardcoded
  switch statement. **New modules must add to this catalog, not invent a parallel auth model.**
- `server/permissions.ts` — `requirePermission(...)` middleware, in-memory permission cache.
- `server/routes.ts` (~2000 lines) — all API routes.
- `server/storage.ts` (~2050 lines) — DB access layer, one class, one interface per table group.
- `client/src/App.tsx` — route table wrapped in `PermissionRoute`, sidebar + top bar shell.
- `threat_model.md` — living threat model, updated per feature. Keep updating it; don't let it
  go stale.

Auth today: session cookie (`sm.sid`), `role` column on `users` (ADMIN, LIVERY_ADMIN, VETERINARY,
STORES, FINANCE, VIEWER — all staff). There is no customer identity concept at all yet.

---

## 1. Target End State

One platform, two operational domains sharing resources, plus a customer-facing portal:

- **Livery** (exists) — unchanged in behavior.
- **Riding School** (new) — lesson templates, scheduling/calendar, capacity, rider levels,
  packages, cancellation/credit policy.
- **Shared resource layer** (new, used by both) — horses (incl. wellbeing/fatigue status),
  instructors, arenas. This is the layer that lets a future "stable management work scheduling"
  feature (feeding, lunging, walking) affect riding-school capacity without a data-sync bridge.
- **Customer Portal** (new) — a second, simpler frontend/auth surface for members: dashboard,
  calendar/booking, family sub-accounts ("riders"), package purchase, my horses.
- **Admin Portal** (extended) — the existing staff app, with a Riding School / Stable Management
  mode toggle, and a Riding School sidebar (Overview, Calendar, Horse Management, Arenas,
  Customers, Instructors, Reports, Settings).

### 1.1 Database strategy: one schema, module boundaries in code

**Do not split into separate databases or Postgres schemas per domain.** Horses and instructors
are genuinely shared entities — a stable-management task must be able to affect the same
`horses` row a riding-school booking reads, in the same transaction, without a sync layer.
Isolation between livery and riding-school code should be enforced by **module boundaries**, not
database boundaries:

- New code lives under `server/modules/riding-school/*` and `server/modules/shared/*`
  (horses, instructors, arenas), separate from the existing livery code in `server/routes.ts` /
  `server/storage.ts`. Riding-school modules call into the shared module's functions; they never
  write livery tables directly, and vice versa.
- New tables get a `rs_` prefix (`rs_lesson_templates`, `rs_bookings`, `rs_scheduled_lessons`,
  `rs_riding_packages`, `rs_package_purchases`, `rs_credit_vouchers`, `rs_rider_levels`) so
  ownership is visually obvious. Shared tables stay unprefixed: `horses`, `instructors`,
  `arenas`, and a new `horse_wellbeing_status` history table.
- Extend `shared/permissions.ts` with new action groups (`Riding School Scheduling`,
  `Riding School Resources`, `Riding School Settings`) rather than a second permission system.

### 1.2 Identity model

Keep `users` as the single identity table but add an `accountType` discriminator
(`STAFF` | `CUSTOMER`) and a nullable `customerId` FK. Do **not** create a second login table.

- A **CUSTOMER** user maps 1:1 to a `customers` row (the existing billing entity, already used
  by livery/NetSuite). This is the "master account."
- Add a `riders` table: `id, customerId (FK, the master/billing account), fullName,
  dateOfBirth, riderLevelId, isAccountHolder (bool)`. Children do **not** get their own login in
  phase 1 — the master account books, views, and cancels on behalf of every rider under it. This
  directly satisfies "a parent with kids, each with their own schedule, master account is billed."
- A **STAFF** user can optionally have `linkedCustomerId` set (staff who is also a member) — this
  is what powers the "switch to Customer Portal" option in the top-right menu. If it's null, that
  option is hidden.
- Top bar (`client/src/App.tsx` currently renders a static avatar div, lines ~144-151): replace
  with a Radix `DropdownMenu` (already a dependency) — right-click *or* click on the avatar shows
  Logout, Switch to Admin Portal / Switch to Customer Portal (conditional per above), and — only
  inside the admin portal — a segmented control for Riding School vs Stable Management, which
  filters the sidebar route set. Persist the active mode in a query param or top-level context,
  not just component state, so refresh/deep-linking works.

### 1.3 Riding-school data model (new tables)

| Table | Purpose |
|---|---|
| `arenas` | id, name, status — intentionally minimal, no opening-hours/HR modeling |
| `instructors` | id, name, status — minimal, optional future `userId` link |
| `rider_levels` | id, name, sortOrder — tag catalog, admin-managed |
| `lesson_templates` | id, name, minAge, maxAge, riderLevelId, minRiders, maxRiders (1-6), durationMinutes, price, isActive |
| `rs_lesson_recurrences` | id, templateId, instructorId, arenaId, daysOfWeek, startTime, until (≤12 months out), isPublic |
| `rs_scheduled_lessons` | id, templateId, recurrenceId (nullable), instructorId, arenaId, startDatetime, endDatetime, capacity, isPublic, isException (bool), status |
| `rs_bookings` | id, scheduledLessonId, riderId, bookedByUserId, horseId (nullable until assigned), status, packagePurchaseId (nullable), createdAt |
| `rs_riding_packages` | id, name, lessonTemplateCategory, numberOfLessons, validityDays, price, isActive |
| `rs_package_purchases` | id, customerId, packageId, lessonsRemaining, validUntil, invoiceId, status, purchasedAt |
| `rs_cancellation_policy` | admin-configured thresholds (24/48/72h) → credit eligibility |
| `rs_credit_vouchers` | id, customerId, lessonTemplateCategory, sourceBookingId, status, expiresAt |
| `horse_wellbeing_status` | id, horseId, statusTag, note, setBy, createdAt — append-only history, read by both domains |

Recurrence editing must follow the Outlook pattern: editing a generated `rs_scheduled_lessons`
row prompts "this event / the series"; editing "this event" sets `isException = true` and detaches
it from the recurrence so future regeneration doesn't clobber the override.

Capacity enforcement (max lessons per horse per day/week) reads `horse_wellbeing_status` +
`rs_bookings` + (later) livery/stable-management activity — this is the concrete reason the
shared-schema decision above matters; it would be a distributed query otherwise.

Rider-level visibility: the customer portal calendar endpoint filters `rs_scheduled_lessons` to
templates whose `riderLevelId` matches the requesting rider's level, and to `isPublic = true`.

### 1.4 Payments

Phase 1/2: **simulate**, same pattern as livery today — a package purchase creates an invoice row
and pushes a Sales Order JSON to NetSuite via the existing OAuth 1.0 TBA integration
(`server/routes.ts`); finance reconciles from there. No real payment capture.

To avoid a rewrite later, introduce a `PaymentProvider` interface now
(`createCharge`, `refund`, `issueCredit`) with one `SimulatedProvider` implementation behind it.
Booking, cancellation, and credit-voucher logic call the interface, not NetSuite/Stripe directly —
so a `StripeProvider` slots in during Phase 3 without touching scheduler code.

---

## Phase 1 — Local build (functional platform, capacity/stakeholder demo)

**Goal:** every feature below runs via `npm run dev` against a local/dev Postgres. No Azure, no
CI/CD yet — this phase proves the product, not the infra.

1. **Schema migration**: add all tables from §1.3 plus the identity changes from §1.2 via
   `drizzle-kit`. Extend `shared/permissions.ts` with the new action groups/keys.
2. **Shared resource module**: `instructors`, `arenas`, `horse_wellbeing_status` CRUD + the
   fatigue/usage tracking read model (aggregates lesson bookings; leave a documented extension
   point for livery/stable-management activity to feed the same aggregate later).
3. **Admin — Riding School mode**: sidebar (Overview, Calendar, Horse Management, Arenas,
   Customers, Instructors, Reports, Settings) gated behind the mode toggle described in §1.2.
   - Calendar: month/week/day view switch, Y-axis resource view (per instructor), template
     instantiation into single or recurring (≤12 months) scheduled lessons, instructor + 1
     horse-per-rider assignment, public/private toggle, Outlook-style single-vs-series edit.
   - Settings: rider levels, arenas, lesson templates, riding packages, cancellation/credit
     policy (24/48/72h → voucher).
4. **Customer Portal** (new app shell, separate top-level route/layout, reuses the same session
   auth but a distinct sidebar for `accountType = CUSTOMER`):
   - Dashboard (next lesson, next 7 days, KPIs)
   - Calendar (level-filtered, public lessons only, book/cancel)
   - My Riders (manage/add child riders, book/cancel on their behalf)
   - Riding Packages / Terms (purchase, remaining balance)
   - My Horses (from existing `horse_ownership`, read-only)
5. **Booking engine rules**: capacity (min/max riders per template), 1 horse per rider per
   booking, level-gating, recurrence generation, cancellation → credit voucher issuance,
   package-lesson redemption decrementing `lessonsRemaining`.
6. **Top bar rework** per §1.2 (portal switch, mode toggle).
7. **Testing**: stand up Vitest for booking/capacity/proration logic and Playwright for the
   golden paths (book a class, cancel within/outside policy window, parent books for a child,
   capacity rejection, package purchase → redemption). There are zero automated tests in the repo
   today — this is not optional for a "professional standard" build.
8. **Security pass**: update `threat_model.md` with the new trust boundary (customer-facing,
   self-service, family-account delegation is a new privilege-escalation surface — a rider must
   never be bookable/cancelable by a customer who isn't their master account). Run a security
   review before calling Phase 1 done.

**Exit criteria:** a stakeholder can log in as a staff admin, create a lesson template, schedule a
recurring class, and separately log in as a customer, see only their level's classes, book for
themselves and a child, buy a package, and cancel a booking to see a credit voucher appear —
end to end, locally.

---

## Phase 2 — Environments, secrets, CI/CD (Azure + GitHub Actions)

**Goal:** the Phase 1 app deployed and reproducible across dev/UAT/prod, with a tested,
reviewable pipeline — before more features get built on top.

1. **Repo hygiene first**: canonical remote is
   `https://github.com/patrik-alexander-wagner/EquestrianPlatform` (decided). Point `origin` at
   it, remove the stale Replit `subrepl-*` remotes and the other now-superseded remotes
   (`github`/`personnal`/old `origin` → `ADEC-DT/equestrian_dev`), and set branch protection on
   `main`/`develop` there before wiring GitHub Actions triggers to it.
2. **Azure resources**, three resource groups (`rg-equestrian-dev/uat/prod`):
   - Azure Container Apps (recommended over App Service — revision-based blue/green, scale-to-zero
     for dev/uat, straight path to background workers for future fatigue/usage rollups).
   - Azure Database for PostgreSQL Flexible Server — Burstable for dev/uat, General Purpose +
     zone-redundant HA for prod. Fully separate server per environment (not schemas-within-one-
     server) — infra isolation protects prod data from a bad dev migration.
   - Azure Key Vault per environment (session secret, NetSuite creds, DB connection string, later
     Stripe keys) — referenced via managed identity, never in env files or the repo.
   - Application Insights per environment, wired in from the start.
   - Blob storage for agreement/document uploads — replace the current base64-in-Postgres
     approach (`agreement_documents.file_data`) as part of this phase; flag as tech debt now.
3. **GitHub Actions pipeline**:
   - PR checks: typecheck (`tsc`), lint, Vitest, Playwright (headless), `npm audit`/semgrep,
     `drizzle-kit` migration dry-run against an ephemeral Postgres service container.
   - Merge to `develop` → auto-deploy to dev (Container Apps revision).
   - Manual promotion gate → UAT, automated smoke test suite runs post-deploy.
   - Manual approval + smoke tests → prod, traffic-split revision rollout, automated rollback on
     smoke-test failure.
   - Use OIDC federated credentials from GitHub to Azure — no long-lived cloud secrets stored in
     GitHub at all.
4. **Pipeline validation**: before trusting this pipeline with real feature work, deliberately
   run it end-to-end at least once per environment (dev → uat → prod) with a trivial change, and
   once with a deliberately failing test/migration, to confirm the gates actually block.
5. **Data**: seed scripts per environment (dev = synthetic, UAT = anonymized-prod-shape, prod =
   real), documented and reproducible — not manual SQL against prod.

**Exit criteria:** a PR merged to `develop` reaches dev automatically, promotion to UAT/prod is a
deliberate, auditable action, and a bad change is provably caught by CI before reaching prod.

---

## Phase 3 — Continuous development

Ongoing once Phases 1-2 are stable:

- **Stripe integration**: implement `StripeProvider` against the `PaymentProvider` interface
  from §1.4; keep the NetSuite SO push as the finance-of-record step regardless of payment rail.
- **Mobile app**: version the API (`/api/v1/...`) once the customer portal is live; add
  token-based auth (short-lived JWT + refresh) *alongside* existing sessions rather than
  replacing them, so staff/web auth is untouched.
- **Stable-management ↔ riding-school integration**: schedule feeding/lunging/walking tasks
  against the shared `horses`/`horse_wellbeing_status` tables so they feed the same
  fatigue/usage read model the riding-school calendar already relies on — this is the payoff of
  the shared-schema decision in §1.1.
- **Stakeholder iteration cadence**: treat this as a standard backlog from here — feature
  requests get triaged into the existing module boundaries (livery / riding-school / shared /
  customer-portal), not bolted on ad hoc.
