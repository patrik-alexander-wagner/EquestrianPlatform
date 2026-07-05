import { db } from "../../db";
import { eq, and, gte, lte, desc, sql, inArray, ne } from "drizzle-orm";
import {
  lessonTemplates, rsLessonRecurrences, rsScheduledLessons, rsBookings,
  rsRidingPackages, rsPackageTemplates, rsPackagePurchases, rsCancellationPolicy, rsCreditVouchers, riders,
  rsHorseStatus,
  type InsertLessonTemplate, type LessonTemplate,
  type InsertRsLessonRecurrence, type RsLessonRecurrence,
  type InsertRsScheduledLesson, type RsScheduledLesson,
  type InsertRsBooking, type RsBooking,
  type InsertRsRidingPackage, type RsRidingPackage,
  type InsertRsPackagePurchase, type RsPackagePurchase,
  type RsCancellationPolicy,
  type InsertRsCreditVoucher, type RsCreditVoucher,
  type InsertRider, type Rider,
  type InsertRsHorseStatus, type RsHorseStatus,
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
  // True once a template has at least one instance — a recurring series or a
  // single scheduled lesson — anywhere on the calendar, past, present, or
  // future (rows are never deleted once a lesson has happened, so this also
  // covers "already consumed"). Templates in this state are locked: only
  // toggling isActive is allowed, everything else must go through a new
  // template instead of mutating history out from under past lessons.
  async hasLessonTemplateInstances(id: string): Promise<boolean> {
    const [recurrence] = await db.select().from(rsLessonRecurrences).where(eq(rsLessonRecurrences.templateId, id)).limit(1);
    if (recurrence) return true;
    const [lesson] = await db.select().from(rsScheduledLessons).where(eq(rsScheduledLessons.templateId, id)).limit(1);
    return !!lesson;
  },
  // Bulk variant for the templates list endpoint (avoids one query per row).
  async getLessonTemplateIdsWithInstances(): Promise<Set<string>> {
    const fromRecurrences = await db.selectDistinct({ templateId: rsLessonRecurrences.templateId }).from(rsLessonRecurrences);
    const fromLessons = await db.selectDistinct({ templateId: rsScheduledLessons.templateId }).from(rsScheduledLessons);
    return new Set([...fromRecurrences.map((r) => r.templateId), ...fromLessons.map((l) => l.templateId)]);
  },
  async createLessonTemplate(data: InsertLessonTemplate): Promise<LessonTemplate> {
    const [row] = await db.insert(lessonTemplates).values(data).returning();
    return row;
  },
  async updateLessonTemplate(id: string, data: Partial<InsertLessonTemplate>): Promise<LessonTemplate | undefined> {
    const changesOtherThanActive = Object.keys(data).some((k) => k !== "isActive");
    if (changesOtherThanActive && await this.hasLessonTemplateInstances(id)) {
      throw { status: 400, message: "Cannot edit: this template has at least one scheduled lesson (past, present, or future). Mark it inactive instead and create a new template for the change." };
    }
    const [row] = await db.update(lessonTemplates).set(data).where(eq(lessonTemplates.id, id)).returning();
    return row;
  },
  async deleteLessonTemplate(id: string): Promise<void> {
    if (await this.hasLessonTemplateInstances(id)) {
      throw { status: 400, message: "Cannot delete: this template has at least one scheduled lesson (past, present, or future). Mark it inactive instead and create a new template." };
    }
    await db.delete(rsPackageTemplates).where(eq(rsPackageTemplates.templateId, id));
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
      .where(and(
        gte(rsScheduledLessons.startDatetime, fromDate),
        lte(rsScheduledLessons.startDatetime, toDate),
        ne(rsScheduledLessons.status, "cancelled"),
      ));
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
  // Soft-delete: flips status to "cancelled" rather than removing the row.
  // A hard DELETE fails here even after the active-booking guard passes,
  // because cancelled bookings (kept as history, never removed — see
  // cancelBooking) still hold a not-null FK to rs_scheduled_lessons.id.
  // Mirrors cancelBooking's own status-flip pattern for the same reason.
  // Used for "delete this occurrence" (a single id) and "delete this and
  // following events" (the ids from getFutureNonExceptionInstances). Past
  // instances and detached exceptions are never touched by the series case,
  // mirroring updateFutureSeries's scope exactly. The recurrence row itself
  // is deliberately left in place even if this empties its future instances
  // — it's still meaningful history (and keeps hasLessonTemplateInstances
  // correctly locking the template that generated it).
  async cancelScheduledLessons(ids: string[]): Promise<void> {
    if (ids.length === 0) return;
    await db.update(rsScheduledLessons).set({ status: "cancelled" }).where(inArray(rsScheduledLessons.id, ids));
  },

  // --- Bookings ---
  async getActiveBookingsForLesson(scheduledLessonId: string): Promise<RsBooking[]> {
    return db.select().from(rsBookings)
      .where(and(eq(rsBookings.scheduledLessonId, scheduledLessonId), eq(rsBookings.status, "confirmed")));
  },
  // Bulk variant for the series-delete guard — checks every affected
  // instance in one query instead of one-per-lesson.
  async getActiveBookingsForLessons(scheduledLessonIds: string[]): Promise<RsBooking[]> {
    if (scheduledLessonIds.length === 0) return [];
    return db.select().from(rsBookings)
      .where(and(inArray(rsBookings.scheduledLessonId, scheduledLessonIds), eq(rsBookings.status, "confirmed")));
  },
  // Bulk fetch for the calendar's Horses/Customers resource axes — a lesson
  // itself only carries instructorId/arenaId, so which horses/riders are
  // involved can only be resolved through their bookings.
  async getConfirmedBookingsInRange(fromDate: Date, toDate: Date): Promise<RsBooking[]> {
    return db.select({
      id: rsBookings.id,
      scheduledLessonId: rsBookings.scheduledLessonId,
      riderId: rsBookings.riderId,
      bookedByUserId: rsBookings.bookedByUserId,
      horseId: rsBookings.horseId,
      status: rsBookings.status,
      packagePurchaseId: rsBookings.packagePurchaseId,
      createdAt: rsBookings.createdAt,
    }).from(rsBookings)
      .innerJoin(rsScheduledLessons, eq(rsBookings.scheduledLessonId, rsScheduledLessons.id))
      .where(and(
        eq(rsBookings.status, "confirmed"),
        gte(rsScheduledLessons.startDatetime, fromDate),
        lte(rsScheduledLessons.startDatetime, toDate),
      ));
  },
  // Every booking (any status — confirmed and cancelled alike), joined with
  // its lesson's date/template for the admin Booking History list. Unlike
  // getConfirmedBookingsInRange this deliberately includes cancellations —
  // that's a customer "interaction" too, not just successful bookings.
  async getBookingHistoryInRange(fromDate: Date, toDate: Date): Promise<Array<RsBooking & { lessonStartDatetime: Date; lessonTemplateId: string }>> {
    return db.select({
      id: rsBookings.id,
      scheduledLessonId: rsBookings.scheduledLessonId,
      riderId: rsBookings.riderId,
      bookedByUserId: rsBookings.bookedByUserId,
      horseId: rsBookings.horseId,
      status: rsBookings.status,
      packagePurchaseId: rsBookings.packagePurchaseId,
      createdAt: rsBookings.createdAt,
      lessonStartDatetime: rsScheduledLessons.startDatetime,
      lessonTemplateId: rsScheduledLessons.templateId,
    }).from(rsBookings)
      .innerJoin(rsScheduledLessons, eq(rsBookings.scheduledLessonId, rsScheduledLessons.id))
      .where(and(
        gte(rsScheduledLessons.startDatetime, fromDate),
        lte(rsScheduledLessons.startDatetime, toDate),
      ))
      .orderBy(desc(rsScheduledLessons.startDatetime));
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
  // Staff-side lookup (all riders, any customer) — used by the calendar's
  // Customers resource axis to resolve a booking's riderId to its owning
  // customerId. server/modules/customer-portal/routes.ts never calls this;
  // it always scopes through getRidersForCustomer instead.
  async getAllRiders(): Promise<Rider[]> {
    return db.select().from(riders);
  },
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

  // --- Riding packages ("Terms / Riding Package" products) ---
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
    const [purchase] = await db.select().from(rsPackagePurchases).where(eq(rsPackagePurchases.packageId, id)).limit(1);
    if (purchase) {
      throw { status: 400, message: "Cannot delete: at least one customer has purchased this package. Mark it inactive instead so it stops appearing for new purchases." };
    }
    await db.delete(rsPackageTemplates).where(eq(rsPackageTemplates.packageId, id));
    await db.delete(rsRidingPackages).where(eq(rsRidingPackages.id, id));
  },

  // Which lesson templates a package's balance may be redeemed against.
  async getTemplateIdsForPackage(packageId: string): Promise<string[]> {
    const rows = await db.select().from(rsPackageTemplates).where(eq(rsPackageTemplates.packageId, packageId));
    return rows.map((r) => r.templateId);
  },
  // Bulk variant for listing all packages at once (avoids N+1).
  async getAllPackageTemplateLinks(): Promise<{ packageId: string; templateId: string }[]> {
    return db.select({ packageId: rsPackageTemplates.packageId, templateId: rsPackageTemplates.templateId }).from(rsPackageTemplates);
  },
  async setPackageTemplates(packageId: string, templateIds: string[]): Promise<void> {
    await db.transaction(async (tx) => {
      await tx.delete(rsPackageTemplates).where(eq(rsPackageTemplates.packageId, packageId));
      const unique = Array.from(new Set(templateIds));
      if (unique.length > 0) {
        await tx.insert(rsPackageTemplates).values(unique.map((templateId) => ({ packageId, templateId })));
      }
    });
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

  // --- Cancellation policy: single row, admin-editable notice window ---
  async getCancellationPolicy(): Promise<RsCancellationPolicy | undefined> {
    const [row] = await db.select().from(rsCancellationPolicy).limit(1);
    return row;
  },
  async upsertCancellationPolicy(thresholdHours: number): Promise<RsCancellationPolicy> {
    const existing = await this.getCancellationPolicy();
    if (existing) {
      const [row] = await db.update(rsCancellationPolicy).set({ thresholdHours }).where(eq(rsCancellationPolicy.id, existing.id)).returning();
      return row;
    }
    const [row] = await db.insert(rsCancellationPolicy).values({ thresholdHours }).returning();
    return row;
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

  // --- Riding School horse status (append-only mood/lesson-limit history) ---
  async createHorseStatus(data: InsertRsHorseStatus): Promise<RsHorseStatus> {
    const [row] = await db.insert(rsHorseStatus).values(data).returning();
    return row;
  },
  async getHorseStatusHistory(horseId: string): Promise<RsHorseStatus[]> {
    return db.select().from(rsHorseStatus).where(eq(rsHorseStatus.horseId, horseId)).orderBy(desc(rsHorseStatus.createdAt));
  },
  // Bulk "latest status per horse" for the Horse Management list (avoids N+1).
  async getLatestHorseStatusForHorses(horseIds: string[]): Promise<Map<string, RsHorseStatus>> {
    if (horseIds.length === 0) return new Map();
    const rows = await db.select().from(rsHorseStatus)
      .where(inArray(rsHorseStatus.horseId, horseIds))
      .orderBy(desc(rsHorseStatus.createdAt));
    const latest = new Map<string, RsHorseStatus>();
    for (const row of rows) {
      if (!latest.has(row.horseId)) latest.set(row.horseId, row);
    }
    return latest;
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
