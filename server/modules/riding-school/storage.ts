import { db } from "../../db";
import { eq, and, gte, lte, desc, sql } from "drizzle-orm";
import {
  lessonTemplates, rsLessonRecurrences, rsScheduledLessons, rsBookings,
  rsRidingPackages, rsPackagePurchases, rsCancellationPolicy, rsCreditVouchers, riders,
  type InsertLessonTemplate, type LessonTemplate,
  type InsertRsLessonRecurrence, type RsLessonRecurrence,
  type InsertRsScheduledLesson, type RsScheduledLesson,
  type InsertRsBooking, type RsBooking,
  type InsertRsRidingPackage, type RsRidingPackage,
  type InsertRsPackagePurchase, type RsPackagePurchase,
  type RsCancellationPolicy,
  type InsertRsCreditVoucher, type RsCreditVoucher,
  type InsertRider, type Rider,
} from "@shared/schema";

// Storage for the Riding School domain — lesson templates, scheduling,
// bookings, packages, cancellation credits. Kept separate from
// server/storage.ts's IStorage/DatabaseStorage on purpose (module boundary).
export const ridingSchoolStorage = {
  // --- Lesson templates ---
  async getLessonTemplates(): Promise<LessonTemplate[]> {
    return db.select().from(lessonTemplates);
  },
  async getLessonTemplate(id: string): Promise<LessonTemplate | undefined> {
    const [row] = await db.select().from(lessonTemplates).where(eq(lessonTemplates.id, id));
    return row;
  },
  async createLessonTemplate(data: InsertLessonTemplate): Promise<LessonTemplate> {
    const [row] = await db.insert(lessonTemplates).values(data).returning();
    return row;
  },
  async updateLessonTemplate(id: string, data: Partial<InsertLessonTemplate>): Promise<LessonTemplate | undefined> {
    const [row] = await db.update(lessonTemplates).set(data).where(eq(lessonTemplates.id, id)).returning();
    return row;
  },
  async deleteLessonTemplate(id: string): Promise<void> {
    await db.delete(lessonTemplates).where(eq(lessonTemplates.id, id));
  },

  // --- Recurrences ---
  async getRecurrence(id: string): Promise<RsLessonRecurrence | undefined> {
    const [row] = await db.select().from(rsLessonRecurrences).where(eq(rsLessonRecurrences.id, id));
    return row;
  },
  async createRecurrence(data: InsertRsLessonRecurrence): Promise<RsLessonRecurrence> {
    const [row] = await db.insert(rsLessonRecurrences).values(data).returning();
    return row;
  },

  // --- Scheduled lessons ---
  async getScheduledLessonsInRange(fromDate: Date, toDate: Date): Promise<RsScheduledLesson[]> {
    return db.select().from(rsScheduledLessons)
      .where(and(gte(rsScheduledLessons.startDatetime, fromDate), lte(rsScheduledLessons.startDatetime, toDate)));
  },
  async getScheduledLesson(id: string): Promise<RsScheduledLesson | undefined> {
    const [row] = await db.select().from(rsScheduledLessons).where(eq(rsScheduledLessons.id, id));
    return row;
  },
  async createScheduledLesson(data: InsertRsScheduledLesson): Promise<RsScheduledLesson> {
    const [row] = await db.insert(rsScheduledLessons).values(data).returning();
    return row;
  },
  async createScheduledLessons(data: InsertRsScheduledLesson[]): Promise<RsScheduledLesson[]> {
    if (data.length === 0) return [];
    return db.insert(rsScheduledLessons).values(data).returning();
  },
  async updateScheduledLesson(id: string, data: Partial<InsertRsScheduledLesson>): Promise<RsScheduledLesson | undefined> {
    const [row] = await db.update(rsScheduledLessons).set(data).where(eq(rsScheduledLessons.id, id)).returning();
    return row;
  },
  async getFutureNonExceptionInstances(recurrenceId: string, fromDate: Date): Promise<RsScheduledLesson[]> {
    return db.select().from(rsScheduledLessons)
      .where(and(
        eq(rsScheduledLessons.recurrenceId, recurrenceId),
        eq(rsScheduledLessons.isException, false),
        gte(rsScheduledLessons.startDatetime, fromDate),
      ));
  },

  // --- Bookings ---
  async getActiveBookingsForLesson(scheduledLessonId: string): Promise<RsBooking[]> {
    return db.select().from(rsBookings)
      .where(and(eq(rsBookings.scheduledLessonId, scheduledLessonId), eq(rsBookings.status, "confirmed")));
  },
  async getBooking(id: string): Promise<RsBooking | undefined> {
    const [row] = await db.select().from(rsBookings).where(eq(rsBookings.id, id));
    return row;
  },
  async createBooking(data: InsertRsBooking): Promise<RsBooking> {
    const [row] = await db.insert(rsBookings).values(data).returning();
    return row;
  },
  async updateBooking(id: string, data: Partial<InsertRsBooking>): Promise<RsBooking | undefined> {
    const [row] = await db.update(rsBookings).set(data).where(eq(rsBookings.id, id)).returning();
    return row;
  },
  async getBookingsForRider(riderId: string): Promise<RsBooking[]> {
    return db.select().from(rsBookings).where(eq(rsBookings.riderId, riderId)).orderBy(desc(rsBookings.createdAt));
  },

  // --- Riders ---
  async getRidersForCustomer(customerId: string): Promise<Rider[]> {
    return db.select().from(riders).where(eq(riders.customerId, customerId));
  },
  async getRider(id: string): Promise<Rider | undefined> {
    const [row] = await db.select().from(riders).where(eq(riders.id, id));
    return row;
  },
  async createRider(data: InsertRider): Promise<Rider> {
    const [row] = await db.insert(riders).values(data).returning();
    return row;
  },
  async updateRider(id: string, data: Partial<InsertRider>): Promise<Rider | undefined> {
    const [row] = await db.update(riders).set(data).where(eq(riders.id, id)).returning();
    return row;
  },

  // --- Riding packages (products) ---
  async getRidingPackages(): Promise<RsRidingPackage[]> {
    return db.select().from(rsRidingPackages);
  },
  async getRidingPackage(id: string): Promise<RsRidingPackage | undefined> {
    const [row] = await db.select().from(rsRidingPackages).where(eq(rsRidingPackages.id, id));
    return row;
  },
  async createRidingPackage(data: InsertRsRidingPackage): Promise<RsRidingPackage> {
    const [row] = await db.insert(rsRidingPackages).values(data).returning();
    return row;
  },
  async updateRidingPackage(id: string, data: Partial<InsertRsRidingPackage>): Promise<RsRidingPackage | undefined> {
    const [row] = await db.update(rsRidingPackages).set(data).where(eq(rsRidingPackages.id, id)).returning();
    return row;
  },
  async deleteRidingPackage(id: string): Promise<void> {
    await db.delete(rsRidingPackages).where(eq(rsRidingPackages.id, id));
  },

  // --- Package purchases (a customer's owned instance of a package) ---
  async getPackagePurchasesForCustomer(customerId: string): Promise<RsPackagePurchase[]> {
    return db.select().from(rsPackagePurchases).where(eq(rsPackagePurchases.customerId, customerId));
  },
  async getPackagePurchase(id: string): Promise<RsPackagePurchase | undefined> {
    const [row] = await db.select().from(rsPackagePurchases).where(eq(rsPackagePurchases.id, id));
    return row;
  },
  async createPackagePurchase(data: InsertRsPackagePurchase): Promise<RsPackagePurchase> {
    const [row] = await db.insert(rsPackagePurchases).values(data).returning();
    return row;
  },
  // Atomic decrement guarded by lessons_remaining > 0 — returns undefined if
  // the package had no lessons left (caller must treat that as "can't redeem").
  async decrementPackageLessonsRemaining(id: string): Promise<RsPackagePurchase | undefined> {
    const [row] = await db.update(rsPackagePurchases)
      .set({ lessonsRemaining: sql`${rsPackagePurchases.lessonsRemaining} - 1` })
      .where(and(eq(rsPackagePurchases.id, id), sql`${rsPackagePurchases.lessonsRemaining} > 0`))
      .returning();
    return row;
  },
  async incrementPackageLessonsRemaining(id: string): Promise<RsPackagePurchase | undefined> {
    const [row] = await db.update(rsPackagePurchases)
      .set({ lessonsRemaining: sql`${rsPackagePurchases.lessonsRemaining} + 1` })
      .where(eq(rsPackagePurchases.id, id))
      .returning();
    return row;
  },

  // --- Cancellation policy (admin-configured reference data, seeded in M1) ---
  async getCancellationPolicies(): Promise<RsCancellationPolicy[]> {
    return db.select().from(rsCancellationPolicy).orderBy(desc(rsCancellationPolicy.thresholdHours));
  },

  // --- Credit vouchers ---
  async getCreditVouchersForCustomer(customerId: string): Promise<RsCreditVoucher[]> {
    return db.select().from(rsCreditVouchers).where(eq(rsCreditVouchers.customerId, customerId));
  },
  async createCreditVoucher(data: InsertRsCreditVoucher): Promise<RsCreditVoucher> {
    const [row] = await db.insert(rsCreditVouchers).values(data).returning();
    return row;
  },
  async redeemCreditVoucher(id: string): Promise<RsCreditVoucher | undefined> {
    const [row] = await db.update(rsCreditVouchers).set({ status: "redeemed" }).where(eq(rsCreditVouchers.id, id)).returning();
    return row;
  },

  // --- Reporting aggregates ---
  async getReportSummary(fromDate: Date, toDate: Date) {
    const [lessonsInRange] = await db.select({ count: sql<number>`count(*)::int` }).from(rsScheduledLessons)
      .where(and(gte(rsScheduledLessons.startDatetime, fromDate), lte(rsScheduledLessons.startDatetime, toDate)));
    const [confirmedBookings] = await db.select({ count: sql<number>`count(*)::int` }).from(rsBookings)
      .where(eq(rsBookings.status, "confirmed"));
    const [cancelledBookings] = await db.select({ count: sql<number>`count(*)::int` }).from(rsBookings)
      .where(eq(rsBookings.status, "cancelled"));
    const [activePackagePurchases] = await db.select({ count: sql<number>`count(*)::int` }).from(rsPackagePurchases)
      .where(eq(rsPackagePurchases.status, "active"));
    const [activeVouchers] = await db.select({ count: sql<number>`count(*)::int` }).from(rsCreditVouchers)
      .where(eq(rsCreditVouchers.status, "active"));

    return {
      lessonsInRange: lessonsInRange.count,
      confirmedBookings: confirmedBookings.count,
      cancelledBookings: cancelledBookings.count,
      activePackagePurchases: activePackagePurchases.count,
      activeVouchers: activeVouchers.count,
    };
  },
};
