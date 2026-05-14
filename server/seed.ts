import { storage } from "./storage";
import { db } from "./db";
import { customers, horses, stables, boxes, items, liveryAgreements, horseOwnership, horseMovements } from "@shared/schema";

async function ensureAdminUser() {
  const existing = await storage.getUserByUsername("admin");
  if (existing) {
    return;
  }

  const adminPassword = process.env.SEED_ADMIN_PASSWORD;

  if (!adminPassword) {
    if (process.env.NODE_ENV === "production") {
      console.error(
        "SEED_ADMIN_PASSWORD is not set. Skipping admin user creation in production. " +
        "Set this environment variable to provision an initial admin account."
      );
      return;
    }
    console.warn(
      "Warning: No SEED_ADMIN_PASSWORD set. Creating admin user with default password 'admin123' " +
      "for development only. Never deploy without setting SEED_ADMIN_PASSWORD."
    );
    await storage.createUser({ username: "admin", password: "admin123", role: "ADMIN" });
  } else {
    await storage.createUser({ username: "admin", password: adminPassword, role: "ADMIN" });
  }

  console.log("Admin user created");
}

export async function seedDatabase() {
  await ensureAdminUser();

  const existingCustomers = await storage.getCustomers();
  if (existingCustomers.length > 0) return;

  const [stable1] = await db.insert(stables).values([
    { name: "Main Stable", status: "active" },
    { name: "North Wing", status: "active" },
    { name: "South Paddock", status: "active" },
  ]).returning();

  const allStables = await storage.getStables();

  const boxData = [];
  const boxNames = ["A1", "A2", "A3", "A4", "B1", "B2", "B3", "B4"];
  for (const stable of allStables) {
    for (const name of boxNames) {
      boxData.push({ name: `${name}`, type: "box" as const, stableId: stable.id, status: "active" });
    }
    boxData.push({ name: `Tack Room ${stable.name}`, type: "tack_room" as const, stableId: stable.id, status: "active" });
    boxData.push({ name: `Storage ${stable.name}`, type: "storage_room" as const, stableId: stable.id, status: "active" });
  }
  await db.insert(boxes).values(boxData);

  const createdCustomers = await db.insert(customers).values([
    { fullname: "Sophie Martin" },
    { fullname: "Jean-Pierre Dubois" },
    { fullname: "Claire Laurent" },
    { fullname: "Thomas Bernard" },
    { fullname: "Marie Leroy", isInactive: true },
  ]).returning();

  const createdHorses = await db.insert(horses).values([
    { horseName: "Eclipse", breed: "Thoroughbred", sex: "Mare", color: "Bay", size: "165cm", dateOfBirth: "2018-03-15", status: "active" },
    { horseName: "Thunder", breed: "Arabian", sex: "Stallion", color: "Grey", size: "158cm", dateOfBirth: "2016-07-22", status: "active" },
    { horseName: "Moonlight", breed: "Warmblood", sex: "Gelding", color: "Black", size: "172cm", dateOfBirth: "2019-11-03", status: "active" },
    { horseName: "Daisy", breed: "Shetland Pony", sex: "Mare", color: "Chestnut", size: "102cm", dateOfBirth: "2020-05-10", status: "active" },
    { horseName: "Storm", breed: "Hanoverian", sex: "Stallion", color: "Dark Bay", size: "170cm", dateOfBirth: "2017-01-28", status: "active" },
  ]).returning();

  const createdItems = await db.insert(items).values([
    { name: "Full Livery Package", unitFactor: "1", price: "1200", isLiveryPackage: true },
    { name: "Part Livery Package", unitFactor: "1", price: "750", isLiveryPackage: true },
    { name: "DIY Livery Package", unitFactor: "1", price: "450", isLiveryPackage: true },
    { name: "Farrier Service", unitFactor: "1", price: "120", isLiveryPackage: false },
    { name: "Veterinary Check", unitFactor: "1", price: "150", isLiveryPackage: false },
    { name: "Saddle Fitting", unitFactor: "1", price: "75", isLiveryPackage: false },
    { name: "Feed Supplement", unitFactor: "1", price: "45", isLiveryPackage: false },
    { name: "Arena Booking", unitFactor: "1", price: "35", isLiveryPackage: false },
  ]).returning();

  const allBoxes = await storage.getBoxes();
  const boxTypeBoxes = allBoxes.filter(b => b.type === "box");

  const createdAgreements = await db.insert(liveryAgreements).values([
    {
      referenceNumber: "LA-2025-001",
      customerId: createdCustomers[0].id,
      boxId: boxTypeBoxes[0].id,
      itemId: createdItems[0].id,
      startDate: "2025-01-15",
      type: "permanent",
      status: "active",
      monthlyAmount: "1200",
    },
    {
      referenceNumber: "LA-2025-002",
      customerId: createdCustomers[1].id,
      boxId: boxTypeBoxes[1].id,
      itemId: createdItems[1].id,
      startDate: "2025-02-01",
      type: "permanent",
      status: "active",
      monthlyAmount: "750",
    },
    {
      referenceNumber: "LA-2025-003",
      customerId: createdCustomers[2].id,
      boxId: boxTypeBoxes[2].id,
      itemId: createdItems[0].id,
      startDate: "2025-01-20",
      endDate: "2025-06-20",
      type: "temporary",
      status: "active",
      monthlyAmount: "1200",
    },
  ]).returning();

  await db.insert(horseOwnership).values([
    { horseId: createdHorses[0].id, customerId: createdCustomers[0].id },
    { horseId: createdHorses[1].id, customerId: createdCustomers[1].id },
    { horseId: createdHorses[2].id, customerId: createdCustomers[2].id },
  ]);

  await db.insert(horseMovements).values([
    { agreementId: createdAgreements[0].id, horseId: createdHorses[0].id, stableboxId: boxTypeBoxes[0].id, checkIn: "2025-01-15" },
    { agreementId: createdAgreements[1].id, horseId: createdHorses[1].id, stableboxId: boxTypeBoxes[1].id, checkIn: "2025-02-01" },
    { agreementId: createdAgreements[2].id, horseId: createdHorses[2].id, stableboxId: boxTypeBoxes[2].id, checkIn: "2025-01-20", checkOut: "2025-06-20" },
  ]);

  console.log("Database seeded successfully");
}
