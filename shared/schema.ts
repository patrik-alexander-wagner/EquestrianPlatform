import { sql } from "drizzle-orm";
import { pgTable, text, varchar, integer, numeric, boolean, date, timestamp, uuid } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const users = pgTable("users", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  role: text("role").notNull().default("user"),
});

export const insertUserSchema = createInsertSchema(users).omit({ id: true });
export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof users.$inferSelect;

export const customers = pgTable("customers", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  netsuiteId: text("netsuite_id"),
  firstname: text("firstname").notNull(),
  lastname: text("lastname").notNull(),
  phone: text("phone"),
  email: text("email"),
  status: text("status").notNull().default("active"),
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
  department: text("department"),
  class: text("class"),
  location: text("location"),
  isInactive: boolean("is_inactive").notNull().default(false),
  status: text("status").notNull().default("active"),
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
  horseId: uuid("horse_id").references(() => horses.id),
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
  quantity: integer("quantity").notNull().default(1),
  base: numeric("base"),
  price: numeric("price").notNull(),
  transactionDate: text("transaction_date").notNull(),
  billingMonth: text("billing_month"),
  billed: boolean("billed").notNull().default(false),
  invoiceId: uuid("invoice_id"),
  createdAt: timestamp("created_at").defaultNow(),
});

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
  status: text("status").notNull().default("pending"),
  soGenerated: boolean("so_generated").notNull().default(false),
  sentToNetsuite: boolean("sent_to_netsuite").notNull().default(false),
  poNumber: text("po_number"),
  netsuiteJson: text("netsuite_json"),
});

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
