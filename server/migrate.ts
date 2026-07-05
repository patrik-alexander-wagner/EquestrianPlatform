import pg from "pg";

export async function runMigration() {
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();

  try {
    await client.query("SELECT pg_advisory_lock(20260410)");

    const itemsObsoleteCols = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'items'
        AND column_name IN ('department', 'location', 'class', 'status')
    `);
    if (itemsObsoleteCols.rows.length > 0) {
      console.log(`Migration: Dropping obsolete items columns: ${itemsObsoleteCols.rows.map(r => r.column_name).join(", ")}`);
      await client.query(`
        ALTER TABLE items
          DROP COLUMN IF EXISTS department,
          DROP COLUMN IF EXISTS location,
          DROP COLUMN IF EXISTS class,
          DROP COLUMN IF EXISTS status
      `);
      console.log("Migration: Obsolete items columns dropped");
    }

    const lastPurchasePriceCheck = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'items' AND column_name = 'last_purchase_price'
    `);
    if (lastPurchasePriceCheck.rows.length === 0) {
      console.log("Migration: Adding last_purchase_price column to items...");
      await client.query(`ALTER TABLE items ADD COLUMN last_purchase_price NUMERIC`);
      console.log("Migration: last_purchase_price column added");
    }

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

    // Multiple invoices per customer per billing month are now allowed, so the
    // old customer+month uniqueness must NOT exist. Drop it if a previous
    // migration created it.
    await client.query(`
      DROP INDEX IF EXISTS idx_invoices_customer_billing_month
    `);

    // Prevent the same livery agreement being billed twice for one month.
    await client.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS billing_elements_agreement_month_unique
      ON billing_elements(agreement_id, billing_month)
      WHERE agreement_id IS NOT NULL
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
    if (ssoIdColCheck.rows.length > 0) {
      console.log("Migration: Removing sso_id column from users (Unified Portal SSO module removed)...");
      await client.query(`DROP INDEX IF EXISTS users_sso_id_unique`);
      await client.query(`ALTER TABLE users DROP COLUMN IF EXISTS sso_id`);
      console.log("Migration: sso_id column removed from users");
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
