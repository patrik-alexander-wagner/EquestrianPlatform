import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import {
  insertUserSchema, insertCustomerSchema, insertHorseSchema,
  insertStableSchema, insertBoxSchema, insertItemSchema,
  insertLiveryAgreementSchema, insertBillingElementSchema, insertInvoiceSchema,
} from "@shared/schema";
import { ZodError } from "zod";

function validateBody(schema: any, body: any) {
  const result = schema.safeParse(body);
  if (!result.success) {
    throw { status: 400, message: result.error.errors.map((e: any) => e.message).join(", ") };
  }
  return result.data;
}

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {

  // Users
  app.get("/api/users", async (_req, res) => {
    const users = await storage.getUsers();
    res.json(users);
  });

  app.post("/api/users", async (req, res) => {
    try {
      const data = validateBody(insertUserSchema, req.body);
      const user = await storage.createUser(data);
      res.json(user);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  // Customers
  app.get("/api/customers", async (req, res) => {
    const search = req.query.search as string | undefined;
    const customers = await storage.getCustomers(search);
    res.json(customers);
  });

  app.get("/api/customers/:id", async (req, res) => {
    const customer = await storage.getCustomer(req.params.id);
    if (!customer) return res.status(404).json({ message: "Customer not found" });
    res.json(customer);
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
    const { customers: data } = req.body;
    const results = [];
    for (const c of data) {
      const created = await storage.createCustomer(c);
      results.push(created);
    }
    res.json(results);
  });

  // Horses
  app.get("/api/horses", async (req, res) => {
    const search = req.query.search as string | undefined;
    const customerSearch = req.query.customerSearch as string | undefined;
    const stableBoxSearch = req.query.stableBoxSearch as string | undefined;
    const horses = await storage.getHorses(search, customerSearch, stableBoxSearch);
    res.json(horses);
  });

  app.get("/api/horses/:id", async (req, res) => {
    const horse = await storage.getHorse(req.params.id);
    if (!horse) return res.status(404).json({ message: "Horse not found" });
    res.json(horse);
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
    const horse = await storage.updateHorse(req.params.id, req.body);
    if (!horse) return res.status(404).json({ message: "Horse not found" });
    res.json(horse);
  });

  app.post("/api/horses/import", async (req, res) => {
    const { horses: data } = req.body;
    const results = [];
    for (const h of data) {
      const created = await storage.createHorse(h);
      results.push(created);
    }
    res.json(results);
  });

  // Stables
  app.get("/api/stables", async (_req, res) => {
    const stables = await storage.getStables();
    res.json(stables);
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
    const stable = await storage.updateStable(req.params.id, req.body);
    if (!stable) return res.status(404).json({ message: "Stable not found" });
    res.json(stable);
  });

  app.delete("/api/stables/:id", async (req, res) => {
    await storage.deleteStable(req.params.id);
    res.json({ success: true });
  });

  // Boxes
  app.get("/api/boxes", async (req, res) => {
    const stableSearch = req.query.stableSearch as string | undefined;
    const boxSearch = req.query.boxSearch as string | undefined;
    const boxes = await storage.getBoxes(stableSearch, boxSearch);
    res.json(boxes);
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
    const box = await storage.updateBox(req.params.id, req.body);
    if (!box) return res.status(404).json({ message: "Box not found" });
    res.json(box);
  });

  app.delete("/api/boxes/:id", async (req, res) => {
    await storage.deleteBox(req.params.id);
    res.json({ success: true });
  });

  app.post("/api/boxes/import", async (req, res) => {
    const { boxes: data } = req.body;
    const results = [];
    for (const b of data) {
      const created = await storage.createBox(b);
      results.push(created);
    }
    res.json(results);
  });

  // Items
  app.get("/api/items", async (req, res) => {
    const search = req.query.search as string | undefined;
    const items = await storage.getItems(search);
    res.json(items);
  });

  app.get("/api/items/livery-packages", async (_req, res) => {
    const items = await storage.getLiveryPackageItems();
    res.json(items);
  });

  app.get("/api/items/non-livery-packages", async (_req, res) => {
    const items = await storage.getNonLiveryPackageItems();
    res.json(items);
  });

  app.post("/api/items/import", async (req, res) => {
    const { items: data } = req.body;
    const results = [];
    for (const i of data) {
      const created = await storage.createItem(i);
      results.push(created);
    }
    res.json(results);
  });

  app.patch("/api/items/:id", async (req, res) => {
    const item = await storage.updateItem(req.params.id, req.body);
    if (!item) return res.status(404).json({ message: "Item not found" });
    res.json(item);
  });

  // Livery Agreements
  app.get("/api/livery-agreements", async (req, res) => {
    const status = req.query.status as string | undefined;
    const agreements = await storage.getLiveryAgreements(status);
    res.json(agreements);
  });

  app.post("/api/livery-agreements", async (req, res) => {
    try {
      const data = validateBody(insertLiveryAgreementSchema, req.body);
      const agreement = await storage.createLiveryAgreement(data);
      res.json(agreement);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/livery-agreements/:id", async (req, res) => {
    const agreement = await storage.updateLiveryAgreement(req.params.id, req.body);
    if (!agreement) return res.status(404).json({ message: "Agreement not found" });
    res.json(agreement);
  });

  app.get("/api/boxes-with-status", async (_req, res) => {
    const boxes = await storage.getBoxesWithAgreementStatus();
    res.json(boxes);
  });

  // Billing Elements
  app.get("/api/billing-elements", async (req, res) => {
    const billed = req.query.billed !== undefined ? req.query.billed === "true" : undefined;
    const elements = await storage.getBillingElements(billed);
    res.json(elements);
  });

  app.post("/api/billing-elements", async (req, res) => {
    try {
      const data = validateBody(insertBillingElementSchema, req.body);
      const element = await storage.createBillingElement(data);
      res.json(element);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.get("/api/horses-with-agreements", async (_req, res) => {
    const horses = await storage.getHorsesWithActiveAgreements();
    res.json(horses);
  });

  // Invoices
  app.get("/api/invoices", async (_req, res) => {
    const invoices = await storage.getInvoices();
    res.json(invoices);
  });

  app.post("/api/invoices", async (req, res) => {
    const invoice = await storage.createInvoice(req.body);
    await storage.markBillingElementsAsInvoiced(req.body.customerId, invoice.id);
    res.json(invoice);
  });

  // Reports
  app.get("/api/reports/livery", async (req, res) => {
    const groupBy = (req.query.groupBy as string) || "month";
    const data = await storage.getReportData(groupBy);
    res.json(data);
  });

  // Settings - Livery Package Configuration
  app.post("/api/settings/livery-packages", async (req, res) => {
    const { itemIds } = req.body;
    const allItems = await storage.getItems();
    for (const item of allItems) {
      const isPackage = itemIds.includes(item.id);
      if (item.isLiveryPackage !== isPackage) {
        await storage.updateItem(item.id, { isLiveryPackage: isPackage });
      }
    }
    res.json({ success: true });
  });

  return httpServer;
}
