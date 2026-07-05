import pg from "pg";

// Adds the Riding School horse roster:
//  1. horses.is_riding_school_horse — simple membership flag (which horses
//     are used for riding-school lessons). No history needed for membership
//     itself; rs_bookings.horseId already gives a historical record of when
//     a horse was actually doing lessons.
//  2. rs_horse_status — append-only mood/lesson-limit history for horses on
//     that roster (insert a new row to change status, never update/delete).
//  3. Drops horse_wellbeing_status — the old general-purpose freeform
//     wellbeing log (any horse, livery or not), now superseded by
//     rs_horse_status for Riding School horses specifically.
// Own advisory lock id, separate from migrate.ts (20260410), riding-school.ts
// (20260701), multi-role.ts (20260702), riding-school-settings-v2.ts (20260703).
export async function runRidingSchoolHorsesMigration() {
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();

  try {
    await client.query("SELECT pg_advisory_lock(20260704)");

    const hasFlagCol = (await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'horses' AND column_name = 'is_riding_school_horse'
    `)).rows.length > 0;

    if (!hasFlagCol) {
      console.log("RidingSchoolHorsesMigration: adding horses.is_riding_school_horse...");
      await client.query(`ALTER TABLE horses ADD COLUMN is_riding_school_horse BOOLEAN NOT NULL DEFAULT false`);
    }

    const hasMoodEnum = (await client.query(`SELECT 1 FROM pg_type WHERE typname = 'rs_horse_mood'`)).rows.length > 0;
    if (!hasMoodEnum) {
      console.log("RidingSchoolHorsesMigration: creating rs_horse_mood enum...");
      await client.query(`CREATE TYPE rs_horse_mood AS ENUM ('fit', 'lame', 'needs_training', 'injured')`);
    }

    await client.query(`
      CREATE TABLE IF NOT EXISTS rs_horse_status (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        horse_id UUID NOT NULL REFERENCES horses(id),
        mood rs_horse_mood NOT NULL,
        max_lessons_per_day INTEGER,
        max_lessons_per_week INTEGER,
        note TEXT,
        set_by UUID REFERENCES users(id),
        created_at TIMESTAMP DEFAULT now()
      )
    `);

    const hasWellbeingTable = (await client.query(`SELECT 1 FROM information_schema.tables WHERE table_name = 'horse_wellbeing_status'`)).rows.length > 0;
    if (hasWellbeingTable) {
      console.log("RidingSchoolHorsesMigration: dropping retired horse_wellbeing_status table...");
      await client.query(`DROP TABLE horse_wellbeing_status`);
    }

    await client.query("SELECT pg_advisory_unlock(20260704)");
  } catch (error) {
    await client.query("SELECT pg_advisory_unlock(20260704)").catch(() => {});
    console.error("RidingSchoolHorsesMigration: FAILED", error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}
