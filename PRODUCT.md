# Konsou

**Type:** App UI
**Register:** product
**Scene:** Anime viewers at home, late at night, in a darkened room, using Konsou as a companion to what's on their other screen. Ambient light is low.

## Product
Offline-first anime tracker for desktop (Windows, Linux) and Android. Users sign in once with Google, and that is the entire setup. The list loads instantly from SQLite; network is for search and sync, never for the core experience.

## Design principles
- Cover art is the hero. Every surface choice exists to make anime covers pop.
- Dark by default. This follows from the scene, not stylistic preference.
- Accent color signals state, never decoration. The accent glow on a card means "in your list." Hover alone gets a depth shadow, not color.
- Score is never required. Users can add to any status without rating.
- Offline-first. The experience starts before any network call completes.

## Palette
Sunset amber and coral on warm near-black surfaces, set by the default Ember theme. The exact OKLCH tokens live in `src/styles/tokens.css`; that file is the source of truth, not a copy here. Eight themes ship (Void, Ocean, Ember, Forest, Midnight, Crimson, Paper, Ash), each with a paired accent, and both surface and accent are overridable in Settings. Backgrounds are never neutral grey; every theme carries a deliberate hue cast.

## Target users
Anime fans who track what they watch, from casual to completionist. Desktop-first, carried everywhere on Android.

## Key pages
1. My List: the user's collection, three view densities (Grid, List, Compact)
2. Search: AniList search with instant local-cache results, plus filtered search of your own list
3. Discover: seasonal airing, trending, top rated
4. Schedule: a weekly airing calendar for the shows you're watching
5. Alerts: sequel radar, airing now / announced / missed releases
6. Anime Detail: full info, relation chain, edit controls
7. Stats: local totals by status, episodes and time watched
8. Settings: appearance, sync status, account
