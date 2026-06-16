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

export function isAdminRole(roleKey: string | undefined | null): boolean {
  return !!roleKey && adminRoleKeys.has(roleKey);
}

export function can(roleKey: string | undefined | null, actionKey: string): boolean {
  if (!roleKey) return false;
  if (adminRoleKeys.has(roleKey)) return true;
  return permissionsByRole[roleKey]?.has(actionKey) ?? false;
}

// Resolve the full set of granted action keys for a role (used by /api/me).
export function permissionsForRole(roleKey: string | undefined | null): string[] {
  if (!roleKey) return [];
  return Array.from(permissionsByRole[roleKey] || []);
}

// Middleware factory: allow if user's role is an admin role OR has ANY of the keys.
export function requirePermission(...actionKeys: string[]) {
  return async (req: Request, res: Response, next: NextFunction) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Authentication required" });
    await ensureLoaded();
    const user = req.user as any;
    const roleKey = user?.role as string | undefined;
    if (isAdminRole(roleKey)) return next();
    if (actionKeys.some(key => can(roleKey, key))) return next();
    return res.status(403).json({ message: "Insufficient permissions" });
  };
}
