import type { Express, Request, Response, NextFunction } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import passport from "passport";
import rateLimit from "express-rate-limit";
import {
  insertUserSchema, insertCustomerSchema, insertHorseSchema,
  insertStableSchema, insertBoxSchema, insertItemSchema,
  insertLiveryAgreementSchema, insertBillingElementSchema, insertInvoiceSchema,
  insertAgreementDocumentSchema,
} from "@shared/schema";
import { ZodError } from "zod";

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
  if (user?.role !== "admin") return res.status(403).json({ message: "Admin access required" });
  next();
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

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {

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
      const user = await storage.createUser(data);
      auditLog(req, "create_user", "user", user.id, `Created user: ${user.username}`);
      res.json({ id: user.id, username: user.username });
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

  app.post("/api/customers", async (req, res) => {
    try {
      const data = validateBody(insertCustomerSchema, req.body);
      const customer = await storage.createCustomer(data);
      res.json(customer);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/customers/import", async (req, res) => {
    try {
      const { customers: data } = req.body;
      if (!Array.isArray(data)) throw { status: 400, message: "customers must be an array" };
      const results = [];
      for (const c of data) {
        const validated = validateBody(insertCustomerSchema, c);
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
      res.json(horse);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/horses", async (req, res) => {
    try {
      const data = validateBody(insertHorseSchema, req.body);
      const horse = await storage.createHorse(data);
      res.json(horse);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/horses/:id", async (req, res) => {
    try {
      const data = validateBody(insertHorseSchema.partial(), req.body);
      const horse = await storage.updateHorse(req.params.id, data);
      if (!horse) return res.status(404).json({ message: "Horse not found" });
      res.json(horse);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/horses/import", async (req, res) => {
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

  app.post("/api/stables", async (req, res) => {
    try {
      const data = validateBody(insertStableSchema, req.body);
      const stable = await storage.createStable(data);
      res.json(stable);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/stables/:id", async (req, res) => {
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

  app.post("/api/boxes", async (req, res) => {
    try {
      const data = validateBody(insertBoxSchema, req.body);
      const box = await storage.createBox(data);
      res.json(box);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/boxes/:id", async (req, res) => {
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

  app.post("/api/boxes/import", async (req, res) => {
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

  app.post("/api/items/import", async (req, res) => {
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

  app.patch("/api/items/:id", async (req, res) => {
    try {
      const data = validateBody(insertItemSchema.partial(), req.body);
      const item = await storage.updateItem(req.params.id, data);
      if (!item) return res.status(404).json({ message: "Item not found" });
      res.json(item);
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

  app.post("/api/livery-agreements", async (req, res) => {
    try {
      const data = validateBody(insertLiveryAgreementSchema, req.body);
      const agreement = await storage.createLiveryAgreement(data);
      auditLog(req, "create_agreement", "agreement", agreement.id, `Created agreement: ${agreement.referenceNumber}`);
      res.json(agreement);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/livery-agreements/:id", async (req, res) => {
    try {
      const data = validateBody(insertLiveryAgreementSchema.partial(), req.body);
      const agreement = await storage.updateLiveryAgreement(req.params.id, data);
      if (!agreement) return res.status(404).json({ message: "Agreement not found" });
      if (data.endDate) {
        auditLog(req, "checkout_agreement", "agreement", req.params.id, `Checkout agreement, end date: ${data.endDate}`);
      }
      res.json(agreement);
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

  app.post("/api/billing-elements", async (req, res) => {
    try {
      if (req.body.transactionDate && !req.body.billingMonth) {
        req.body.billingMonth = req.body.transactionDate.substring(0, 7);
      }
      const data = validateBody(insertBillingElementSchema, req.body);
      const element = await storage.createBillingElement(data);
      auditLog(req, "create_billing_element", "billing_element", element.id);
      res.json(element);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/billing-elements/:id", async (req, res) => {
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

  // Invoices
  app.get("/api/invoices", async (_req, res) => {
    try {
      const invoices = await storage.getInvoices();
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

  app.post("/api/invoices", async (req, res) => {
    try {
      const { customerId, invoiceDate, billingMonth, totalAmount, status, billingElementIds, liveryItems } = req.body;
      if (!customerId || !invoiceDate || !totalAmount) throw { status: 400, message: "Missing required fields: customerId, invoiceDate, totalAmount" };
      const invoice = await storage.createInvoice({ customerId, invoiceDate, billingMonth, totalAmount, status });

      if (liveryItems && Array.isArray(liveryItems) && liveryItems.length > 0) {
        for (const item of liveryItems) {
          const validatedItem = validateBody(insertBillingElementSchema, {
            horseId: item.horseId,
            customerId,
            boxId: item.boxId,
            itemId: item.itemId,
            agreementId: item.agreementId,
            quantity: 1,
            price: item.price,
            transactionDate: invoiceDate,
            billingMonth: item.billingMonth,
            billed: true,
            invoiceId: invoice.id,
          });
          await storage.createBillingElement(validatedItem);
        }
      }

      if (billingElementIds && billingElementIds.length > 0) {
        await storage.markBillingElementsByIds(billingElementIds, invoice.id);
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

  app.post("/api/invoices/:id/generate-so", async (req, res) => {
    try {
      const invoice = await storage.getInvoice(req.params.id);
      if (!invoice) return res.status(404).json({ message: "Invoice not found" });

      const details = await storage.getInvoiceDetailsForSO(req.params.id);
      if (!details) return res.status(404).json({ message: "Invoice details not found" });

      const poNumber = invoice.poNumber || await storage.getNextPoNumber();

      const billingMonth = invoice.billingMonth || "";
      let memoMonth = "";
      if (billingMonth) {
        const [y, m] = billingMonth.split("-").map(Number);
        const date = new Date(y, m - 1);
        memoMonth = date.toLocaleString("en-US", { month: "short", year: "numeric" });
      }
      const customerName = details.customer
        ? `${details.customer.firstname} ${details.customer.lastname}`
        : "Unknown";

      const today = new Date();
      const tranDate = `${String(today.getDate()).padStart(2, "0")}/${String(today.getMonth() + 1).padStart(2, "0")}/${today.getFullYear()}`;

      const soJson = {
        customerId: details.customer?.netsuiteId || "",
        po: poNumber,
        department: "32",
        memo: `Monthly Livery Invoice - ${customerName} (${memoMonth})`,
        tranDate,
        items: details.items,
      };

      const jsonString = JSON.stringify(soJson, null, 2);

      await storage.updateInvoice(req.params.id, {
        soGenerated: true,
        poNumber,
        netsuiteJson: jsonString,
        status: "SO Generated",
        sentToNetsuite: false,
      });

      res.json({ success: true, poNumber, json: soJson });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Reports
  app.get("/api/reports/livery", async (req, res) => {
    try {
      const groupBy = (req.query.groupBy as string) || "month";
      const data = await storage.getReportData(groupBy);
      res.json(data);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Send invoice to NetSuite via N8N webhook
  app.post("/api/invoices/:id/send-to-netsuite", async (req, res) => {
    try {
      const invoice = await storage.getInvoice(req.params.id);
      if (!invoice) return res.status(404).json({ message: "Invoice not found" });
      if (!invoice.soGenerated) return res.status(400).json({ message: "SO must be generated before sending to NetSuite" });
      if (!invoice.netsuiteJson) return res.status(400).json({ message: "No NetSuite JSON found on this invoice" });

      const webhookUrl = await storage.getSetting("n8n_webhook_url");
      if (!webhookUrl) return res.status(400).json({ message: "N8N Webhook URL is not configured. Please set it in Settings." });

      const response = await fetch(webhookUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: invoice.netsuiteJson,
      });

      if (!response.ok) {
        const errorText = await response.text().catch(() => "Unknown error");
        return res.status(502).json({ message: `N8N webhook returned error: ${response.status} - ${errorText}` });
      }

      let netsuiteId: string | null = null;
      let parseError = false;
      try {
        const responseData = await response.json();
        if (responseData?.netsuiteId) netsuiteId = String(responseData.netsuiteId);
        else if (responseData?.id) netsuiteId = String(responseData.id);
      } catch {
        parseError = true;
      }

      if (parseError && !netsuiteId) {
        return res.status(502).json({ message: "Webhook returned success but response could not be parsed. Invoice was not marked as sent." });
      }

      const updateData: any = {
        sentToNetsuite: true,
        status: "Sent to NetSuite",
      };
      if (netsuiteId) updateData.netsuiteId = netsuiteId;

      await storage.updateInvoice(req.params.id, updateData);

      res.json({ success: true, netsuiteId });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Settings - N8N Webhook URL
  app.get("/api/settings/n8n-webhook", async (_req, res) => {
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
  app.get("/api/livery-agreements/:id/documents", async (req, res) => {
    try {
      const docs = await storage.getAgreementDocuments(req.params.id);
      res.json(docs.map(d => ({ id: d.id, agreementId: d.agreementId, filename: d.filename, uploadedAt: d.uploadedAt })));
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/livery-agreements/:id/documents", async (req, res) => {
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

  app.get("/api/agreement-documents/:id/download", async (req, res) => {
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

  app.delete("/api/agreement-documents/:id", async (req, res) => {
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

  return httpServer;
}
