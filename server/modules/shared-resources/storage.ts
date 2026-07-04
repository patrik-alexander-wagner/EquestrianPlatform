import { db } from "../../db";
import { eq, desc } from "drizzle-orm";
import {
  arenas, instructors, riderLevels, horseWellbeingStatus,
  type InsertArena, type Arena,
  type InsertInstructor, type Instructor,
  type InsertRiderLevel, type RiderLevel,
  type InsertHorseWellbeingStatus, type HorseWellbeingStatus,
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

  // Instructors
  async getInstructors(): Promise<Instructor[]> {
    return db.select().from(instructors);
  },
  async getInstructor(id: string): Promise<Instructor | undefined> {
    const [row] = await db.select().from(instructors).where(eq(instructors.id, id));
    return row;
  },
  async createInstructor(data: InsertInstructor): Promise<Instructor> {
    const [row] = await db.insert(instructors).values(data).returning();
    return row;
  },
  async updateInstructor(id: string, data: Partial<InsertInstructor>): Promise<Instructor | undefined> {
    const [row] = await db.update(instructors).set(data).where(eq(instructors.id, id)).returning();
    return row;
  },
  async deleteInstructor(id: string): Promise<void> {
    await db.delete(instructors).where(eq(instructors.id, id));
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

  // Horse wellbeing status — append-only history; no update/delete.
  async getHorseWellbeingHistory(horseId: string): Promise<HorseWellbeingStatus[]> {
    return db.select().from(horseWellbeingStatus)
      .where(eq(horseWellbeingStatus.horseId, horseId))
      .orderBy(desc(horseWellbeingStatus.createdAt));
  },
  async addHorseWellbeingStatus(data: InsertHorseWellbeingStatus): Promise<HorseWellbeingStatus> {
    const [row] = await db.insert(horseWellbeingStatus).values(data).returning();
    return row;
  },
};
