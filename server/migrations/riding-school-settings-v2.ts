import pg from "pg";

// Reworks three parts of the Riding School settings model:
//  1. lesson_templates: single rider_level_id -> a [min, max] rider-level
//     range (min_rider_level_id / max_rider_level_id).
//  2. rs_riding_packages: drops the free-text lesson_template_category
//     (never actually matched against anything at redemption time) in favor
//     of a proper rs_package_templates join table.
//  3. rs_cancellation_policy: drops credit_percent — the policy is now a
//     single row + binary rule (full refund before the notice window,
//     nothing after), not a tiered percentage table.
// Own advisory lock id, separate from migrate.ts (20260410),
// riding-school.ts (20260701), and multi-role.ts (20260702).
export async function runRidingSchoolSettingsV2Migration() {
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();

  try {
    await client.query("SELECT pg_advisory_lock(20260703)");

    // --- lesson_templates: rider_level_id -> min/max range ---
    const hasOldLevelCol = (await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'lesson_templates' AND column_name = 'rider_level_id'
    `)).rows.length > 0;

    if (hasOldLevelCol) {
      console.log("RidingSchoolSettingsV2Migration: migrating lesson_templates.rider_level_id to min/max range...");
      await client.query(`ALTER TABLE lesson_templates ADD COLUMN IF NOT EXISTS min_rider_level_id UUID REFERENCES rider_levels(id)`);
      await client.query(`ALTER TABLE lesson_templates ADD COLUMN IF NOT EXISTS max_rider_level_id UUID REFERENCES rider_levels(id)`);
      // A template that previously required an exact level now requires
      // exactly that level as both bounds — same effective behavior.
      await client.query(`UPDATE lesson_templates SET min_rider_level_id = rider_level_id, max_rider_level_id = rider_level_id WHERE rider_level_id IS NOT NULL`);
      await client.query(`ALTER TABLE lesson_templates DROP COLUMN rider_level_id`);
    }

    // --- rs_riding_packages / rs_package_templates ---
    await client.query(`
      CREATE TABLE IF NOT EXISTS rs_package_templates (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        package_id UUID NOT NULL REFERENCES rs_riding_packages(id),
        template_id UUID NOT NULL REFERENCES lesson_templates(id),
        CONSTRAINT rs_package_templates_package_template_unique UNIQUE (package_id, template_id)
      )
    `);

    const hasOldCategoryCol = (await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'rs_riding_packages' AND column_name = 'lesson_template_category'
    `)).rows.length > 0;

    if (hasOldCategoryCol) {
      console.log("RidingSchoolSettingsV2Migration: backfilling rs_package_templates from lesson_template_category...");
      // Best-effort: the old field was freeform text, only ever useful when
      // it happened to match a template's name exactly.
      await client.query(`
        INSERT INTO rs_package_templates (package_id, template_id)
        SELECT p.id, t.id FROM rs_riding_packages p
        JOIN lesson_templates t ON t.name = p.lesson_template_category
        ON CONFLICT (package_id, template_id) DO NOTHING
      `);
      await client.query(`ALTER TABLE rs_riding_packages DROP COLUMN lesson_template_category`);
    }

    // --- rs_cancellation_policy: tiered -> single-row binary rule ---
    const hasCreditPercentCol = (await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'rs_cancellation_policy' AND column_name = 'credit_percent'
    `)).rows.length > 0;

    if (hasCreditPercentCol) {
      console.log("RidingSchoolSettingsV2Migration: collapsing rs_cancellation_policy to a single notice-hours row...");
      // Keep the row that used to grant full (100%) credit as "the" notice
      // window; if none did, keep whichever has the highest threshold.
      await client.query(`
        DELETE FROM rs_cancellation_policy
        WHERE id NOT IN (
          SELECT id FROM rs_cancellation_policy
          ORDER BY (credit_percent = 100) DESC, threshold_hours DESC
          LIMIT 1
        )
      `);
      await client.query(`ALTER TABLE rs_cancellation_policy DROP COLUMN credit_percent`);
    }

    await client.query("SELECT pg_advisory_unlock(20260703)");
  } catch (error) {
    await client.query("SELECT pg_advisory_unlock(20260703)").catch(() => {});
    console.error("RidingSchoolSettingsV2Migration: FAILED", error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}
