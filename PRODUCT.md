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
- WCAG 2.1 AA contrast is the target in both worlds, Lantern and Neon.

---

<!-- The visual world now lives in DESIGN.md, which is derived from the shipped
     surface rather than from intentions. What follows is the product-level
     summary only; DESIGN.md and src/styles/tokens.css are the source of truth. -->

## Design principles

- Cover art is the hero. Every surface choice exists to make anime covers pop.
- Dark by default. This follows from the scene, not stylistic preference.
- One lit object per surface. A glow means live, and only one element on a screen may carry it.
- Score is never required. Users can add to any status without rating.
- Offline-first. The experience starts before any network call completes.

## Palette

The world is the Night Market: a near-black street with one lit stall on it. Each
world states exactly two hues, signage (names a thing, marks a boundary) and
highlight (means live, counted, yours). Two worlds ship, and they are renditions
of one world rather than palettes on a neutral chassis: **Lantern** (default,
warm near-black ground, coral signage, amber highlight, 4px corner) and **Neon**
(blue-black ground, magenta signage, cyan highlight, hard 0px corner). The exact
OKLCH tokens live in `src/styles/tokens.css`, which is the source of truth, not a
copy here. There is no accent picker: the old per-theme accent-ink system was
deleted when the eight themes collapsed to two worlds. Backgrounds are never
neutral grey; each world carries a deliberate hue cast.
