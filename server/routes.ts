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
    try {
      const users = await storage.getUsers();
      res.json(users);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
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
      const results = [];
      for (const c of data) {
        const created = await storage.createCustomer(c);
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
      const horse = await storage.updateHorse(req.params.id, req.body);
      if (!horse) return res.status(404).json({ message: "Horse not found" });
      res.json(horse);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/horses/import", async (req, res) => {
    try {
      const { horses: data } = req.body;
      const results = [];
      for (const h of data) {
        const created = await storage.createHorse(h);
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
      const stable = await storage.updateStable(req.params.id, req.body);
      if (!stable) return res.status(404).json({ message: "Stable not found" });
      res.json(stable);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/stables/:id", async (req, res) => {
    try {
      await storage.deleteStable(req.params.id);
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
      const box = await storage.updateBox(req.params.id, req.body);
      if (!box) return res.status(404).json({ message: "Box not found" });
      res.json(box);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/boxes/:id", async (req, res) => {
    try {
      await storage.deleteBox(req.params.id);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/boxes/import", async (req, res) => {
    try {
      const { boxes: data } = req.body;
      const results = [];
      for (const b of data) {
        const created = await storage.createBox(b);
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
      const results = await storage.createItemsBulk(data);
      res.json({ imported: results.length });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/items/:id", async (req, res) => {
    try {
      const item = await storage.updateItem(req.params.id, req.body);
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
      res.json(agreement);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.patch("/api/livery-agreements/:id", async (req, res) => {
    try {
      const agreement = await storage.updateLiveryAgreement(req.params.id, req.body);
      if (!agreement) return res.status(404).json({ message: "Agreement not found" });
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
      const data = validateBody(insertBillingElementSchema, req.body);
      const element = await storage.createBillingElement(data);
      res.json(element);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/billing-elements/:id", async (req, res) => {
    try {
      const deleted = await storage.deleteBillingElement(req.params.id);
      if (!deleted) return res.status(404).json({ message: "Billing element not found" });
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
      const invoice = await storage.createInvoice({ customerId, invoiceDate, billingMonth, totalAmount, status });

      if (liveryItems && liveryItems.length > 0) {
        for (const item of liveryItems) {
          const created = await storage.createBillingElement({
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
        }
      }

      if (billingElementIds && billingElementIds.length > 0) {
        await storage.markBillingElementsByIds(billingElementIds, invoice.id);
      }

      res.json(invoice);
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.delete("/api/invoices/:id", async (req, res) => {
    try {
      await storage.deleteInvoice(req.params.id);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  app.post("/api/invoices/:id/generate-so", async (req, res) => {
    try {
      const invoice = await storage.getInvoice(req.params.id);
      if (!invoice) return res.status(404).json({ message: "Invoice not found" });
      if (invoice.soGenerated) return res.status(400).json({ message: "SO already generated for this invoice" });

      const details = await storage.getInvoiceDetailsForSO(req.params.id);
      if (!details) return res.status(404).json({ message: "Invoice details not found" });

      const poNumber = await storage.getNextPoNumber();

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

  // Settings - Livery Package Configuration
  app.post("/api/settings/livery-packages", async (req, res) => {
    try {
      const { itemIds } = req.body;
      const allItems = await storage.getItems();
      for (const item of allItems) {
        const isPackage = itemIds.includes(item.id);
        if (item.isLiveryPackage !== isPackage) {
          await storage.updateItem(item.id, { isLiveryPackage: isPackage });
        }
      }
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 500).json({ message: e.message || "Server error" });
    }
  });

  return httpServer;
}
