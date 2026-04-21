import pg from "pg";

export async function runMigration() {
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();

  try {
    await client.query("SELECT pg_advisory_lock(20260410)");

    const approvalTableCheck = await client.query(`
      SELECT table_name FROM information_schema.tables
      WHERE table_name = 'monthly_billing_approvals'
    `);
    if (approvalTableCheck.rows.length === 0) {
      console.log("Migration: Creating monthly_billing_approvals table...");
      await client.query(`
        CREATE TABLE monthly_billing_approvals (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          customer_id UUID NOT NULL REFERENCES customers(id),
          billing_month TEXT NOT NULL,
          step TEXT NOT NULL,
          user_id UUID NOT NULL REFERENCES users(id),
          approved BOOLEAN NOT NULL DEFAULT false,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        )
      `);
      await client.query(`
        CREATE UNIQUE INDEX IF NOT EXISTS idx_monthly_billing_approvals_unique
        ON monthly_billing_approvals(customer_id, billing_month, step)
      `);
      console.log("Migration: monthly_billing_approvals table created");
    }

    await client.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_invoices_customer_billing_month
      ON invoices(customer_id, billing_month)
    `);

    const userIdColCheck = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'billing_elements' AND column_name = 'user_id'
    `);
    if (userIdColCheck.rows.length === 0) {
      console.log("Migration: Adding user_id column to billing_elements...");
      await client.query(`ALTER TABLE billing_elements ADD COLUMN user_id uuid REFERENCES users(id)`);
      console.log("Migration: user_id column added");
    }

    const beBackfill = await client.query(`
      UPDATE billing_elements be
      SET user_id = sub.user_uuid
      FROM (
        SELECT DISTINCT ON (al.entity_id)
          al.entity_id AS be_id,
          al.user_id::uuid AS user_uuid
        FROM audit_logs al
        WHERE al.entity_type = 'billing_element'
          AND al.action = 'create_billing_element'
          AND al.user_id IS NOT NULL
          AND al.user_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        ORDER BY al.entity_id, al.created_at ASC
      ) AS sub
      WHERE be.id::text = sub.be_id
        AND be.user_id IS NULL
    `);
    if ((beBackfill.rowCount ?? 0) > 0) {
      console.log(`Migration: Backfilled user_id on ${beBackfill.rowCount} billing_elements from audit_logs`);
    }

    const ssoIdColCheck = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'sso_id'
    `);
    if (ssoIdColCheck.rows.length === 0) {
      console.log("Migration: Adding sso_id column to users...");
      await client.query(`ALTER TABLE users ADD COLUMN sso_id TEXT`);
      await client.query(`
        CREATE UNIQUE INDEX IF NOT EXISTS users_sso_id_unique
        ON users(sso_id)
        WHERE sso_id IS NOT NULL
      `);
      console.log("Migration: sso_id column added to users");
    }

    const colCheck = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'livery_agreements' AND column_name = 'horse_id'
    `);

    if (colCheck.rows.length === 0) {
      console.log("Migration: horse_id column already removed — skipping migration");
      await client.query("SELECT pg_advisory_unlock(20260410)");
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

    await client.query(`ALTER TABLE livery_agreements DROP COLUMN IF EXISTS horse_id`);
    console.log("Migration: Dropped horse_id column from livery_agreements");

    await client.query("COMMIT");
    console.log("Migration: Completed successfully");

    await client.query("SELECT pg_advisory_unlock(20260410)");
  } catch (error) {
    await client.query("ROLLBACK");
    await client.query("SELECT pg_advisory_unlock(20260410)").catch(() => {});
    console.error("Migration: FAILED — rolled back all changes", error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}
