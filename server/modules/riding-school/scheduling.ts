import { db } from "../../db";
import { eq, and, sql } from "drizzle-orm";
import {
  rsScheduledLessons, rsBookings, rsLessonRecurrences, lessonTemplates, riders, riderLevels,
  rsPackagePurchases, rsPackageTemplates, rsCreditVouchers,
  type RsScheduledLesson, type RsBooking, type RsLessonRecurrence,
} from "@shared/schema";
import { ridingSchoolStorage } from "./storage";
import { computeRecurrenceInstanceDates, getsFullRefund, riderLevelAllowed } from "./scheduling-logic";

const MAX_RECURRENCE_MONTHS = 12;

// Materializes rs_scheduled_lessons rows from a recurrence, starting today
// through its `until` date (hard-capped at 12 months regardless of what
// `until` claims, as a safety net against a bad admin input reaching here).
export async function generateInstancesFromRecurrence(recurrence: RsLessonRecurrence): Promise<RsScheduledLesson[]> {
  const template = await ridingSchoolStorage.getLessonTemplate(recurrence.templateId);
  if (!template) throw { status: 400, message: "Lesson template not found for recurrence" };

  const instances = computeRecurrenceInstanceDates(
    recurrence.daysOfWeek,
    recurrence.startTime,
    new Date(recurrence.until),
    template.durationMinutes,
    new Date(),
    MAX_RECURRENCE_MONTHS,
  );

  return ridingSchoolStorage.createScheduledLessons(
    instances.map(({ start, end }) => ({
      templateId: recurrence.templateId,
      recurrenceId: recurrence.id,
      instructorId: recurrence.instructorId,
      arenaId: recurrence.arenaId,
      startDatetime: start,
      endDatetime: end,
      capacity: template.maxRiders,
      isPublic: recurrence.isPublic,
      isException: false,
      status: "scheduled",
    })),
  );
}

// Outlook-style "edit this event only": detaches the instance from its
// recurrence's future regeneration by flipping isException.
export async function detachAndUpdateInstance(
  scheduledLessonId: string,
  updates: Partial<{ instructorId: string; arenaId: string; startDatetime: Date; endDatetime: Date; capacity: number; isPublic: boolean; status: string }>,
): Promise<RsScheduledLesson | undefined> {
  return ridingSchoolStorage.updateScheduledLesson(scheduledLessonId, { ...updates, isException: true });
}

// Outlook-style "edit the series": applies to all future, non-exception
// instances of a recurrence — never past ones, never ones already detached.
export async function updateFutureSeries(
  recurrenceId: string,
  updates: Partial<{ instructorId: string; arenaId: string; capacity: number; isPublic: boolean }>,
): Promise<number> {
  const instances = await ridingSchoolStorage.getFutureNonExceptionInstances(recurrenceId, new Date());
  for (const instance of instances) {
    await ridingSchoolStorage.updateScheduledLesson(instance.id, updates);
  }
  return instances.length;
}

export interface BookLessonInput {
  scheduledLessonId: string;
  riderId: string;
  bookedByUserId: string;
  horseId?: string;
  packagePurchaseId?: string;
}

