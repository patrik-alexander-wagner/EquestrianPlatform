import { sql } from "drizzle-orm";
import { pgTable, text, varchar, integer, numeric, boolean, date, timestamp, uuid, pgEnum, unique, uniqueIndex } from "drizzle-orm/pg-core";
import { createSchemaFactory } from "drizzle-zod";
import { z } from "zod";

// Coerce date/timestamp columns (accepts both real Date objects and ISO
// strings) rather than the drizzle-zod default of requiring an actual Date
// instance — request bodies over JSON can only ever carry strings, so
// without this every date/timestamp field rejects normal API input.
const { createInsertSchema } = createSchemaFactory({ coerce: { date: true } });

export const userRoleEnum = pgEnum("user_role", ["ADMIN", "LIVERY_ADMIN", "VETERINARY", "STORES", "FINANCE", "VIEWER"]);

export const invoiceStatusEnum = pgEnum("invoice_status", [
  "DRAFT", "VET_VALIDATION", "STORES_VALIDATION", "FINANCE_VALIDATION",
  "APPROVED", "PUSHED_TO_ERP", "REJECTED"
]);

export const validationStepEnum = pgEnum("validation_step", ["VET", "STORES", "FINANCE", "ADMIN_OVERRIDE"]);
export const validationActionEnum = pgEnum("validation_action", ["APPROVED", "REJECTED"]);

export const users = pgTable("users", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  role: text("role").notNull().default("LIVERY_ADMIN"),
  ssoId: text("sso_id").unique(),
  // "STAFF" | "CUSTOMER" — CUSTOMER users are gated by accountType checks in portal
  // routes, not by the staff role/permission catalog below.
  accountType: text("account_type").notNull().default("STAFF"),
  // The CUSTOMER user's own billing/master account (riding-school portal identity).
  customerId: uuid("customer_id").references(() => customers.id),
  // Set on a STAFF user who is also a member, to power "switch to Customer Portal".
  linkedCustomerId: uuid("linked_customer_id").references(() => customers.id),
});

export const insertUserSchema = createInsertSchema(users).omit({ id: true });
export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof users.$inferSelect;

export const roles = pgTable("roles", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  key: text("key").notNull().unique(),
  name: text("name").notNull(),
  isSystem: boolean("is_system").notNull().default(false),
  isAdmin: boolean("is_admin").notNull().default(false),
});

export const insertRoleSchema = createInsertSchema(roles).omit({ id: true });
export type InsertRole = z.infer<typeof insertRoleSchema>;
export type Role = typeof roles.$inferSelect;

export const rolePermissions = pgTable("role_permissions", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  roleKey: text("role_key").notNull(),
  actionKey: text("action_key").notNull(),
}, (t) => ({
  uniqRolePermission: unique("role_permissions_role_action_unique").on(t.roleKey, t.actionKey),
}));

export const insertRolePermissionSchema = createInsertSchema(rolePermissions).omit({ id: true });
export type InsertRolePermission = z.infer<typeof insertRolePermissionSchema>;
export type RolePermission = typeof rolePermissions.$inferSelect;

export const customers = pgTable("customers", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  netsuiteId: text("netsuite_id"),
  fullname: text("fullname").notNull().default(""),
  isInactive: boolean("is_inactive").notNull().default(false),
});

export const insertCustomerSchema = createInsertSchema(customers).omit({ id: true });
export type InsertCustomer = z.infer<typeof insertCustomerSchema>;
export type Customer = typeof customers.$inferSelect;

export const horses = pgTable("horses", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  netsuiteId: text("netsuite_id"),
  horseName: text("horse_name").notNull(),
  passportName: text("passport_name"),
  passportNumber: text("passport_number"),
  sex: text("sex"),
  size: text("size"),
  color: text("color"),
  breed: text("breed"),
  dateOfBirth: text("date_of_birth"),
  comments: text("comments"),
  status: text("status").notNull().default("active"),
});

export const insertHorseSchema = createInsertSchema(horses).omit({ id: true });
export type InsertHorse = z.infer<typeof insertHorseSchema>;
export type Horse = typeof horses.$inferSelect;

export const stables = pgTable("stables", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  netsuiteId: text("netsuite_id"),
  name: text("name").notNull(),
  status: text("status").notNull().default("active"),
});

export const insertStableSchema = createInsertSchema(stables).omit({ id: true });
export type InsertStable = z.infer<typeof insertStableSchema>;
export type Stable = typeof stables.$inferSelect;

