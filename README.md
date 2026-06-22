<div align="center">

<img src="public/konsou.svg" alt="Konsou" width="80" height="80" />

# Konsou

**Offline-first anime tracker for Windows and Linux** _(Android coming soon)_.

Track what you're watching. Get notified when sequels drop.  
Your list lives on your device — optionally synced through your own Google Drive.

[![GitHub release](https://img.shields.io/github/v/release/ashenvii/Konsou?style=flat-square&color=7c3aed)](https://github.com/ashenvii/Konsou/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-lightgrey?style=flat-square)](#download)

</div>

---

## Download

Go to **[Releases](https://github.com/ashenvii/Konsou/releases/latest)** and grab the installer for your platform:

| Platform | File |
|---|---|
| **Windows** | `Konsou_x.x.x_x64-setup.exe` (recommended) or `.msi` |
| **Linux** | `Konsou_x.x.x_amd64.AppImage` (portable) or `.deb` |

> **Windows SmartScreen warning?** Click **More info → Run anyway**. This is expected for new apps that aren't code-signed yet — it's safe.

---

## Features

- **Anime list** — Track status (watching, completed, plan to watch, on hold, dropped, rewatching), episodes, score, and personal notes
- **Sequel radar** — Proactive alerts when a completed show gets a new season, movie, or OVA
- **AniList import** — Import any public AniList profile in seconds; smart merge keeps your local edits
- **Google Drive sync** — Sign in once, your list stays in sync across all your devices through your own Drive. No Konsou server ever sees your data
- **Search & discover** — Browse seasonal anime, trending titles, and top rated — powered by AniList
- **Offline-first** — Fully usable with no account and no internet connection

---

## Privacy

Konsou stores your list on your device. When sync is enabled it writes to a private `appDataFolder` in your Google Drive that only Konsou can read — no Konsou server exists. See the full [Privacy Policy](https://ashenvii.github.io/Konsou/privacy.html).

---

## Building from source

### Prerequisites

- [Node.js](https://nodejs.org/) 20+
- [Rust](https://rustup.rs/) stable
- Linux only: `libgtk-3-dev libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev`

### Setup

```bash
git clone https://github.com/ashenvii/Konsou.git
cd Konsou
npm install
```

Copy `.env.example` to `.env` and fill in your Google OAuth credentials (see `.env.example` for instructions). Leave them blank to use the app without sync.

```bash
# Browser preview — no Rust needed, uses in-memory storage shim
npm run dev

# Full desktop app
npm run tauri:dev

# Production build → src-tauri/target/release/bundle/
npm run tauri:build
```

### Android

Android builds share the same React frontend and most of the Rust backend. One-time setup:

```bash
npm run android:init   # generates src-tauri/gen/android (git-ignored)
npm run android:dev    # hot-reload on device/emulator
npm run android:build  # produces an APK
```

Requires JDK 17 and Android SDK. Pin to JDK 17 — other versions cause Gradle issues with Tauri 2.

---

## Tech stack

| Layer | Choice |
|---|---|
| Shell | Tauri 2 |
| Frontend | React 19 + TypeScript + Vite |
| State | Zustand + TanStack Query |
| Database | SQLite (`tauri-plugin-sql`, WAL mode) |
| Sync | Google Drive `appdata` scope via PKCE OAuth |
| Anime data | AniList GraphQL API |
| Icons | Phosphor Icons |
| Styling | OKLCH design tokens, plain CSS |

---

## Contributing

Issues and PRs are welcome. Please open an issue first for larger changes so we can discuss the approach.

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">
<sub>Made with care · <a href="https://ko-fi.com/ashenvii">Support on Ko-fi</a></sub>
</div>
