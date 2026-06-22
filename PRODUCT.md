# Konsou

**Type:** App UI
**Register:** product
**Scene:** Anime viewers at home, late at night, in a darkened room, using Konsou as a companion to what's on their other screen. Ambient light is low.

## Product
Offline-first anime tracker for desktop (Windows/macOS/Linux) and Android. Users sign in once with Google — that's the entire setup. The list loads instantly from SQLite; network is for search and sync, never for the core experience.

## Design principles
- Cover art is the hero. Every surface choice exists to make anime covers pop.
- Dark by default — this follows from the scene, not stylistic preference.
- Accent color signals state, never decoration. The violet glow on a card means "in your list." Hover alone gets depth shadow, not color.
- Score is never required. Users can add to any status without rating.
- Offline-first. The experience starts before any network call completes.

## Palette
- Seed color: `oklch(52% 0.27 290)` — violet
- All design tokens use OKLCH format
- Three user-selectable accent options:
  - Violet (default): `oklch(52% 0.27 290)` / `#7C5CFC`
  - Cobalt: `oklch(58% 0.18 240)` / `#2B8FE8`
  - Crimson rose: `oklch(55% 0.20 10)` / `#E8507A`
- Surfaces: violet-cast near-black — `oklch(8.5% 0.012 280)` / `#0E0D12`
- Never neutral grey backgrounds. The violet cast (hue 280) is intentional.

## Target users
Anime fans who track what they watch. All levels of engagement — casual to completionist. Desktop-first but carried everywhere on Android.

## Key pages
1. My List — the user's anime collection, three view densities (Grid / List / Compact)
2. Search — AniList search with instant local-cache results
3. Discover — seasonal airing, trending
4. Alerts — sequel radar: airing now / announced / missed releases
5. Anime Detail — full info, relation chain, edit controls
6. Settings — appearance, sync status, account
