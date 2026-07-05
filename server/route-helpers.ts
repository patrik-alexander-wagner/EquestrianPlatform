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
// staff role/permission catalog (shared/permissions.ts): CUSTOMER is a role
// like any other (held via user_roles, possibly alongside staff roles, e.g.
// an admin who also wants to see the member-facing booking experience), and
// it never appears in DEFAULT_ROLE_PERMISSIONS so it grants zero staff
// actions on its own. This resolves one unambiguous effectiveCustomerId so
// route handlers never have to re-derive which field to trust.
export function requireCustomer(req: Request, res: Response, next: NextFunction) {
  if (!req.isAuthenticated()) return res.status(401).json({ message: "Authentication required" });
  const user = req.user as any;
  const roles = (user.roles as string[] | undefined) ?? [];
  if (!roles.includes("CUSTOMER") || !user.customerId) {
    return res.status(403).json({ message: "Customer account required" });
  }
  (req as any).effectiveCustomerId = user.customerId;
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