// The core booking transaction: locks the target lesson row, validates
// capacity / rider level / horse availability, optionally redeems a package,
// then inserts the booking. All under one transaction so two concurrent
// bookings can never both succeed past capacity (mirrors the atomic-write
// precedent used elsewhere in this codebase for race-sensitive counters).
export async function bookLesson(input: BookLessonInput): Promise<RsBooking> {
  return db.transaction(async (tx) => {
    const [lesson] = await tx.select().from(rsScheduledLessons)
      .where(eq(rsScheduledLessons.id, input.scheduledLessonId))
      .for("update");
    if (!lesson) throw { status: 404, message: "Scheduled lesson not found" };
    if (lesson.status !== "scheduled") throw { status: 400, message: "This lesson is no longer available for booking" };

    const [template] = await tx.select().from(lessonTemplates).where(eq(lessonTemplates.id, lesson.templateId));
    if (!template) throw { status: 400, message: "Lesson template not found" };

    const [rider] = await tx.select().from(riders).where(eq(riders.id, input.riderId));
    if (!rider) throw { status: 404, message: "Rider not found" };

    const allLevels = await tx.select().from(riderLevels);
    const sortOrderById = Object.fromEntries(allLevels.map((l) => [l.id, l.sortOrder]));
    const riderSortOrder = rider.riderLevelId ? sortOrderById[rider.riderLevelId] : null;
    const minSortOrder = template.minRiderLevelId ? sortOrderById[template.minRiderLevelId] : null;
    const maxSortOrder = template.maxRiderLevelId ? sortOrderById[template.maxRiderLevelId] : null;
    if (!riderLevelAllowed(riderSortOrder, minSortOrder, maxSortOrder)) {
      throw { status: 400, message: "This class is not available for the rider's level" };
    }

    const activeBookings = await tx.select().from(rsBookings)
      .where(and(eq(rsBookings.scheduledLessonId, input.scheduledLessonId), eq(rsBookings.status, "confirmed")));
    if (activeBookings.length >= lesson.capacity) {
      throw { status: 400, message: "This class is fully booked" };
    }

    if (input.horseId) {
      const horseAlreadyUsed = activeBookings.some((b) => b.horseId === input.horseId);
      if (horseAlreadyUsed) throw { status: 400, message: "This horse is already assigned in this class" };
    }

    if (input.packagePurchaseId) {
      const [pkg] = await tx.select().from(rsPackagePurchases).where(eq(rsPackagePurchases.id, input.packagePurchaseId));
      if (!pkg) throw { status: 404, message: "Package purchase not found" };
      if (pkg.customerId !== rider.customerId) throw { status: 400, message: "This package does not belong to the rider's account" };
      if (pkg.status !== "active" || pkg.lessonsRemaining <= 0) throw { status: 400, message: "This package has no lessons remaining" };
      if (new Date(pkg.validUntil) < new Date()) throw { status: 400, message: "This package has expired" };

      const eligibleTemplates = await tx.select().from(rsPackageTemplates).where(eq(rsPackageTemplates.packageId, pkg.packageId));
      if (!eligibleTemplates.some((et) => et.templateId === lesson.templateId)) {
        throw { status: 400, message: "This package cannot be used for this lesson" };
      }

      const [updated] = await tx.update(rsPackagePurchases)
        .set({ lessonsRemaining: sql`${rsPackagePurchases.lessonsRemaining} - 1` })
        .where(and(eq(rsPackagePurchases.id, input.packagePurchaseId), sql`${rsPackagePurchases.lessonsRemaining} > 0`))
        .returning();
      if (!updated) throw { status: 400, message: "This package has no lessons remaining" };
    }

    const [booking] = await tx.insert(rsBookings).values({
      scheduledLessonId: input.scheduledLessonId,
      riderId: input.riderId,
      bookedByUserId: input.bookedByUserId,
      horseId: input.horseId,
      packagePurchaseId: input.packagePurchaseId,
      status: "confirmed",
    }).returning();

    return booking;
  });
}

export interface CancelBookingResult {
  booking: RsBooking;
  creditPercent: number;
  refundedToPackage: boolean;
  voucherIssued: boolean;
}

// Applies the single-field cancellation policy: cancel with at least
// policy.thresholdHours notice and get a full refund (credit/voucher);
// cancel later than that and get nothing. `creditPercent` in the result is
// just 100 or 0 — kept as a percent for API-shape compatibility, but there's
// no partial-credit tier anymore.
export async function cancelBooking(bookingId: string): Promise<CancelBookingResult> {
  return db.transaction(async (tx) => {
    const [booking] = await tx.select().from(rsBookings).where(eq(rsBookings.id, bookingId)).for("update");
    if (!booking) throw { status: 404, message: "Booking not found" };
    if (booking.status !== "confirmed") throw { status: 400, message: "This booking is not active" };

    const [lesson] = await tx.select().from(rsScheduledLessons).where(eq(rsScheduledLessons.id, booking.scheduledLessonId));
    if (!lesson) throw { status: 400, message: "Scheduled lesson not found" };

    const [rider] = await tx.select().from(riders).where(eq(riders.id, booking.riderId));
    if (!rider) throw { status: 400, message: "Rider not found" };

    const [template] = await tx.select().from(lessonTemplates).where(eq(lessonTemplates.id, lesson.templateId));

    const hoursUntilLesson = (new Date(lesson.startDatetime).getTime() - Date.now()) / (60 * 60 * 1000);
    const policy = await ridingSchoolStorage.getCancellationPolicy();
    const fullRefund = getsFullRefund(hoursUntilLesson, policy?.thresholdHours ?? 0);
    const creditPercent = fullRefund ? 100 : 0;

    let refundedToPackage = false;
    let voucherIssued = false;

    if (fullRefund) {
      if (booking.packagePurchaseId) {
        await tx.update(rsPackagePurchases)
          .set({ lessonsRemaining: sql`${rsPackagePurchases.lessonsRemaining} + 1` })
          .where(eq(rsPackagePurchases.id, booking.packagePurchaseId));
        refundedToPackage = true;
      } else {
        await tx.insert(rsCreditVouchers).values({
          customerId: rider.customerId,
          lessonTemplateCategory: template?.name ?? "General",
          sourceBookingId: booking.id,
          status: "active",
        });
        voucherIssued = true;
      }
    }

    const [updated] = await tx.update(rsBookings).set({ status: "cancelled" }).where(eq(rsBookings.id, bookingId)).returning();

    return { booking: updated, creditPercent, refundedToPackage, voucherIssued };
  });
}
