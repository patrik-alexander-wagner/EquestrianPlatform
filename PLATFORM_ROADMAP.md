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

## STATUS (as of 2026-07-05) — read this before doing anything else

Phase 1 milestones M1-M5 are built and verified live; M6 testing infra is in place. **M6 is still
not fully done** — 2 of the original 4 security findings remain open (see below). Since M5, the
identity model, branding, admin navigation, the Riding School calendar, and Riding School Settings
have all been substantially reworked — treat the milestone-by-milestone narrative further down in
this doc as the *original* target shape, and this STATUS section as ground truth for what the code
actually looks like today.

### Identity: multi-role, not single `role` + `accountType`

The original single `users.role` column plus a separate `accountType` ("STAFF"|"CUSTOMER") /
`linkedCustomerId` pair has been **replaced** with a proper many-to-many `user_roles` table
(`shared/schema.ts`, migrated in `server/migrations/multi-role.ts`). A user can hold multiple
roles at once (e.g. `ADMIN` + `CUSTOMER`, so staff can see the member-facing booking experience
without a second account). `CUSTOMER` is now just a role like any other — held via `user_roles`,
carrying zero default permissions of its own (`shared/permissions.ts`) — and `users.customerId`
alone (no more `linkedCustomerId`) identifies which customer record a `CUSTOMER`-role holder
represents, regardless of what other roles they also hold. `server/permissions.ts`'s
`can()`/`isAdminRole()`/`requirePermission()` all operate on `roleKeys: string[]` (union semantics:
admin/granted if *any* held role qualifies) — same on the client via `useCan()`/`PermissionRoute`,
which now also accept an array of alternative action keys (any-of), not just one.
`INSTRUCTOR` is a second identity-only role added later: holding it auto-creates/retires the
user's row in the shared `instructors` table (`DatabaseStorage.syncInstructorForUser` in
`server/storage.ts`) — instructors are no longer created by hand, only by granting this role.

**Security side-effects of the multi-role rework** (see the original 4-finding list this section
used to carry): finding #1 (CUSTOMER defaulting to the staff `VIEWER` role) and #4 (mass-assignable
`accountType`/`linkedCustomerId` on `POST /api/users`) are now **structurally fixed** — those
columns don't exist anymore, and `CUSTOMER` genuinely carries zero staff permissions. **Findings
#2 and #3 are still open**: `server/modules/riding-school/routes.ts`'s
`GET /customers/:customerId/{riders,package-purchases,credit-vouchers}` (still `requireAuth`-only,
no ownership check against `req.params.customerId`) and `GET /scheduled-lessons*` (still
unfiltered for any authenticated session) — fix before calling M6 done.

### Branding: "Saddle Hub by ADEC"

Rebranded from "StableMaster" per the client's brand PDF and a follow-up high-fidelity design
handoff (mockups in `design_handoff_saddle_hub/`, not part of this repo). Brand tokens live in
`client/src/index.css`: root theme = Stable Management (brand green `#183a2c`), `.riding-school-theme`
class swaps the accent to near-black `#231f20` (same white sidebar), `.portal-theme` class swaps
the *sidebar background* to warm cream `#f7edde` with a pale-green active-nav fill (avatar/buttons
stay brand green — cream is the differentiator, not a different accent hue). Logo mark is a real
asset (`attached_assets/logo-mark.png`, via `client/src/components/icons/logo-mark.tsx`), not the
old horseshoe icon (that icon still exists and is still used for unrelated "Horses" nav entries —
only the brand mark itself was replaced). Wordmark font is Playfair Display (already preloaded,
zero extra cost) — ADEC's actual licensed typefaces (ABC Arizona Mix / Aeonik Pro) were not
available and would need to be swapped in later if provided.

### Admin navigation: one Settings page, not two

`/riding-school/settings` no longer exists. `client/src/pages/admin-settings.tsx` is now the single
Settings page for **both** admin modes, reachable via the shared `administrationNavGroup` in
`app-sidebar.tsx` (Users/Roles/Settings/Audit Logs, shown regardless of Stable Mgmt vs Riding School
toggle). Since a Riding School Admin doesn't have `admin.settings` by default, the route/nav gate
had to become "any of `admin.settings` OR the three `riding_school.*.manage` keys" — each section
within the page (Livery Packages / Lesson Templates / Terms-Riding-Package / Cancellation Notice)
independently shows/hides based on the viewer's own specific permission, so a Livery-only admin
never sees Riding School config and vice versa.

### Riding School Settings: what changed

