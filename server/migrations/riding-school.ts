import pg from "pg";

// Additive migration for the Riding School domain + shared resources + customer
// identity columns. Kept separate from server/migrate.ts (which owns the
// pre-existing livery migration history) so livery migrations are never at
// risk of being touched while this domain evolves. Uses its own advisory lock
// id to avoid any lock-reentrancy assumptions with runMigration()'s lock.
export async function runRidingSchoolMigration() {
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();

  try {
    await client.query("SELECT pg_advisory_lock(20260701)");

    // --- users: identity columns for the Riding School customer portal ---

    const accountTypeCol = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'account_type'
    `);
    if (accountTypeCol.rows.length === 0) {
      console.log("RidingSchoolMigration: Adding account_type column to users...");
      await client.query(`ALTER TABLE users ADD COLUMN account_type TEXT NOT NULL DEFAULT 'STAFF'`);
    }

    const customerIdCol = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'customer_id'
    `);
    if (customerIdCol.rows.length === 0) {
      console.log("RidingSchoolMigration: Adding customer_id column to users...");
      await client.query(`ALTER TABLE users ADD COLUMN customer_id UUID REFERENCES customers(id)`);
    }

    const linkedCustomerIdCol = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'linked_customer_id'
    `);
    if (linkedCustomerIdCol.rows.length === 0) {
      console.log("RidingSchoolMigration: Adding linked_customer_id column to users...");
      await client.query(`ALTER TABLE users ADD COLUMN linked_customer_id UUID REFERENCES customers(id)`);
    }

    // --- shared resources (no interdependencies beyond users/horses) ---

    await client.query(`
      CREATE TABLE IF NOT EXISTS arenas (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active'
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS instructors (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        user_id UUID REFERENCES users(id)
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS rider_levels (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS horse_wellbeing_status (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        horse_id UUID NOT NULL REFERENCES horses(id),
        status_tag TEXT NOT NULL,
        note TEXT,
        set_by UUID REFERENCES users(id),
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // --- riding-school identity: riders (depends on customers, rider_levels) ---

    await client.query(`
      CREATE TABLE IF NOT EXISTS riders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id UUID NOT NULL REFERENCES customers(id),
        full_name TEXT NOT NULL,
        date_of_birth DATE,
        rider_level_id UUID REFERENCES rider_levels(id),
        is_account_holder BOOLEAN NOT NULL DEFAULT false
      )
    `);

    // --- lessons, scheduling, bookings ---

    await client.query(`
      CREATE TABLE IF NOT EXISTS lesson_templates (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL,
        min_age INTEGER,
        max_age INTEGER,
        rider_level_id UUID REFERENCES rider_levels(id),
        min_riders INTEGER NOT NULL DEFAULT 1,
        max_riders INTEGER NOT NULL DEFAULT 1,
        duration_minutes INTEGER NOT NULL,
        price NUMERIC NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT true
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS rs_lesson_recurrences (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        template_id UUID NOT NULL REFERENCES lesson_templates(id),
        instructor_id UUID NOT NULL REFERENCES instructors(id),
        arena_id UUID NOT NULL REFERENCES arenas(id),
        days_of_week TEXT NOT NULL,
        start_time TEXT NOT NULL,
        until DATE NOT NULL,
        is_public BOOLEAN NOT NULL DEFAULT true
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS rs_scheduled_lessons (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        template_id UUID NOT NULL REFERENCES lesson_templates(id),
        recurrence_id UUID REFERENCES rs_lesson_recurrences(id),
        instructor_id UUID NOT NULL REFERENCES instructors(id),
        arena_id UUID NOT NULL REFERENCES arenas(id),
        start_datetime TIMESTAMPTZ NOT NULL,
        end_datetime TIMESTAMPTZ NOT NULL,
        capacity INTEGER NOT NULL,
        is_public BOOLEAN NOT NULL DEFAULT true,
        is_exception BOOLEAN NOT NULL DEFAULT false,
        status TEXT NOT NULL DEFAULT 'scheduled'
      )
    `);

    // --- packages (rs_riding_packages has no FK deps; purchases reference invoices) ---

    await client.query(`
      CREATE TABLE IF NOT EXISTS rs_riding_packages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL,
        lesson_template_category TEXT NOT NULL,
        number_of_lessons INTEGER NOT NULL,
        validity_days INTEGER NOT NULL,
        price NUMERIC NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT true
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS rs_package_purchases (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id UUID NOT NULL REFERENCES customers(id),
        package_id UUID NOT NULL REFERENCES rs_riding_packages(id),
        lessons_remaining INTEGER NOT NULL,
        valid_until DATE NOT NULL,
        invoice_id UUID REFERENCES invoices(id),
        status TEXT NOT NULL DEFAULT 'active',
        purchased_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // rs_bookings depends on rs_scheduled_lessons, riders, users, horses, rs_package_purchases
    await client.query(`
      CREATE TABLE IF NOT EXISTS rs_bookings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        scheduled_lesson_id UUID NOT NULL REFERENCES rs_scheduled_lessons(id),
        rider_id UUID NOT NULL REFERENCES riders(id),
        booked_by_user_id UUID NOT NULL REFERENCES users(id),
        horse_id UUID REFERENCES horses(id),
        status TEXT NOT NULL DEFAULT 'confirmed',
        package_purchase_id UUID REFERENCES rs_package_purchases(id),
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // --- cancellation policy + credit vouchers ---

    await client.query(`
      CREATE TABLE IF NOT EXISTS rs_cancellation_policy (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        threshold_hours INTEGER NOT NULL,
        credit_percent INTEGER NOT NULL DEFAULT 100
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS rs_credit_vouchers (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id UUID NOT NULL REFERENCES customers(id),
        lesson_template_category TEXT NOT NULL,
        source_booking_id UUID REFERENCES rs_bookings(id),
        status TEXT NOT NULL DEFAULT 'active',
        expires_at DATE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    await client.query("SELECT pg_advisory_unlock(20260701)");
  } catch (error) {
    await client.query("SELECT pg_advisory_unlock(20260701)").catch(() => {});
    console.error("RidingSchoolMigration: FAILED", error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}
