# Konsou

An offline-first anime tracker for your own record. The user's list is theirs; titles, covers and scores come from MyAnimeList.

## Language

**Entry**:
One anime on the user's list, with the user's own status, progress, score and notes.
_Avoid_: Item, show, row

**Record**:
The user's own data in `konsou.db`: entries, finished watches, alerts, deletions and settings. Only the record is backed up to Drive, without the local names.
_Avoid_: User data, save file

**Details**:
What was fetched from MyAnimeList, or worked out from it, in `details.db`. Never backed up, safe to delete, fetched again when needed.
_Avoid_: Cache, metadata

**Library**:
The screen that lists every entry. It has the tabs All, Watching, Planned and Completed, a dropdown for the other statuses, a sort and a grid or list view, and no filters.
_Avoid_: My List, Collection

**Watching**:
Both a status an entry can have and a screen. The screen shows what is ready to watch and what is waiting for its next episode.
_Avoid_: Currently airing

**Ready to watch**:
A Watching entry whose next episode has already aired.
_Avoid_: Up next, queue

**Waiting for next episode**:
A Watching entry whose next episode has not aired yet, shown with a countdown.
_Avoid_: Airing soon

**Discover**:
The screen for finding anime the user does not have yet. Its tabs are Browse, For you and Top 10. Schedule is its own screen.
_Avoid_: Explore, Catalog

**Browse**:
The Discover tab with a title search, a Filters button and the results grid.
_Avoid_: Advanced search

**Quick search**:
The always-available search at the top of the app (Ctrl K). It looks up a title by name and has no filters.
_Avoid_: Global search

**Filter**:
A condition on the Browse results, such as genre or format. Each can include or exclude. Filters exist only on Browse.
_Avoid_: Facet, refinement

**Scope**:
The set of titles loaded for a Browse view, such as This season or Top rated. Filters narrow the scope; they never fetch more.
_Avoid_: Result set, feed

**Token**:
A named color, size, radius or font size defined once. Added only when the owner says so.
_Avoid_: Variable, theme value

**Component**:
A reusable piece of interface with fixed spacing, size and type. A new need gets a new component; an existing one is not bent to fit.
_Avoid_: Widget, element

**Nekomimi**:
The mascot, a square cat head. It sits beside the Konsou wordmark.
_Avoid_: Logo cat, cat icon

**Status section**:
The small icons beside the wordmark that report sync, connection, a waiting update and a list conflict. Each says its state when hovered.
_Avoid_: Status bar, banners

**Wordmark menu**:
The dropdown that opens from the Nekomimi and Konsou button. It holds what's new and the app restart.
_Avoid_: Logo menu

**Detail page**:
The full page for one title, with its hero, tabs and, when the title is on the list, the entry bar.
_Avoid_: Anime page, details view

**Entry bar**:
The bar fixed to the bottom of the detail page for a title on the list. It shows the status and steps the episode count.
_Avoid_: Footer, mini player

**Streamer mode**:
A setting, off by default, that hides adult titles, covers and synopses everywhere while streaming.
_Avoid_: Safe mode, adult filter

**Rewatch**:
Watching a Completed entry again. It sets the status to Rewatching and restarts the episode count, and the earlier completion stays on record.
_Avoid_: Repeat

**Toast**:
A short message at the bottom of the screen with an optional action. It never closes while the pointer is on it or while a review is open.
_Avoid_: Snackbar, notification
