import type { Express } from "express";
import { requirePermission } from "../../permissions";
import { requireAuth, validateBody, auditLog } from "../../route-helpers";
import { storage } from "../../storage";
import {
  insertLessonTemplateSchema, insertRsLessonRecurrenceSchema, insertRsScheduledLessonSchema,
  insertRsRidingPackageSchema, insertRiderSchema, insertRsHorseStatusSchema,
} from "@shared/schema";
import { z } from "zod";
import { ridingSchoolStorage } from "./storage";
import {
  generateInstancesFromRecurrence, detachAndUpdateInstance, updateFutureSeries,
  bookLesson, cancelBooking,
} from "./scheduling";
import { simulatedPaymentProvider } from "./payment-provider";

// Routes for the Riding School domain. Registered from the existing
// registerRoutes() in server/routes.ts via one import + one call.
export function registerRidingSchoolRoutes(app: Express) {
  // --- Lesson templates ---
  app.get("/api/riding-school/lesson-templates", requireAuth, async (_req, res) => {
    const templates = await ridingSchoolStorage.getLessonTemplates();
    const idsWithInstances = await ridingSchoolStorage.getLessonTemplateIdsWithInstances();
    res.json(templates.map((t) => ({ ...t, hasInstances: idsWithInstances.has(t.id) })));
  });

  app.post("/api/riding-school/lesson-templates", requirePermission("riding_school.templates.manage"), async (req, res) => {
    try {
      const data = validateBody(insertLessonTemplateSchema, req.body);
      const template = await ridingSchoolStorage.createLessonTemplate(data);
      auditLog(req, "create_lesson_template", "lesson_template", template.id, `Created lesson template: ${template.name}`);
      res.status(201).json(template);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/riding-school/lesson-templates/:id", requirePermission("riding_school.templates.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const data = validateBody(insertLessonTemplateSchema.partial(), req.body);
      const template = await ridingSchoolStorage.updateLessonTemplate(id, data);
      if (!template) return res.status(404).json({ message: "Lesson template not found" });
      auditLog(req, "update_lesson_template", "lesson_template", template.id, `Updated lesson template: ${template.name}`);
      res.json(template);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/riding-school/lesson-templates/:id", requirePermission("riding_school.templates.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const template = await ridingSchoolStorage.getLessonTemplate(id);
      if (!template) return res.status(404).json({ message: "Lesson template not found" });
      await ridingSchoolStorage.deleteLessonTemplate(id);
      auditLog(req, "delete_lesson_template", "lesson_template", template.id, `Deleted lesson template: ${template.name}`);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Calendar (scheduled lessons) ---
  // GET is auth-only: both staff (admin calendar) and, later, customers
  // (portal calendar) need to read this; level/visibility filtering for
  // the customer portal is applied in M5, not here.
  app.get("/api/riding-school/scheduled-lessons", requireAuth, async (req, res) => {
    const from = req.query.from ? new Date(req.query.from as string) : new Date();
    const to = req.query.to ? new Date(req.query.to as string) : new Date(from.getTime() + 30 * 24 * 60 * 60 * 1000);
    res.json(await ridingSchoolStorage.getScheduledLessonsInRange(from, to));
  });

  app.get("/api/riding-school/scheduled-lessons/:id", requireAuth, async (req, res) => {
    const lesson = await ridingSchoolStorage.getScheduledLesson(req.params.id as string);
    if (!lesson) return res.status(404).json({ message: "Scheduled lesson not found" });
    res.json(lesson);
  });

  // Single-lesson creation (no recurrence).
  app.post("/api/riding-school/scheduled-lessons", requirePermission("riding_school.calendar.manage"), async (req, res) => {
    try {
      const data = validateBody(insertRsScheduledLessonSchema, req.body);
      const lesson = await ridingSchoolStorage.createScheduledLesson(data);
      auditLog(req, "create_scheduled_lesson", "scheduled_lesson", lesson.id, "Created single scheduled lesson");
      res.status(201).json(lesson);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Recurring creation: creates the recurrence row, then materializes
  // instances up to 12 months out (or the given `until`, whichever sooner).
  app.post("/api/riding-school/recurrences", requirePermission("riding_school.calendar.manage"), async (req, res) => {
    try {
      const data = validateBody(insertRsLessonRecurrenceSchema, req.body);
      const recurrence = await ridingSchoolStorage.createRecurrence(data);
      const instances = await generateInstancesFromRecurrence(recurrence);
      auditLog(req, "create_recurrence", "recurrence", recurrence.id, `Created recurring lesson series (${instances.length} instances)`);
      res.status(201).json({ recurrence, instanceCount: instances.length });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Outlook-style edit: "this event" (detach) vs "the series" (bulk update).
  app.patch("/api/riding-school/scheduled-lessons/:id", requirePermission("riding_school.calendar.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const scope = (req.body.scope === "series" ? "series" : "instance") as "instance" | "series";
      const updates = validateBody(
        z.object({
          instructorId: z.string().uuid().optional(),
          arenaId: z.string().uuid().optional(),
          startDatetime: z.coerce.date().optional(),
          endDatetime: z.coerce.date().optional(),
          capacity: z.number().int().positive().optional(),
          isPublic: z.boolean().optional(),
          status: z.string().optional(),
        }),
        req.body,
      );

      if (scope === "series") {
        const lesson = await ridingSchoolStorage.getScheduledLesson(id);
        if (!lesson || !lesson.recurrenceId) return res.status(400).json({ message: "This lesson is not part of a series" });
        const count = await updateFutureSeries(lesson.recurrenceId, updates);
        auditLog(req, "update_lesson_series", "recurrence", lesson.recurrenceId, `Updated ${count} future instance(s)`);
        return res.json({ updatedCount: count });
      }

      const lesson = await detachAndUpdateInstance(id, updates);
      if (!lesson) return res.status(404).json({ message: "Scheduled lesson not found" });
      auditLog(req, "update_lesson_instance", "scheduled_lesson", lesson.id, "Updated single lesson instance");
      res.json(lesson);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Preview for the delete-confirmation dialog: which dates "delete this and
  // following events" would actually remove (same set updateFutureSeries
  // would update — future, non-exception instances only).
  app.get("/api/riding-school/recurrences/:id/future-instances", requireAuth, async (req, res) => {
    res.json(await ridingSchoolStorage.getFutureNonExceptionInstances(req.params.id as string, new Date()));
  });

  // Deletes an instance ("this occurrence") or a whole future series ("this
  // and following events"), refusing whenever any affected instance still
  // has an active booking — the admin must cancel those first, or fall back
  // to deleting only the unbooked occurrences individually.
  app.delete("/api/riding-school/scheduled-lessons/:id", requirePermission("riding_school.calendar.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const scope = (req.query.scope === "series" ? "series" : "instance") as "instance" | "series";
      const lesson = await ridingSchoolStorage.getScheduledLesson(id);
      if (!lesson) return res.status(404).json({ message: "Scheduled lesson not found" });

      if (scope === "series") {
        if (!lesson.recurrenceId) return res.status(400).json({ message: "This lesson is not part of a series" });
        const instances = await ridingSchoolStorage.getFutureNonExceptionInstances(lesson.recurrenceId, new Date());
        const ids = instances.map((i) => i.id);
        const bookings = await ridingSchoolStorage.getActiveBookingsForLessons(ids);
        if (bookings.length > 0) {
          const blockedCount = new Set(bookings.map((b) => b.scheduledLessonId)).size;
          return res.status(400).json({
            message: `Cannot delete series: ${blockedCount} lesson(s) in this series have active bookings. Cancel those bookings first, or delete individual occurrences instead.`,
          });
        }
        await ridingSchoolStorage.cancelScheduledLessons(ids);
        auditLog(req, "delete_lesson_series", "recurrence", lesson.recurrenceId, `Deleted ${ids.length} future instance(s) of the series`);
        return res.json({ deletedCount: ids.length });
      }

      const bookings = await ridingSchoolStorage.getActiveBookingsForLesson(id);
      if (bookings.length > 0) {
        return res.status(400).json({ message: `Cannot delete: ${bookings.length} rider(s) are booked on this lesson. Cancel their booking(s) first.` });
      }
      await ridingSchoolStorage.cancelScheduledLessons([id]);
      auditLog(req, "delete_lesson_instance", "scheduled_lesson", id, "Deleted single lesson instance");
      res.json({ deletedCount: 1 });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Bookings ---
  app.get("/api/riding-school/scheduled-lessons/:id/bookings", requireAuth, async (req, res) => {
    res.json(await ridingSchoolStorage.getActiveBookingsForLesson(req.params.id as string));
  });

  // Bulk lookup for the calendar's Horses/Customers resource axes — avoids
  // an N+1 fetch per lesson in the visible range.
  app.get("/api/riding-school/bookings", requireAuth, async (req, res) => {
    const from = req.query.from ? new Date(req.query.from as string) : new Date();
    const to = req.query.to ? new Date(req.query.to as string) : new Date(from.getTime() + 30 * 24 * 60 * 60 * 1000);
    res.json(await ridingSchoolStorage.getConfirmedBookingsInRange(from, to));
  });

  // Admin Booking History list — every customer interaction (booked or
  // cancelled) with a scheduled lesson, not just currently-confirmed ones.
  app.get("/api/riding-school/bookings/history", requirePermission("riding_school.view"), async (req, res) => {
    const from = req.query.from ? new Date(req.query.from as string) : new Date(new Date().setDate(new Date().getDate() - 30));
    const to = req.query.to ? new Date(req.query.to as string) : new Date(new Date().setDate(new Date().getDate() + 30));
    res.json(await ridingSchoolStorage.getBookingHistoryInRange(from, to));
  });

  const bookLessonSchema = z.object({
    scheduledLessonId: z.string().uuid(),
    riderId: z.string().uuid(),
    horseId: z.string().uuid().optional(),
    packagePurchaseId: z.string().uuid().optional(),
  });

  app.post("/api/riding-school/bookings", requirePermission("riding_school.bookings.manage"), async (req, res) => {
    try {
      const data = validateBody(bookLessonSchema, req.body);
      const user = req.user as any;
      const booking = await bookLesson({ ...data, bookedByUserId: user.id });
      auditLog(req, "create_booking", "booking", booking.id, `Booked rider ${data.riderId} onto lesson ${data.scheduledLessonId}`);
      res.status(201).json(booking);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/riding-school/bookings/:id/cancel", requirePermission("riding_school.bookings.manage"), async (req, res) => {
    try {
      const result = await cancelBooking(req.params.id as string);
      auditLog(
        req, "cancel_booking", "booking", result.booking.id,
        `Cancelled booking (credit: ${result.creditPercent}%, refundedToPackage: ${result.refundedToPackage}, voucherIssued: ${result.voucherIssued})`,
      );
      res.json(result);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Riders (managed by staff on behalf of a customer; M5 adds the
  // customer-portal self-service surface on top of the same storage) ---
  // All-riders lookup for the calendar's Customers resource axis (resolves
  // a booking's riderId to its owning customerId).
  app.get("/api/riding-school/riders", requireAuth, async (_req, res) => {
    res.json(await ridingSchoolStorage.getAllRiders());
  });

  app.get("/api/riding-school/customers/:customerId/riders", requireAuth, async (req, res) => {
    res.json(await ridingSchoolStorage.getRidersForCustomer(req.params.customerId as string));
  });

  app.post("/api/riding-school/riders", requirePermission("riding_school.bookings.manage"), async (req, res) => {
    try {
      const data = validateBody(insertRiderSchema, req.body);
      const rider = await ridingSchoolStorage.createRider(data);
      auditLog(req, "create_rider", "rider", rider.id, `Created rider: ${rider.fullName}`);
      res.status(201).json(rider);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/riding-school/riders/:id", requirePermission("riding_school.bookings.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const data = validateBody(insertRiderSchema.partial(), req.body);
      const rider = await ridingSchoolStorage.updateRider(id, data);
      if (!rider) return res.status(404).json({ message: "Rider not found" });
      auditLog(req, "update_rider", "rider", rider.id, `Updated rider: ${rider.fullName}`);
      res.json(rider);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Riding packages ("Terms / Riding Package" products) ---
  app.get("/api/riding-school/packages", requireAuth, async (_req, res) => {
    const [packages, links] = await Promise.all([
      ridingSchoolStorage.getRidingPackages(),
      ridingSchoolStorage.getAllPackageTemplateLinks(),
    ]);
    const templateIdsByPackage: Record<string, string[]> = {};
    for (const link of links) (templateIdsByPackage[link.packageId] ||= []).push(link.templateId);
    res.json(packages.map((p) => ({ ...p, templateIds: templateIdsByPackage[p.id] || [] })));
  });

  app.post("/api/riding-school/packages", requirePermission("riding_school.packages.manage"), async (req, res) => {
    try {
      const { templateIds, ...body } = req.body;
      const data = validateBody(insertRsRidingPackageSchema, body);
      const ids: string[] = Array.isArray(templateIds) ? templateIds : [];
      if (ids.length === 0) return res.status(400).json({ message: "At least one lesson template is required" });
      const pkg = await ridingSchoolStorage.createRidingPackage(data);
      await ridingSchoolStorage.setPackageTemplates(pkg.id, ids);
      auditLog(req, "create_riding_package", "riding_package", pkg.id, `Created riding package: ${pkg.name}`);
      res.status(201).json({ ...pkg, templateIds: ids });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/riding-school/packages/:id", requirePermission("riding_school.packages.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const { templateIds, ...body } = req.body;
      const data = validateBody(insertRsRidingPackageSchema.partial(), body);
      const pkg = await ridingSchoolStorage.updateRidingPackage(id, data);
      if (!pkg) return res.status(404).json({ message: "Riding package not found" });
      if (templateIds !== undefined) {
        const ids: string[] = Array.isArray(templateIds) ? templateIds : [];
        if (ids.length === 0) return res.status(400).json({ message: "At least one lesson template is required" });
        await ridingSchoolStorage.setPackageTemplates(id, ids);
      }
      auditLog(req, "update_riding_package", "riding_package", pkg.id, `Updated riding package: ${pkg.name}`);
      res.json({ ...pkg, templateIds: templateIds ?? await ridingSchoolStorage.getTemplateIdsForPackage(id) });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/riding-school/packages/:id", requirePermission("riding_school.packages.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const pkg = await ridingSchoolStorage.getRidingPackage(id);
      if (!pkg) return res.status(404).json({ message: "Riding package not found" });
      await ridingSchoolStorage.deleteRidingPackage(id);
      auditLog(req, "delete_riding_package", "riding_package", pkg.id, `Deleted riding package: ${pkg.name}`);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Package purchases (simulated payment: Phase 1) ---
  app.get("/api/riding-school/customers/:customerId/package-purchases", requireAuth, async (req, res) => {
    res.json(await ridingSchoolStorage.getPackagePurchasesForCustomer(req.params.customerId as string));
  });

  const purchasePackageSchema = z.object({
    customerId: z.string().uuid(),
    packageId: z.string().uuid(),
  });

  app.post("/api/riding-school/package-purchases", requirePermission("riding_school.packages.manage"), async (req, res) => {
    try {
      const { customerId, packageId } = validateBody(purchasePackageSchema, req.body);
      const pkg = await ridingSchoolStorage.getRidingPackage(packageId);
      if (!pkg) return res.status(404).json({ message: "Riding package not found" });

      const { invoiceId } = await simulatedPaymentProvider.createCharge({
        customerId,
        amount: pkg.price,
        description: `Riding package purchase: ${pkg.name}`,
      });

      const validUntil = new Date();
      validUntil.setDate(validUntil.getDate() + pkg.validityDays);

      const purchase = await ridingSchoolStorage.createPackagePurchase({
        customerId,
        packageId,
        lessonsRemaining: pkg.numberOfLessons,
        validUntil: validUntil.toISOString().slice(0, 10),
        invoiceId,
        status: "active",
      });

      auditLog(req, "purchase_riding_package", "package_purchase", purchase.id, `Purchased package: ${pkg.name}`);
      res.status(201).json(purchase);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Credit vouchers ---
  app.get("/api/riding-school/customers/:customerId/credit-vouchers", requireAuth, async (req, res) => {
    res.json(await ridingSchoolStorage.getCreditVouchersForCustomer(req.params.customerId as string));
  });

  // --- Cancellation policy: single row, editable from Settings ---
  app.get("/api/riding-school/cancellation-policy", requireAuth, async (_req, res) => {
    const policy = await ridingSchoolStorage.getCancellationPolicy();
    res.json(policy || { thresholdHours: 24 });
  });

  app.patch("/api/riding-school/cancellation-policy", requirePermission("riding_school.settings.manage"), async (req, res) => {
    try {
      const { thresholdHours } = validateBody(z.object({ thresholdHours: z.number().int().min(0) }), req.body);
      const policy = await ridingSchoolStorage.upsertCancellationPolicy(thresholdHours);
      auditLog(req, "update_cancellation_policy", "cancellation_policy", policy.id, `Set cancellation notice to ${thresholdHours}h`);
      res.json(policy);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Riding School horse roster + status ---
  // The full horse+owner catalog for the "Assign Riding School Horses" picker
  // is served by the existing GET /api/horses-with-owners (already includes
  // isRidingSchoolHorse); this endpoint is just the filtered, status-joined
  // list for the Horse Management page itself.
  app.get("/api/riding-school/horses", requireAuth, async (_req, res) => {
    const allHorses = await storage.getHorsesWithOwners();
    const rsHorses = allHorses.filter((h: any) => h.isRidingSchoolHorse);
    const statusByHorse = await ridingSchoolStorage.getLatestHorseStatusForHorses(rsHorses.map((h: any) => h.horseId));
    res.json(rsHorses.map((h: any) => ({ ...h, status: statusByHorse.get(h.horseId) || null })));
  });

  app.post("/api/riding-school/horses/assignments", requirePermission("riding_school.horses.manage"), async (req, res) => {
    try {
      const { horseIds } = validateBody(z.object({ horseIds: z.array(z.string().uuid()) }), req.body);
      await storage.setRidingSchoolHorses(horseIds);
      auditLog(req, "assign_riding_school_horses", "horse", "bulk", `Set Riding School roster to ${horseIds.length} horse(s)`);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/riding-school/horses/:horseId/status-history", requireAuth, async (req, res) => {
    res.json(await ridingSchoolStorage.getHorseStatusHistory(req.params.horseId as string));
  });

  app.post("/api/riding-school/horses/:horseId/status", requirePermission("riding_school.horses.manage"), async (req, res) => {
    try {
      const horseId = req.params.horseId as string;
      const user = req.user as any;
      const data = validateBody(insertRsHorseStatusSchema, {
        ...req.body,
        horseId,
        setBy: user?.id || null,
      });
      const entry = await ridingSchoolStorage.createHorseStatus(data);
      auditLog(req, "set_riding_school_horse_status", "horse", horseId, `Set status: ${entry.mood}`);
      res.status(201).json(entry);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Reports ---
  app.get("/api/riding-school/reports/summary", requirePermission("riding_school.view"), async (req, res) => {
    const from = req.query.from ? new Date(req.query.from as string) : new Date(new Date().setDate(new Date().getDate() - 30));
    const to = req.query.to ? new Date(req.query.to as string) : new Date(new Date().setDate(new Date().getDate() + 30));
    res.json(await ridingSchoolStorage.getReportSummary(from, to));
  });
}
