import { defineConfig, devices } from "@playwright/test";

// Assumes the dev server (npm run dev) is already running on port 5000 with
// a seeded database — matches how this app has been manually verified
// throughout development. A dedicated CI/test environment with its own
// webServer + database lifecycle is a Phase 2 concern (see
// PLATFORM_ROADMAP.md), not something this config tries to own yet.
export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  retries: 0,
  reporter: "list",
  use: {
    baseURL: "http://localhost:5000",
    trace: "on-first-retry",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
  ],
});
