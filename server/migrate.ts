import pg from "pg";

export async function runMigration() {
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();

  try {
    const colCheck = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'livery_agreements' AND column_name = 'horse_id'
    `);

    if (colCheck.rows.length === 0) {
      console.log("Migration: horse_id column already removed — skipping migration");
      return;
    }

    console.log("Migration: Starting horse_id data migration...");

    await client.query("BEGIN");

    await client.query(`
      CREATE TABLE IF NOT EXISTS horse_ownership (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        horse_id UUID NOT NULL REFERENCES horses(id),
        customer_id UUID NOT NULL REFERENCES customers(id),
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS horse_movements (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        agreement_id UUID REFERENCES livery_agreements(id),
        horse_id UUID NOT NULL REFERENCES horses(id),
        stablebox_id UUID NOT NULL REFERENCES boxes(id),
        check_in TEXT NOT NULL,
        check_out TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    const ownershipResult = await client.query(`
      INSERT INTO horse_ownership (horse_id, customer_id)
      SELECT DISTINCT la.horse_id, la.customer_id
      FROM livery_agreements la
      WHERE la.horse_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM horse_ownership ho
          WHERE ho.horse_id = la.horse_id AND ho.customer_id = la.customer_id
        )
      RETURNING id
    `);
    console.log(`Migration: Created ${ownershipResult.rowCount} horse_ownership records`);

    const movementResult = await client.query(`
      INSERT INTO horse_movements (agreement_id, horse_id, stablebox_id, check_in)
      SELECT la.id, la.horse_id, la.box_id, la.start_date
      FROM livery_agreements la
      WHERE la.horse_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM horse_movements hm
          WHERE hm.agreement_id = la.id AND hm.horse_id = la.horse_id
        )
      RETURNING id
    `);
    console.log(`Migration: Created ${movementResult.rowCount} horse_movements records`);

    await client.query(`ALTER TABLE livery_agreements DROP COLUMN horse_id`);
    console.log("Migration: Dropped horse_id column from livery_agreements");

    await client.query("COMMIT");
    console.log("Migration: Completed successfully");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Migration: FAILED — rolled back all changes", error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}