export const boxes = pgTable("boxes", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  netsuiteId: text("netsuite_id"),
  name: text("name").notNull(),
  type: text("type").notNull().default("box"),
  stableId: uuid("stable_id").notNull().references(() => stables.id),
  status: text("status").notNull().default("active"),
});

export const insertBoxSchema = createInsertSchema(boxes).omit({ id: true });
export type InsertBox = z.infer<typeof insertBoxSchema>;
export type Box = typeof boxes.$inferSelect;

export const items = pgTable("items", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  netsuiteId: text("netsuite_id"),
  name: text("name").notNull(),
  unitFactor: numeric("unit_factor"),
  price: numeric("price"),
  averageCost: numeric("average_cost"),
  lastPurchasePrice: numeric("last_purchase_price"),
  isInactive: boolean("is_inactive").notNull().default(false),
  isLiveryPackage: boolean("is_livery_package").notNull().default(false),
});

export const insertItemSchema = createInsertSchema(items).omit({ id: true });
export type InsertItem = z.infer<typeof insertItemSchema>;
export type Item = typeof items.$inferSelect;

export const itemPrices = pgTable("item_prices", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  itemId: uuid("item_id").notNull().references(() => items.id),
  price: numeric("price").notNull(),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").defaultNow(),
  createdBy: text("created_by"),
});

export const insertItemPriceSchema = createInsertSchema(itemPrices).omit({ id: true, createdAt: true });
export type InsertItemPrice = z.infer<typeof insertItemPriceSchema>;
export type ItemPrice = typeof itemPrices.$inferSelect;

export const liveryAgreements = pgTable("livery_agreements", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  referenceNumber: text("reference_number").notNull(),
  agreementCategory: text("agreement_category").notNull().default("with_horse"),
  customerId: uuid("customer_id").notNull().references(() => customers.id),
  boxId: uuid("box_id").notNull().references(() => boxes.id),
  itemId: uuid("item_id").notNull().references(() => items.id),
  startDate: text("start_date").notNull(),
  endDate: text("end_date"),
  type: text("type").notNull().default("permanent"),
  status: text("status").notNull().default("active"),
  notes: text("notes"),
  checkoutReason: text("checkout_reason"),
  monthlyAmount: numeric("monthly_amount"),
});

export const insertLiveryAgreementSchema = createInsertSchema(liveryAgreements).omit({ id: true });
export type InsertLiveryAgreement = z.infer<typeof insertLiveryAgreementSchema>;
export type LiveryAgreement = typeof liveryAgreements.$inferSelect;

export const billingElements = pgTable("billing_elements", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  horseId: uuid("horse_id").references(() => horses.id),
  customerId: uuid("customer_id").notNull().references(() => customers.id),
  boxId: uuid("box_id").references(() => boxes.id),
  itemId: uuid("item_id").notNull().references(() => items.id),
  agreementId: uuid("agreement_id").references(() => liveryAgreements.id),
  quantity: numeric("quantity").notNull().default("1"),
  base: numeric("base"),
  price: numeric("price").notNull(),
  transactionDate: text("transaction_date").notNull(),
  billingMonth: text("billing_month"),
  billed: boolean("billed").notNull().default(false),
  invoiceId: uuid("invoice_id"),
  userId: uuid("user_id").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
}, (table) => ({
  uniqueLiveryAgreementMonth: uniqueIndex("billing_elements_agreement_month_unique")
    .on(table.agreementId, table.billingMonth)
    .where(sql`${table.agreementId} IS NOT NULL`),
}));

export const insertBillingElementSchema = createInsertSchema(billingElements).omit({ id: true, createdAt: true });
export type InsertBillingElement = z.infer<typeof insertBillingElementSchema>;
export type BillingElement = typeof billingElements.$inferSelect;

export const invoices = pgTable("invoices", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  netsuiteId: text("netsuite_id"),
  customerId: uuid("customer_id").notNull().references(() => customers.id),
  invoiceDate: text("invoice_date").notNull(),
  billingMonth: text("billing_month"),
  totalAmount: numeric("total_amount").notNull(),
  status: text("status").notNull().default("DRAFT"),
  soGenerated: boolean("so_generated").notNull().default(false),
  sentToNetsuite: boolean("sent_to_netsuite").notNull().default(false),
  poNumber: text("po_number"),
  netsuiteJson: text("netsuite_json"),
}, (table) => ({
  uniquePoNumber: unique("invoices_po_number_unique").on(table.poNumber),
}));

export const agreementDocuments = pgTable("agreement_documents", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  agreementId: uuid("agreement_id").notNull().references(() => liveryAgreements.id),
  filename: text("filename").notNull(),
  fileData: text("file_data").notNull(),
  uploadedAt: timestamp("uploaded_at").defaultNow(),
});

