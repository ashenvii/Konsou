# Changelog

All notable changes to Konsou are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.5.0] - 2026-06-30

### Added
- **Android**: the same codebase now builds and runs on Android, distributed as a
  signed APK through GitHub Releases. Download the `.apk`, open it, and allow the
  install when prompted. Updates are manual (grab the newer APK); silent
  auto-update stays desktop-only.

### Changed
- App icons are regenerated from the in-app logo so the Windows, Linux, Android,
  and iOS launcher icons all match.

## [0.4.0] - 2026-06-30

### Added
- **Search your list**: the list search now filters down to just the entries that
  match, with a result count, instead of dimming non-matches in place. On a large
  library you no longer scroll hunting for a highlighted card.
- **Schedule page**: a weekly airing calendar for the shows you're watching, built
  from AniList airing data.
- **Stats page**: local totals, entries by status, episodes and time watched, and a
  status breakdown. No account required.

### Changed
- **New signature look**: Konsou now leads with a sunset amber/coral identity on
  warm near-black surfaces, replacing the muted violet default. Purple lives on as
  the Void theme for anyone who wants it.
- **Refreshed logo and app icons**: the K mark is redrawn in the amber-to-coral
  palette with a teal accent, and the desktop and mobile icon set was regenerated
  to match.
- **List and franchise redesign**: segmented per-season progress bar and franchise
  badge on grid cards; list and compact rows enriched to match (poster, status
  pill, season chip, progress, score) via a shared SeasonBar.
- **Franchise sheet, now a season manager**: art-backed header with aggregate
  progress, numbered season rows with an inline stepper, per-season and
  per-franchise remove, and a prominent "Up next".
- **Navigation**: Settings, Account, and Stats moved behind the avatar (top bar on
  mobile, sidebar footer on desktop), making room for the Schedule tab without
  growing the bar. Pages gained an optional back button.
- **Onboarding**: trimmed to the core value props, title-language choice, and
  Connect Google.

### Fixed
- **Clickable affordances**: hover and press states across cards, rows, and the
  franchise sheet so interactive controls read as interactive.
- **Build**: corrected the `airingScan` list update and the `DbDriver` to
  `KonsouDb` import in the franchise sheet.

## [0.2.0] - 2026-06-25

### Added
- **Color themes**: eight surface palettes (Void, Ocean, Ember, Forest, Midnight,
  Crimson, Paper, Ash). Each theme ships with a paired accent; both are
  independently overridable in Settings.
- **Expanded accent palette**: Sakura, Violet, Cobalt, Crimson, Amber, Aqua, Jade.
- **Sidebar modes**: rail (icons only), hover (expands over content on pointer),
  and expanded (pinned open, page reflows). Desktop only, persisted in settings.
- **Progressive cover reveal**: watching and rewatching cards show a greyscale
  cover that fills with colour left-to-right as episodes are watched.
- **Per-status card markers**: each list status gets a distinct shape on the cover
  (chip, badge, ribbon, or border glow) so the state is readable at a glance.
- **MAL list import**: import a MyAnimeList export XML file directly into Konsou.
- **Adaptive sequel scan scheduler**: sequel detection now runs per-seed on an
  exponential backoff (12h for volatile franchises; 1d to 30d for stable ones)
  instead of a single 6h global cooldown. Scales to large lists without hammering
  the API.
- **On-demand seed check**: marking an entry completed or dropped immediately scans
  it for sequels in the foreground, while the background drip-scan handles the rest.
- **Title language preference**: display Romaji, English, or Native titles
  throughout the app.
- **Forgiving search**: Jikan/MAL fallback kicks in when AniList returns few prefix
  matches, closing gaps for partial or romanisation-variant queries.

### Fixed
- **Drive sync**: a failed Drive read is no longer treated as an empty remote,
  which previously caused the local list to be wiped on reconnect.
- **Drive sync**: deletion tombstones are now reconciled on sign-in so entries
  deleted on another device are removed rather than resurrected.
- **AniList batch detection**: lowered batch size from 50 to 12 ids to stay under
  AniList's 500-complexity cap; previously large batches were rejected outright and
  silently aborted sequel detection.
- **AniList partial-success**: a batch that includes a deleted or private media id
  returns HTTP 404 with partial data; the client now reads the body instead of
  throwing, so the rest of the batch is not discarded.
- **Rate limiter**: background sequel scans run at low priority and leave a 25%
  headroom reserve for foreground requests, so a scan can never starve the first
  searches after launch.

### Changed
- Status colour palette reworked so each state has a distinct, unambiguous hue
  (completed=green, watching=blue, plan_to_watch=amber, dropped=red, on_hold=purple,
  rewatching=teal).
- Surface chroma raised so the void theme reads as intentionally purple, not grey.
- Icons migrated from Phosphor to Lucide.
- My List empty state redesigned with an illustrated shelf and an import CTA.

## [0.1.0] - 2026-06-22

Initial release.

### Added
- Anime list tracking (status, episodes, score, notes) backed by local SQLite.
- AniList search and discovery (Seasonal / Trending / Top Rated).
- Sequel radar: proactive alerts when a completed show gets a new season, movie,
  or OVA.
- Google Drive sync via PKCE OAuth with clock-skew-tolerant merge.
- AniList import from any public username, with smart local-edit merge.
- First-run onboarding, error boundaries, and an in-app update checker.
- Cross-platform release pipeline (Windows / Linux) via GitHub Actions.

[Unreleased]: https://github.com/ashenvii/Konsou/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/ashenvii/Konsou/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/ashenvii/Konsou/compare/v0.3.0...v0.4.0
[0.2.0]: https://github.com/ashenvii/Konsou/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ashenvii/Konsou/releases/tag/v0.1.0