- **Lesson Templates**: edit was silently missing from the UI (the PATCH route already existed —
  pure frontend gap, now fixed). Rider-level gating changed from a single exact `riderLevelId` to a
  `minRiderLevelId`/`maxRiderLevelId` **range** over `rider_levels.sort_order`
  (`scheduling-logic.ts`'s `riderLevelAllowed`), used by both `bookLesson` and the customer portal
  calendar's visibility filter.
- **Terms / Riding Package** (renamed from "Riding Packages"): edit was also missing (same
  frontend-only gap). The old free-text `lessonTemplateCategory` field — which was never actually
  checked against anything at redemption time — is now a real many-to-many join
  (`rs_package_templates`), edited via a checkbox list of lesson templates. `bookLesson` now
  actually enforces it: redeeming a package for a lesson whose template isn't in that package's
  allowed set is rejected (this was a real gap before, not just a naming issue).
- **Cancellation policy**: collapsed from a tiered `{thresholdHours, creditPercent}` table to a
  single `{thresholdHours}` row (`rs_cancellation_policy`) with a binary rule — full refund if
  cancelled with at least that much notice, nothing otherwise
  (`scheduling-logic.ts`'s `getsFullRefund`). Migrated via `server/migrations/riding-school-settings-v2.ts`,
  which also carries the min/max rider-level backfill and the package/template backfill described
  above.

### Riding School Calendar: rebuilt from scratch

`react-big-calendar` is gone (dependency removed from `package.json`). `client/src/components/riding-school-calendar.tsx`
is now a custom resource-grid component: Day/Week/Month view toggle, a Full-Day/By-Hour toggle
(forced to "By Hour" in Day view, forced to "Full Day" and hidden entirely in Month view), and a
Horses/Instructors/Customers/Facilities resource-axis toggle (hidden in Month view, which is a
plain full-month grid with no resource rows). Two new bulk-lookup endpoints
(`GET /api/riding-school/bookings`, `GET /api/riding-school/riders`) support the Horses/Customers
axes without N+1 queries. `RIDING_SCHOOL_ADMIN` also picked up `customers.view`/`horses.view` by
default here — the nav already linked to those pages, but the role never actually had access.

### SSO ("Unified Portal") removed entirely

The `GET /sso` token-handoff route (verified against `aksportal.com`, auto-provisioned/linked local
users) has been deleted from `server/routes.ts`, along with `users.ssoId`
(`server/storage.ts`'s `getUserBySsoId`, the `getUsers()` column selection) and the client-side SSO
error-message handling in `login.tsx`. `server/migrate.ts`'s `sso_id` migration now drops the column
instead of adding it. Standalone `/api/login` (Passport local) is untouched and was verified live
after the change. `threat_model.md` updated to remove SSO from trust boundaries/spoofing sections.

### Lesson Template lifecycle: delete guards + Active/Inactive lock

Deleting a lesson template or Terms/Riding Package used to throw a raw Postgres FK-violation 500
(`Failed query: delete from "lesson_templates"...`) whenever a recurrence/scheduled lesson/package
purchase referenced it. Both now check first and throw a friendly 400 ("Mark it inactive instead")
— `deleteLessonTemplate`/`deleteRidingPackage` in `server/modules/riding-school/storage.ts`.

Lesson templates went further per an explicit follow-up request: `hasLessonTemplateInstances(id)`
(true if any recurrence or scheduled lesson — past, present, or future — references the template)
now also **blocks editing** any field other than `isActive` once true (`updateLessonTemplate`),
not just deleting. `GET /api/riding-school/lesson-templates` returns a `hasInstances` flag per row
so the UI can grey out Edit/Delete without extra round-trips. `admin-settings.tsx`'s Lesson
Templates section gained: an Active/Inactive/All filter (defaults to Active), a Status column, and
a 3-dot menu with **Edit** (disabled when `hasInstances`), **Deactivate/Activate** (always
available — a direct one-click `isActive` toggle, no dialog, so a locked template can still be
retired), and **Delete** (disabled when `hasInstances`). The calendar's "New Lesson" template
picker now filters to `isActive` templates only, so inactive ones can't be used to schedule new
classes. Riding Packages got the delete-guard fix but not the same lock/filter/lifecycle UI — that
was scoped to lesson templates only per the request that drove it.

### Riding School horse roster (new) + `horse_wellbeing_status` removed

Two related changes, same session:

- **New roster concept**: `horses.isRidingSchoolHorse` (simple boolean flag — no history needed;
  `rs_bookings.horseId` already answers "when did this horse do lessons"). An "Assign Riding School
  Horses" button on Horse Management opens a dialog listing every horse + owner (reuses
  `storage.getHorsesWithOwners()`, now including the flag) with separate search filters for horse
  name and owner, checkboxes, and a bulk-set save (`POST /api/riding-school/horses/assignments` →
  `storage.setRidingSchoolHorses`). A new append-only `rs_horse_status` table
  (`server/migrations/riding-school-horses.ts`) tracks each roster horse's `mood` (enum: fit / lame
  / needs_training / injured) plus `maxLessonsPerDay`/`maxLessonsPerWeek` over time — insert-only,
  never update, same philosophy as the table it superseded (see below). Horse Management
  (`client/src/pages/riding-school/horse-management.tsx`, previously just an unfiltered dump of
  every horse in the system — hence "the page is empty/wrong" complaint that started this) now
  shows **only** roster horses, each with its latest status and a history view. New permission:
  `riding_school.horses.manage`, granted to `RIDING_SCHOOL_ADMIN` by default.
- **`horse_wellbeing_status` deleted**: the old general-purpose freeform wellbeing log (any horse,
  livery or not — `statusTag` + note, embedded in the plain Horses page edit dialog) is gone —
  table, storage methods, routes, the `shared_resources.horse_wellbeing.manage` permission, and the
  `HorseWellbeingSection` component all removed. Superseded by `rs_horse_status` for Riding School
  horses specifically; the general Horses page has no wellbeing UI anymore. Migration drops the
  table for existing databases; `riding-school.ts`'s original `CREATE TABLE` for it was also
  removed so fresh databases never create it. Verified idempotent (drop logs once, silent no-op on
  the next boot).

### Customer Portal: riders are now editable

`PATCH /api/portal/riders/:id` already existed (ownership-checked, M5) but had no UI. `my-riders.tsx`
now has a Pencil action per row opening an edit dialog (Full Name / DOB / Riding Level — deliberately
not `isAccountHolder`, same fields the Create dialog exposes).

### New admin page: Booking History (`/riding-school/booking-history`)

One row per customer **interaction** with a scheduled lesson — booked or cancelled, not just
currently-confirmed (deliberately broader than the existing `GET /api/riding-school/bookings`,
which stays confirmed-only because the calendar's resource axes depend on that). New
`getBookingHistoryInRange`/`GET /api/riding-school/bookings/history` (gated by `riding_school.view`).
Columns: Lesson, Lesson Date, Rider, Customer, Horse, Status, Booked On; filters: date range,
status, and a text search across rider/customer/lesson name.

### Known unresolved: deleting a scheduled lesson (calendar)

A "Delete Lesson" flow was added to the calendar's lesson-detail dialog (this occurrence vs. this
and following events, with a preview of exactly which dates a series-delete would remove, and a
block if any target instance has an active booking) — `DELETE /api/riding-school/scheduled-lessons/:id?scope=`,
`GET /api/riding-school/recurrences/:id/future-instances`. Live-tested by the user: deleting a
27-occurrence series failed with the same class of raw FK-violation 500 as the lesson-template bug
above — `rs_bookings.scheduledLessonId` is `notNull`, and **cancelled** bookings are kept as history
(never deleted, per `cancelBooking`), so a hard `DELETE` on `rs_scheduled_lessons` fails even after
the active-booking guard passes, because old cancelled bookings still FK-reference the row.

A fix mirroring `cancelBooking`'s own pattern was written — `cancelScheduledLessons` (renamed from
`deleteScheduledLessons`) now flips `status` to `"cancelled"` instead of hard-deleting, and
`getScheduledLessonsInRange` excludes `status = "cancelled"` so cancelled lessons disappear from
the calendar/portal calendar views without breaking the FK. **This fix is implemented in code but
NOT yet live-verified** — the user asked to pause and investigate further ("I didn't know it was
referenced somewhere else") right as the fix landed, and the session moved on to other work before
confirming it live. Next session: restart the server, retest the exact series-delete scenario that
originally failed, confirm cancelled scheduled lessons vanish from both calendars, and check
`getReportSummary`'s `lessonsInRange` count (still counts by date range only, does not yet exclude
`status = "cancelled"` — decide if that should also be excluded before calling this done).

### Not started: Riding School Billing page

Requested: a Billing section under Riding School admin showing all customer transactions (package
purchases and one-off lesson bookings). Investigation surfaced a real gap: **one-off (non-package)
lesson bookings currently create no invoice/charge at all** — `bookLesson`
(`server/modules/riding-school/scheduling.ts`) only calls `simulatedPaymentProvider.createCharge`
when a `packagePurchaseId` is present; a customer can book and attend a lesson paying nothing today
if they don't redeem a package. The user was asked whether to (a) implement one-off charging first
so the new page reflects both transaction types, or (b) scope the page to package purchases only
for now — the question was dismissed/deferred, not answered. **Nothing has been built for this
yet** — no page, no route, no decision made on the one-off-charging gap. Ask the user which
direction before starting.

**Next steps when resuming, in priority order:** (1) decide + verify the scheduled-lesson delete
fix above, (2) get a decision on one-off lesson billing and build the Billing page, (3) fix IDOR
findings #2/#3 from the Identity section above, re-verify live, update `threat_model.md` for any
trust-boundary changes — then this doc's Phase 1 exit criteria (below) can be considered met and
M6/Phase 1 called done.

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