export const insertAgreementDocumentSchema = createInsertSchema(agreementDocuments).omit({ id: true, uploadedAt: true });
export type InsertAgreementDocument = z.infer<typeof insertAgreementDocumentSchema>;
export type AgreementDocument = typeof agreementDocuments.$inferSelect;

export const appSettings = pgTable("app_settings", {
  key: text("key").primaryKey(),
  value: text("value").notNull(),
});

export const insertInvoiceSchema = createInsertSchema(invoices).omit({ id: true });
export type InsertInvoice = z.infer<typeof insertInvoiceSchema>;
export type Invoice = typeof invoices.$inferSelect;

export const auditLogs = pgTable("audit_logs", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  userId: text("user_id"),
  username: text("username"),
  action: text("action").notNull(),
  entityType: text("entity_type"),
  entityId: text("entity_id"),
  details: text("details"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const insertAuditLogSchema = createInsertSchema(auditLogs).omit({ id: true, createdAt: true });
export type InsertAuditLog = z.infer<typeof insertAuditLogSchema>;
export type AuditLog = typeof auditLogs.$inferSelect;

export const invoiceValidations = pgTable("invoice_validations", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  invoiceId: uuid("invoice_id").notNull().references(() => invoices.id),
  step: text("step").notNull(),
  action: text("action").notNull(),
  userId: uuid("user_id").notNull().references(() => users.id),
  comment: text("comment"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const insertInvoiceValidationSchema = createInsertSchema(invoiceValidations).omit({ id: true, createdAt: true });
export type InsertInvoiceValidation = z.infer<typeof insertInvoiceValidationSchema>;
export type InvoiceValidation = typeof invoiceValidations.$inferSelect;

export const horseOwnership = pgTable("horse_ownership", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  horseId: uuid("horse_id").notNull().references(() => horses.id),
  customerId: uuid("customer_id").notNull().references(() => customers.id),
  createdAt: timestamp("created_at").defaultNow(),
});

export const insertHorseOwnershipSchema = createInsertSchema(horseOwnership).omit({ id: true, createdAt: true });
export type InsertHorseOwnership = z.infer<typeof insertHorseOwnershipSchema>;
export type HorseOwnership = typeof horseOwnership.$inferSelect;

export const monthlyBillingApprovals = pgTable("monthly_billing_approvals", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  customerId: uuid("customer_id").notNull().references(() => customers.id),
  billingMonth: text("billing_month").notNull(),
  step: text("step").notNull(),
  userId: uuid("user_id").notNull().references(() => users.id),
  approved: boolean("approved").notNull().default(false),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const insertMonthlyBillingApprovalSchema = createInsertSchema(monthlyBillingApprovals).omit({ id: true, createdAt: true, updatedAt: true });
export type InsertMonthlyBillingApproval = z.infer<typeof insertMonthlyBillingApprovalSchema>;
export type MonthlyBillingApproval = typeof monthlyBillingApprovals.$inferSelect;

export const horseMovements = pgTable("horse_movements", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  agreementId: uuid("agreement_id").references(() => liveryAgreements.id),
  horseId: uuid("horse_id").notNull().references(() => horses.id),
  stableboxId: uuid("stablebox_id").notNull().references(() => boxes.id),
  checkIn: text("check_in").notNull(),
  checkOut: text("check_out"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const insertHorseMovementSchema = createInsertSchema(horseMovements).omit({ id: true, createdAt: true });
export type InsertHorseMovement = z.infer<typeof insertHorseMovementSchema>;
export type HorseMovement = typeof horseMovements.$inferSelect;

// ---------------------------------------------------------------------------
// Shared resources (used by both Livery and Riding School)
// ---------------------------------------------------------------------------

export const arenas = pgTable("arenas", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  name: text("name").notNull(),
  status: text("status").notNull().default("active"),
});

export const insertArenaSchema = createInsertSchema(arenas).omit({ id: true });
export type InsertArena = z.infer<typeof insertArenaSchema>;
export type Arena = typeof arenas.$inferSelect;

export const instructors = pgTable("instructors", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  name: text("name").notNull(),
  status: text("status").notNull().default("active"),
  userId: uuid("user_id").references(() => users.id),
});

export const insertInstructorSchema = createInsertSchema(instructors).omit({ id: true });
export type InsertInstructor = z.infer<typeof insertInstructorSchema>;
export type Instructor = typeof instructors.$inferSelect;

export const riderLevels = pgTable("rider_levels", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  name: text("name").notNull(),
  sortOrder: integer("sort_order").notNull().default(0),
});

export const insertRiderLevelSchema = createInsertSchema(riderLevels).omit({ id: true });
export type InsertRiderLevel = z.infer<typeof insertRiderLevelSchema>;
export type RiderLevel = typeof riderLevels.$inferSelect;

// Append-only history; no update/delete — always insert a new row to change status.
export const horseWellbeingStatus = pgTable("horse_wellbeing_status", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  horseId: uuid("horse_id").notNull().references(() => horses.id),
  statusTag: text("status_tag").notNull(),
  note: text("note"),
  setBy: uuid("set_by").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
});

export const insertHorseWellbeingStatusSchema = createInsertSchema(horseWellbeingStatus).omit({ id: true, createdAt: true });
export type InsertHorseWellbeingStatus = z.infer<typeof insertHorseWellbeingStatusSchema>;
export type HorseWellbeingStatus = typeof horseWellbeingStatus.$inferSelect;

// ---------------------------------------------------------------------------
// Riding School — customer/rider identity
// ---------------------------------------------------------------------------

// A person who rides — either the billing/master account holder themselves,
// or a child/family member managed (booked, cancelled) by the master account.
export const riders = pgTable("riders", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  customerId: uuid("customer_id").notNull().references(() => customers.id),
  fullName: text("full_name").notNull(),
  dateOfBirth: date("date_of_birth"),
  riderLevelId: uuid("rider_level_id").references(() => riderLevels.id),
  isAccountHolder: boolean("is_account_holder").notNull().default(false),
});

export const insertRiderSchema = createInsertSchema(riders).omit({ id: true });
export type InsertRider = z.infer<typeof insertRiderSchema>;
export type Rider = typeof riders.$inferSelect;

// ---------------------------------------------------------------------------
// Riding School — lessons, scheduling, bookings
// ---------------------------------------------------------------------------

export const lessonTemplates = pgTable("lesson_templates", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  name: text("name").notNull(),
  minAge: integer("min_age"),
  maxAge: integer("max_age"),
  riderLevelId: uuid("rider_level_id").references(() => riderLevels.id),
  minRiders: integer("min_riders").notNull().default(1),
  maxRiders: integer("max_riders").notNull().default(1),
  durationMinutes: integer("duration_minutes").notNull(),
  price: numeric("price").notNull(),
  isActive: boolean("is_active").notNull().default(true),
});

