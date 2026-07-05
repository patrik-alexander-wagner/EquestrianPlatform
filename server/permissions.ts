import type { Request, Response, NextFunction } from "express";
import { storage } from "./storage";

// In-memory caches, refreshed on any role/permission change.
let adminRoleKeys = new Set<string>();
let permissionsByRole: Record<string, Set<string>> = {};
let loaded = false;

export async function loadPermissions(): Promise<void> {
  const roles = await storage.getRoles();
  const permMap = await storage.getAllRolePermissions();
  adminRoleKeys = new Set(roles.filter(r => r.isAdmin).map(r => r.key));
  const next: Record<string, Set<string>> = {};
  for (const role of roles) {
    next[role.key] = new Set(permMap[role.key] || []);
  }
  permissionsByRole = next;
  loaded = true;
}

export async function ensureLoaded(): Promise<void> {
  if (!loaded) await loadPermissions();
}

// A user can hold multiple roles at once (e.g. ADMIN + CUSTOMER); every check
// below is a union across all of them — admin if ANY held role is admin,
// granted if ANY held role grants the action.
export function isAdminRole(roleKeys: string[] | undefined | null): boolean {
  if (!roleKeys) return false;
  return roleKeys.some(key => adminRoleKeys.has(key));
}

export function can(roleKeys: string[] | undefined | null, actionKey: string): boolean {
  if (!roleKeys || roleKeys.length === 0) return false;
  if (isAdminRole(roleKeys)) return true;
  return roleKeys.some(key => permissionsByRole[key]?.has(actionKey) ?? false);
}

// Resolve the full set of granted action keys across all of a user's roles
// (used by /api/me).
export function permissionsForRoles(roleKeys: string[] | undefined | null): string[] {
  if (!roleKeys) return [];
  const union = new Set<string>();
  for (const key of roleKeys) {
    for (const action of Array.from(permissionsByRole[key] || [])) union.add(action);
  }
  return Array.from(union);
}

// Middleware factory: allow if any of the user's roles is admin OR grants ANY of the keys.
export function requirePermission(...actionKeys: string[]) {
  return async (req: Request, res: Response, next: NextFunction) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Authentication required" });
    await ensureLoaded();
    const user = req.user as any;
    const roleKeys = (user?.roles as string[] | undefined) ?? [];
    if (isAdminRole(roleKeys)) return next();
    if (actionKeys.some(key => can(roleKeys, key))) return next();
    return res.status(403).json({ message: "Insufficient permissions" });
  };
}
