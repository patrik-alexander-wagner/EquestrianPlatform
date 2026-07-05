import { defineConfig } from "vitest/config";
import path from "path";

// Standalone from vite.config.ts on purpose — that config is scoped to the
// client build (root: "client", React plugins, Replit-specific plugins) and
// isn't meant to also drive server-side unit tests.
export default defineConfig({
  resolve: {
    alias: {
      "@shared": path.resolve(import.meta.dirname, "shared"),
    },
  },
  test: {
    environment: "node",
    include: ["server/**/*.test.ts", "shared/**/*.test.ts"],
  },
});