export const insertLessonTemplateSchema = createInsertSchema(lessonTemplates).omit({ id: true });
export type InsertLessonTemplate = z.infer<typeof insertLessonTemplateSchema>;
export type LessonTemplate = typeof lessonTemplates.$inferSelect;

export const rsLessonRecurrences = pgTable("rs_lesson_recurrences", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  templateId: uuid("template_id").notNull().references(() => lessonTemplates.id),
  instructorId: uuid("instructor_id").notNull().references(() => instructors.id),
  arenaId: uuid("arena_id").notNull().references(() => arenas.id),
  // Comma-separated day-of-week ints (0=Sun..6=Sat), e.g. "1,3,5".
  daysOfWeek: text("days_of_week").notNull(),
  startTime: text("start_time").notNull(), // "HH:mm"
  until: date("until").notNull(), // capped at 12 months out, enforced at write time
  isPublic: boolean("is_public").notNull().default(true),
});

export const insertRsLessonRecurrenceSchema = createInsertSchema(rsLessonRecurrences).omit({ id: true });
export type InsertRsLessonRecurrence = z.infer<typeof insertRsLessonRecurrenceSchema>;
export type RsLessonRecurrence = typeof rsLessonRecurrences.$inferSelect;

export const rsScheduledLessons = pgTable("rs_scheduled_lessons", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  templateId: uuid("template_id").notNull().references(() => lessonTemplates.id),
  recurrenceId: uuid("recurrence_id").references(() => rsLessonRecurrences.id),
  instructorId: uuid("instructor_id").notNull().references(() => instructors.id),
  arenaId: uuid("arena_id").notNull().references(() => arenas.id),
  startDatetime: timestamp("start_datetime").notNull(),
  endDatetime: timestamp("end_datetime").notNull(),
  capacity: integer("capacity").notNull(),
  isPublic: boolean("is_public").notNull().default(true),
  // True once this instance has been edited independently of its recurrence
  // ("this event" in the Outlook-style edit prompt) — future series edits
  // and regeneration must skip exception rows.
  isException: boolean("is_exception").notNull().default(false),
  status: text("status").notNull().default("scheduled"),
});

