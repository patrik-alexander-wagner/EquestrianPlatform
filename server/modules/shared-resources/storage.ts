import { db } from "../../db";
import { eq } from "drizzle-orm";
import {
  arenas, instructors, riderLevels, users,
  type InsertArena, type Arena,
  type InsertInstructor, type Instructor,
  type InsertRiderLevel, type RiderLevel,
} from "@shared/schema";

// Storage for the Shared Resources domain (arenas, instructors, rider levels,
// horse wellbeing history) — used by both Livery and Riding School. Kept
// separate from server/storage.ts's IStorage/DatabaseStorage on purpose, so
// this module can evolve independently of the livery domain.
export const sharedResourcesStorage = {
  // Arenas
  async getArenas(): Promise<Arena[]> {
    return db.select().from(arenas);
  },
  async getArena(id: string): Promise<Arena | undefined> {
    const [row] = await db.select().from(arenas).where(eq(arenas.id, id));
    return row;
  },
  async createArena(data: InsertArena): Promise<Arena> {
    const [row] = await db.insert(arenas).values(data).returning();
    return row;
  },
  async updateArena(id: string, data: Partial<InsertArena>): Promise<Arena | undefined> {
    const [row] = await db.update(arenas).set(data).where(eq(arenas.id, id)).returning();
    return row;
  },
  async deleteArena(id: string): Promise<void> {
    await db.delete(arenas).where(eq(arenas.id, id));
  },

  // Instructors — instantiated by granting the INSTRUCTOR role on a user
  // (see server/storage.ts DatabaseStorage.syncInstructorForUser), never
  // created directly here.
  async getInstructors(): Promise<(Instructor & { username: string | null })[]> {
    const allInstructors = await db.select().from(instructors);
    const allUsers = await db.select({ id: users.id, username: users.username }).from(users);
    return allInstructors.map(i => ({
      ...i,
      username: allUsers.find(u => u.id === i.userId)?.username || null,
    }));
  },
  async getInstructor(id: string): Promise<Instructor | undefined> {
    const [row] = await db.select().from(instructors).where(eq(instructors.id, id));
    return row;
  },
  async updateInstructor(id: string, data: Partial<InsertInstructor>): Promise<Instructor | undefined> {
    const [row] = await db.update(instructors).set(data).where(eq(instructors.id, id)).returning();
    return row;
  },

  // Rider levels (managed from Riding School Settings)
  async getRiderLevels(): Promise<RiderLevel[]> {
    return db.select().from(riderLevels).orderBy(riderLevels.sortOrder);
  },
  async getRiderLevel(id: string): Promise<RiderLevel | undefined> {
    const [row] = await db.select().from(riderLevels).where(eq(riderLevels.id, id));
    return row;
  },
  async createRiderLevel(data: InsertRiderLevel): Promise<RiderLevel> {
    const [row] = await db.insert(riderLevels).values(data).returning();
    return row;
  },
  async updateRiderLevel(id: string, data: Partial<InsertRiderLevel>): Promise<RiderLevel | undefined> {
    const [row] = await db.update(riderLevels).set(data).where(eq(riderLevels.id, id)).returning();
    return row;
  },
  async deleteRiderLevel(id: string): Promise<void> {
    await db.delete(riderLevels).where(eq(riderLevels.id, id));
  },
};
