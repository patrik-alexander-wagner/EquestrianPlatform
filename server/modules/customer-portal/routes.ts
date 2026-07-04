import type { Express } from "express";
import { z } from "zod";
import { requireCustomer, validateBody, auditLog } from "../../route-helpers";
import { insertRiderSchema } from "@shared/schema";
import { storage } from "../../storage";
import { ridingSchoolStorage } from "../riding-school/storage";
import { bookLesson, cancelBooking } from "../riding-school/scheduling";
import { simulatedPaymentProvider } from "../riding-school/payment-provider";

// Routes for the Customer Portal — the self-service surface for members.
// Every route here is scoped to the logged-in customer's own data; this is
// a new trust boundary (self-service, family-account delegation) so every
// handler explicitly checks ownership rather than trusting client-supplied
// ids (a rider/booking/package-purchase id in the URL or body is never
// enough on its own — it must also belong to req.user.customerId).
export function registerCustomerPortalRoutes(app: Express) {
  function customerId(req: any): string {
    return req.effectiveCustomerId as string;
  }

  // --- Riders (the master account manages every rider under it) ---
  app.get("/api/portal/riders", requireCustomer, async (req, res) => {
    res.json(await ridingSchoolStorage.getRidersForCustomer(customerId(req)));
  });

  app.post("/api/portal/riders", requireCustomer, async (req, res) => {
    try {
      const data = validateBody(insertRiderSchema, { ...req.body, customerId: customerId(req) });
      const rider = await ridingSchoolStorage.createRider(data);
      auditLog(req, "portal_create_rider", "rider", rider.id, `Created rider: ${rider.fullName}`);
      res.status(201).json(rider);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/portal/riders/:id", requireCustomer, async (req, res) => {
    try {
      const existing = await ridingSchoolStorage.getRider(req.params.id as string);
      if (!existing || existing.customerId !== customerId(req)) {
        return res.status(404).json({ message: "Rider not found" });
      }
      const data = validateBody(insertRiderSchema.partial().omit({ customerId: true }), req.body);
      const rider = await ridingSchoolStorage.updateRider(existing.id, data);
      auditLog(req, "portal_update_rider", "rider", existing.id, `Updated rider: ${rider?.fullName}`);
      res.json(rider);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Calendar (level-filtered, public lessons only) ---
  app.get("/api/portal/calendar", requireCustomer, async (req, res) => {
    const from = req.query.from ? new Date(req.query.from as string) : new Date();
    const to = req.query.to ? new Date(req.query.to as string) : new Date(from.getTime() + 30 * 24 * 60 * 60 * 1000);

    const riders = await ridingSchoolStorage.getRidersForCustomer(customerId(req));
    const riderLevelIds = new Set(riders.map((r) => r.riderLevelId).filter(Boolean));

    const lessons = await ridingSchoolStorage.getScheduledLessonsInRange(from, to);
    const visible = [];
    for (const lesson of lessons) {
      if (!lesson.isPublic || lesson.status !== "scheduled") continue;
      const template = await ridingSchoolStorage.getLessonTemplate(lesson.templateId);
      if (template && template.riderLevelId && !riderLevelIds.has(template.riderLevelId)) continue;
      const bookings = await ridingSchoolStorage.getActiveBookingsForLesson(lesson.id);
      visible.push({ ...lesson, templateName: template?.name, price: template?.price, bookedCount: bookings.length });
    }
    res.json(visible);
  });

  // --- Bookings (across every rider under this account) ---
  app.get("/api/portal/bookings", requireCustomer, async (req, res) => {
    const riders = await ridingSchoolStorage.getRidersForCustomer(customerId(req));
    const result = [];
    for (const rider of riders) {
      const bookings = await ridingSchoolStorage.getBookingsForRider(rider.id);
      for (const booking of bookings) {
        const lesson = await ridingSchoolStorage.getScheduledLesson(booking.scheduledLessonId);
        const template = lesson ? await ridingSchoolStorage.getLessonTemplate(lesson.templateId) : undefined;
        result.push({ ...booking, riderName: rider.fullName, lessonName: template?.name, startDatetime: lesson?.startDatetime, endDatetime: lesson?.endDatetime });
      }
    }
    res.json(result);
  });

  const portalBookingSchema = z.object({
    scheduledLessonId: z.string().uuid(),
    riderId: z.string().uuid(),
    horseId: z.string().uuid().optional(),
    packagePurchaseId: z.string().uuid().optional(),
  });

  app.post("/api/portal/bookings", requireCustomer, async (req, res) => {
    try {
      const data = validateBody(portalBookingSchema, req.body);
      const rider = await ridingSchoolStorage.getRider(data.riderId);
      if (!rider || rider.customerId !== customerId(req)) {
        return res.status(404).json({ message: "Rider not found on this account" });
      }
      if (data.packagePurchaseId) {
        const pkg = await ridingSchoolStorage.getPackagePurchase(data.packagePurchaseId);
        if (!pkg || pkg.customerId !== customerId(req)) {
          return res.status(404).json({ message: "Package not found on this account" });
        }
      }
      const user = req.user as any;
      const booking = await bookLesson({ ...data, bookedByUserId: user.id });
      auditLog(req, "portal_create_booking", "booking", booking.id, `Booked rider ${data.riderId} onto lesson ${data.scheduledLessonId}`);
      res.status(201).json(booking);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/portal/bookings/:id/cancel", requireCustomer, async (req, res) => {
    try {
      const booking = await ridingSchoolStorage.getBooking(req.params.id as string);
      if (!booking) return res.status(404).json({ message: "Booking not found" });
      const rider = await ridingSchoolStorage.getRider(booking.riderId);
      if (!rider || rider.customerId !== customerId(req)) {
        return res.status(404).json({ message: "Booking not found on this account" });
      }
      const result = await cancelBooking(req.params.id as string);
      auditLog(req, "portal_cancel_booking", "booking", booking.id, `Cancelled booking (credit: ${result.creditPercent}%)`);
      res.json(result);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Riding packages (catalog + own purchases) ---
  app.get("/api/portal/packages", requireCustomer, async (_req, res) => {
    const packages = await ridingSchoolStorage.getRidingPackages();
    res.json(packages.filter((p) => p.isActive));
  });

  app.get("/api/portal/package-purchases", requireCustomer, async (req, res) => {
    res.json(await ridingSchoolStorage.getPackagePurchasesForCustomer(customerId(req)));
  });

  app.post("/api/portal/package-purchases", requireCustomer, async (req, res) => {
    try {
      const { packageId } = validateBody(z.object({ packageId: z.string().uuid() }), req.body);
      const pkg = await ridingSchoolStorage.getRidingPackage(packageId);
      if (!pkg || !pkg.isActive) return res.status(404).json({ message: "Riding package not found" });

      const cid = customerId(req);
      const { invoiceId } = await simulatedPaymentProvider.createCharge({
        customerId: cid,
        amount: pkg.price,
        description: `Riding package purchase: ${pkg.name}`,
      });

      const validUntil = new Date();
      validUntil.setDate(validUntil.getDate() + pkg.validityDays);

      const purchase = await ridingSchoolStorage.createPackagePurchase({
        customerId: cid,
        packageId,
        lessonsRemaining: pkg.numberOfLessons,
        validUntil: validUntil.toISOString().slice(0, 10),
        invoiceId,
        status: "active",
      });

      auditLog(req, "portal_purchase_package", "package_purchase", purchase.id, `Purchased package: ${pkg.name}`);
      res.status(201).json(purchase);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // --- Credit vouchers ---
  app.get("/api/portal/credit-vouchers", requireCustomer, async (req, res) => {
    res.json(await ridingSchoolStorage.getCreditVouchersForCustomer(customerId(req)));
  });

  // --- My Horses (read-only, from the existing livery horse_ownership) ---
  app.get("/api/portal/horses", requireCustomer, async (req, res) => {
    const ownership = await storage.getHorseOwnershipByCustomerId(customerId(req));
    const horses = [];
    for (const o of ownership) {
      const horse = await storage.getHorse(o.horseId);
      if (horse) horses.push(horse);
    }
    res.json(horses);
  });

  // --- Dashboard ---
  app.get("/api/portal/dashboard", requireCustomer, async (req, res) => {
    const riders = await ridingSchoolStorage.getRidersForCustomer(customerId(req));
    const now = new Date();
    const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const upcoming: any[] = [];
    for (const rider of riders) {
      const bookings = await ridingSchoolStorage.getBookingsForRider(rider.id);
      for (const booking of bookings) {
        if (booking.status !== "confirmed") continue;
        const lesson = await ridingSchoolStorage.getScheduledLesson(booking.scheduledLessonId);
        if (!lesson || new Date(lesson.startDatetime) < now) continue;
        const template = await ridingSchoolStorage.getLessonTemplate(lesson.templateId);
        upcoming.push({
          bookingId: booking.id, riderName: rider.fullName, lessonName: template?.name,
          startDatetime: lesson.startDatetime, endDatetime: lesson.endDatetime,
        });
      }
    }
    upcoming.sort((a, b) => new Date(a.startDatetime).getTime() - new Date(b.startDatetime).getTime());

    res.json({
      nextLesson: upcoming[0] || null,
      upcomingThisWeek: upcoming.filter((u) => new Date(u.startDatetime) <= in7Days),
      riderCount: riders.length,
    });
  });
}
