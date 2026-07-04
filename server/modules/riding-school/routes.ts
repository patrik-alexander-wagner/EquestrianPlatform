import type { Express } from "express";
import { requirePermission } from "../../permissions";
import { requireAuth, validateBody, auditLog } from "../../route-helpers";
import {
  insertLessonTemplateSchema, insertRsLessonRecurrenceSchema, insertRsScheduledLessonSchema,
  insertRsRidingPackageSchema, insertRiderSchema,
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
    res.json(await ridingSchoolStorage.getLessonTemplates());
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
    const id = req.params.id as string;
    const template = await ridingSchoolStorage.getLessonTemplate(id);
    if (!template) return res.status(404).json({ message: "Lesson template not found" });
    await ridingSchoolStorage.deleteLessonTemplate(id);
    auditLog(req, "delete_lesson_template", "lesson_template", template.id, `Deleted lesson template: ${template.name}`);
    res.json({ success: true });
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

  // --- Bookings ---
  app.get("/api/riding-school/scheduled-lessons/:id/bookings", requireAuth, async (req, res) => {
    res.json(await ridingSchoolStorage.getActiveBookingsForLesson(req.params.id as string));
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

  // --- Riding packages (products) ---
  app.get("/api/riding-school/packages", requireAuth, async (_req, res) => {
    res.json(await ridingSchoolStorage.getRidingPackages());
  });

  app.post("/api/riding-school/packages", requirePermission("riding_school.packages.manage"), async (req, res) => {
    try {
      const data = validateBody(insertRsRidingPackageSchema, req.body);
      const pkg = await ridingSchoolStorage.createRidingPackage(data);
      auditLog(req, "create_riding_package", "riding_package", pkg.id, `Created riding package: ${pkg.name}`);
      res.status(201).json(pkg);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/riding-school/packages/:id", requirePermission("riding_school.packages.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const data = validateBody(insertRsRidingPackageSchema.partial(), req.body);
      const pkg = await ridingSchoolStorage.updateRidingPackage(id, data);
      if (!pkg) return res.status(404).json({ message: "Riding package not found" });
      auditLog(req, "update_riding_package", "riding_package", pkg.id, `Updated riding package: ${pkg.name}`);
      res.json(pkg);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/riding-school/packages/:id", requirePermission("riding_school.packages.manage"), async (req, res) => {
    const id = req.params.id as string;
    const pkg = await ridingSchoolStorage.getRidingPackage(id);
    if (!pkg) return res.status(404).json({ message: "Riding package not found" });
    await ridingSchoolStorage.deleteRidingPackage(id);
    auditLog(req, "delete_riding_package", "riding_package", pkg.id, `Deleted riding package: ${pkg.name}`);
    res.json({ success: true });
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

  // --- Cancellation policy (read-only reference data, admin-seeded) ---
  app.get("/api/riding-school/cancellation-policy", requireAuth, async (_req, res) => {
    res.json(await ridingSchoolStorage.getCancellationPolicies());
  });

  // --- Reports ---
  app.get("/api/riding-school/reports/summary", requirePermission("riding_school.view"), async (req, res) => {
    const from = req.query.from ? new Date(req.query.from as string) : new Date(new Date().setDate(new Date().getDate() - 30));
    const to = req.query.to ? new Date(req.query.to as string) : new Date(new Date().setDate(new Date().getDate() + 30));
    res.json(await ridingSchoolStorage.getReportSummary(from, to));
  });
}
