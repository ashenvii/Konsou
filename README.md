# Konsou

Offline-first anime tracker for desktop (Windows / macOS / Linux) and Android.
Sign in once with Google, your list syncs through your own Google Drive. No forced
scoring. The flagship feature is a **sequel radar** that proactively tells you when a
completed anime gets a new season, movie, or continuation.

> **Bundle identifier:** `com.konsou.app` — this is permanent. Never change it.
> Changing it orphans every existing install's data (see Trap 8 in the design docs).

## Stack

| Layer | Choice |
|---|---|
| Shell | Tauri 2 (desktop + Android from one codebase) |
| Frontend | React 19 + TypeScript + Vite 6 |
| Routing | React Router 7 (**HashRouter** — required for the `tauri://` / `file://` origin) |
| State | Zustand (UI/list) + TanStack Query (async/network) |
| Lists | TanStack Virtual (every long list is virtualized) |
| Database | SQLite via `tauri-plugin-sql` (WAL mode, versioned migrations) |
| Icons | Phosphor Icons (`regular` + `fill` only) |
| Styling | Token-driven plain CSS (OKLCH design tokens) |

### Two deliberate deviations from the original blueprint

1. **Plain CSS instead of Tailwind.** The entire design system is expressed as OKLCH
   CSS custom properties; Tailwind would only re-reference them. `src/styles/tokens.css`
   is the single source of truth and matches the *UI & Design System* doc verbatim.
2. **Typed GraphQL `fetch` client instead of urql.** Konsou's cache is the SQLite
   TTL tables (`anime_cache`, `search_cache`, `relation_snapshots`), so urql's
   normalized cache would be redundant. See `src/lib/api/anilist/`.

## Running it

```bash
npm install

# Web preview (fast iteration — uses an in-memory storage shim, AniList works via CORS)
npm run dev            # http://localhost:1420

# Real desktop app (SQLite + native HTTP) — requires the Rust toolchain
npm run tauri:dev
npm run tauri:build    # produces .msi / .dmg / .AppImage in src-tauri/target/release/bundle
```

The app is **offline-first**: it is fully usable with no account. Google sign-in and
Drive sync are optional and live behind a clean interface (`src/lib/sync/`,
`src/lib/auth/`) — currently stubbed pending OAuth client credentials.

### Storage abstraction

`src/lib/db/driver.ts` picks a backend at runtime:

- **Under Tauri** → real SQLite (`tauri-plugin-sql`, WAL, migrations).
- **In a plain browser** (`npm run dev`) → an in-memory + `localStorage` shim so the
  whole UI is demonstrable without the Rust runtime.

Both implement the same `DbDriver` interface, so feature code never branches on platform.

## Android

```bash
npm run android:init     # one-time; generates src-tauri/gen/android
npm run android:dev
npm run android:build    # outputs an APK for sideloading
```

Pin **JDK 17** and avoid Tauri **2.9.2** for Android (versionCode / back-button
regressions). See `../Konsou — Mobile Trap Solutions.md`. The Android manifest must set
`android:windowSoftInputMode="adjustResize"` after `android:init` (Trap 2).

## Design docs

The authoritative specs live one directory up, in the Obsidian vault:

- `Konsou — v1 Foundation Blueprint.md` — structure, schema, CI/CD
- `Konsou — UI & Design System.md` — tokens, components, motion
- `Konsou — Interaction Design Map.md` — every gesture and state
- `Konsou — Mobile Trap Solutions.md` — the 11 Android/desktop traps + fixes
- `Konsou — Research Dossier.md` — APIs, sync, sequel-detection algorithm
