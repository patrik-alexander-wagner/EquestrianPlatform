import type { Express } from "express";
import { requirePermission } from "../../permissions";
import { requireAuth, validateBody, auditLog } from "../../route-helpers";
import {
  insertArenaSchema, insertInstructorSchema, insertRiderLevelSchema,
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
  // Read-only + rename here: an instructor's row is created/retired
  // automatically by granting/removing the INSTRUCTOR role on a user
  // (server/storage.ts DatabaseStorage.syncInstructorForUser) — there is no
  // direct create/delete anymore, only editing the display name.
  app.get("/api/instructors", requireAuth, async (_req, res) => {
    res.json(await sharedResourcesStorage.getInstructors());
  });

  app.patch("/api/instructors/:id", requirePermission("shared_resources.instructors.manage"), async (req, res) => {
    try {
      const id = req.params.id as string;
      const data = validateBody(insertInstructorSchema.pick({ name: true }).partial(), req.body);
      const instructor = await sharedResourcesStorage.updateInstructor(id, data);
      if (!instructor) return res.status(404).json({ message: "Instructor not found" });
      auditLog(req, "update_instructor", "instructor", instructor.id, `Updated instructor: ${instructor.name}`);
      res.json(instructor);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
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
}
