import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import * as schema from "@shared/schema";

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL must be set");
}

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
});

// Force every connection's session timezone to UTC. Without this, the pg
// driver parses timestamptz values using the Postgres session's (or the
// underlying OS's) default timezone, which is environment-dependent — this
// surfaced as a real bug where node-postgres mis-serialized a stored UTC
// instant when the session timezone was Asia/Dubai. Timestamps are always
// meant to be UTC end-to-end (client/server both convert to/from a fixed
// club offset explicitly, see shared/timezone.ts), so the DB session must
// not silently reinterpret them via an ambient timezone.
pool.on("connect", (client) => {
  client.query("SET TIME ZONE 'UTC'").catch((err) => console.error("Failed to set session timezone to UTC:", err));
});

export const db = drizzle(pool, { schema });
