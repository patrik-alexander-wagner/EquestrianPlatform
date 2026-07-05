import pg from "pg";

// Moves user->role from a single users.role column to a many-to-many
// user_roles join table, so a user can hold multiple roles at once (e.g.
// ADMIN + CUSTOMER, so staff can see the booking/public schedule experience
// from a member's point of view). Also retires the accountType/
// linkedCustomerId columns: "is this user a customer" is now just "does
// user_roles contain CUSTOMER for them", and customerId alone (kept on
// users) identifies which customer record they represent either way.
// Own advisory lock id, separate from migrate.ts (20260410) and
// riding-school.ts (20260701).
export async function runMultiRoleMigration() {
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();

  try {
    await client.query("SELECT pg_advisory_lock(20260702)");

    await client.query(`
      CREATE TABLE IF NOT EXISTS user_roles (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id),
        role_key TEXT NOT NULL,
        CONSTRAINT user_roles_user_role_unique UNIQUE (user_id, role_key)
      )
    `);

    // Backfill from the legacy single-role columns, only if they still exist
    // (idempotent: a second run after the columns are dropped skips straight
    // past this block).
    const roleCol = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'role'
    `);
    if (roleCol.rows.length > 0) {
      console.log("MultiRoleMigration: backfilling user_roles from legacy users.role/account_type...");

      // account_type/linked_customer_id may not exist yet on a DB that never
      // went through the Riding School (M1) migration at all — guard each
      // reference individually rather than assuming all three columns exist
      // together.
      const hasAccountType = (await client.query(`
        SELECT column_name FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'account_type'
      `)).rows.length > 0;
      const hasLinkedCustomerId = (await client.query(`
        SELECT column_name FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'linked_customer_id'
      `)).rows.length > 0;

      if (hasAccountType) {
        // Staff accounts keep their existing single role.
        await client.query(`
          INSERT INTO user_roles (user_id, role_key)
          SELECT id, role FROM users WHERE role IS NOT NULL AND account_type = 'STAFF'
          ON CONFLICT (user_id, role_key) DO NOTHING
        `);

        // Pure customer accounts get the CUSTOMER role instead of their old
        // staff-role default (that default, e.g. VIEWER, was never meant to
        // grant staff data access to a self-service portal login).
        await client.query(`
          INSERT INTO user_roles (user_id, role_key)
          SELECT id, 'CUSTOMER' FROM users WHERE account_type = 'CUSTOMER'
          ON CONFLICT (user_id, role_key) DO NOTHING
        `);

        if (hasLinkedCustomerId) {
          // Staff who are also members (linked_customer_id set) keep their
          // staff role and additionally gain the CUSTOMER role.
          await client.query(`
            INSERT INTO user_roles (user_id, role_key)
            SELECT id, 'CUSTOMER' FROM users WHERE account_type = 'STAFF' AND linked_customer_id IS NOT NULL
            ON CONFLICT (user_id, role_key) DO NOTHING
          `);

          // Consolidate into the single customerId column kept on users.
          await client.query(`
            UPDATE users SET customer_id = linked_customer_id
            WHERE customer_id IS NULL AND linked_customer_id IS NOT NULL
          `);
        }
      } else {
        // No account_type concept ever existed — every user was staff, with
        // a single role.
        await client.query(`
          INSERT INTO user_roles (user_id, role_key)
          SELECT id, role FROM users WHERE role IS NOT NULL
          ON CONFLICT (user_id, role_key) DO NOTHING
        `);
      }

      await client.query(`ALTER TABLE users DROP COLUMN role`);
      console.log("MultiRoleMigration: backfill complete");
    }

    // Drop account_type/linked_customer_id whenever found, independent of
    // whether `role` was already gone (e.g. an older riding-school.ts build
    // re-added them after this migration had already run once) — those
    // columns carry no data that isn't already reflected in user_roles by
    // that point.
    const staleAccountType = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'account_type'
    `);
    if (staleAccountType.rows.length > 0) {
      console.log("MultiRoleMigration: dropping stray account_type column...");
      await client.query(`ALTER TABLE users DROP COLUMN account_type`);
    }
    const staleLinkedCustomerId = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'linked_customer_id'
    `);
    if (staleLinkedCustomerId.rows.length > 0) {
      console.log("MultiRoleMigration: dropping stray linked_customer_id column...");
      await client.query(`ALTER TABLE users DROP COLUMN linked_customer_id`);
    }

    await client.query("SELECT pg_advisory_unlock(20260702)");
  } catch (error) {
    await client.query("SELECT pg_advisory_unlock(20260702)").catch(() => {});
    console.error("MultiRoleMigration: FAILED", error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}
