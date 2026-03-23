import { eq, and, ilike, or, sql, desc } from "drizzle-orm";
import { db } from "./db";
import { hashPassword } from "./auth";
import {
  users, customers, horses, stables, boxes, items, itemPrices,
  liveryAgreements, billingElements, invoices, appSettings, agreementDocuments, auditLogs,
  type User, type InsertUser,
  type Customer, type InsertCustomer,
  type Horse, type InsertHorse,
  type Stable, type InsertStable,
  type Box, type InsertBox,
  type Item, type InsertItem,
  type ItemPrice, type InsertItemPrice,
  type LiveryAgreement, type InsertLiveryAgreement,
  type BillingElement, type InsertBillingElement,
  type Invoice, type InsertInvoice,
  type AgreementDocument, type InsertAgreementDocument,
  type AuditLog, type InsertAuditLog,
} from "@shared/schema";

export interface IStorage {
  getUser(id: string): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  updateUserPassword(id: string, password: string, role?: string): Promise<void>;
  getUsers(): Promise<Omit<User, "password">[]>;

  getCustomers(search?: string): Promise<Customer[]>;
  getCustomer(id: string): Promise<Customer | undefined>;
  createCustomer(customer: InsertCustomer): Promise<Customer>;
  updateCustomer(id: string, customer: Partial<InsertCustomer>): Promise<Customer | undefined>;

  getHorses(search?: string, customerSearch?: string, stableBoxSearch?: string): Promise<any[]>;
  getHorse(id: string): Promise<Horse | undefined>;
  createHorse(horse: InsertHorse): Promise<Horse>;
  updateHorse(id: string, horse: Partial<InsertHorse>): Promise<Horse | undefined>;

  getStables(): Promise<Stable[]>;
  getStable(id: string): Promise<Stable | undefined>;
  createStable(stable: InsertStable): Promise<Stable>;
  updateStable(id: string, stable: Partial<InsertStable>): Promise<Stable | undefined>;
  deleteStable(id: string): Promise<boolean>;

  getBoxes(stableSearch?: string, boxSearch?: string): Promise<any[]>;
  getBox(id: string): Promise<Box | undefined>;
  createBox(box: InsertBox): Promise<Box>;
  updateBox(id: string, box: Partial<InsertBox>): Promise<Box | undefined>;
  deleteBox(id: string): Promise<boolean>;

  getItems(search?: string): Promise<Item[]>;
  getItem(id: string): Promise<Item | undefined>;
  createItem(item: InsertItem): Promise<Item>;
  createItemsBulk(itemsList: InsertItem[]): Promise<Item[]>;
  updateItem(id: string, item: Partial<InsertItem>): Promise<Item | undefined>;
  getLiveryPackageItems(): Promise<Item[]>;
  getNonLiveryPackageItems(): Promise<Item[]>;

  getLiveryAgreements(status?: string): Promise<any[]>;
  getLiveryAgreement(id: string): Promise<LiveryAgreement | undefined>;
  createLiveryAgreement(agreement: InsertLiveryAgreement): Promise<LiveryAgreement>;
  updateLiveryAgreement(id: string, agreement: Partial<InsertLiveryAgreement>): Promise<LiveryAgreement | undefined>;
  getBoxesWithAgreementStatus(): Promise<any[]>;
  getAvailableHorses(): Promise<any[]>;

  getBillingElements(billed?: boolean): Promise<any[]>;
  getBillingElement(id: string): Promise<BillingElement | undefined>;
  createBillingElement(element: InsertBillingElement): Promise<BillingElement>;
  deleteBillingElement(id: string): Promise<boolean>;
  getHorsesWithActiveAgreements(): Promise<any[]>;