export const insertRsScheduledLessonSchema = createInsertSchema(rsScheduledLessons).omit({ id: true });
export type InsertRsScheduledLesson = z.infer<typeof insertRsScheduledLessonSchema>;
export type RsScheduledLesson = typeof rsScheduledLessons.$inferSelect;

export const rsBookings = pgTable("rs_bookings", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  scheduledLessonId: uuid("scheduled_lesson_id").notNull().references(() => rsScheduledLessons.id),
  riderId: uuid("rider_id").notNull().references(() => riders.id),
  bookedByUserId: uuid("booked_by_user_id").notNull().references(() => users.id),
  horseId: uuid("horse_id").references(() => horses.id),
  status: text("status").notNull().default("confirmed"),
  packagePurchaseId: uuid("package_purchase_id").references(() => rsPackagePurchases.id),
  createdAt: timestamp("created_at").defaultNow(),
});

export const insertRsBookingSchema = createInsertSchema(rsBookings).omit({ id: true, createdAt: true });
export type InsertRsBooking = z.infer<typeof insertRsBookingSchema>;
export type RsBooking = typeof rsBookings.$inferSelect;

// ---------------------------------------------------------------------------
// Riding School — packages, cancellation policy, credit vouchers
// ---------------------------------------------------------------------------

export const rsRidingPackages = pgTable("rs_riding_packages", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  name: text("name").notNull(),
  lessonTemplateCategory: text("lesson_template_category").notNull(),
  numberOfLessons: integer("number_of_lessons").notNull(),
  validityDays: integer("validity_days").notNull(),
  price: numeric("price").notNull(),
  isActive: boolean("is_active").notNull().default(true),
});

export const insertRsRidingPackageSchema = createInsertSchema(rsRidingPackages).omit({ id: true });
export type InsertRsRidingPackage = z.infer<typeof insertRsRidingPackageSchema>;
export type RsRidingPackage = typeof rsRidingPackages.$inferSelect;

export const rsPackagePurchases = pgTable("rs_package_purchases", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  customerId: uuid("customer_id").notNull().references(() => customers.id),
  packageId: uuid("package_id").notNull().references(() => rsRidingPackages.id),
  lessonsRemaining: integer("lessons_remaining").notNull(),
  validUntil: date("valid_until").notNull(),
  invoiceId: uuid("invoice_id").references(() => invoices.id),
  status: text("status").notNull().default("active"),
  purchasedAt: timestamp("purchased_at").defaultNow(),
});

export const insertRsPackagePurchaseSchema = createInsertSchema(rsPackagePurchases).omit({ id: true, purchasedAt: true });
export type InsertRsPackagePurchase = z.infer<typeof insertRsPackagePurchaseSchema>;
export type RsPackagePurchase = typeof rsPackagePurchases.$inferSelect;

export const rsCancellationPolicy = pgTable("rs_cancellation_policy", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  thresholdHours: integer("threshold_hours").notNull(),
  creditPercent: integer("credit_percent").notNull().default(100),
});

export const insertRsCancellationPolicySchema = createInsertSchema(rsCancellationPolicy).omit({ id: true });
export type InsertRsCancellationPolicy = z.infer<typeof insertRsCancellationPolicySchema>;
export type RsCancellationPolicy = typeof rsCancellationPolicy.$inferSelect;

export const rsCreditVouchers = pgTable("rs_credit_vouchers", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  customerId: uuid("customer_id").notNull().references(() => customers.id),
  lessonTemplateCategory: text("lesson_template_category").notNull(),
  sourceBookingId: uuid("source_booking_id").references(() => rsBookings.id),
  status: text("status").notNull().default("active"),
  expiresAt: date("expires_at"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const insertRsCreditVoucherSchema = createInsertSchema(rsCreditVouchers).omit({ id: true, createdAt: true });
export type InsertRsCreditVoucher = z.infer<typeof insertRsCreditVoucherSchema>;
export type RsCreditVoucher = typeof rsCreditVouchers.$inferSelect;

export const VALID_ROLES = ["ADMIN", "LIVERY_ADMIN", "VETERINARY", "STORES", "FINANCE", "VIEWER"] as const;
export type UserRole = typeof VALID_ROLES[number];

export const INVOICE_STATUSES = [
  "DRAFT", "VET_VALIDATION", "STORES_VALIDATION", "FINANCE_VALIDATION",
  "APPROVED", "PUSHED_TO_ERP", "REJECTED"
] as const;
export type InvoiceStatus = typeof INVOICE_STATUSES[number];
