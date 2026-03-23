import { storage } from "./storage";
import { db } from "./db";
import { customers, horses, stables, boxes, items, liveryAgreements } from "@shared/schema";

async function ensureAdminUser() {
  const adminPassword = process.env.SEED_ADMIN_PASSWORD ?? "admin123";
  const existing = await storage.getUserByUsername("admin");
  if (existing) {
    await storage.updateUserPassword(existing.id, adminPassword, "ADMIN");
    console.log("Admin user password and role updated");
  } else {
    await storage.createUser({ username: "admin", password: adminPassword, role: "ADMIN" });
    console.log("Admin user created");
  }
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
    { firstname: "Sophie", lastname: "Martin", phone: "+33 6 12 34 56 78", email: "sophie.martin@email.com", status: "active" },
    { firstname: "Jean-Pierre", lastname: "Dubois", phone: "+33 6 23 45 67 89", email: "jp.dubois@email.com", status: "active" },
    { firstname: "Claire", lastname: "Laurent", phone: "+33 6 34 56 78 90", email: "claire.laurent@email.com", status: "active" },
    { firstname: "Thomas", lastname: "Bernard", phone: "+33 6 45 67 89 01", email: "t.bernard@email.com", status: "active" },
    { firstname: "Marie", lastname: "Leroy", phone: "+33 6 56 78 90 12", email: "marie.leroy@email.com", status: "inactive" },
  ]).returning();

  const createdHorses = await db.insert(horses).values([
    { horseName: "Eclipse", breed: "Thoroughbred", sex: "Mare", color: "Bay", size: "165cm", dateOfBirth: "2018-03-15", status: "active" },
    { horseName: "Thunder", breed: "Arabian", sex: "Stallion", color: "Grey", size: "158cm", dateOfBirth: "2016-07-22", status: "active" },
    { horseName: "Moonlight", breed: "Warmblood", sex: "Gelding", color: "Black", size: "172cm", dateOfBirth: "2019-11-03", status: "active" },
    { horseName: "Daisy", breed: "Shetland Pony", sex: "Mare", color: "Chestnut", size: "102cm", dateOfBirth: "2020-05-10", status: "active" },
    { horseName: "Storm", breed: "Hanoverian", sex: "Stallion", color: "Dark Bay", size: "170cm", dateOfBirth: "2017-01-28", status: "active" },
  ]).returning();

  const createdItems = await db.insert(items).values([
    { name: "Full Livery Package", unitFactor: "1", price: "1200", department: "Livery", status: "active", isLiveryPackage: true },
    { name: "Part Livery Package", unitFactor: "1", price: "750", department: "Livery", status: "active", isLiveryPackage: true },
    { name: "DIY Livery Package", unitFactor: "1", price: "450", department: "Livery", status: "active", isLiveryPackage: true },
    { name: "Farrier Service", unitFactor: "1", price: "120", department: "Services", status: "active", isLiveryPackage: false },
    { name: "Veterinary Check", unitFactor: "1", price: "150", department: "Services", status: "active", isLiveryPackage: false },
    { name: "Saddle Fitting", unitFactor: "1", price: "75", department: "Equipment", status: "active", isLiveryPackage: false },
    { name: "Feed Supplement", unitFactor: "1", price: "45", department: "Feed", status: "active", isLiveryPackage: false },
    { name: "Arena Booking", unitFactor: "1", price: "35", department: "Facilities", status: "active", isLiveryPackage: false },
  ]).returning();

  const allBoxes = await storage.getBoxes();
  const boxTypeBoxes = allBoxes.filter(b => b.type === "box");

  await db.insert(liveryAgreements).values([
    {
      referenceNumber: "LA-2025-001",
      horseId: createdHorses[0].id,
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
      horseId: createdHorses[1].id,
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
      horseId: createdHorses[2].id,
      customerId: createdCustomers[2].id,
      boxId: boxTypeBoxes[2].id,
      itemId: createdItems[0].id,
      startDate: "2025-01-20",
      endDate: "2025-06-20",
      type: "temporary",
      status: "active",
      monthlyAmount: "1200",
    },
  ]);

  console.log("Database seeded successfully");
}
