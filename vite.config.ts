import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath, URL } from "node:url";
import { readFileSync } from "node:fs";
import process from "node:process";

const host = process.env.TAURI_DEV_HOST;

// Single source of truth for the app version: package.json. Injected as
// __APP_VERSION__ so nothing in the app hardcodes a version string.
const pkg = JSON.parse(
  readFileSync(new URL("./package.json", import.meta.url), "utf-8"),
) as { version: string };

// And for the app's display NAME: the Tauri manifest, which is what the
// installer, the window title and the OS all use. Injected the same way so a
// rename lands everywhere at once instead of leaving "Konsou" written into a
// notification string somewhere.
const tauri = JSON.parse(
  readFileSync(new URL("./src-tauri/tauri.conf.json", import.meta.url), "utf-8"),
) as { productName?: string };

// https://vite.dev/config/, tailored for Tauri development.
export default defineConfig(() => ({
  plugins: [react()],

  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },

  // Prevent Vite from obscuring Rust errors.
  clearScreen: false,
  server: {
    // Tauri expects a fixed port and fails if it isn't available.
    port: 1420,
    strictPort: true,
    host: host || false,
    hmr: host ? { protocol: "ws", host, port: 1421 } : undefined,
    watch: {
      // Don't watch the Rust side.
      ignored: ["**/src-tauri/**"],
    },
  },

  define: {
    __APP_VERSION__: JSON.stringify(pkg.version),
    __APP_NAME__: JSON.stringify(tauri.productName ?? "Konsou"),
  },

  // Env vars with these prefixes are exposed via import.meta.env in the app.
  envPrefix: ["VITE_", "TAURI_ENV_*"],

  build: {
    // Tauri uses Chromium on Windows and WebKit on macOS/Linux.
    target: process.env.TAURI_ENV_PLATFORM === "windows" ? "chrome105" : "safari13",
    minify: process.env.TAURI_ENV_DEBUG ? false : ("esbuild" as const),
    sourcemap: !!process.env.TAURI_ENV_DEBUG,
    rollupOptions: {
      output: {
        // The framework is loaded on first paint no matter what and almost never
        // changes between releases, so it rides in its own chunk: it splits the
        // heaviest weight out of the app bundle and lets the web build reuse it
        // from cache across updates. Feature libraries (icons especially, which
        // Vite already tree-shakes per-glyph into the lazy route chunks) are left
        // to default chunking on purpose.
        manualChunks(id) {
          if (!id.includes("node_modules")) return undefined;
          if (
            id.includes("/react-router") ||
            id.includes("/react-dom/") ||
            id.includes("/react/") ||
            id.includes("/scheduler/") ||
            id.includes("/@tanstack/") ||
            id.includes("/zustand/")
          ) {
            return "vendor";
          }
          return undefined;
        },
      },
    },
  },
}));
