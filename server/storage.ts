import { eq, and, ilike, or, sql, desc } from "drizzle-orm";
import { db } from "./db";
import { hashPassword } from "./auth";
import {
  users, customers, horses, stables, boxes, items, itemPrices,
  liveryAgreements, billingElements, invoices, appSettings, agreementDocuments, auditLogs, invoiceValidations,
  horseOwnership, horseMovements, monthlyBillingApprovals,
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
  type InvoiceValidation, type InsertInvoiceValidation,
  type HorseOwnership, type InsertHorseOwnership,
  type HorseMovement, type InsertHorseMovement,
  type MonthlyBillingApproval, type InsertMonthlyBillingApproval,
} from "@shared/schema";

function formatHorseName(horse: { horseName: string; passportName?: string | null }): string {
  if (horse.passportName) {
    return `${horse.horseName} (${horse.passportName})`;
  }
  return horse.horseName;
}

const EXCLUDED_REPORT_CUSTOMERS = ["ADEC"];

function isExcludedReportCustomer(name: string | undefined | null): boolean {
  if (!name) return false;
  return EXCLUDED_REPORT_CUSTOMERS.some(exc => name.toUpperCase() === exc.toUpperCase());
}

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
  createHorseWithOwner(horse: InsertHorse, ownerId: string): Promise<Horse>;
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
  updateBillingElement(id: string, data: Partial<InsertBillingElement>): Promise<BillingElement | undefined>;
  deleteBillingElement(id: string): Promise<boolean>;
  getHorsesWithActiveAgreements(): Promise<any[]>;
  getHorsesWithOwners(): Promise<any[]>;

  getInvoices(): Promise<any[]>;
  getInvoice(id: string): Promise<Invoice | undefined>;
  getInvoiceDetails(id: string): Promise<any>;
  createInvoice(invoice: InsertInvoice): Promise<Invoice>;
  createInvoiceWithLineItems(invoice: InsertInvoice, liveryItems: InsertBillingElement[], adhocBillingElementIds: string[]): Promise<Invoice>;
  getInvoiceLineItemCount(invoiceId: string): Promise<number>;
  updateInvoice(id: string, data: Partial<Invoice>): Promise<Invoice | undefined>;
  unbillByInvoiceId(invoiceId: string): Promise<void>;
  deleteInvoice(id: string): Promise<boolean>;
  markBillingElementsByIds(elementIds: string[], invoiceId: string): Promise<void>;
  getBilledMonthsForAgreements(agreementIds: string[]): Promise<Record<string, string[]>>;
  getNextPoNumber(): Promise<string>;
  getInvoiceDetailsForSO(id: string): Promise<any>;
  getSetting(key: string): Promise<string | null>;
  setSetting(key: string, value: string): Promise<void>;

  getItemPriceHistory(itemId: string): Promise<ItemPrice[]>;
  changeItemPrice(itemId: string, newPrice: string, createdBy?: string): Promise<ItemPrice>;

  getReportKpis(month: string): Promise<any>;
  getReportData(groupBy: string, month?: string): Promise<any[]>;
  getNewLiveryHorses(month: string): Promise<any[]>;
  getDepartedLiveryHorses(month: string): Promise<any[]>;
  getLiveryCustomersInfo(): Promise<any[]>;
  getAllCustomersReport(): Promise<any[]>;

  getAgreementDocuments(agreementId: string): Promise<AgreementDocument[]>;
  getAgreementDocument(id: string): Promise<AgreementDocument | undefined>;
  createAgreementDocument(doc: InsertAgreementDocument): Promise<AgreementDocument>;
  deleteAgreementDocument(id: string): Promise<boolean>;

  createAuditLog(log: InsertAuditLog): Promise<AuditLog>;
  getAuditLogs(limit?: number, offset?: number): Promise<{ logs: AuditLog[]; total: number }>;

  createInvoiceValidation(validation: InsertInvoiceValidation): Promise<InvoiceValidation>;
  getInvoiceValidations(invoiceId: string): Promise<any[]>;
  updateUser(id: string, data: Partial<{ username: string; role: string }>): Promise<User | undefined>;

  createHorseOwnership(ownership: InsertHorseOwnership): Promise<HorseOwnership>;
  getHorseOwnershipByHorseId(horseId: string): Promise<HorseOwnership | undefined>;
  getHorseOwnership(horseId: string): Promise<HorseOwnership[]>;
  getHorseOwnershipByCustomerId(customerId: string): Promise<HorseOwnership[]>;

  createHorseMovement(movement: InsertHorseMovement): Promise<HorseMovement>;
  updateHorseMovement(id: string, data: Partial<InsertHorseMovement>): Promise<HorseMovement | undefined>;
  getHorseMovementsByAgreementId(agreementId: string): Promise<HorseMovement[]>;
  getActiveMovementByBoxId(boxId: string): Promise<HorseMovement | undefined>;
  getHorseMovements(): Promise<HorseMovement[]>;
  getEnrichedHorseMovements(): Promise<any[]>;
  getBoxGridWithOccupants(): Promise<any[]>;
  moveHorseToBox(movementId: string, newBoxId: string): Promise<any>;
  swapHorseInBox(movementId: string, newHorseId: string): Promise<any>;
  checkAgreementsHorseAssignment(billingMonth: string, customerId?: string): Promise<any[]>;

  getMonthlyBillingApprovals(billingMonth: string, customerId?: string): Promise<any[]>;
  upsertMonthlyBillingApproval(data: { customerId: string; billingMonth: string; step: string; userId: string; approved: boolean }): Promise<MonthlyBillingApproval>;
  hasInvoiceForCustomerMonth(customerId: string, billingMonth: string): Promise<boolean>;
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
    return await db.select({ id: users.id, username: users.username, role: users.role }).from(users);
  }

  async getCustomers(search?: string): Promise<Customer[]> {
    if (search) {
      return await db.select().from(customers).where(
        ilike(customers.fullname, `%${search}%`)
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
    const allOwnership = await db.select().from(horseOwnership);

    const allMovements = await db.select().from(horseMovements);

    let result = allHorses.map(horse => {
      const activeMovement = allMovements.find(m => m.horseId === horse.id && !m.checkOut);
      const agreement = activeMovement ? allAgreements.find(a => a.id === activeMovement.agreementId) : null;
      const customer = agreement ? allCustomers.find(c => c.id === agreement.customerId) : null;
      const box = agreement ? allBoxes.find(b => b.id === agreement.boxId) : null;
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      const ownershipRecords = allOwnership.filter(o => o.horseId === horse.id);
      const ownership = ownershipRecords.length > 0
        ? ownershipRecords.sort((a, b) => (b.createdAt?.getTime() || 0) - (a.createdAt?.getTime() || 0))[0]
        : null;
      const owner = ownership ? allCustomers.find(c => c.id === ownership.customerId) : null;
      return {
        ...horse,
        rawHorseName: horse.horseName,
        horseName: formatHorseName(horse),
        customer: customer ? customer.fullname : null,
        customerId: customer?.id || null,
        box: box?.name || null,
        boxId: box?.id || null,
        stable: stable?.name || null,
        stableId: stable?.id || null,
        ownerName: owner ? owner.fullname : null,
        ownerId: ownership?.customerId || null,
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

  async createHorseWithOwner(horse: InsertHorse, ownerId: string): Promise<Horse> {
    return await db.transaction(async (tx) => {
      const [created] = await tx.insert(horses).values(horse).returning();
      await tx.insert(horseOwnership).values({ horseId: created.id, customerId: ownerId });
      return created;
    });
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
    const allMovements = await db.select().from(horseMovements);

    return allAgreements.map(agreement => {
      const activeMovement = allMovements.find(m => m.agreementId === agreement.id && !m.checkOut);
      const horse = activeMovement ? allHorses.find(h => h.id === activeMovement.horseId) : null;
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      const box = allBoxes.find(b => b.id === agreement.boxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      const item = allItems.find(i => i.id === agreement.itemId);
      return {
        ...agreement,
        horseName: horse ? formatHorseName(horse) : null,
        horseId: horse?.id || null,
        customerName: customer ? customer.fullname : "Unknown",
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
    const allMovements = await db.select().from(horseMovements);
    const allHorses = await db.select().from(horses);
    const allCustomers = await db.select().from(customers);
    const today = new Date().toISOString().split("T")[0];

    return allBoxes.map(box => {
      const stable = allStables.find(s => s.id === box.stableId);
      const agreement = activeAgreements.find(a => a.boxId === box.id && (!a.endDate || a.endDate >= today));
      const activeMovement = allMovements.find(m => m.stableboxId === box.id && !m.checkOut);
      const horse = activeMovement ? allHorses.find(h => h.id === activeMovement.horseId) : null;
      const customer = agreement ? allCustomers.find(c => c.id === agreement.customerId) : null;
      return {
        ...box,
        stableName: stable?.name || "Unknown",
        isAvailable: !agreement,
        agreementId: agreement?.id || null,
        horseName: horse ? formatHorseName(horse) : null,
        customerName: customer?.fullname || null,
      };
    });
  }

  async getAvailableHorses(): Promise<any[]> {
    const allHorses = await db.select().from(horses).where(eq(horses.status, "active"));
    const activeMovements = await db.select().from(horseMovements).where(sql`${horseMovements.checkOut} IS NULL`);
    const checkedInHorseIds = new Set(activeMovements.map(m => m.horseId));
    return allHorses.filter(h => !checkedInHorseIds.has(h.id));
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
    const allUsers = await db.select().from(users);

    return query.map(element => {
      const horse = element.horseId ? allHorses.find(h => h.id === element.horseId) : null;
      const customer = allCustomers.find(c => c.id === element.customerId);
      const box = allBoxes.find(b => b.id === element.boxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      const item = allItems.find(i => i.id === element.itemId);
      const creator = element.userId ? allUsers.find(u => u.id === element.userId) : null;
      return {
        ...element,
        horseName: horse ? formatHorseName(horse) : null,
        customerName: customer ? customer.fullname : "Unknown",
        boxName: box?.name || "Unknown",
        stableName: stable?.name || "Unknown",
        itemName: item?.name || "Unknown",
        createdByUsername: creator?.username || null,
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

  async updateBillingElement(id: string, data: Partial<InsertBillingElement>): Promise<BillingElement | undefined> {
    const [updated] = await db.update(billingElements).set(data).where(eq(billingElements.id, id)).returning();
    return updated;
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
    const allMovements = await db.select().from(horseMovements);

    return activeAgreements.map(agreement => {
      const activeMovement = allMovements.find(m => m.agreementId === agreement.id && !m.checkOut);
      const horse = activeMovement ? allHorses.find(h => h.id === activeMovement.horseId) : null;
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      const box = allBoxes.find(b => b.id === agreement.boxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      return {
        horseId: horse?.id || null,
        horseName: horse ? formatHorseName(horse) : "Unknown",
        customerId: customer?.id,
        customerName: customer ? customer.fullname : "Unknown",
        boxId: box?.id,
        boxName: box?.name || "Unknown",
        stableId: stable?.id,
        stableName: stable?.name || "Unknown",
        agreementId: agreement.id,
      };
    });
  }

  async getHorsesWithOwners(): Promise<any[]> {
    const allHorses = await db.select().from(horses).where(eq(horses.status, "active"));
    const allOwnership = await db.select().from(horseOwnership);
    const allCustomers = await db.select().from(customers);
    const allMovements = await db.select().from(horseMovements);
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);

    return allHorses.map(horse => {
      const ownershipRecords = allOwnership.filter(o => o.horseId === horse.id);
      const ownership = ownershipRecords.length > 0
        ? ownershipRecords.sort((a, b) => (b.createdAt?.getTime() || 0) - (a.createdAt?.getTime() || 0))[0]
        : null;
      const owner = ownership ? allCustomers.find(c => c.id === ownership.customerId) : null;
      const activeMovement = allMovements.find(m => m.horseId === horse.id && !m.checkOut);
      const box = activeMovement ? allBoxes.find(b => b.id === activeMovement.stableboxId) : null;
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      return {
        horseId: horse.id,
        horseName: formatHorseName(horse),
        ownerId: owner?.id || null,
        ownerName: owner?.fullname || "—",
        boxId: box?.id || null,
        boxName: box?.name || null,
        stableName: stable?.name || null,
      };
    });
  }

  async getInvoices(): Promise<any[]> {
    const allInvoices = await db.select().from(invoices).orderBy(desc(invoices.invoiceDate));
    const allCustomers = await db.select().from(customers);
    const counts = await db
      .select({ invoiceId: billingElements.invoiceId, count: sql<number>`count(*)::int` })
      .from(billingElements)
      .where(sql`${billingElements.invoiceId} IS NOT NULL`)
      .groupBy(billingElements.invoiceId);
    const countMap = new Map(counts.map(c => [c.invoiceId, Number(c.count)]));

    return allInvoices.map(invoice => {
      const customer = allCustomers.find(c => c.id === invoice.customerId);
      return {
        ...invoice,
        customerName: customer ? customer.fullname : "Unknown",
        lineItemCount: countMap.get(invoice.id) || 0,
      };
    });
  }

  async getInvoiceLineItemCount(invoiceId: string): Promise<number> {
    const [row] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(billingElements)
      .where(eq(billingElements.invoiceId, invoiceId));
    return Number(row?.count || 0);
  }

  async createInvoiceWithLineItems(
    invoiceData: InsertInvoice,
    liveryItems: InsertBillingElement[],
    adhocBillingElementIds: string[],
  ): Promise<Invoice> {
    return await db.transaction(async (tx) => {
      const [invoice] = await tx.insert(invoices).values(invoiceData).returning();

      for (const li of liveryItems) {
        await tx.insert(billingElements).values({ ...li, invoiceId: invoice.id, billed: true });
      }

      if (adhocBillingElementIds.length > 0) {
        for (const id of adhocBillingElementIds) {
          const result = await tx.update(billingElements)
            .set({ billed: true, invoiceId: invoice.id })
            .where(and(
              eq(billingElements.id, id),
              eq(billingElements.customerId, invoiceData.customerId),
              sql`${billingElements.invoiceId} IS NULL`,
            ))
            .returning({ id: billingElements.id });
          if (result.length === 0) {
            throw new Error(`Billing element ${id} could not be linked (not found, already invoiced, or wrong customer) — invoice rolled back`);
          }
        }
      }

      const [{ count }] = await tx
        .select({ count: sql<number>`count(*)::int` })
        .from(billingElements)
        .where(eq(billingElements.invoiceId, invoice.id));
      if (Number(count) === 0) {
        throw new Error("Invoice would be created with no line items — rolled back");
      }

      return invoice;
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
      const horse = el.horseId ? allHorses.find(h => h.id === el.horseId) : null;
      const item = allItems.find(i => i.id === el.itemId);
      return {
        description: item?.name || "Unknown",
        horseName: horse ? formatHorseName(horse) : "—",
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
      customerName: customer ? customer.fullname : "Unknown",
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
      const horse = el.horseId ? allHorses.find(h => h.id === el.horseId) : null;
      const item = allItems.find(i => i.id === el.itemId);
      const box = allBoxes.find(b => b.id === el.boxId);
      return {
        itemId: item?.netsuiteId || "",
        horseId: el.horseId,
        horse: horse ? String(horse.netsuiteId || "") : "",
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

  async unbillByInvoiceId(invoiceId: string): Promise<void> {
    await db.update(billingElements)
      .set({ billed: false, invoiceId: null })
      .where(eq(billingElements.invoiceId, invoiceId));
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

  async getReportKpis(month: string): Promise<any> {
    const allAgreements = await db.select().from(liveryAgreements);
    const allBillingElements = await db.select().from(billingElements);
    const allItems = await db.select().from(items);

    const [year, mon] = month.split("-").map(Number);
    const monthEnd = new Date(year, mon, 0);
    const monthEndStr = monthEnd.toISOString().split("T")[0];
    const monthStartStr = `${month}-01`;

    const allCustomers = await db.select().from(customers);
    const excludedCustomerIds = new Set(allCustomers.filter(c => isExcludedReportCustomer(c.fullname)).map(c => c.id));

    const activeAtEnd = allAgreements.filter(a => {
      if (excludedCustomerIds.has(a.customerId)) return false;
      if (a.status !== "active") return false;
      if (!a.startDate || a.startDate > monthEndStr) return false;
      if (a.endDate && a.endDate < monthStartStr) return false;
      return true;
    });

    const allMovements = await db.select().from(horseMovements);
    const activeAtEndIds = new Set(activeAtEnd.map(a => a.id));
    const uniqueHorseIds = new Set(
      allMovements
        .filter(m => m.agreementId && activeAtEndIds.has(m.agreementId) && !m.checkOut)
        .map(m => m.horseId)
    );
    const uniqueCustomerIds = new Set(activeAtEnd.map(a => a.customerId));

    const monthBillingElements = allBillingElements.filter(el => {
      if (excludedCustomerIds.has(el.customerId)) return false;
      return el.billingMonth === month || el.transactionDate?.substring(0, 7) === month;
    });

    let liveryRevenue = 0;
    let adhocRevenue = 0;

    for (const el of monthBillingElements) {
      const item = allItems.find(i => i.id === el.itemId);
      const amount = parseFloat(el.price || "0");
      if (el.agreementId && item?.isLiveryPackage) {
        liveryRevenue += amount;
      } else {
        adhocRevenue += amount;
      }
    }

    const totalRevenue = liveryRevenue + adhocRevenue;

    return {
      totalRevenue,
      liveryRevenue,
      adhocRevenue,
      liveryHorses: uniqueHorseIds.size,
      liveryCustomers: uniqueCustomerIds.size,
    };
  }

  async getAllCustomersReport(): Promise<any[]> {
    const activeAgreements = await db.select().from(liveryAgreements).where(eq(liveryAgreements.status, "active"));
    const today = new Date().toISOString().split("T")[0];
    const current = activeAgreements.filter(a => !a.endDate || a.endDate >= today);

    const allCustomers = await db.select().from(customers);
    const allHorses = await db.select().from(horses);
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);
    const allMovements = await db.select().from(horseMovements);

    const result: any[] = [];
    for (const agreement of current) {
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      if (isExcludedReportCustomer(customer?.fullname)) continue;
      const box = allBoxes.find(b => b.id === agreement.boxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      const boxName = stable && box ? `${stable.name} - ${box.name}` : box?.name || "-";
      const activeMovement = allMovements.find(m => m.agreementId === agreement.id && !m.checkOut);
      const horse = activeMovement ? allHorses.find(h => h.id === activeMovement.horseId) : null;
      const monthlyAmount = agreement.monthlyAmount ? `AED ${parseFloat(agreement.monthlyAmount).toLocaleString()}` : "-";

      result.push({
        customerName: customer ? customer.fullname : "Unknown",
        boxName,
        horseName: horse ? formatHorseName(horse) : "-",
        arrivalDate: agreement.startDate || "",
        departureDate: agreement.endDate || "",
        monthlyAmount,
      });
    }
    return result;
  }

  async getReportData(groupBy: string, month?: string): Promise<any[]> {
    const allBillingElements = await db.select().from(billingElements);
    const allCustomers = await db.select().from(customers);
    const allItems = await db.select().from(items);

    let filtered = allBillingElements;
    if (month && groupBy === "customer") {
      filtered = allBillingElements.filter(el => el.billingMonth === month || el.transactionDate?.substring(0, 7) === month);
    }

    const grouped: Record<string, any> = {};

    for (const el of filtered) {
      const item = allItems.find(i => i.id === el.itemId);
      const amount = parseFloat(el.price || "0");
      const isLivery = !!(el.agreementId && item?.isLiveryPackage);

      let key: string;
      if (groupBy === "customer") {
        const customer = allCustomers.find(c => c.id === el.customerId);
        if (isExcludedReportCustomer(customer?.fullname)) continue;
        key = customer ? customer.fullname : "Unknown";
      } else {
        key = el.billingMonth || el.transactionDate?.substring(0, 7) || "Unknown";
      }

      if (!grouped[key]) {
        grouped[key] = { label: key, liveryRevenue: 0, adhocRevenue: 0, totalRevenue: 0 };
      }
      if (isLivery) {
        grouped[key].liveryRevenue += amount;
      } else {
        grouped[key].adhocRevenue += amount;
      }
      grouped[key].totalRevenue += amount;
    }

    const result = Object.values(grouped);
    if (groupBy === "customer") {
      result.sort((a, b) => b.totalRevenue - a.totalRevenue);
    } else {
      result.sort((a, b) => a.label.localeCompare(b.label));
    }
    return result;
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
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);
    const allMovements = await db.select().from(horseMovements);

    const filtered = allAgreements.filter(a => a.startDate?.substring(0, 7) === month);

    const result: any[] = [];
    for (const agreement of filtered) {
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      if (isExcludedReportCustomer(customer?.fullname)) continue;
      const box = allBoxes.find(b => b.id === agreement.boxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      const boxName = stable && box ? `${stable.name} - ${box.name}` : box?.name || "-";
      const activeMovement = allMovements.find(m => m.agreementId === agreement.id && !m.checkOut);
      const horse = activeMovement ? allHorses.find(h => h.id === activeMovement.horseId) : null;
      const monthlyAmount = agreement.monthlyAmount ? `AED ${parseFloat(agreement.monthlyAmount).toLocaleString()}` : "-";

      result.push({
        customerName: customer ? customer.fullname : "Unknown",
        boxName,
        horseName: horse ? formatHorseName(horse) : "-",
        arrivalDate: agreement.startDate || "",
        departureDate: agreement.endDate || "",
        monthlyAmount,
      });
    }

    return result;
  }

  async getDepartedLiveryHorses(month: string): Promise<any[]> {
    const allAgreements = await db.select().from(liveryAgreements);
    const allCustomers = await db.select().from(customers);
    const allHorses = await db.select().from(horses);
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);
    const allMovements = await db.select().from(horseMovements);

    const filtered = allAgreements.filter(a => a.endDate && a.endDate.substring(0, 7) === month);

    const result: any[] = [];
    for (const agreement of filtered) {
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      if (isExcludedReportCustomer(customer?.fullname)) continue;
      const box = allBoxes.find(b => b.id === agreement.boxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      const boxName = stable && box ? `${stable.name} - ${box.name}` : box?.name || "-";
      const movements = allMovements.filter(m => m.agreementId === agreement.id);
      const lastMovement = movements.sort((a, b) => (b.checkIn || "").localeCompare(a.checkIn || ""))[0];
      const horse = lastMovement ? allHorses.find(h => h.id === lastMovement.horseId) : null;
      const monthlyAmount = agreement.monthlyAmount ? `AED ${parseFloat(agreement.monthlyAmount).toLocaleString()}` : "-";

      result.push({
        customerName: customer ? customer.fullname : "Unknown",
        boxName,
        horseName: horse ? formatHorseName(horse) : "-",
        arrivalDate: agreement.startDate || "",
        departureDate: agreement.endDate,
        monthlyAmount,
      });
    }

    return result;
  }

  async getLiveryCustomersInfo(): Promise<any[]> {
    const activeAgreements = await db.select().from(liveryAgreements).where(eq(liveryAgreements.status, "active"));
    const today = new Date().toISOString().split("T")[0];
    const current = activeAgreements.filter(a => !a.endDate || a.endDate >= today);

    const allCustomers = await db.select().from(customers);
    const allHorses = await db.select().from(horses);
    const allMovements = await db.select().from(horseMovements);

    const grouped: Record<string, any> = {};
    for (const agreement of current) {
      const customer = allCustomers.find(c => c.id === agreement.customerId);
      if (isExcludedReportCustomer(customer?.fullname)) continue;
      const activeMovement = allMovements.find(m => m.agreementId === agreement.id && !m.checkOut);
      const horse = activeMovement ? allHorses.find(h => h.id === activeMovement.horseId) : null;
      const customerName = customer ? customer.fullname : "Unknown";

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
        horseName: horse ? formatHorseName(horse) : "Unknown",
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

  async createInvoiceValidation(validation: InsertInvoiceValidation): Promise<InvoiceValidation> {
    const [created] = await db.insert(invoiceValidations).values(validation).returning();
    return created;
  }

  async getInvoiceValidations(invoiceId: string): Promise<any[]> {
    const validations = await db.select().from(invoiceValidations)
      .where(eq(invoiceValidations.invoiceId, invoiceId))
      .orderBy(desc(invoiceValidations.createdAt));
    const allUsers = await db.select({ id: users.id, username: users.username }).from(users);
    return validations.map(v => {
      const user = allUsers.find(u => u.id === v.userId);
      return { ...v, username: user?.username || "Unknown" };
    });
  }

  async updateUser(id: string, data: Partial<{ username: string; role: string }>): Promise<User | undefined> {
    const [updated] = await db.update(users).set(data).where(eq(users.id, id)).returning();
    return updated;
  }

  async createHorseOwnership(ownership: InsertHorseOwnership): Promise<HorseOwnership> {
    const [created] = await db.insert(horseOwnership).values(ownership).returning();
    return created;
  }

  async getHorseOwnershipByHorseId(horseId: string): Promise<HorseOwnership | undefined> {
    const [ownership] = await db.select().from(horseOwnership).where(eq(horseOwnership.horseId, horseId));
    return ownership;
  }

  async getHorseOwnership(horseId: string): Promise<HorseOwnership[]> {
    return await db.select().from(horseOwnership).where(eq(horseOwnership.horseId, horseId));
  }

  async getHorseOwnershipByCustomerId(customerId: string): Promise<HorseOwnership[]> {
    return await db.select().from(horseOwnership).where(eq(horseOwnership.customerId, customerId));
  }

  async createHorseMovement(movement: InsertHorseMovement): Promise<HorseMovement> {
    const [created] = await db.insert(horseMovements).values(movement).returning();
    return created;
  }

  async updateHorseMovement(id: string, data: Partial<InsertHorseMovement>): Promise<HorseMovement | undefined> {
    const [updated] = await db.update(horseMovements).set(data).where(eq(horseMovements.id, id)).returning();
    return updated;
  }

  async getHorseMovementsByAgreementId(agreementId: string): Promise<HorseMovement[]> {
    return await db.select().from(horseMovements).where(eq(horseMovements.agreementId, agreementId));
  }

  async getActiveMovementByBoxId(boxId: string): Promise<HorseMovement | undefined> {
    const [movement] = await db.select().from(horseMovements)
      .where(and(eq(horseMovements.stableboxId, boxId), sql`${horseMovements.checkOut} IS NULL`));
    return movement;
  }

  async getHorseMovements(): Promise<HorseMovement[]> {
    return await db.select().from(horseMovements).orderBy(desc(horseMovements.createdAt));
  }

  async getEnrichedHorseMovements(): Promise<any[]> {
    const allMovements = await db.select().from(horseMovements).orderBy(desc(horseMovements.createdAt));
    const allHorses = await db.select().from(horses);
    const allCustomers = await db.select().from(customers);
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);
    const allAgreements = await db.select().from(liveryAgreements);

    return allMovements.map(m => {
      const horse = allHorses.find(h => h.id === m.horseId);
      const box = allBoxes.find(b => b.id === m.stableboxId);
      const stable = box ? allStables.find(s => s.id === box.stableId) : null;
      const agreement = m.agreementId ? allAgreements.find(a => a.id === m.agreementId) : null;
      const customer = agreement ? allCustomers.find(c => c.id === agreement.customerId) : null;
      return {
        ...m,
        horseName: horse ? formatHorseName(horse) : "Unknown",
        customerName: customer?.fullname || "Unknown",
        boxName: box?.name || "Unknown",
        stableName: stable?.name || "Unknown",
      };
    });
  }

  async moveHorseToBox(movementId: string, newBoxId: string): Promise<any> {
    return await db.transaction(async (tx) => {
      const [currentMovement] = await tx.select().from(horseMovements).where(eq(horseMovements.id, movementId));
      if (!currentMovement || currentMovement.checkOut) {
        throw { status: 400, message: "No active movement found with that ID" };
      }
      const [existingOccupant] = await tx.select().from(horseMovements)
        .where(and(eq(horseMovements.stableboxId, newBoxId), sql`${horseMovements.checkOut} IS NULL`));
      if (existingOccupant) {
        throw { status: 400, message: "Target box already has a horse checked in" };
      }
      const [targetBox] = await tx.select().from(boxes).where(eq(boxes.id, newBoxId));
      if (!targetBox) {
        throw { status: 400, message: "Target box does not exist" };
      }
      const today = new Date().toISOString().split("T")[0];
      const existingAgreements = await tx.select().from(liveryAgreements)
        .where(and(eq(liveryAgreements.boxId, newBoxId), eq(liveryAgreements.status, "active")));
      const activeAgreementOnTarget = existingAgreements.find(a => !a.endDate || a.endDate >= today);
      if (activeAgreementOnTarget) {
        const sourceAgreement = currentMovement.agreementId
          ? (await tx.select().from(liveryAgreements).where(eq(liveryAgreements.id, currentMovement.agreementId)))[0]
          : null;
        if (!sourceAgreement || sourceAgreement.customerId !== activeAgreementOnTarget.customerId) {
          throw { status: 400, message: "Target box has an active agreement for a different customer" };
        }
      }
      await tx.update(horseMovements).set({ checkOut: today }).where(eq(horseMovements.id, movementId));
      const targetAgreementId = activeAgreementOnTarget ? activeAgreementOnTarget.id : currentMovement.agreementId;
      const [newMovement] = await tx.insert(horseMovements).values({
        agreementId: targetAgreementId,
        horseId: currentMovement.horseId,
        stableboxId: newBoxId,
        checkIn: today,
      }).returning();
      if (currentMovement.agreementId && !activeAgreementOnTarget) {
        await tx.update(liveryAgreements).set({ boxId: newBoxId }).where(eq(liveryAgreements.id, currentMovement.agreementId));
      }
      return newMovement;
    });
  }

  async swapHorseInBox(movementId: string, newHorseId: string): Promise<any> {
    return await db.transaction(async (tx) => {
      const [currentMovement] = await tx.select().from(horseMovements).where(eq(horseMovements.id, movementId));
      if (!currentMovement || currentMovement.checkOut) {
        throw { status: 400, message: "No active movement found with that ID" };
      }
      const [newHorse] = await tx.select().from(horses).where(eq(horses.id, newHorseId));
      if (!newHorse) {
        throw { status: 400, message: "Horse not found" };
      }
      if (currentMovement.agreementId) {
        const [agreement] = await tx.select().from(liveryAgreements).where(eq(liveryAgreements.id, currentMovement.agreementId));
        if (agreement) {
          const [ownership] = await tx.select().from(horseOwnership).where(eq(horseOwnership.horseId, newHorseId));
          if (!ownership || ownership.customerId !== agreement.customerId) {
            throw { status: 400, message: "Replacement horse must belong to the same customer as the agreement" };
          }
        }
      }
      const [existingActiveMovement] = await tx.select().from(horseMovements)
        .where(and(eq(horseMovements.horseId, newHorseId), sql`${horseMovements.checkOut} IS NULL`));
      if (existingActiveMovement) {
        throw { status: 400, message: "This horse is already checked in to another box" };
      }
      const today = new Date().toISOString().split("T")[0];
      await tx.update(horseMovements).set({ checkOut: today }).where(eq(horseMovements.id, movementId));
      const [newMovement] = await tx.insert(horseMovements).values({
        agreementId: currentMovement.agreementId,
        horseId: newHorseId,
        stableboxId: currentMovement.stableboxId,
        checkIn: today,
      }).returning();
      return newMovement;
    });
  }

  async getBoxGridWithOccupants(): Promise<any[]> {
    const allBoxes = await db.select().from(boxes);
    const allStables = await db.select().from(stables);
    const allMovements = await db.select().from(horseMovements);
    const allHorses = await db.select().from(horses);
    const allCustomers = await db.select().from(customers);
    const allAgreements = await db.select().from(liveryAgreements);
    const allItems = await db.select().from(items);

    const today = new Date().toISOString().split("T")[0];
    return allBoxes.map(box => {
      const stable = allStables.find(s => s.id === box.stableId);
      const activeMovement = allMovements.find(m => m.stableboxId === box.id && !m.checkOut);
      const horse = activeMovement ? allHorses.find(h => h.id === activeMovement.horseId) : null;
      let agreement = activeMovement?.agreementId ? allAgreements.find(a => a.id === activeMovement.agreementId) : null;
      if (!agreement) {
        agreement = allAgreements.find(a => a.boxId === box.id && a.status === "active" && (!a.endDate || a.endDate >= today)) || null;
      }
      const customer = agreement ? allCustomers.find(c => c.id === agreement.customerId) : null;
      const item = agreement ? allItems.find(i => i.id === agreement.itemId) : null;
      return {
        ...box,
        stableName: stable?.name || "Unknown",
        isOccupied: !!activeMovement,
        hasAgreement: !!agreement,
        movementId: activeMovement?.id || null,
        horseId: horse?.id || null,
        horseName: horse ? formatHorseName(horse) : null,
        customerId: customer?.id || null,
        customerName: customer?.fullname || null,
        agreementId: agreement?.id || null,
        itemName: item?.name || null,
        monthlyAmount: agreement?.monthlyAmount || null,
        checkIn: activeMovement?.checkIn || null,
      };
    });
  }

  async checkAgreementsHorseAssignment(billingMonth: string, customerId?: string): Promise<any[]> {
    const [bmYear, bmMonth] = billingMonth.split("-").map(Number);
    const periodStart = `${bmYear}-${String(bmMonth).padStart(2, "0")}-01`;
    const daysInMonth = new Date(bmYear, bmMonth, 0).getDate();
    const periodEnd = `${bmYear}-${String(bmMonth).padStart(2, "0")}-${String(daysInMonth).padStart(2, "0")}`;

    const allAgreements = customerId
      ? await db.select().from(liveryAgreements).where(eq(liveryAgreements.customerId, customerId))
      : await db.select().from(liveryAgreements);
    const activeAgreements = allAgreements.filter(a => {
      if (a.status !== "active" && a.status !== "ended") return false;
      if (a.startDate && a.startDate > periodEnd) return false;
      if (a.endDate && a.endDate < periodStart) return false;
      return true;
    });

    const allMovements = await db.select().from(horseMovements);
    const allCustomers = await db.select().from(customers);
    const allBoxes = await db.select().from(boxes);
    const allItems = await db.select().from(items);

    const unassigned: any[] = [];
    for (const agreement of activeAgreements) {
      const hasOverlapping = allMovements.some(m => {
        if (m.agreementId !== agreement.id) return false;
        if (m.checkIn > periodEnd) return false;
        if (m.checkOut && m.checkOut < periodStart) return false;
        return true;
      });
      if (!hasOverlapping) {
        const customer = allCustomers.find(c => c.id === agreement.customerId);
        const box = allBoxes.find(b => b.id === agreement.boxId);
        const item = allItems.find(i => i.id === agreement.itemId);
        unassigned.push({
          agreementId: agreement.id,
          referenceNumber: agreement.referenceNumber,
          customerName: customer?.fullname || "Unknown",
          boxName: box?.name || "Unknown",
          itemName: item?.name || "Unknown",
        });
      }
    }
    return unassigned;
  }

  async getMonthlyBillingApprovals(billingMonth: string, customerId?: string): Promise<any[]> {
    const conditions = [eq(monthlyBillingApprovals.billingMonth, billingMonth)];
    if (customerId) {
      conditions.push(eq(monthlyBillingApprovals.customerId, customerId));
    }
    const approvals = await db.select().from(monthlyBillingApprovals).where(and(...conditions));
    const allUsers = await db.select().from(users);
    return approvals.map(a => {
      const user = allUsers.find(u => u.id === a.userId);
      return { ...a, username: user?.username || "Unknown" };
    });
  }

  async upsertMonthlyBillingApproval(data: { customerId: string; billingMonth: string; step: string; userId: string; approved: boolean }): Promise<MonthlyBillingApproval> {
    const result = await db.execute(sql`
      INSERT INTO monthly_billing_approvals (customer_id, billing_month, step, user_id, approved)
      VALUES (${data.customerId}, ${data.billingMonth}, ${data.step}, ${data.userId}, ${data.approved})
      ON CONFLICT (customer_id, billing_month, step)
      DO UPDATE SET approved = ${data.approved}, user_id = ${data.userId}, updated_at = NOW()
      RETURNING *
    `);
    const rows = (result as any).rows || result;
    return Array.isArray(rows) ? rows[0] : rows;
  }

  async hasInvoiceForCustomerMonth(customerId: string, billingMonth: string): Promise<boolean> {
    const result = await db.select({ id: invoices.id }).from(invoices).where(
      and(eq(invoices.customerId, customerId), eq(invoices.billingMonth, billingMonth))
    );
    return result.length > 0;
  }
}

export const storage = new DatabaseStorage();