  getInvoices(): Promise<any[]>;
  getInvoice(id: string): Promise<Invoice | undefined>;
  getInvoiceDetails(id: string): Promise<any>;
  createInvoice(invoice: InsertInvoice): Promise<Invoice>;
  updateInvoice(id: string, data: Partial<Invoice>): Promise<Invoice | undefined>;
  deleteInvoice(id: string): Promise<boolean>;
  markBillingElementsByIds(elementIds: string[], invoiceId: string): Promise<void>;
  getBilledMonthsForAgreements(agreementIds: string[]): Promise<Record<string, string[]>>;
  getNextPoNumber(): Promise<string>;
  getInvoiceDetailsForSO(id: string): Promise<any>;
  getSetting(key: string): Promise<string | null>;
  setSetting(key: string, value: string): Promise<void>;

  getItemPriceHistory(itemId: string): Promise<ItemPrice[]>;
  changeItemPrice(itemId: string, newPrice: string, createdBy?: string): Promise<ItemPrice>;

  getReportData(groupBy: string): Promise<any[]>;
  getNewLiveryHorses(month: string): Promise<any[]>;
  getDepartedLiveryHorses(month: string): Promise<any[]>;
  getLiveryCustomersInfo(): Promise<any[]>;

  getAgreementDocuments(agreementId: string): Promise<AgreementDocument[]>;
  getAgreementDocument(id: string): Promise<AgreementDocument | undefined>;
  createAgreementDocument(doc: InsertAgreementDocument): Promise<AgreementDocument>;
  deleteAgreementDocument(id: string): Promise<boolean>;

  createAuditLog(log: InsertAuditLog): Promise<AuditLog>;
  getAuditLogs(limit?: number, offset?: number): Promise<{ logs: AuditLog[]; total: number }>;
}

export class DatabaseStorage implements IStorage {
  async getUser(id: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user;
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    return user;
  }

  async createUser(user: InsertUser): Promise<User> {
    const hashedPassword = await hashPassword(user.password);
    const [created] = await db.insert(users).values({ ...user, password: hashedPassword }).returning();
    return created;
  }

  async updateUserPassword(id: string, password: string, role?: string): Promise<void> {
    const hashedPassword = await hashPassword(password);
    const updates: any = { password: hashedPassword };
    if (role) updates.role = role;
    await db.update(users).set(updates).where(eq(users.id, id));
  }

  async getUsers(): Promise<Omit<User, "password">[]> {
    return await db.select({ id: users.id, username: users.username }).from(users);
  }

  async getCustomers(search?: string): Promise<Customer[]> {
    if (search) {
      return await db.select().from(customers).where(
        or(
          ilike(customers.firstname, `%${search}%`),
          ilike(customers.lastname, `%${search}%`)
        )
      );
    }
    return await db.select().from(customers);
  }

  async getCustomer(id: string): Promise<Customer | undefined> {
    const [customer] = await db.select().from(customers).where(eq(customers.id, id));
    return customer;
  }

  async createCustomer(customer: InsertCustomer): Promise<Customer> {
    const [created] = await db.insert(customers).values(customer).returning();
    return created;
  }

  async updateCustomer(id: string, customer: Partial<InsertCustomer>): Promise<Customer | undefined> {
    const [updated] = await db.update(customers).set(customer).where(eq(customers.id, id)).returning();
    return updated;
  }

  async getHorses(search?: string, customerSearch?: string, stableBoxSearch?: string): Promise<any[]> {
    const allHorses = await db.select().from(horses);
    const allAgreements = await db.select().from(liveryAgreements).where(eq(liveryAgreements.status, "active"));
    const allCustomers = await db.select().from(customers);
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);

    let result = allHorses.map(horse => {
      const agreement = allAgreements.find(a => a.horseId === horse.id);
      const customer = agreement ? allCustomers.find(c => c.id === agreement.customerId) : null;
      const box = agreement ? allBoxes.find(b => b.id === agreement.boxId) : null;
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      return {
        ...horse,
        customer: customer ? `${customer.firstname} ${customer.lastname}` : null,
        customerId: customer?.id || null,
        box: box?.name || null,
        boxId: box?.id || null,
        stable: stable?.name || null,
        stableId: stable?.id || null,
      };
    });

