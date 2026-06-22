# Changelog

All notable changes to Konsou are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Silent auto-update via `tauri-plugin-updater`: the app checks for new releases
  on launch, downloads them in the background, and offers a one-click
  "Update Now" that installs and relaunches automatically.
- MIT `LICENSE` and this changelog.

## [0.1.0] — 2026-06-22

Initial release.

### Added
- Anime list tracking (status, episodes, score, notes) backed by local SQLite.
- AniList search and discovery (Seasonal / Trending / Top Rated).
- Sequel radar — proactive alerts when a completed show gets a new season,
  movie, or OVA.
- Google Drive sync via PKCE OAuth with clock-skew-tolerant merge.
- AniList import from any public username, with smart local-edit merge.
- First-run onboarding, error boundaries, and an in-app update checker.
- Cross-platform release pipeline (Windows / macOS / Linux) via GitHub Actions.

[Unreleased]: https://github.com/ashenvii/Konsou/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ashenvii/Konsou/releases/tag/v0.1.0
