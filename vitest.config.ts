import { defineConfig } from "vitest/config";
import { fileURLToPath, URL } from "node:url";

/**
 * Test config, kept separate from vite.config.ts so nothing here can affect a
 * Tauri build. The `@` alias has to be repeated because the two configs don't
 * share a resolver.
 *
 * jsdom is the environment everywhere, not just for component tests: the app is
 * a browser app, and pure modules still reach for browser globals (parseExport
 * uses DOMParser, the storage helpers touch localStorage). Running the pure
 * tests in Node would pass locally and then fail the moment a module grew a
 * browser dependency.
 */
export default defineConfig({
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  test: {
    environment: "jsdom",
    setupFiles: ["./src/test/setup.ts"],
    include: ["src/**/*.test.{ts,tsx}"],
    // Explicit imports over injected globals — one less thing tsconfig has to
    // know about, and it keeps test files reading like the rest of the source.
    globals: false,
    restoreMocks: true,
  },
});
