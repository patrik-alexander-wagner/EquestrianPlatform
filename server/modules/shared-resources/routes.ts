import type { Express } from "express";
import { requirePermission } from "../../permissions";
import { requireAuth, validateBody, auditLog } from "../../route-helpers";
import {
  insertArenaSchema, insertInstructorSchema, insertRiderLevelSchema, insertHorseWellbeingStatusSchema,
} from "@shared/schema";
import { sharedResourcesStorage } from "./storage";

// Routes for the Shared Resources domain. Registered from the existing
// registerRoutes() in server/routes.ts via one import + one call — this file
// (and storage.ts) are the only places Shared Resources logic lives.
export function registerSharedResourcesRoutes(app: Express) {
  // --- Arenas ---
  // GET is auth-only (shared lookup reused by Riding School booking/calendar
  // flows later), matching the existing "shared lookup" precedent elsewhere
  // in this codebase (e.g. horses/available, boxes-with-status).
  app.get("/api/arenas", requireAuth, async (_req, res) => {
    res.json(await sharedResourcesStorage.getArenas());
  });

  app.post("/api/arenas", requirePermission("shared_resources.arenas.manage"), async (req, res) => {
    try {
      const data = validateBody(insertArenaSchema, req.body);
      const arena = await sharedResourcesStorage.createArena(data);
      auditLog(req, "create_arena", "arena", arena.id, `Created arena: ${arena.name}`);
      res.status(201).json(arena);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/arenas/:id", requirePermission("shared_resources.arenas.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const data = validateBody(insertArenaSchema.partial(), req.body);
      const arena = await sharedResourcesStorage.updateArena(id, data);
      if (!arena) return res.status(404).json({ message: "Arena not found" });
      auditLog(req, "update_arena", "arena", arena.id, `Updated arena: ${arena.name}`);
      res.json(arena);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/arenas/:id", requirePermission("shared_resources.arenas.manage"), async (req, res) => {
    const id = req.params.id as string;
    const arena = await sharedResourcesStorage.getArena(id);
    if (!arena) return res.status(404).json({ message: "Arena not found" });
    await sharedResourcesStorage.deleteArena(id);
    auditLog(req, "delete_arena", "arena", arena.id, `Deleted arena: ${arena.name}`);
    res.json({ success: true });
  });

  // --- Instructors ---
  app.get("/api/instructors", requireAuth, async (_req, res) => {
    res.json(await sharedResourcesStorage.getInstructors());
  });

  app.post("/api/instructors", requirePermission("shared_resources.instructors.manage"), async (req, res) => {
    try {
      const data = validateBody(insertInstructorSchema, req.body);
      const instructor = await sharedResourcesStorage.createInstructor(data);
      auditLog(req, "create_instructor", "instructor", instructor.id, `Created instructor: ${instructor.name}`);
      res.status(201).json(instructor);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/instructors/:id", requirePermission("shared_resources.instructors.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const data = validateBody(insertInstructorSchema.partial(), req.body);
      const instructor = await sharedResourcesStorage.updateInstructor(id, data);
      if (!instructor) return res.status(404).json({ message: "Instructor not found" });
      auditLog(req, "update_instructor", "instructor", instructor.id, `Updated instructor: ${instructor.name}`);
      res.json(instructor);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/instructors/:id", requirePermission("shared_resources.instructors.manage"), async (req, res) => {
    const id = req.params.id as string;
    const instructor = await sharedResourcesStorage.getInstructor(id);
    if (!instructor) return res.status(404).json({ message: "Instructor not found" });
    await sharedResourcesStorage.deleteInstructor(id);
    auditLog(req, "delete_instructor", "instructor", instructor.id, `Deleted instructor: ${instructor.name}`);
    res.json({ success: true });
  });

  // --- Rider levels (managed from Riding School Settings) ---
  app.get("/api/rider-levels", requireAuth, async (_req, res) => {
    res.json(await sharedResourcesStorage.getRiderLevels());
  });

  app.post("/api/rider-levels", requirePermission("riding_school.settings.manage"), async (req, res) => {
    try {
      const data = validateBody(insertRiderLevelSchema, req.body);
      const level = await sharedResourcesStorage.createRiderLevel(data);
      auditLog(req, "create_rider_level", "rider_level", level.id, `Created rider level: ${level.name}`);
      res.status(201).json(level);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/rider-levels/:id", requirePermission("riding_school.settings.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const data = validateBody(insertRiderLevelSchema.partial(), req.body);
      const level = await sharedResourcesStorage.updateRiderLevel(id, data);
      if (!level) return res.status(404).json({ message: "Rider level not found" });
      auditLog(req, "update_rider_level", "rider_level", level.id, `Updated rider level: ${level.name}`);
      res.json(level);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/rider-levels/:id", requirePermission("riding_school.settings.manage"), async (req, res) => {
    const id = req.params.id as string;
    const level = await sharedResourcesStorage.getRiderLevel(id);
    if (!level) return res.status(404).json({ message: "Rider level not found" });
    await sharedResourcesStorage.deleteRiderLevel(id);
    auditLog(req, "delete_rider_level", "rider_level", level.id, `Deleted rider level: ${level.name}`);
    res.json({ success: true });
  });

  // --- Horse wellbeing status (append-only, embedded in the Horses page) ---
  app.get("/api/horses/:horseId/wellbeing-status", requireAuth, async (req, res) => {
    const horseId = req.params.horseId as string;
    res.json(await sharedResourcesStorage.getHorseWellbeingHistory(horseId));
  });

  app.post("/api/horses/:horseId/wellbeing-status", requirePermission("shared_resources.horse_wellbeing.manage"), async (req, res) => {
    try {
      const horseId = req.params.horseId as string;
      const user = req.user as any;
      const data = validateBody(insertHorseWellbeingStatusSchema, {
        ...req.body,
        horseId,
        setBy: user?.id || null,
      });
      const entry = await sharedResourcesStorage.addHorseWellbeingStatus(data);
      auditLog(req, "add_horse_wellbeing_status", "horse", horseId, `Set wellbeing status: ${entry.statusTag}`);
      res.status(201).json(entry);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });
}
