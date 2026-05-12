import type { Express, Request, Response, NextFunction } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import passport from "passport";
import rateLimit from "express-rate-limit";
import OAuth from "oauth-1.0a";
import crypto from "crypto";
import {
  insertUserSchema, insertCustomerSchema, insertHorseSchema,
  insertStableSchema, insertBoxSchema, insertItemSchema,
  insertLiveryAgreementSchema, insertBillingElementSchema, insertInvoiceSchema,
  insertAgreementDocumentSchema, insertHorseOwnershipSchema, insertHorseMovementSchema,
  VALID_ROLES,
} from "@shared/schema";
import type { UserRole, InvoiceStatus } from "@shared/schema";
import { z, ZodError } from "zod";

function validateBody(schema: any, body: any) {
  const result = schema.safeParse(body);
  if (!result.success) {
    throw { status: 400, message: result.error.errors.map((e: any) => e.message).join(", ") };
  }
  return result.data;
}

function requireAuth(req: Request, res: Response, next: NextFunction) {
  if (req.isAuthenticated()) return next();
  res.status(401).json({ message: "Authentication required" });
}

function requireAdmin(req: Request, res: Response, next: NextFunction) {
  if (!req.isAuthenticated()) return res.status(401).json({ message: "Authentication required" });
  const user = req.user as any;
  if (user?.role !== "ADMIN") return res.status(403).json({ message: "Admin access required" });
  next();
}

function requireRoles(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Authentication required" });
    const user = req.user as any;
    if (user?.role === "ADMIN" || roles.includes(user?.role)) return next();
    res.status(403).json({ message: "Insufficient permissions" });
  };
}

function auditLog(req: Request, action: string, entityType?: string, entityId?: string, details?: string) {
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

const loginLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  message: { message: "Too many login attempts. Please try again in a minute." },
  standardHeaders: true,
  legacyHeaders: false,
});

const ssoLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  message: { message: "Too many SSO requests. Please try again in a minute." },
  standardHeaders: true,
  legacyHeaders: false,
});

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {

  app.get("/sso", ssoLimiter, async (req, res) => {
    const token = req.query.token;
    if (!token) return res.redirect("/login?error=missing_token");

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000);
      let ssoResponse: globalThis.Response;
      try {
        ssoResponse = await fetch("https://aksportal.com/api/sso/verify-token", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ token }),
          signal: controller.signal,
        });
      } finally {
        clearTimeout(timeoutId);
      }

      if (!ssoResponse.ok) {
        return res.redirect("/login?error=invalid_token");
      }

      const userData = await ssoResponse.json();

      if (!userData.id || typeof userData.id !== "string") {
        console.warn("SSO login rejected: missing or invalid external subject identifier");
        return res.redirect("/login?error=sso_failed");
      }

      if (!userData.username || typeof userData.username !== "string") {
        return res.redirect("/login?error=sso_failed");
      }

      const ssoRoleMap: Record<string, string> = {
        "superadmin": "ADMIN", "admin": "ADMIN",
        "livery_admin": "LIVERY_ADMIN", "veterinary": "VETERINARY",
        "stores": "STORES", "finance": "FINANCE",
      };
      const incomingRole = userData.role?.toLowerCase();
      const mappedRole = incomingRole ? ssoRoleMap[incomingRole] : undefined;
      if (!mappedRole) {
        console.warn(`SSO login rejected: unrecognized or missing role '${userData.role}' for SSO id '${userData.id}'`);
        return res.redirect("/login?error=sso_role_unknown");
      }

      let localUser = await storage.getUserBySsoId(userData.id);
      if (!localUser) {
        const crypto = await import("crypto");
        try {
          localUser = await storage.createUser({
            username: userData.username,
            password: crypto.randomUUID(),
            role: mappedRole,
            ssoId: userData.id,
          });
        } catch (createErr: any) {
          if (createErr?.code === "23505") {
            console.warn(
              `SSO provisioning blocked: username '${userData.username}' already exists as a local account ` +
              `(SSO id '${userData.id}'). Manual account linking is required.`
            );
            return res.redirect("/login?error=sso_username_conflict");
          }
          throw createErr;
        }
      } else if (localUser.role !== mappedRole) {
        const updated = await storage.updateUser(localUser.id, { role: mappedRole });
        if (!updated) {
          console.error(`SSO login rejected: failed to synchronize role for user id '${localUser.id}'`);
          return res.redirect("/login?error=sso_failed");
        }
        localUser = updated;
      }

      const sessionUser = { id: localUser.id, username: localUser.username, role: localUser.role };
      req.logIn(sessionUser, (err) => {
        if (err) {
          console.error("SSO login error:", err);
          return res.redirect("/login?error=sso_failed");
        }
        auditLog(req, "sso_login", "user", localUser!.id, `SSO login via Unified Portal`);
        return res.redirect("/");
      });
    } catch (error) {
      console.error("SSO verification error:", error);
      return res.redirect("/login?error=sso_failed");
    }
  });

  // Auth routes (public)
  app.post("/api/login", loginLimiter, (req, res, next) => {
    passport.authenticate("local", (err: any, user: any, info: any) => {
      if (err) return res.status(500).json({ message: "Server error" });
      if (!user) return res.status(401).json({ message: info?.message || "Invalid credentials" });
      req.logIn(user, (err) => {
        if (err) return res.status(500).json({ message: "Login failed" });
        res.json({ id: user.id, username: user.username, role: user.role });
      });
    })(req, res, next);
  });

  app.post("/api/logout", (req, res) => {
    req.logout((err) => {
      if (err) return res.status(500).json({ message: "Logout failed" });
      res.json({ success: true });
    });
  });

  app.get("/api/me", (req, res) => {
    if (req.isAuthenticated()) {
      const user = req.user as any;
      res.json({ id: user.id, username: user.username, role: user.role });
    } else {
      res.status(401).json({ message: "Not authenticated" });
    }
  });

  // All routes below require authentication
  app.use("/api", (req, res, next) => {
    const publicPaths = ["/login", "/logout", "/me"];
    if (publicPaths.includes(req.path)) return next();
    requireAuth(req, res, next);
  });

  // Users
  app.get("/api/users", requireAdmin, async (_req, res) => {
    try {
      const users = await storage.getUsers();
      res.json(users);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/users", requireAdmin, async (req, res) => {
    try {
      const data = validateBody(insertUserSchema, req.body);
      if (!VALID_ROLES.includes(data.role)) {
        return res.status(400).json({ message: `Invalid role. Must be one of: ${VALID_ROLES.join(", ")}` });
      }
      const user = await storage.createUser(data);
      auditLog(req, "create_user", "user", user.id, `Created user: ${user.username} (role: ${user.role})`);
      res.json({ id: user.id, username: user.username, role: user.role });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/users/:id", requireAdmin, async (req, res) => {
    try {
      const { role } = req.body;
      if (role && !VALID_ROLES.includes(role)) {
        return res.status(400).json({ message: `Invalid role. Must be one of: ${VALID_ROLES.join(", ")}` });
      }
      const updated = await storage.updateUser(req.params.id, { role });
      if (!updated) return res.status(404).json({ message: "User not found" });
      auditLog(req, "update_user", "user", req.params.id, `Updated user role to: ${role}`);
      res.json({ id: updated.id, username: updated.username, role: updated.role });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Customers
  app.get("/api/customers", async (req, res) => {
    try {
      const search = req.query.search as string | undefined;
      const customers = await storage.getCustomers(search);
      res.json(customers);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/customers/:id", async (req, res) => {
    try {
      const customer = await storage.getCustomer(req.params.id);
      if (!customer) return res.status(404).json({ message: "Customer not found" });
      res.json(customer);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/customers", requireAdmin, async (req, res) => {
    try {
      const data = validateBody(insertCustomerSchema, req.body);
      const customer = await storage.createCustomer(data);
      res.json(customer);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/customers/import", requireAdmin, async (req, res) => {
    try {
      const { customers: data } = req.body;
      if (!Array.isArray(data)) throw { status: 400, message: "customers must be an array" };
      const results = [];
      for (const c of data) {
        const withDefaults = {
          ...c,
          firstname: c.firstname || "",
          lastname: c.lastname || "",
        };
        const validated = validateBody(insertCustomerSchema, withDefaults);
        const created = await storage.createCustomer(validated);
        results.push(created);
      }
      res.json(results);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Horses
  app.get("/api/horses", async (req, res) => {
    try {
      const search = req.query.search as string | undefined;
      const customerSearch = req.query.customerSearch as string | undefined;
      const stableBoxSearch = req.query.stableBoxSearch as string | undefined;
      const horses = await storage.getHorses(search, customerSearch, stableBoxSearch);
      res.json(horses);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horses/available", async (_req, res) => {
    try {
      const available = await storage.getAvailableHorses();
      res.json(available);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horses/:id", async (req, res) => {
    try {
      const horse = await storage.getHorse(req.params.id);
      if (!horse) return res.status(404).json({ message: "Horse not found" });
      const ownership = await storage.getHorseOwnershipByHorseId(horse.id);
      let ownerName = null;
      let ownerId = null;
      if (ownership) {
        const owner = await storage.getCustomer(ownership.customerId);
        ownerName = owner?.fullname || null;
        ownerId = ownership.customerId;
      }
      res.json({ ...horse, ownerName, ownerId });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/horses", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const { ownerId, ...horseData } = req.body;
      if (!ownerId) {
        return res.status(400).json({ message: "Owner (ownerId) is required" });
      }
      const data = validateBody(insertHorseSchema, horseData);
      const horse = await storage.createHorseWithOwner(data, ownerId);
      res.json(horse);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/horses/:id", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const { ownerId, ...rest } = req.body;
      const data = validateBody(insertHorseSchema.partial(), rest);
      const horse = await storage.updateHorse(req.params.id, data);
      if (!horse) return res.status(404).json({ message: "Horse not found" });
      if (ownerId) {
        const existingOwnership = await storage.getHorseOwnership(req.params.id);
        if (existingOwnership.length > 0) {
          const latest = existingOwnership.sort((a, b) => (b.createdAt?.getTime() || 0) - (a.createdAt?.getTime() || 0))[0];
          if (latest.customerId !== ownerId) {
            await storage.createHorseOwnership({ horseId: req.params.id, customerId: ownerId });
          }
        } else {
          await storage.createHorseOwnership({ horseId: req.params.id, customerId: ownerId });
        }
      }
      res.json(horse);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/horses/import", requireAdmin, async (req, res) => {
    try {
      const { horses: data } = req.body;
      if (!Array.isArray(data)) throw { status: 400, message: "horses must be an array" };
      const results = [];
      for (const h of data) {
        const validated = validateBody(insertHorseSchema, h);
        const created = await storage.createHorse(validated);
        results.push(created);
      }
      res.json(results);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Stables
  app.get("/api/stables", async (_req, res) => {
    try {
      const stables = await storage.getStables();
      res.json(stables);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/stables", requireAdmin, async (req, res) => {
    try {
      const data = validateBody(insertStableSchema, req.body);
      const stable = await storage.createStable(data);
      res.json(stable);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/stables/:id", requireAdmin, async (req, res) => {
    try {
      const data = validateBody(insertStableSchema.partial(), req.body);
      const stable = await storage.updateStable(req.params.id, data);
      if (!stable) return res.status(404).json({ message: "Stable not found" });
      res.json(stable);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/stables/:id", requireAdmin, async (req, res) => {
    try {
      const existing = await storage.getStable(req.params.id);
      if (!existing) return res.status(404).json({ message: "Stable not found" });
      await storage.deleteStable(req.params.id);
      auditLog(req, "delete_stable", "stable", req.params.id, `Deleted stable: ${existing.name}`);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Boxes
  app.get("/api/boxes", async (req, res) => {
    try {
      const stableSearch = req.query.stableSearch as string | undefined;
      const boxSearch = req.query.boxSearch as string | undefined;
      const boxes = await storage.getBoxes(stableSearch, boxSearch);
      res.json(boxes);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/boxes", requireAdmin, async (req, res) => {
    try {
      const data = validateBody(insertBoxSchema, req.body);
      const box = await storage.createBox(data);
      res.json(box);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/boxes/:id", requireAdmin, async (req, res) => {
    try {
      const data = validateBody(insertBoxSchema.partial(), req.body);
      const box = await storage.updateBox(req.params.id, data);
      if (!box) return res.status(404).json({ message: "Box not found" });
      res.json(box);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/boxes/:id", requireAdmin, async (req, res) => {
    try {
      const existing = await storage.getBox(req.params.id);
      if (!existing) return res.status(404).json({ message: "Box not found" });
      await storage.deleteBox(req.params.id);
      auditLog(req, "delete_box", "box", req.params.id, `Deleted box: ${existing.name}`);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/boxes/import", requireAdmin, async (req, res) => {
    try {
      const { boxes: data } = req.body;
      if (!Array.isArray(data)) throw { status: 400, message: "boxes must be an array" };
      const results = [];
      for (const b of data) {
        const validated = validateBody(insertBoxSchema, b);
        const created = await storage.createBox(validated);
        results.push(created);
      }
      res.json(results);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Items
  app.get("/api/items", async (req, res) => {
    try {
      const search = req.query.search as string | undefined;
      const items = await storage.getItems(search);
      res.json(items);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/items/livery-packages", async (_req, res) => {
    try {
      const items = await storage.getLiveryPackageItems();
      res.json(items);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/items/non-livery-packages", async (_req, res) => {
    try {
      const items = await storage.getNonLiveryPackageItems();
      res.json(items);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/items/sync-netsuite/debug", requireAdmin, async (_req, res) => {
    try {
      const restletUrl = "https://5834136.restlets.api.netsuite.com/app/site/hosting/restlet.nl?script=2163&deploy=1";
      const consumerKey = process.env.NETSUITE_CONSUMER_KEY!;
      const consumerSecret = process.env.NETSUITE_CONSUMER_SECRET!;
      const tokenId = process.env.NETSUITE_TOKEN_ID!;
      const tokenSecret = process.env.NETSUITE_TOKEN_SECRET!;
      const accountId = process.env.NETSUITE_ACCOUNT_ID!;
      const oauth = new OAuth({
        consumer: { key: consumerKey, secret: consumerSecret },
        signature_method: "HMAC-SHA256",
        hash_function(b: string, k: string) { return crypto.createHmac("sha256", k).update(b).digest("base64"); },
      });
      const token = { key: tokenId, secret: tokenSecret };
      const authHeader = oauth.toHeader(oauth.authorize({ url: restletUrl, method: "GET" }, token));
      const authWithRealm = authHeader.Authorization.replace("OAuth ", `OAuth realm="${accountId}", `);
      const response = await fetch(restletUrl, {
        method: "GET",
        headers: { "Content-Type": "application/json", "Authorization": authWithRealm, "Cookie": "" },
      });
      const text = await response.text();
      let payload: any = null;
      try { payload = JSON.parse(text); } catch { payload = { rawText: text.slice(0, 2000) }; }
      const arr = Array.isArray(payload) ? payload
        : Array.isArray(payload?.items) ? payload.items
        : Array.isArray(payload?.data) ? payload.data
        : Array.isArray(payload?.results) ? payload.results
        : null;
      res.json({
        httpStatus: response.status,
        topLevelShape: Array.isArray(payload) ? "array" : (payload && typeof payload === "object" ? Object.keys(payload) : typeof payload),
        totalItems: arr?.length ?? null,
        firstThree: arr?.slice(0, 3) ?? null,
        firstItemKeys: arr?.[0] ? Object.keys(arr[0]) : null,
      });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  let netsuiteSyncInProgress = false;
  app.post("/api/items/sync-netsuite", requireAdmin, async (_req, res) => {
    if (netsuiteSyncInProgress) {
      return res.status(409).json({ message: "A NetSuite sync is already in progress. Please wait for it to finish." });
    }
    netsuiteSyncInProgress = true;
    const startedAt = Date.now();
    try {
      const restletUrl = "https://5834136.restlets.api.netsuite.com/app/site/hosting/restlet.nl?script=2163&deploy=1";
      const consumerKey = process.env.NETSUITE_CONSUMER_KEY;
      const consumerSecret = process.env.NETSUITE_CONSUMER_SECRET;
      const tokenId = process.env.NETSUITE_TOKEN_ID;
      const tokenSecret = process.env.NETSUITE_TOKEN_SECRET;
      const accountId = process.env.NETSUITE_ACCOUNT_ID;

      if (!consumerKey || !consumerSecret || !tokenId || !tokenSecret || !accountId) {
        return res.status(400).json({ message: "NetSuite credentials are not configured. Please set NETSUITE_* environment variables." });
      }

      const oauth = new OAuth({
        consumer: { key: consumerKey, secret: consumerSecret },
        signature_method: "HMAC-SHA256",
        hash_function(baseString: string, key: string) {
          return crypto.createHmac("sha256", key).update(baseString).digest("base64");
        },
      });

      const token = { key: tokenId, secret: tokenSecret };
      const requestData = { url: restletUrl, method: "GET" };
      const authHeader = oauth.toHeader(oauth.authorize(requestData, token));
      const authWithRealm = authHeader.Authorization.replace("OAuth ", `OAuth realm="${accountId}", `);

      const response = await fetch(restletUrl, {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
          "Authorization": authWithRealm,
          "Cookie": "",
        },
      });

      if (!response.ok) {
        const errorText = await response.text().catch(() => "Unknown error");
        return res.status(502).json({ message: `NetSuite returned ${response.status}: ${errorText.slice(0, 500)}` });
      }

      const responseText = await response.text();
      let payload: any;
      try {
        payload = JSON.parse(responseText);
      } catch {
        return res.status(502).json({ message: "NetSuite response was not valid JSON" });
      }

      const netsuiteItems: any[] = Array.isArray(payload)
        ? payload
        : Array.isArray(payload?.items) ? payload.items
        : Array.isArray(payload?.data) ? payload.data
        : Array.isArray(payload?.results) ? payload.results
        : [];

      if (!Array.isArray(netsuiteItems) || netsuiteItems.length === 0) {
        return res.status(502).json({ message: "NetSuite returned no items (or unexpected response shape)" });
      }

      const result = await storage.syncItemsFromNetsuite(netsuiteItems);
      const durationMs = Date.now() - startedAt;
      auditLog(_req as Request, "sync_netsuite_items", "items", "bulk", `created=${result.created} updated=${result.updated} unchanged=${result.unchanged} total=${result.processed}`);
      res.json({ success: true, ...result, durationMs });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "NetSuite sync failed" });
    } finally {
      netsuiteSyncInProgress = false;
    }
  });

  app.post("/api/items/import", requireAdmin, async (req, res) => {
    try {
      const { items: data } = req.body;
      if (!Array.isArray(data)) throw { status: 400, message: "items must be an array" };
      const validated = data.map(item => validateBody(insertItemSchema, item));
      const results = await storage.createItemsBulk(validated);
      res.json({ imported: results.length });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/items/:id", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const data = validateBody(insertItemSchema.partial(), req.body);
      const item = await storage.updateItem(req.params.id, data);
      if (!item) return res.status(404).json({ message: "Item not found" });
      res.json(item);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/items/:id/price-history", async (req, res) => {
    try {
      const item = await storage.getItem(req.params.id);
      if (!item) return res.status(404).json({ message: "Item not found" });
      const history = await storage.getItemPriceHistory(req.params.id);
      res.json(history);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/items/:id/change-price", requireAuth, async (req, res) => {
    try {
      const item = await storage.getItem(req.params.id);
      if (!item) return res.status(404).json({ message: "Item not found" });
      const { price } = req.body;
      if (!price || isNaN(parseFloat(price)) || parseFloat(price) <= 0) return res.status(400).json({ message: "Valid positive price is required" });
      const user = req.user as any;
      const newPriceRecord = await storage.changeItemPrice(req.params.id, String(price), user?.username);
      auditLog(req, "change_item_price", "item", req.params.id, `Price changed to ${price} for item ${item.name}`);
      res.json(newPriceRecord);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Livery Agreements
  app.get("/api/livery-agreements", async (req, res) => {
    try {
      const status = req.query.status as string | undefined;
      const agreements = await storage.getLiveryAgreements(status);
      res.json(agreements);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/livery-agreements", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const data = validateBody(insertLiveryAgreementSchema, req.body);
      const agreement = await storage.createLiveryAgreement(data);
      auditLog(req, "create_agreement", "agreement", agreement.id, `Created agreement: ${agreement.referenceNumber}`);
      res.json(agreement);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/livery-agreements/:id", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const data = validateBody(insertLiveryAgreementSchema.partial(), req.body);
      const existing = await storage.getLiveryAgreement(req.params.id);
      if (!existing) return res.status(404).json({ message: "Agreement not found" });

      const movements = await storage.getHorseMovementsByAgreementId(req.params.id);
      const activeMovement = movements.find(m => !m.checkOut);

      if (data.endDate && activeMovement) {
        await storage.updateHorseMovement(activeMovement.id, { checkOut: data.endDate });
      }

      if (data.boxId && data.boxId !== existing.boxId && activeMovement) {
        await storage.updateHorseMovement(activeMovement.id, { checkOut: new Date().toISOString().split("T")[0] });
      }

      const agreement = await storage.updateLiveryAgreement(req.params.id, data);
      if (data.endDate) {
        auditLog(req, "checkout_agreement", "agreement", req.params.id, `Checkout agreement, end date: ${data.endDate}`);
      }
      res.json(agreement);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/livery-agreements/:id/cancel-checkout", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const agreement = await storage.getLiveryAgreement(req.params.id);
      if (!agreement) return res.status(404).json({ message: "Agreement not found" });
      if (!agreement.endDate) return res.status(400).json({ message: "Agreement does not have a checkout date" });
      const updated = await storage.updateLiveryAgreement(req.params.id, {
        endDate: null,
        checkoutReason: null,
      });
      auditLog(req, "cancel_checkout", "agreement", req.params.id, `Cancelled checkout for agreement ${agreement.referenceNumber}`);
      res.json(updated);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/boxes-with-status", async (_req, res) => {
    try {
      const boxes = await storage.getBoxesWithAgreementStatus();
      res.json(boxes);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/available-boxes", async (_req, res) => {
    try {
      const boxes = await storage.getBoxesWithAgreementStatus();
      res.json(boxes.filter((b: any) => b.isAvailable));
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Billing Elements
  app.get("/api/billing-elements", async (req, res) => {
    try {
      const billed = req.query.billed !== undefined ? req.query.billed === "true" : undefined;
      const elements = await storage.getBillingElements(billed);
      res.json(elements);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/billing-elements", requireAuth, async (req, res) => {
    try {
      if (req.body.transactionDate && !req.body.billingMonth) {
        req.body.billingMonth = req.body.transactionDate.substring(0, 7);
      }
      const user = req.user as any;
      if (user?.id) {
        req.body.userId = user.id;
      }
      const data = validateBody(insertBillingElementSchema, req.body);
      if (data.itemId) {
        const item = await storage.getItem(data.itemId);
        if (!item) return res.status(404).json({ message: "Item not found" });
        if (item.isInactive) return res.status(400).json({ message: `Item "${item.name}" is inactive and cannot be used in new billing elements.` });
      }
      const element = await storage.createBillingElement(data);
      auditLog(req, "create_billing_element", "billing_element", element.id);
      res.json(element);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/billing-elements/:id", requireAuth, async (req, res) => {
    try {
      const existing = await storage.getBillingElement(req.params.id);
      if (!existing) return res.status(404).json({ message: "Billing element not found" });
      if (existing.billed) return res.status(400).json({ message: "Cannot edit a billed element" });

      const editSchema = z.object({
        horseId: z.string().uuid().nullable().optional(),
        itemId: z.string().uuid().optional(),
        quantity: z.number().int().min(1).optional(),
        price: z.string().regex(/^\d+(\.\d{1,2})?$/, "Invalid price format").optional(),
        transactionDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Invalid date format").optional(),
      });
      const parsed = editSchema.parse(req.body);
      const allowedFields: Record<string, any> = {};
      if (parsed.horseId !== undefined) allowedFields.horseId = parsed.horseId; // billing_elements still has horseId
      if (parsed.itemId !== undefined) allowedFields.itemId = parsed.itemId;
      if (parsed.quantity !== undefined) allowedFields.quantity = parsed.quantity;
      if (parsed.price !== undefined) allowedFields.price = parsed.price;
      if (parsed.transactionDate !== undefined) {
        allowedFields.transactionDate = parsed.transactionDate;
        allowedFields.billingMonth = parsed.transactionDate.substring(0, 7);
      }
      if (Object.keys(allowedFields).length === 0) {
        return res.status(400).json({ message: "No valid fields to update" });
      }
      const updated = await storage.updateBillingElement(req.params.id, allowedFields);
      auditLog(req, "update_billing_element", "billing_element", req.params.id);
      res.json(updated);
    } catch (e: any) {
      if (e instanceof z.ZodError) {
        return res.status(400).json({ message: e.errors.map((err: any) => err.message).join(", ") });
      }
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/billing-elements/:id", requireAuth, async (req, res) => {
    try {
      const deleted = await storage.deleteBillingElement(req.params.id);
      if (!deleted) return res.status(404).json({ message: "Billing element not found" });
      auditLog(req, "delete_billing_element", "billing_element", req.params.id);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horses-with-agreements", async (_req, res) => {
    try {
      const horses = await storage.getHorsesWithActiveAgreements();
      res.json(horses);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horses-with-owners", async (_req, res) => {
    try {
      const horses = await storage.getHorsesWithOwners();
      res.json(horses);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/monthly-billing-approvals", async (req, res) => {
    try {
      const billingMonth = req.query.billingMonth as string;
      const customerId = req.query.customerId as string | undefined;
      if (!billingMonth || !/^\d{4}-(0[1-9]|1[0-2])$/.test(billingMonth)) {
        return res.status(400).json({ message: "billingMonth is required in YYYY-MM format" });
      }
      const approvals = await storage.getMonthlyBillingApprovals(billingMonth, customerId);
      res.json(approvals);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/monthly-billing-approvals", async (req, res) => {
    try {
      const user = req.user as any;
      const { customerId, billingMonth, step, approved } = req.body;
      if (!customerId || !billingMonth || !step) {
        return res.status(400).json({ message: "customerId, billingMonth, and step are required" });
      }
      if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(billingMonth)) {
        return res.status(400).json({ message: "billingMonth must be in YYYY-MM format" });
      }
      if (!["VET", "STORES"].includes(step)) {
        return res.status(400).json({ message: "step must be VET or STORES" });
      }
      const roleMap: Record<string, string> = { VET: "VETERINARY", STORES: "STORES" };
      if (user.role !== "ADMIN" && user.role !== roleMap[step]) {
        return res.status(403).json({ message: `Only ${roleMap[step]} or ADMIN can manage ${step} approvals` });
      }

      const hasInvoice = await storage.hasInvoiceForCustomerMonth(customerId, billingMonth);
      if (hasInvoice) {
        return res.status(400).json({ message: "Cannot modify approvals — an invoice already exists for this customer and billing month" });
      }

      const isApproved = approved === true;
      const result = await storage.upsertMonthlyBillingApproval({
        customerId,
        billingMonth,
        step,
        userId: user.id,
        approved: isApproved,
      });
      auditLog(req, isApproved ? "approve_billing_month" : "revoke_billing_month_approval", "monthly_billing_approval", result.id, `${step} ${isApproved ? "approved" : "revoked"} for ${billingMonth}`);
      res.json(result);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Invoices
  app.get("/api/invoices", async (req, res) => {
    try {
      const invoices = await storage.getInvoices();
      const user = req.user as any;
      res.json(invoices);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/invoices/:id/details", async (req, res) => {
    try {
      const details = await storage.getInvoiceDetails(req.params.id);
      if (!details) return res.status(404).json({ message: "Invoice not found" });
      res.json(details);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/billed-months", async (req, res) => {
    try {
      const agreementIds = (req.query.agreementIds as string || "").split(",").filter(Boolean);
      const result = await storage.getBilledMonthsForAgreements(agreementIds);
      res.json(result);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/invoices", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const { customerId, invoiceDate, billingMonth, billingElementIds, liveryItems } = req.body;
      if (!customerId || !invoiceDate) throw { status: 400, message: "Missing required fields: customerId, invoiceDate" };
      if (!billingMonth || !/^\d{4}-(0[1-9]|1[0-2])$/.test(billingMonth)) {
        throw { status: 400, message: "billingMonth is required and must be in YYYY-MM format" };
      }

      {
        const unassigned = await storage.checkAgreementsHorseAssignment(billingMonth, customerId);
        if (unassigned.length > 0) {
          return res.status(400).json({
            message: "Invoice generation blocked — some boxes have no horse assigned for this period",
            unassignedAgreements: unassigned,
          });
        }
      }

      const hasDuplicate = await storage.hasInvoiceForCustomerMonth(customerId, billingMonth);
      if (hasDuplicate) {
        return res.status(400).json({ message: "An invoice already exists for this customer and billing month" });
      }

      const approvals = await storage.getMonthlyBillingApprovals(billingMonth, customerId);
      const vetApproved = approvals.some((a: any) => a.step === "VET" && a.approved);
      const storesApproved = approvals.some((a: any) => a.step === "STORES" && a.approved);
      if (!vetApproved || !storesApproved) {
        return res.status(400).json({ message: "Invoice generation requires both Vet and Stores sign-off for this billing month" });
      }

      const invoiceUser = req.user as any;
      const validatedLiveryItems: any[] = [];
      let computedTotal = 0;

      const [bmYear, bmMonth] = billingMonth.split("-").map(Number);
      const periodStart = `${bmYear}-${String(bmMonth).padStart(2, "0")}-01`;
      const daysInMonth = new Date(bmYear, bmMonth, 0).getDate();
      const periodEnd = `${bmYear}-${String(bmMonth).padStart(2, "0")}-${String(daysInMonth).padStart(2, "0")}`;

      if (liveryItems && Array.isArray(liveryItems) && liveryItems.length > 0) {
        const seenAgreementIds = new Set<string>();
        for (let i = 0; i < liveryItems.length; i++) {
          const item = liveryItems[i];

          if (!item.agreementId) {
            return res.status(400).json({ message: `Livery line item ${i + 1} is missing agreementId.` });
          }

          if (seenAgreementIds.has(item.agreementId)) {
            return res.status(400).json({ message: `Livery line item ${i + 1} duplicates agreement ${item.agreementId} already in this request.` });
          }
          seenAgreementIds.add(item.agreementId);

          const agreement = await storage.getLiveryAgreement(item.agreementId);
          if (!agreement) {
            return res.status(400).json({ message: `Livery line item ${i + 1} references an unknown agreement.` });
          }
          if (agreement.customerId !== customerId) {
            return res.status(400).json({ message: `Livery line item ${i + 1} agreement does not belong to this customer.` });
          }

          const agreementStatus = agreement.status;
          if (agreementStatus !== "active" && agreementStatus !== "ended") {
            return res.status(400).json({ message: `Livery line item ${i + 1} agreement is not in an active or ended state.` });
          }
          if (agreement.startDate && agreement.startDate > periodEnd) {
            return res.status(400).json({ message: `Livery line item ${i + 1} agreement has not started for billing month ${billingMonth}.` });
          }
          if (agreement.endDate && agreement.endDate < periodStart) {
            return res.status(400).json({ message: `Livery line item ${i + 1} agreement ended before billing month ${billingMonth}.` });
          }

          const activeMovement = await storage.getActiveMovementByBoxId(agreement.boxId);
          const trustedHorseId = activeMovement?.horseId ?? null;

          const monthlyAmount = parseFloat(agreement.monthlyAmount ?? "0");
          const overlapStart = agreement.startDate && agreement.startDate > periodStart ? agreement.startDate : periodStart;
          const overlapEnd = agreement.endDate && agreement.endDate < periodEnd ? agreement.endDate : periodEnd;
          const overlapStartDay = parseInt(overlapStart.slice(8, 10), 10);
          const overlapEndDay = parseInt(overlapEnd.slice(8, 10), 10);
          const daysOverlap = Math.max(0, overlapEndDay - overlapStartDay + 1);
          const fraction = daysInMonth > 0 ? daysOverlap / daysInMonth : 0;
          const proratedRaw = monthlyAmount * fraction;
          const proratedPrice = proratedRaw.toFixed(2);

          try {
            const validatedItem = validateBody(insertBillingElementSchema, {
              horseId: trustedHorseId,
              customerId,
              boxId: agreement.boxId,
              itemId: agreement.itemId,
              agreementId: item.agreementId,
              quantity: "1",
              price: proratedPrice,
              transactionDate: invoiceDate,
              billingMonth,
              billed: true,
              userId: invoiceUser?.id || null,
            });
            validatedLiveryItems.push(validatedItem);
            computedTotal += proratedRaw;
          } catch (err: any) {
            return res.status(400).json({
              message: `Livery line item ${i + 1} is invalid: ${err.message || "validation failed"}. Invoice was not created.`,
            });
          }
        }
      }

      const adhocIds: string[] = Array.isArray(billingElementIds) ? billingElementIds : [];

      for (const elId of adhocIds) {
        const element = await storage.getBillingElement(elId);
        if (!element) {
          return res.status(400).json({ message: `Ad-hoc billing element ${elId} not found.` });
        }
        if (element.customerId !== customerId) {
          return res.status(400).json({ message: `Ad-hoc billing element ${elId} does not belong to this customer.` });
        }
        const elementMonth = element.billingMonth || (element.transactionDate ? element.transactionDate.substring(0, 7) : null);
        if (elementMonth !== billingMonth) {
          return res.status(400).json({
            message: `Ad-hoc billing element ${elId} belongs to billing month ${elementMonth || "(none)"}, not ${billingMonth}. Cross-month billing is not allowed.`,
          });
        }
        if (element.billed || element.invoiceId) {
          return res.status(400).json({ message: `Ad-hoc billing element ${elId} has already been invoiced.` });
        }
        computedTotal += parseFloat(element.price || "0");
      }

      if (validatedLiveryItems.length === 0 && adhocIds.length === 0) {
        return res.status(400).json({ message: "Cannot create invoice with no line items" });
      }

      const totalAmount = computedTotal.toFixed(2);

      let invoice;
      try {
        invoice = await storage.createInvoiceWithLineItems(
          { customerId, invoiceDate, billingMonth, totalAmount, status: "APPROVED" },
          validatedLiveryItems,
          adhocIds,
        );
      } catch (err: any) {
        if (err.code === "23505") {
          return res.status(400).json({ message: "An invoice already exists for this customer and billing month" });
        }
        return res.status(400).json({ message: err.message || "Failed to create invoice — rolled back" });
      }

      auditLog(req, "create_invoice", "invoice", invoice.id, `Created invoice for billing month ${billingMonth || "N/A"}`);
      res.json(invoice);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/invoices/:id", requireAdmin, async (req, res) => {
    try {
      await storage.deleteInvoice(req.params.id);
      auditLog(req, "delete_invoice", "invoice", req.params.id);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/invoices/:id/rollback", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const invoice = await storage.getInvoice(req.params.id);
      if (!invoice) return res.status(404).json({ message: "Invoice not found" });
      if (invoice.status === "PUSHED_TO_ERP") {
        return res.status(400).json({ message: "Cannot rollback an invoice that has been pushed to ERP" });
      }

      await storage.deleteInvoice(req.params.id);

      auditLog(req, "rollback_invoice", "invoice", req.params.id);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/invoices/:id/send-for-validation", async (_req, res) => {
    res.status(410).json({ message: "This endpoint is deprecated. Approvals now happen on the To Invoice page before invoice generation." });
  });

  app.post("/api/invoices/:id/validate", async (_req, res) => {
    res.status(410).json({ message: "This endpoint is deprecated. Approvals now happen on the To Invoice page before invoice generation." });
  });

  app.get("/api/invoices/:id/validations", async (req, res) => {
    try {
      const validations = await storage.getInvoiceValidations(req.params.id);
      res.json(validations);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/invoices/:id/generate-so", requireRoles("FINANCE"), async (req, res) => {
    try {
      const invoice = await storage.getInvoice(req.params.id);
      if (!invoice) return res.status(404).json({ message: "Invoice not found" });

      const lineCount = await storage.getInvoiceLineItemCount(req.params.id);
      if (lineCount === 0) {
        return res.status(400).json({ message: "Invoice has no line items — cannot generate SO. Please delete this empty invoice." });
      }

      const details = await storage.getInvoiceDetailsForSO(req.params.id);
      if (!details) return res.status(404).json({ message: "Invoice details not found" });

      if (!details.customer?.netsuiteId) {
        return res.status(400).json({ message: "Customer does not have a NetSuite ID. Please set it before generating SO." });
      }

      const missingItemIds = new Set<string>();
      const missingItemMessages: string[] = [];
      for (const item of details.items) {
        if (!item.itemId && !missingItemIds.has(item.description)) {
          missingItemIds.add(item.description);
          missingItemMessages.push(`Item "${item.description}" is missing NetSuite ID`);
        }
      }
      if (missingItemMessages.length > 0) {
        return res.status(400).json({ message: `Missing NetSuite IDs:\n${missingItemMessages.join("\n")}` });
      }

      const poNumber = invoice.poNumber || await storage.getNextPoNumber();

      const billingMonth = invoice.billingMonth || "";
      let memoMonth = "";
      if (billingMonth) {
        const [y, m] = billingMonth.split("-").map(Number);
        const date = new Date(y, m - 1);
        memoMonth = date.toLocaleString("en-US", { month: "short", year: "numeric" });
      }
      const customerName = details.customer
        ? details.customer.fullname
        : "Unknown";

      let tranDate: string;
      if (billingMonth) {
        const [y, m] = billingMonth.split("-").map(Number);
        const lastDay = new Date(y, m, 0).getDate();
        tranDate = `${String(lastDay).padStart(2, "0")}/${String(m).padStart(2, "0")}/${y}`;
      } else {
        const today = new Date();
        tranDate = `${String(today.getDate()).padStart(2, "0")}/${String(today.getMonth() + 1).padStart(2, "0")}/${today.getFullYear()}`;
      }

      const soJson = {
        customerId: details.customer?.netsuiteId || "",
        po: poNumber,
        department: "188",
        memo: `Monthly Livery Invoice - ${customerName} (${memoMonth})`,
        tranDate,
        items: details.items,
      };

      const jsonString = JSON.stringify(soJson, null, 2);

      await storage.updateInvoice(req.params.id, {
        soGenerated: true,
        poNumber,
        netsuiteJson: jsonString,
        sentToNetsuite: false,
      });

      res.json({ success: true, poNumber, json: soJson });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Reports
  app.get("/api/reports/kpis", async (req, res) => {
    try {
      const month = req.query.month as string;
      if (!month || !/^\d{4}-\d{2}$/.test(month)) return res.status(400).json({ message: "month parameter required (YYYY-MM)" });
      const data = await storage.getReportKpis(month);
      res.json(data);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/reports/all-customers", async (_req, res) => {
    try {
      const data = await storage.getAllCustomersReport();
      res.json(data);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/reports/livery", async (req, res) => {
    try {
      const groupBy = (req.query.groupBy as string) || "month";
      const month = req.query.month as string | undefined;
      const data = await storage.getReportData(groupBy, month);
      res.json(data);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/reports/new-livery-horses", async (req, res) => {
    try {
      const month = req.query.month as string;
      if (!month || !/^\d{4}-\d{2}$/.test(month)) return res.status(400).json({ message: "month parameter required (YYYY-MM)" });
      const data = await storage.getNewLiveryHorses(month);
      res.json(data);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/reports/departed-livery-horses", async (req, res) => {
    try {
      const month = req.query.month as string;
      if (!month || !/^\d{4}-\d{2}$/.test(month)) return res.status(400).json({ message: "month parameter required (YYYY-MM)" });
      const data = await storage.getDepartedLiveryHorses(month);
      res.json(data);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/reports/livery-customers-info", async (_req, res) => {
    try {
      const data = await storage.getLiveryCustomersInfo();
      res.json(data);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Send invoice to NetSuite via RESTlet (OAuth 1.0 TBA)
  app.post("/api/invoices/:id/send-to-netsuite", requireRoles("FINANCE"), async (req, res) => {
    try {
      const invoice = await storage.getInvoice(req.params.id);
      if (!invoice) return res.status(404).json({ message: "Invoice not found" });
      if (!invoice.soGenerated) return res.status(400).json({ message: "SO must be generated before sending to NetSuite" });
      if (!invoice.netsuiteJson) return res.status(400).json({ message: "No NetSuite JSON found on this invoice" });

      const lineCount = await storage.getInvoiceLineItemCount(req.params.id);
      if (lineCount === 0) {
        return res.status(400).json({ message: "Invoice has no line items — cannot send to NetSuite. Please delete this empty invoice." });
      }

      const restletUrl = process.env.NETSUITE_RESTLET_URL;
      const consumerKey = process.env.NETSUITE_CONSUMER_KEY;
      const consumerSecret = process.env.NETSUITE_CONSUMER_SECRET;
      const tokenId = process.env.NETSUITE_TOKEN_ID;
      const tokenSecret = process.env.NETSUITE_TOKEN_SECRET;
      const accountId = process.env.NETSUITE_ACCOUNT_ID;

      if (!restletUrl || !consumerKey || !consumerSecret || !tokenId || !tokenSecret || !accountId) {
        return res.status(400).json({ message: "NetSuite RESTlet credentials are not configured. Please set NETSUITE_* environment variables." });
      }

      const oauth = new OAuth({
        consumer: { key: consumerKey, secret: consumerSecret },
        signature_method: "HMAC-SHA256",
        hash_function(baseString: string, key: string) {
          return crypto.createHmac("sha256", key).update(baseString).digest("base64");
        },
      });

      const token = { key: tokenId, secret: tokenSecret };
      const requestData = { url: restletUrl, method: "POST" };
      const authHeader = oauth.toHeader(oauth.authorize(requestData, token));
      const authWithRealm = authHeader.Authorization.replace(
        'OAuth ',
        `OAuth realm="${accountId}", `
      );

      const response = await fetch(restletUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": authWithRealm,
          "Cookie": "",
        },
        body: invoice.netsuiteJson,
      });

      if (!response.ok) {
        const errorText = await response.text().catch(() => "Unknown error");
        return res.status(502).json({ message: `NetSuite RESTlet returned error: ${response.status} - ${errorText}` });
      }

      let netsuiteId: string | null = null;
      try {
        const responseText = await response.text();
        const responseData = JSON.parse(responseText);
        if (responseData?.netsuiteId) netsuiteId = String(responseData.netsuiteId);
        else if (responseData?.salesOrderId) netsuiteId = String(responseData.salesOrderId);
        else if (responseData?.SalesOrderId) netsuiteId = String(responseData.SalesOrderId);
        else if (responseData?.salesOrderInternalId) netsuiteId = String(responseData.salesOrderInternalId);
        else if (responseData?.internalId) netsuiteId = String(responseData.internalId);
        else if (responseData?.id) netsuiteId = String(responseData.id);
      } catch {
        // Response was not valid JSON; netsuiteId remains null
      }

      const updateData: any = {
        sentToNetsuite: true,
        status: "PUSHED_TO_ERP",
      };
      if (netsuiteId) updateData.netsuiteId = netsuiteId;

      await storage.updateInvoice(req.params.id, updateData);

      res.json({ success: true, netsuiteId });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Settings - N8N Webhook URL
  app.get("/api/settings/n8n-webhook", requireAdmin, async (_req, res) => {
    try {
      const url = await storage.getSetting("n8n_webhook_url");
      res.json({ url: url || "" });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/settings/n8n-webhook", requireAdmin, async (req, res) => {
    try {
      const { url } = req.body;
      if (typeof url !== "string") return res.status(400).json({ message: "URL must be a string" });
      if (url.trim() && !/^https?:\/\/.+/i.test(url.trim())) {
        return res.status(400).json({ message: "URL must start with http:// or https://" });
      }
      await storage.setSetting("n8n_webhook_url", url.trim());
      auditLog(req, "update_setting", "setting", "n8n_webhook_url", `Updated N8N webhook URL`);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Settings - Livery Package Configuration
  app.post("/api/settings/livery-packages", requireAdmin, async (req, res) => {
    try {
      const { itemIds } = req.body;
      if (!Array.isArray(itemIds)) throw { status: 400, message: "itemIds must be an array" };
      const allItems = await storage.getItems();
      for (const item of allItems) {
        const isPackage = itemIds.includes(item.id);
        if (item.isLiveryPackage !== isPackage) {
          await storage.updateItem(item.id, { isLiveryPackage: isPackage });
        }
      }
      auditLog(req, "update_setting", "setting", "livery_packages", `Updated livery packages`);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Agreement Documents
  app.get("/api/livery-agreements/:id/documents", requireAuth, async (req, res) => {
    try {
      const docs = await storage.getAgreementDocuments(req.params.id);
      res.json(docs.map(d => ({ id: d.id, agreementId: d.agreementId, filename: d.filename, uploadedAt: d.uploadedAt })));
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/livery-agreements/:id/documents", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const { filename, fileData } = req.body;
      if (!filename || !fileData) throw { status: 400, message: "filename and fileData are required" };

      if (!fileData.startsWith("JVBERi")) {
        return res.status(400).json({ message: "Only PDF files are allowed" });
      }

      const existingDocs = await storage.getAgreementDocuments(req.params.id);
      if (existingDocs.length >= 20) {
        return res.status(400).json({ message: "Maximum 20 documents per agreement reached" });
      }

      const doc = await storage.createAgreementDocument({
        agreementId: req.params.id,
        filename,
        fileData,
      });
      auditLog(req, "upload_document", "agreement_document", doc.id, `Uploaded ${filename} for agreement ${req.params.id}`);
      res.json({ id: doc.id, agreementId: doc.agreementId, filename: doc.filename, uploadedAt: doc.uploadedAt });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/agreement-documents/:id/download", requireAuth, async (req, res) => {
    try {
      const doc = await storage.getAgreementDocument(req.params.id);
      if (!doc) return res.status(404).json({ message: "Document not found" });
      const buffer = Buffer.from(doc.fileData, "base64");
      res.setHeader("Content-Type", "application/pdf");
      res.setHeader("Content-Disposition", `attachment; filename="${doc.filename}"`);
      res.send(buffer);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/agreement-documents/:id", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const deleted = await storage.deleteAgreementDocument(req.params.id);
      if (!deleted) return res.status(404).json({ message: "Document not found" });
      auditLog(req, "delete_document", "agreement_document", req.params.id);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/audit-logs", requireAdmin, async (req, res) => {
    try {
      const page = Math.max(1, parseInt(req.query.page as string) || 1);
      const limit = Math.min(parseInt(req.query.limit as string) || 50, 200);
      const offset = (page - 1) * limit;
      const logs = await storage.getAuditLogs(limit, offset);
      res.json(logs);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horse-ownership/:horseId", async (req, res) => {
    try {
      const ownership = await storage.getHorseOwnershipByHorseId(req.params.horseId);
      res.json(ownership || null);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horse-ownership/customer/:customerId", async (req, res) => {
    try {
      const ownership = await storage.getHorseOwnershipByCustomerId(req.params.customerId);
      res.json(ownership);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/horse-ownership", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const data = validateBody(insertHorseOwnershipSchema, req.body);
      const ownership = await storage.createHorseOwnership(data);
      res.json(ownership);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horse-movements", async (_req, res) => {
    try {
      const movements = await storage.getHorseMovements();
      res.json(movements);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horse-movements/agreement/:agreementId", async (req, res) => {
    try {
      const movements = await storage.getHorseMovementsByAgreementId(req.params.agreementId);
      res.json(movements);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horse-movements/box/:boxId/active", async (req, res) => {
    try {
      const movement = await storage.getActiveMovementByBoxId(req.params.boxId);
      res.json(movement || null);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/horse-movements", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const data = validateBody(insertHorseMovementSchema, req.body);
      const allMovements = await storage.getHorseMovements();
      const activeHorseMovement = allMovements.find(m => m.horseId === data.horseId && !m.checkOut);
      if (activeHorseMovement) {
        return res.status(400).json({ message: "This horse is already checked in to another box" });
      }
      if (data.stableboxId) {
        const activeBoxMovement = await storage.getActiveMovementByBoxId(data.stableboxId);
        if (activeBoxMovement) {
          return res.status(400).json({ message: "This box already has a horse checked in" });
        }
      }
      if (data.agreementId) {
        const agreement = await storage.getLiveryAgreement(data.agreementId);
        if (!agreement) {
          return res.status(400).json({ message: "Agreement not found" });
        }
        if (data.stableboxId && agreement.boxId !== data.stableboxId) {
          return res.status(400).json({ message: "Agreement does not belong to the specified box" });
        }
        const ownership = await storage.getHorseOwnershipByHorseId(data.horseId);
        if (!ownership || ownership.customerId !== agreement.customerId) {
          return res.status(400).json({ message: "Horse does not belong to the customer of this agreement" });
        }
      }
      const movement = await storage.createHorseMovement(data);
      res.json(movement);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/horse-movements/:id", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const { checkOut } = req.body;
      if (!checkOut || typeof checkOut !== "string") {
        return res.status(400).json({ message: "Only checkOut may be set via this endpoint" });
      }
      const allowedKeys = Object.keys(req.body).filter(k => k !== "checkOut");
      if (allowedKeys.length > 0) {
        return res.status(400).json({ message: "Only checkOut may be set via this endpoint" });
      }
      if (!/^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/.test(checkOut)) {
        return res.status(400).json({ message: "checkOut must be a valid date in YYYY-MM-DD format" });
      }
      const allMovements = await storage.getHorseMovements();
      const existing = allMovements.find(m => m.id === req.params.id);
      if (!existing) {
        return res.status(404).json({ message: "Movement not found" });
      }
      if (existing.checkOut) {
        return res.status(400).json({ message: "Movement is already checked out" });
      }
      if (checkOut < existing.checkIn) {
        return res.status(400).json({ message: "Check-out date cannot be before check-in date" });
      }
      const movement = await storage.updateHorseMovement(req.params.id, { checkOut });
      if (!movement) return res.status(404).json({ message: "Movement not found" });
      res.json(movement);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horse-assignment-check", async (req, res) => {
    try {
      const billingMonth = req.query.billingMonth as string;
      const customerId = req.query.customerId as string | undefined;
      if (!billingMonth || !/^\d{4}-(0[1-9]|1[0-2])$/.test(billingMonth)) {
        return res.status(400).json({ message: "billingMonth query param required (YYYY-MM, valid month 01-12)" });
      }
      const unassigned = await storage.checkAgreementsHorseAssignment(billingMonth, customerId);
      res.json(unassigned);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horse-movements/enriched", async (_req, res) => {
    try {
      const movements = await storage.getEnrichedHorseMovements();
      res.json(movements);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/box-grid", async (_req, res) => {
    try {
      const grid = await storage.getBoxGridWithOccupants();
      res.json(grid);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/horse-movements/move", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const schema = z.object({ movementId: z.string().uuid(), newBoxId: z.string().uuid() });
      const data = validateBody(schema, req.body);
      const newMovement = await storage.moveHorseToBox(data.movementId, data.newBoxId);
      auditLog(req, "move_horse", "horse_movement", newMovement.id, `Moved horse to new box`);
      res.json(newMovement);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/horse-movements/swap", requireRoles("LIVERY_ADMIN"), async (req, res) => {
    try {
      const schema = z.object({
        movementId: z.string().uuid(),
        newHorseId: z.string().uuid(),
      });
      const data = validateBody(schema, req.body);
      const newMovement = await storage.swapHorseInBox(data.movementId, data.newHorseId);
      auditLog(req, "swap_horse", "horse_movement", newMovement.id, `Swapped horse in box`);
      res.json(newMovement);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  return httpServer;
}
