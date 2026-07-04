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

// Gate for the Customer Portal — customer identity is orthogonal to the
// staff role/permission catalog (shared/permissions.ts), so portal routes
// check accountType directly rather than going through requirePermission.
//
// Two kinds of session can reach the portal: a real CUSTOMER account (its
// own customerId), or a STAFF account that also has a linkedCustomerId (a
// staff member who is also a member, using the "switch to Customer Portal"
// option). Either way, this resolves one unambiguous effectiveCustomerId so
// route handlers never have to re-derive which field to trust.
export function requireCustomer(req: Request, res: Response, next: NextFunction) {
  if (!req.isAuthenticated()) return res.status(401).json({ message: "Authentication required" });
  const user = req.user as any;
  const effectiveCustomerId = user.accountType === "CUSTOMER" ? user.customerId : user.linkedCustomerId;
  if (!effectiveCustomerId) {
    return res.status(403).json({ message: "Customer account required" });
  }
  (req as any).effectiveCustomerId = effectiveCustomerId;
  next();
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