    if (search) {
      result = result.filter(h => h.horseName.toLowerCase().includes(search.toLowerCase()));
    }
    if (customerSearch) {
      result = result.filter(h => h.customer && h.customer.toLowerCase().includes(customerSearch.toLowerCase()));
    }
    if (stableBoxSearch) {
      result = result.filter(h =>
        (h.stable && h.stable.toLowerCase().includes(stableBoxSearch.toLowerCase())) ||
        (h.box && h.box.toLowerCase().includes(stableBoxSearch.toLowerCase()))
      );
    }

    return result;
  }

  async getHorse(id: string): Promise<Horse | undefined> {
    const [horse] = await db.select().from(horses).where(eq(horses.id, id));
    return horse;
  }

  async createHorse(horse: InsertHorse): Promise<Horse> {
    const [created] = await db.insert(horses).values(horse).returning();
    return created;
  }

  async updateHorse(id: string, horse: Partial<InsertHorse>): Promise<Horse | undefined> {
    const [updated] = await db.update(horses).set(horse).where(eq(horses.id, id)).returning();
    return updated;
  }

  async getStables(): Promise<Stable[]> {
    return await db.select().from(stables);
  }

  async getStable(id: string): Promise<Stable | undefined> {
    const [stable] = await db.select().from(stables).where(eq(stables.id, id));
    return stable;
  }

  async createStable(stable: InsertStable): Promise<Stable> {
    const [created] = await db.insert(stables).values(stable).returning();
    return created;
  }

  async updateStable(id: string, stable: Partial<InsertStable>): Promise<Stable | undefined> {
    const [updated] = await db.update(stables).set(stable).where(eq(stables.id, id)).returning();
    return updated;
  }

  async deleteStable(id: string): Promise<boolean> {
    const result = await db.delete(stables).where(eq(stables.id, id));
    return true;
  }

  async getBoxes(stableSearch?: string, boxSearch?: string): Promise<any[]> {
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);

    let result = allBoxes.map(box => {
      const stable = allStables.find(s => s.id === box.stableId);
      return { ...box, stableName: stable?.name || "Unknown" };
    });

    if (stableSearch) {
      result = result.filter(b => b.stableName.toLowerCase().includes(stableSearch.toLowerCase()));
    }
    if (boxSearch) {
      result = result.filter(b => b.name.toLowerCase().includes(boxSearch.toLowerCase()));
    }

    return result;
  }

  async getBox(id: string): Promise<Box | undefined> {
    const [box] = await db.select().from(boxes).where(eq(boxes.id, id));
    return box;
  }

  async createBox(box: InsertBox): Promise<Box> {
    const [created] = await db.insert(boxes).values(box).returning();
    return created;
  }

  async updateBox(id: string, box: Partial<InsertBox>): Promise<Box | undefined> {
    const [updated] = await db.update(boxes).set(box).where(eq(boxes.id, id)).returning();
    return updated;
  }

  async deleteBox(id: string): Promise<boolean> {
    await db.delete(boxes).where(eq(boxes.id, id));
    return true;
  }

  async getItems(search?: string): Promise<Item[]> {
    if (search) {
      return await db.select().from(items).where(ilike(items.name, `%${search}%`));
    }
    return await db.select().from(items);
  }

  async getItem(id: string): Promise<Item | undefined> {
    const [item] = await db.select().from(items).where(eq(items.id, id));
    return item;
  }

  async createItem(item: InsertItem): Promise<Item> {
    const [created] = await db.insert(items).values(item).returning();
    return created;
  }

  async createItemsBulk(itemsList: InsertItem[]): Promise<Item[]> {
    if (itemsList.length === 0) return [];
    const batchSize = 100;
    const results: Item[] = [];
    for (let i = 0; i < itemsList.length; i += batchSize) {
      const batch = itemsList.slice(i, i + batchSize);
      const created = await db.insert(items).values(batch).returning();
      results.push(...created);
    }
    return results;
  }

  async updateItem(id: string, item: Partial<InsertItem>): Promise<Item | undefined> {
    const [updated] = await db.update(items).set(item).where(eq(items.id, id)).returning();
    return updated;
  }

  async getLiveryPackageItems(): Promise<Item[]> {
    return await db.select().from(items).where(eq(items.isLiveryPackage, true));
  }

  async getNonLiveryPackageItems(): Promise<Item[]> {
    return await db.select().from(items).where(eq(items.isLiveryPackage, false));
  }

  async getLiveryAgreements(status?: string): Promise<any[]> {
    const allAgreements = status
      ? await db.select().from(liveryAgreements).where(eq(liveryAgreements.status, status))
      : await db.select().from(liveryAgreements);
    const allHorses = await db.select().from(horses);
    const allCustomers = await db.select().from(customers);
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);
    const allItems = await db.select().from(items);

    return allAgreements.map(agreement => {
      const horse = agreement.horseId ? allHorses.find(h => h.id === agreement.horseId) : null;
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      const box = allBoxes.find(b => b.id === agreement.boxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      const item = allItems.find(i => i.id === agreement.itemId);
      return {
        ...agreement,
        horseName: horse?.horseName || null,
        customerName: customer ? `${customer.firstname} ${customer.lastname}` : "Unknown",
        boxName: box?.name || "Unknown",
        stableName: stable?.name || "Unknown",
        itemName: item?.name || "Unknown",
      };
    });
  }

  async getLiveryAgreement(id: string): Promise<LiveryAgreement | undefined> {
    const [agreement] = await db.select().from(liveryAgreements).where(eq(liveryAgreements.id, id));
    return agreement;
  }

  async createLiveryAgreement(agreement: InsertLiveryAgreement): Promise<LiveryAgreement> {
    const [created] = await db.insert(liveryAgreements).values(agreement).returning();
    return created;
  }

  async updateLiveryAgreement(id: string, agreement: Partial<InsertLiveryAgreement>): Promise<LiveryAgreement | undefined> {
    const [updated] = await db.update(liveryAgreements).set(agreement).where(eq(liveryAgreements.id, id)).returning();
    return updated;
  }

  async getBoxesWithAgreementStatus(): Promise<any[]> {
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);
    const activeAgreements = await db.select().from(liveryAgreements).where(eq(liveryAgreements.status, "active"));
    const today = new Date().toISOString().split("T")[0];

    return allBoxes.map(box => {
      const stable = allStables.find(s => s.id === box.stableId);
      const agreement = activeAgreements.find(a => a.boxId === box.id && (!a.endDate || a.endDate >= today));
      return {
        ...box,
        stableName: stable?.name || "Unknown",
        isAvailable: !agreement,
        agreementId: agreement?.id || null,
      };
    });
  }

  async getAvailableHorses(): Promise<any[]> {
    const allHorses = await db.select().from(horses).where(eq(horses.status, "active"));
    const activeAgreements = await db.select().from(liveryAgreements).where(eq(liveryAgreements.status, "active"));
    const today = new Date().toISOString().split("T")[0];
    const bookedHorseIds = new Set(activeAgreements.filter(a => a.horseId && (!a.endDate || a.endDate >= today)).map(a => a.horseId));
    return allHorses.filter(h => !bookedHorseIds.has(h.id));
  }

  async getBillingElements(billed?: boolean): Promise<any[]> {
    const query = billed !== undefined
      ? await db.select().from(billingElements).where(eq(billingElements.billed, billed))
      : await db.select().from(billingElements);

    const allHorses = await db.select().from(horses);
    const allCustomers = await db.select().from(customers);
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);
    const allItems = await db.select().from(items);

    return query.map(element => {
      const horse = allHorses.find(h => h.id === element.horseId);
      const customer = allCustomers.find(c => c.id === element.customerId);
      const box = allBoxes.find(b => b.id === element.boxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      const item = allItems.find(i => i.id === element.itemId);
      return {
        ...element,
        horseName: horse?.horseName || "Unknown",
        customerName: customer ? `${customer.firstname} ${customer.lastname}` : "Unknown",
        boxName: box?.name || "Unknown",
        stableName: stable?.name || "Unknown",
        itemName: item?.name || "Unknown",
      };
    });
  }

  async getBillingElement(id: string): Promise<BillingElement | undefined> {
    const [element] = await db.select().from(billingElements).where(eq(billingElements.id, id));
    return element;
  }

  async createBillingElement(element: InsertBillingElement): Promise<BillingElement> {
    const [created] = await db.insert(billingElements).values(element).returning();
    return created;
  }

  async deleteBillingElement(id: string): Promise<boolean> {
    const result = await db.delete(billingElements).where(eq(billingElements.id, id)).returning();
    return result.length > 0;
  }

  async getHorsesWithActiveAgreements(): Promise<any[]> {
    const allAgreements = await db.select().from(liveryAgreements).where(eq(liveryAgreements.status, "active"));
    const today = new Date().toISOString().split("T")[0];
    const activeAgreements = allAgreements.filter(a => !a.endDate || a.endDate >= today);
    const allHorses = await db.select().from(horses);
    const allCustomers = await db.select().from(customers);
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);

    return activeAgreements.map(agreement => {
      const horse = allHorses.find(h => h.id === agreement.horseId);
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      const box = allBoxes.find(b => b.id === agreement.boxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      return {
        horseId: horse?.id,
        horseName: horse?.horseName || "Unknown",
        customerId: customer?.id,
        customerName: customer ? `${customer.firstname} ${customer.lastname}` : "Unknown",
        boxId: box?.id,
        boxName: box?.name || "Unknown",
        stableId: stable?.id,
        stableName: stable?.name || "Unknown",
        agreementId: agreement.id,
      };
    });
  }

  async getInvoices(): Promise<any[]> {
    const allInvoices = await db.select().from(invoices).orderBy(desc(invoices.invoiceDate));
    const allCustomers = await db.select().from(customers);

    return allInvoices.map(invoice => {
      const customer = allCustomers.find(c => c.id === invoice.customerId);
      return {
        ...invoice,
        customerName: customer ? `${customer.firstname} ${customer.lastname}` : "Unknown",
      };
    });
  }

  async getInvoice(id: string): Promise<Invoice | undefined> {
    const [invoice] = await db.select().from(invoices).where(eq(invoices.id, id));
    return invoice;
  }

  async getInvoiceDetails(id: string): Promise<any> {
    const [invoice] = await db.select().from(invoices).where(eq(invoices.id, id));
    if (!invoice) return null;

    const customer = await this.getCustomer(invoice.customerId);
    const linkedElements = await db.select().from(billingElements).where(eq(billingElements.invoiceId, id));
    const allHorses = await db.select().from(horses);
    const allItems = await db.select().from(items);

    const lineItems = linkedElements.map(el => {
      const horse = allHorses.find(h => h.id === el.horseId);
      const item = allItems.find(i => i.id === el.itemId);
      return {
        description: item?.name || "Unknown",
        horseName: horse?.horseName || "Unknown",
        billDate: el.transactionDate,
        quantity: el.quantity,
        unit: item?.unitFactor ? `${item.unitFactor}` : "Each",
        unitPrice: (el.quantity || 1) > 0 ? parseFloat(el.price || "0") / (el.quantity || 1) : parseFloat(el.price || "0"),
        amount: parseFloat(el.price || "0"),
        isLivery: !!el.agreementId,
        billingMonth: el.billingMonth,
      };
    });

    return {
      ...invoice,
      customerName: customer ? `${customer.firstname} ${customer.lastname}` : "Unknown",
      customerNumber: customer?.netsuiteId || "",
      lineItems,
    };
  }

  async createInvoice(invoice: InsertInvoice): Promise<Invoice> {
    const [created] = await db.insert(invoices).values(invoice).returning();
    return created;
  }

  async markBillingElementsByIds(elementIds: string[], invoiceId: string): Promise<void> {
    for (const id of elementIds) {
      await db.update(billingElements)
        .set({ billed: true, invoiceId })
        .where(eq(billingElements.id, id));
    }
  }

  async getBilledMonthsForAgreements(agreementIds: string[]): Promise<Record<string, string[]>> {
    if (agreementIds.length === 0) return {};
    const allBilled = await db.select().from(billingElements)
      .where(and(
        eq(billingElements.billed, true),
        sql`${billingElements.agreementId} IS NOT NULL`
      ));
    const result: Record<string, string[]> = {};
    for (const el of allBilled) {
      if (el.agreementId && el.billingMonth) {
        if (!result[el.agreementId]) result[el.agreementId] = [];
        result[el.agreementId].push(el.billingMonth);
      }
    }
    return result;
  }

  async updateInvoice(id: string, data: Partial<Invoice>): Promise<Invoice | undefined> {
    const [updated] = await db.update(invoices).set(data).where(eq(invoices.id, id)).returning();
    return updated;
  }

  async getNextPoNumber(): Promise<string> {
    const [setting] = await db.select().from(appSettings).where(eq(appSettings.key, "last_po_number"));
    const current = setting ? parseInt(setting.value) : 2026002999;
    const next = current + 1;
    await db.insert(appSettings)
      .values({ key: "last_po_number", value: String(next) })
      .onConflictDoUpdate({ target: appSettings.key, set: { value: String(next) } });
    return String(next);
  }

  async getInvoiceDetailsForSO(id: string): Promise<any> {
    const [invoice] = await db.select().from(invoices).where(eq(invoices.id, id));
    if (!invoice) return null;

    const customer = await this.getCustomer(invoice.customerId);
    const linkedElements = await db.select().from(billingElements).where(eq(billingElements.invoiceId, id));
    const allHorses = await db.select().from(horses);
    const allItems = await db.select().from(items);
    const allBoxes = await db.select().from(boxes);

    const itemsList = linkedElements.map(el => {
      const horse = allHorses.find(h => h.id === el.horseId);
      const item = allItems.find(i => i.id === el.itemId);
      const box = allBoxes.find(b => b.id === el.boxId);
      return {
        itemId: item?.netsuiteId || "",
        horse: String(horse?.netsuiteId || ""),
        quantity: el.quantity,
        rate: (el.quantity || 1) > 0 ? parseFloat(el.price || "0") / (el.quantity || 1) : parseFloat(el.price || "0"),
        description: item?.name || "Unknown",
        department: item?.department || "",
        class: item?.class || "",
        subclass: box?.netsuiteId || "",
        location: item?.location || "",
      };
    });

    return {
      invoice,
      customer,
      items: itemsList,
    };
  }

  async getSetting(key: string): Promise<string | null> {
    const [setting] = await db.select().from(appSettings).where(eq(appSettings.key, key));
    return setting ? setting.value : null;
  }

  async setSetting(key: string, value: string): Promise<void> {
    await db.insert(appSettings)
      .values({ key, value })
      .onConflictDoUpdate({ target: appSettings.key, set: { value } });
  }

  async deleteInvoice(id: string): Promise<boolean> {
    await db.delete(billingElements)
      .where(and(eq(billingElements.invoiceId, id), sql`${billingElements.agreementId} IS NOT NULL`));
    await db.update(billingElements)
      .set({ billed: false, invoiceId: null })
      .where(eq(billingElements.invoiceId, id));
    await db.delete(invoices).where(eq(invoices.id, id));
    return true;
  }

  async getReportData(groupBy: string): Promise<any[]> {
    const activeAgreements = await db.select().from(liveryAgreements).where(eq(liveryAgreements.status, "active"));
    const allCustomers = await db.select().from(customers);
    const allItems = await db.select().from(items);
    const allBillingElements = await db.select().from(billingElements);

    if (groupBy === "customer") {
      const grouped: Record<string, any> = {};
      for (const agreement of activeAgreements) {
        const customer = allCustomers.find(c => c.id === agreement.customerId);
        const key = customer ? `${customer.firstname} ${customer.lastname}` : "Unknown";
        if (!grouped[key]) {
          grouped[key] = { label: key, horseCount: 0, liveryRevenue: 0, otherRevenue: 0, totalRevenue: 0 };
        }
        grouped[key].horseCount++;
        const amount = parseFloat(agreement.monthlyAmount || "0");
        grouped[key].liveryRevenue += amount;
        grouped[key].totalRevenue += amount;
      }
      for (const el of allBillingElements) {
        const customer = allCustomers.find(c => c.id === el.customerId);
        const key = customer ? `${customer.firstname} ${customer.lastname}` : "Unknown";
        if (!grouped[key]) {
          grouped[key] = { label: key, horseCount: 0, liveryRevenue: 0, otherRevenue: 0, totalRevenue: 0 };
        }
        const amount = parseFloat(el.price || "0") * (el.quantity || 1);
        grouped[key].otherRevenue += amount;
        grouped[key].totalRevenue += amount;
      }
      return Object.values(grouped);
    } else {
      const grouped: Record<string, any> = {};
      for (const agreement of activeAgreements) {
        const month = agreement.startDate?.substring(0, 7) || "Unknown";
        if (!grouped[month]) {
          grouped[month] = { label: month, horseCount: 0, liveryRevenue: 0, otherRevenue: 0, totalRevenue: 0 };
        }
        grouped[month].horseCount++;
        const amount = parseFloat(agreement.monthlyAmount || "0");
        grouped[month].liveryRevenue += amount;
        grouped[month].totalRevenue += amount;
      }
      for (const el of allBillingElements) {
        const month = el.transactionDate?.substring(0, 7) || "Unknown";
        if (!grouped[month]) {
          grouped[month] = { label: month, horseCount: 0, liveryRevenue: 0, otherRevenue: 0, totalRevenue: 0 };
        }
        const amount = parseFloat(el.price || "0") * (el.quantity || 1);
        grouped[month].otherRevenue += amount;
        grouped[month].totalRevenue += amount;
      }
      return Object.values(grouped).sort((a, b) => a.label.localeCompare(b.label));
    }
  }
  async getItemPriceHistory(itemId: string): Promise<ItemPrice[]> {
    return await db.select().from(itemPrices)
      .where(eq(itemPrices.itemId, itemId))
      .orderBy(desc(itemPrices.createdAt));
  }

  async changeItemPrice(itemId: string, newPrice: string, createdBy?: string): Promise<ItemPrice> {
    return await db.transaction(async (tx) => {
      await tx.update(itemPrices)
        .set({ isActive: false })
        .where(and(eq(itemPrices.itemId, itemId), eq(itemPrices.isActive, true)));

      const [newRecord] = await tx.insert(itemPrices).values({
        itemId,
        price: newPrice,
        isActive: true,
        createdBy: createdBy || null,
      }).returning();

      await tx.update(items).set({ price: newPrice }).where(eq(items.id, itemId));

      return newRecord;
    });
  }

  async getNewLiveryHorses(month: string): Promise<any[]> {
    const allAgreements = await db.select().from(liveryAgreements);
    const allCustomers = await db.select().from(customers);
    const allHorses = await db.select().from(horses);
    const allItems = await db.select().from(items);

    const filtered = allAgreements.filter(a => a.startDate?.substring(0, 7) === month);

    const grouped: Record<string, any> = {};
    for (const agreement of filtered) {
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      const horse = allHorses.find(h => h.id === agreement.horseId);
      const item = allItems.find(i => i.id === agreement.itemId);
      const customerName = customer ? `${customer.firstname} ${customer.lastname}` : "Unknown";

      if (!grouped[agreement.customerId]) {
        grouped[agreement.customerId] = {
          customerName,
          horses: [],
          horseCount: 0,
        };
      }
      grouped[agreement.customerId].horses.push({
        horseName: horse?.horseName || "Unknown",
        arrivalDate: agreement.startDate,
        liveryPrice: agreement.monthlyAmount || (item?.price || "0"),
      });
      grouped[agreement.customerId].horseCount++;
    }

    return Object.values(grouped);
  }

  async getDepartedLiveryHorses(month: string): Promise<any[]> {
    const allAgreements = await db.select().from(liveryAgreements);
    const allCustomers = await db.select().from(customers);
    const allHorses = await db.select().from(horses);

    const filtered = allAgreements.filter(a => a.endDate && a.endDate.substring(0, 7) === month);

    const grouped: Record<string, any> = {};
    for (const agreement of filtered) {
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      const horse = allHorses.find(h => h.id === agreement.horseId);
      const customerName = customer ? `${customer.firstname} ${customer.lastname}` : "Unknown";

      if (!grouped[agreement.customerId]) {
        grouped[agreement.customerId] = {
          customerName,
          horses: [],
          horseCount: 0,
        };
      }
      grouped[agreement.customerId].horses.push({
        horseName: horse?.horseName || "Unknown",
        departureDate: agreement.endDate,
        checkoutReason: agreement.checkoutReason || "",
      });
      grouped[agreement.customerId].horseCount++;
    }

    return Object.values(grouped);
  }

  async getLiveryCustomersInfo(): Promise<any[]> {
    const activeAgreements = await db.select().from(liveryAgreements).where(eq(liveryAgreements.status, "active"));
    const today = new Date().toISOString().split("T")[0];
    const current = activeAgreements.filter(a => !a.endDate || a.endDate >= today);

    const allCustomers = await db.select().from(customers);
    const allHorses = await db.select().from(horses);

    const grouped: Record<string, any> = {};
    for (const agreement of current) {
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      const horse = allHorses.find(h => h.id === agreement.horseId);
      const customerName = customer ? `${customer.firstname} ${customer.lastname}` : "Unknown";

      if (!grouped[agreement.customerId]) {
        grouped[agreement.customerId] = {
          customerName,
          horses: [],
          horseCount: 0,
          totalMonthlyPrice: 0,
        };
      }
      const price = parseFloat(agreement.monthlyAmount || "0");
      grouped[agreement.customerId].horses.push({
        horseName: horse?.horseName || "Unknown",
        monthlyPrice: price,
      });
      grouped[agreement.customerId].horseCount++;
      grouped[agreement.customerId].totalMonthlyPrice += price;
    }

    return Object.values(grouped);
  }

  async getAgreementDocuments(agreementId: string): Promise<AgreementDocument[]> {
    return await db.select().from(agreementDocuments)
      .where(eq(agreementDocuments.agreementId, agreementId));
  }

  async getAgreementDocument(id: string): Promise<AgreementDocument | undefined> {
    const [doc] = await db.select().from(agreementDocuments).where(eq(agreementDocuments.id, id));
    return doc;
  }

  async createAgreementDocument(doc: InsertAgreementDocument): Promise<AgreementDocument> {
    const [created] = await db.insert(agreementDocuments).values(doc).returning();
    return created;
  }

  async deleteAgreementDocument(id: string): Promise<boolean> {
    const result = await db.delete(agreementDocuments).where(eq(agreementDocuments.id, id)).returning();
    return result.length > 0;
  }

  async createAuditLog(log: InsertAuditLog): Promise<AuditLog> {
    const [created] = await db.insert(auditLogs).values(log).returning();
    return created;
  }

  async getAuditLogs(limit = 50, offset = 0): Promise<{ logs: AuditLog[]; total: number }> {
    const logs = await db.select().from(auditLogs).orderBy(desc(auditLogs.createdAt)).limit(limit).offset(offset);
    const [countResult] = await db.select({ count: sql<number>`count(*)` }).from(auditLogs);
    return { logs, total: Number(countResult.count) };
  }
}

export const storage = new DatabaseStorage();
