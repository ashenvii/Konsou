# Konsou

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Anime fans who track what they watch, from casual to completionist. Desktop-first (Windows, Linux), carried everywhere on Android. The primary situation is at home, often late at night in a low-light room, using Konsou as a companion to whatever is playing on another screen.

## Product Purpose

An offline-first anime tracker. Users sign in once with Google, and that is the entire setup. The list loads instantly from local SQLite; the network is only for search and sync, never for the core experience. Success means opening the app and managing the list instantly, anywhere, without depending on a server being up.

## Positioning

You own your data. Local SQLite is the source of truth and sync runs through the user's own Google Drive, with no proprietary Konsou backend or account behind it. A tracker built on a hosted backend cannot truthfully make that claim.

## Operating Context

- Used at home, frequently late at night in a darkened room, as a companion to another screen.
- Desktop-first on Windows and Linux, carried everywhere on Android.
- A one-time Google sign-in is the whole onboarding. Data lives on-device; Google Drive is the user's personal sync channel.
- Catalog and search data come from AniList.

## Capabilities and Constraints

- Local-first store: SQLite via the Tauri `plugin-sql`, with list virtualization for large collections.
- My List: the user's collection in three view densities (Grid, List, Compact).
- Search: AniList search with instant local-cache results, plus filtered search of the user's own list.
- Discover: seasonal airing, trending, top rated.
- Schedule: a weekly airing calendar for shows being watched.
- Alerts / sequel radar: airing now, announced, and missed releases, plus sequel announcements on completed shows.
- Anime Detail: full info, relation chain, edit controls.
- Stats: local totals by status, episodes and time watched.
- Settings: appearance, sync status, account.
- Score is optional. Any status can be set without a rating.
- Auth via Google; sync via the user's own Google Drive.
- Tech: Tauri 2 + React 19, distributed for Windows, Linux, and Android. The UI is a web frontend inside a native wrapper, so the design language is web.

## Brand Commitments

- Name: Konsou. Logo at `public/konsou.svg`.
- Repository `ashenvii/Konsou`, MIT license.
- Voice and personality are not yet formally defined; future work should not assume a tone that has not been set.

## Evidence on Hand

- Real assets: `README.md`, the logo at `public/konsou.svg`, `CHANGELOG.md`, and GitHub releases under `ashenvii/Konsou`.
- No testimonials, user counts, benchmarks, or press exist yet. Future work must not fabricate them.

## Product Principles

- Offline-first: the experience starts before any network call completes.
- Data ownership: local SQLite is the source of truth; sync is the user's own Drive, never a proprietary backend.
- Zero-friction setup: one Google sign-in is the entire onboarding.
- Score is never required: adding to the list never demands a rating.
- Sequel awareness: completed shows keep getting watched for continuations.

## Accessibility & Inclusion

- State is never signaled by color alone: accent-as-state stays legible for colorblind users, paired with glow, shape, or label.
- WCAG 2.1 AA contrast is the target across all eight themes.

---

<!-- Pending migration to DESIGN.md via /impeccable document. Preserved from the legacy record; these are visual-world decisions, not product truth. -->

## Design principles (pending DESIGN.md)

- Cover art is the hero. Every surface choice exists to make anime covers pop.
- Dark by default. This follows from the scene, not stylistic preference.
- Accent color signals state, never decoration. The accent glow on a card means "in your list." Hover alone gets a depth shadow, not color.
- Score is never required. Users can add to any status without rating.
- Offline-first. The experience starts before any network call completes.

## Palette (pending DESIGN.md)

Sunset amber and coral on warm near-black surfaces, set by the default Ember theme. The exact OKLCH tokens live in `src/styles/tokens.css`; that file is the source of truth, not a copy here. Eight themes ship (Void, Ocean, Ember, Forest, Midnight, Crimson, Paper, Ash), each with a paired accent, and both surface and accent are overridable in Settings. Backgrounds are never neutral grey; every theme carries a deliberate hue cast.
