<div align="center">

<img src="public/konsou.svg" alt="Konsou" width="80" height="80" />

# Konsou

**Anime tracker for Windows and Linux.**

Your list lives on your device, syncs through your own Google Drive, and checks for sequel announcements on completed shows.

[![GitHub release](https://img.shields.io/github/v/release/ashenvii/Konsou?style=flat-square&color=7c3aed)](https://github.com/ashenvii/Konsou/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-lightgrey?style=flat-square)](#download)

</div>

---

## Download

Go to **[Releases](https://github.com/ashenvii/Konsou/releases/latest)** and grab the installer for your platform:

| Platform | File |
|---|---|
| **Windows** | `Konsou_x.x.x_x64-setup.exe` (per-user install, no admin required) |
| **Linux** | `Konsou_x.x.x_amd64.AppImage` (portable) or `.deb` |

> **Windows SmartScreen warning?** Click **More info → Run anyway**. This is expected for apps that aren't code-signed yet. It's safe.

---

## What it does

Konsou is a tracker, not a social platform. No accounts, no followers, no discovery feed. Your list sits in a local SQLite database, optionally synced across devices through your own Google Drive.

**List management.** Track any title with status (watching, completed, plan to watch, on hold, dropped, rewatching), episode progress, score, and notes. No score required to save an entry. Episode counters batch-update with a single tap. Cards show a greyscale cover that fills with colour as episodes are watched.

**Sequel radar.** When you mark a show completed or dropped, Konsou immediately scans it for announced sequels, movies, and OVAs via the AniList relations graph. It keeps scanning in the background on an adaptive schedule: volatile franchises check every 12 hours; stable ones back off exponentially up to 30 days. Alerts appear in the app; no subscriptions involved.

**Import.** Pull in any public AniList profile by username, or import a MyAnimeList XML export. Both use a merge that keeps your local edits (scores, notes, manual status changes) intact rather than overwriting them.

**Search and discovery.** Live search backed by AniList GraphQL, with a Jikan fallback for partial matches and romanisation variants that AniList misses. Browse Seasonal, Trending, and Top Rated. Title language (Romaji, English, Native) is a setting that applies everywhere.

**Google Drive sync.** Sign in once with Google. Your list syncs to a private `appDataFolder` in your Drive that only Konsou can read. Conflict resolution is field-level: episode progress takes the higher value, status follows a priority order, scores and notes go last-write-wins. No Konsou server exists. The sync path is your device to Google's servers.

**Appearance.** Eight surface themes (Void, Ocean, Ember, Forest, Midnight, Crimson, Paper, Ash), each with a paired accent. Accents are independently overridable. Sidebar runs in rail, hover, or pinned-expanded mode on desktop.

**Auto-update.** The app checks for updates on launch and shows a persistent toast when one is available. Install and relaunch in one click.

---

## Privacy

Konsou has no backend. List data never leaves your device unless you enable Drive sync, at which point it goes directly to Google's servers under your own account using a scope that makes the folder invisible to anything other than Konsou. The full [Privacy Policy](https://ashenvii.github.io/Konsou/privacy.html) is on the project site.

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

Copy `.env.example` to `.env` and add your Google OAuth credentials. Leave them blank to run the app without sync.

```bash
# Browser preview, no Rust required, uses an in-memory storage shim
npm run dev

# Full desktop app with real SQLite
npm run tauri:dev

# Production build, output at src-tauri/target/release/bundle/
npm run tauri:build
```

---

## Tech stack

| Layer | Choice |
|---|---|
| Shell | Tauri 2 |
| Frontend | React 19 + TypeScript + Vite |
| State | Zustand + TanStack Query |
| Database | SQLite (`tauri-plugin-sql`, WAL mode) |
| Sync | Google Drive `appdata` scope via PKCE OAuth |
| Anime data | AniList GraphQL API + Jikan fallback |
| Icons | Lucide |
| Styling | OKLCH design tokens, plain CSS |

---

## Contributing

Issues and PRs are welcome. Open an issue first for larger changes.

---

## License

MIT. See [LICENSE](LICENSE).

---

<div align="center">
<sub>Free, always · <a href="https://ko-fi.com/ashenvii">Ko-fi</a></sub>
</div>
