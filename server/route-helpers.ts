import type { Request, Response, NextFunction } from "express";
import { storage } from "./storage";

// Small generic helpers shared by server/routes.ts and the newer per-domain
// route modules (server/modules/*). Extracted so new modules don't have to
// import from routes.ts itself (which would create a circular dependency,
// since routes.ts registers those modules).

export function validateBody(schema: any, body: any) {
  const result = schema.safeParse(body);
  if (!result.success) {
    throw { status: 400, message: result.error.errors.map((e: any) => e.message).join(", ") };
  }
  return result.data;
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  if (req.isAuthenticated()) return next();
  res.status(401).json({ message: "Authentication required" });
}

export function auditLog(req: Request, action: string, entityType?: string, entityId?: string, details?: string) {
  const user = req.user as any;
  storage.createAuditLog({
    userId: user?.id || null,
    username: user?.username || null,
    action,
    entityType: entityType || null,
    entityId: entityId || null,
    details: details || null,
  }).catch(err => console.error("Audit log error:", err));
}
