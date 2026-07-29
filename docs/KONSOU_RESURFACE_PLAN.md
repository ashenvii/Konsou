# Konsou resurface — master plan (resume-in-new-chat)

Single source of truth for the Field Guide resurface program. A fresh chat should
read, in order: the auto-loaded memory `konsou_field_guide_resurface.md`, then
`DESIGN.md` (the committed world), then this file. Anti-reference (the old world we
replaced) is `docs/DESIGN.anti-reference.md`.

Branch: `feat/mylist-rework`. Platform: Tauri 2 + React 19 (web frontend). Owner
preferences: no em dashes anywhere; nothing should read AI-generated; plain, direct.

---

## 1. What is DONE and verified (do not redo)

**The visual world — "The Field Guide"** (a naturalist's specimen catalogue).
Committed and built. Deep herbarium green-black examination table, warm ivory ink,
ONE vermilion stamp of record, crisp ruled keyline plates + photo-corners, EB
Garamond (italic species names) + Courier Prime (mono labels/numbers), no glow, no
pills, stamp/mount/loupe motion. Full contract in `DESIGN.md`.

- **Tokens** (`src/styles/tokens.css`): `:root` = Herbarium default. All **8 themes**
  rebuilt as "plates": Herbarium(ember), Nocturne(void), Cyanotype(ocean),
  Foxing(forest), Slate(midnight), Oxblood(crimson), Vellum(paper-light),
  Specimen Card(ash-light). Legacy enum keys kept stable (no persisted-value
  migration); Settings UI relabeled to plate/ink names. 8 accent "inks."
- **Accessibility verified**: WCAG AA measured on all 8 plates (canvas pixel
  readback). Added `--color-on-accent` (dark for light inks), darkened
  vermilion/ink-violet to 55% L, tertiary ink to 54% alpha, light-plate
  accent-glow darkening. State stays colorblind-safe (hue + glyph + word).
- **Anchor surface (My List look)**: nav rail + bottom nav (mono labels, vermilion
  tab notch), catalogue search field, Garamond-italic genus headings, keyline
  specimen cards (italic species title, mono accession, vermilion stamp quick-add).
- **The loupe**: FranchiseSheet skinned as the examination loupe (mounted cover +
  photo-corners, italic genus title, mono census, vermilion accession tab on the
  watch-order numbers). Stamp motion on episode logging (`konsou-stamp` keyframe,
  `.k-stamped` on the EpisodeCounter number via `key={displayEp}`; respects
  reduced-motion).
- **Navigation + menu system (Examination bench)** — COMPLETE:
  1. Docked loupe: `BottomSheet` gained a `dock` prop → on desktop (>=1024) the
     loupe docks as a 460px full-height right panel; mobile stays a bottom sheet.
     FranchiseSheet + QuickMenu pass `dock`.
  2. Menu consolidation: QuickMenu is the single-specimen loupe (docked + plate
     skin). Shared status picker `.k-status-option` (QuickMenu + StatusSheet) is
     now field-note stamps. EditSheet confirmed dead → flagged for removal
     (spawn_task task_2eb15dd6).
  3. Index edge: the desktop Sidebar is now the whole index (brand seal + tabs +
     account seal); the desktop top Header is removed (mobile-only).
  4. Command palette (Ctrl+K) reframed + skinned as the catalogue "look up a
     specimen or section" lookup.

Verification setup: `npm run dev` / launch config `konsou-web` (port 5199). Web
store seeds via `localStorage["konsou.web.list"]` (array of AnimeListEntry). This
dev machine has Windows animation effects OFF (reduced-motion) and the browser
pane defaults to 431px + can't screenshot — resize to `{width:1280,height:800}` +
reload for desktop, verify via computed styles / read_page, not screenshots.

---

## 2. THE MY LIST FUNCTION REDESIGN (planned here, build next)

The owner rejected a pure collection-organization scheme in favor of a
**category-forward** model. Direction, in the owner's own priorities:

**Core insight:** Planned and Completed are the two stars people actually live in.
Watching / On-hold are optional (many users tag straight from Planned -> Completed).
Everything should be easy, cool-looking, impressive, and non-complicated: an easy
overview, then go into each category for a fresh, polished logging/planning system.

### 2a. Overview (the landing) = a calm launcher
- Not a big list. A cool at-a-glance page: a small **census** of the collection,
  two big beautiful **doors** (Planned, Completed), and a light **"on the field
  now" strip** that only appears if something is in progress.
- Keep the cross-status "have you seen it?" search at top (the memory job).
- Keep a first-class **"newly described"** (sequel radar / more-to-watch) strip.

### 2b. Planned = the ordered watch-plan
- An explicit **manual rank 1..N** (drag to order) so you always know exactly
  what's next and never lose the intended order. (Existing `plan_rank` +
  OrderSheet/QueueSlider are the seed; make ordering the spine of the whole room,
  not just an "Up Next" shelf.)
- Each entry gets **two equal-weight one-tap buttons: Start / Complete**, no
  single promoted action (confirmed decision, see 2e.4). Complete uses the
  existing `toast.action` undo pattern for mistap safety.
- Easy to track a planned entry through to completion.

### 2c. Completed = the ledger / catalogue
- A **year/season completion timeline** of finished entries — chronological, the
  record of what got watched and when. Deliberately lean: no time/episode
  counts, no score distribution, no genre breakdown on this room (confirmed
  decision, see 2e.3). The existing time-accounting/Wrapped work stays
  available elsewhere (Stats page) but is not duplicated here.

### 2d. Watching / On-hold = kept as their own room
- Confirmed: Watching stays a **dedicated room** (owner overrode the
  fold-into-Planned recommendation). On-hold keeps its existing behavior too.
  Only Planned and Completed get the bespoke room treatment; Watching/On-hold
  continue on the generic StatusRoom path unchanged for now.

### 2e. OPEN DECISIONS — CONFIRMED 2026-07-27
1. Overview role: **Light launcher.** Census + Planned/Completed doors + continue
   strip + newly-described strip. (As recommended.)
2. In-progress model: **keep a dedicated Watching room** (owner overrode the
   fold-into-Planned recommendation). Watching/On-hold keep their own room; only
   Planned and Completed get bespoke treatment (see #5).
3. Completed ledger: **timeline only** (chronological, grouped by year/season).
   Owner explicitly rejected the "all four" recommendation — no time/episode
   counts, no score distribution, no genre breakdown on this room. Keep it lean.
4. Planned primary action: **dual equal-weight buttons, Start / Complete**, no
   single promoted action (owner rejected pure "Mark complete primary" — wanted
   both visible, not one over the other). Mistap safety: reuse the existing
   `toast.action` undo pattern already used elsewhere in `listStore.ts` for
   status changes and removals — no new confirmation mechanism, no press-and-hold,
   no dialog. Buttons same size as today's Start button (~44px tall), separated by
   a small gap, each with its own hairline border so a fat thumb can't bridge
   both. This also closes an existing gap: today's Start button has no undo at
   all.
5. Planned and Completed become bespoke dedicated rooms, **replacing** the
   generic StatusRoom for those two statuses only. Watching/On-hold are
   unaffected by this and keep using their existing room.
6. Rewatch + removal history: **full completion-events log** (new table) +
   **ghost records survive removal** on the timeline (owner chose correctness
   over cost — "whatever IS THE BETTER OUTCOME... log completely well with our
   status tab in watch hours, how many of it was rewatching hours"). Full design
   in 2h. This also fixes a real bug found during research: `completed_at` today
   is a single column that's set once and never updated on a rewatch-completion
   (`listStore.ts` updateStatus, `rewatching -> completed` branch keeps
   `prev.completed_at`), so a title rewatched last month still shows its
   original completion date from years ago. The events log fixes this as a side
   effect, not just adds a feature.

### 2h. Completion-events log (schema addition, feeds 2c + Stats)
Today: single row per anime in `anime_list`. `rewatch_count` (migration v9)
increments on `completed -> rewatching` and resets `episodes_watched` to 0;
`completed_at` is a single timestamp that (bug) never updates past the first
completion. No history table exists anywhere (`anime_list`, `anime_cache`,
`search_cache`, `relation_snapshots`, `notifications`, `settings`, `sync_state`,
`list_tombstones`, `scan_schedule` are the full table list). Removal is a hard
delete after a 4s undo toast + a `list_tombstones` write that exists only for
Drive sync merge, invisible to the user.

New: a `completion_log` table, one **immutable, append-only row per completion
event** (first watch and every rewatch each get their own row):
- `anilist_id`, plus a **denormalized snapshot** (title, cover, total_episodes)
  so a row renders even after the parent `anime_list` row (and possibly
  `anime_cache`) is gone — this is what makes ghost records possible.
- `completed_at` (this event's real date — fixes the bug above, since every
  rewatch-completion writes a NEW row instead of overwriting one column).
- `episodes_at_completion`, `is_rewatch` (bool), `rewatch_index` (0 = first
  watch, 1+ = nth rewatch).
- No `removed`/`deleted_at` flag needed: a log row with no matching current
  `anime_list` row IS a ghost by definition. Timeline renders it faded /
  "no longer in your collection," same data as a live entry, just no live
  status/actions.

Sync: because rows are immutable and append-only, merge is a straight union by
id/timestamp — simpler than the existing last-write-wins merge `anime_list`
needs, no new conflict logic required.

Stats: `Stats.tsx`'s current `effectiveEpisodes` (rewatch_count *
total_episodes aggregate estimate, `Stats.tsx:132`) gets replaced by a real
per-event sum from `completion_log`, split by `is_rewatch` — "watch hours" vs
"rewatch hours" become two real, dated numbers instead of one derived guess.
This is schema-level work, sequenced before the Completed room UI in the build
order (2g) since the room reads from this table, not from `anime_list` directly.

### 2f. Preserve (non-negotiable)
Offline-first instant SQLite load; one-tap logging + undo; Drive sync; franchise
grouping + watch order; the loupe; cross-status search; three densities where they
still apply; per-tab back stacks + sheet-stack back handling; colorblind-safe
state; AA on all 8 themes; the founding-why laws (My List is a memory/library not a
resume-queue; radically simple; own-your-record). Do not strip features silently —
surface any removal for approval.

### 2g. Build order (My List) — BUILT 2026-07-28

All eight steps below are built, verified in the browser preview at 1280x800
and 390x844, and green on every gate (`tsc -b`, `eslint`, 179 vitest, 16 cargo
migration tests). What actually shipped, where it differs from or resolves the
plan text, is recorded inline under each step.

New files: `src/pages/PlanRoom.tsx`, `src/pages/CompletedRoom.tsx`,
`src/components/list/RoomDoor.tsx`, `src/components/list/YearRail.tsx`,
`src/components/anime/StatusStamp.tsx`, `src/lib/store/completionStore.ts`.
Retired (dead after the rework, removed rather than left unreachable): the
`QueueSlider` / `HeroBinge` / `DigitalShelf` carousel containers, all of
`DigitalShelf.tsx` and the `shelf` room variant (the ledger replaced that
room's card language), and the six legacy status markers with their CSS.

1. ~~Confirm the 5 open decisions (2e).~~ DONE 2026-07-27, see 2e.
2. Overview -> the launcher (census + Planned/Completed doors + continue strip +
   newly-described strip; Watching keeps its own door too, per 2d). Rework
   `src/pages/Overview.tsx`. **Structure CONFIRMED 2026-07-27: twin doors side
   by side, equal square footage, immediately below the census header** (the
   most literal "two big beautiful doors" reading of the brief; continue strip
   demotes to a single ruled line below the doors, only shown when something's
   in progress).
   **BUILT.** One 736px column holds the whole surface (field, launcher and
   search results share one edge). Census header = Garamond title + mono
   "N titles · kept since <Mon YYYY>" from real data. Doors are square plates
   (`height: clamp(200px, 42vw, 344px)`, width from the grid — driving it off
   `aspect-ratio` made the height set the width and two squares then ran off a
   390px screen), each carrying a keyline, photo-corners, a mono count, three
   real filed covers, and a foot line ("Next …" / "Last …"). The Completed
   door counts completion EVENTS so it agrees with the room behind it. The
   continue line is one ruled row: cover, italic title, mono `Ep n / m`, and
   the vermilion +1 stamp — the one-tap log stays on the landing, which the
   brief's "light launcher" must not cost. Paused shows offer Resume instead.
   The Watching door is that line's mono heading. New-sequels strip keeps the
   app's own name ("New sequels") and the rail drag-scroll contract.
3. Planned room -> ordered watch-plan with drag rank + dual Start/Complete
   buttons (`toast.action` undo on Complete). (`StatusRoom` "plan" variant,
   `OrderSheet`, `listStore` plan_rank, UP_NEXT_CAP, `QueueCard` in
   `QueueSlider.tsx`.) **Structure CONFIRMED 2026-07-27: split footer bar on
   the cover** — same footprint as today's single Start button, just halved
   into two, so the existing card grid's row-height math is undisturbed. Watch
   mono label sizing at ~70px per button (long labels may need to abbreviate).
   **BUILT** as `src/pages/PlanRoom.tsx`. The order is the room's spine
   literally: its default sort is "My order" — numbered entries lead in their
   own order, everything else follows behind them, one list. No Up Next band:
   the shelf version of that idea measured 299px of an 844px phone restating
   the top of the list, and the launcher no longer carries the queue rail
   either, so the room is where the order lives. Cap (UP_NEXT_CAP) unchanged.
   Buttons are `Start` / `Done` at 66px each (measured, no overflow), each
   with its own keyline and a real gap between them. Both route through a new
   `listStore.updateStatusUndoable`, which captures the queue number, the
   dates, the backfilled episodes and the ledger row, and puts all of it back
   on Undo — including re-inserting the entry at the exact number it held.
   Note the card was fluid only inside a room grid before; the carousel is
   gone, so `.k-qcard` is now simply fluid.
4. `completion_log` migration (2h) — new table, backfill one row per existing
   completed entry (best-effort from current `completed_at`/`rewatch_count`
   since no per-event history exists to recover), wire `updateStatus`'s
   `-> completed` branches to append a row, wire Drive sync to union-merge it.
   **BUILT** as migration 12 + `completionStore.ts`. Key is
   `(anilist_id, rewatch_index)`, not a generated id: the Nth completion of a
   title is ONE event whichever device recorded it, so the Drive merge is a
   plain union with no conflict rules (`mergeCompletions`, earliest date wins,
   a recorded date beats a reconstructed one). Backfill expands
   `rewatch_count` into one row per finished watch via a recursive CTE, so the
   record keeps its count and its hours, and flags every reconstructed row
   `estimated` so the ledger marks the date with a `~` instead of presenting a
   guess as fact. `completed_at` on the parent row now updates on every
   completion (the never-updated-on-rewatch bug in 2e.6). Undo of a Done
   retracts the event — a mistap is not history. `clearAll` wipes the log
   (ghosts survive removing one title, not "erase everything"); `importEntries`
   rebuilds it from a restored backup, idempotently. The web shim reconstructs
   the same backfill on first read, so a seeded dev list is not a lie.
   Covered by 3 new cargo tests + 6 store tests + 6 merge tests + 3 shim tests.
5. Completed room -> bespoke ledger component reading from `completion_log`:
   year/season timeline, ghost records for removed entries, rewatch tag
   (`x{rewatch_index}`) per event (2c, 2h). No stat-card sections. **Structure
   CONFIRMED 2026-07-27, after scale/findability research** (list stress-tested
   to 6500 real entries, see `konsou_stress_import_file` memory):
   - **Spine list**: reuse `SpineRail.tsx` as-is (already ships in franchise
     watch-order lists) — filled node = completed, hollow/faded node = ghost
     record, inline year rider per row. Uniform row height throughout, so it
     drops straight into the existing `@tanstack/react-virtual` setup
     (`FranchiseCollection.tsx`) with no mixed-row-height engineering. Deliberately
     rejected the year-header-grid option (Structure B from the mockup round)
     because the current virtualizer only supports one `estimateSize` for every
     row — a separate header row shape is real new engineering, not a config
     change, and isn't worth it for this room.
   - **Year jump rail**: new, but a direct reuse of `LetterRail.tsx`'s pattern
     (same `virtualizer.scrollToIndex` jump mechanism already used for A-Z jump
     in alpha-sort), keyed by year instead of letter. This is the only genuinely
     new UI in this room.
   - **No new in-room search box.** Cross-status search already lives on
     Overview (`Overview.tsx`, precomputed haystack) and CommandPalette
     (Ctrl+K) already searches unfiltered across all statuses including
     Completed — both already solve "find one specific completed title."
     Building a second, room-scoped search here would duplicate that for no
     reason. The year rail solves the one thing neither existing search covers:
     scanning/browsing by year at scale.
   **BUILT** as `src/pages/CompletedRoom.tsx`. Rows are events, not entries: a
   title watched three times is three dated lines. Uniform 66px rows in their
   own virtualizer, spine node filled for a live completion and hollow for a
   ghost, year riding the gutter only where it changes, `Rewatch ×n` and
   `No longer in your list` as tie-on tags, `~` on reconstructed dates. Held to
   an 820px measure (a dated line stretched across 1500px is not a document).
   **One addition to the plan:** the old Completed room's "show dropped"
   filter had nowhere to go, and dropping it silently would have removed the
   only way to browse dropped titles — so the filter survives as a toggle that
   folds dropped entries into the timeline with an untracked node and a
   Dropped tag.
6. Stats.tsx -> swap `effectiveEpisodes` estimate for a real per-event sum from
   `completion_log`, split watch hours vs rewatch hours (2h).
   **BUILT.** Time is now: every completion event's own episode count × its own
   duration, plus the progress of any run no event covers (watching, paused,
   dropped part-way), with a fallback to the entry's own count if a completed
   entry somehow has no logged event. Totals include watches of titles no
   longer on the list — removing something does not un-watch it. The hero
   carries a second chip, "N h first time, N h again", only when there is a
   rewatch to speak of.
7. Watching/On-hold: leave as-is (no fold, no retirement) — confirm they still
   read correctly once Planned/Completed split off the generic StatusRoom.
   **DONE.** `StatusRoom.tsx` is now just the in-progress room (Watching with
   Paused sunk to the bottom) and lost every plan/completed branch with it:
   score sort, the dropped toggle, the order button, the number picker and the
   quick-add hold all moved to the rooms that own them.
8. `AnimeCard.tsx` status-marker unification (2i) — the six legacy markers
   (pills, seal, bookmark ribbon, diagonal ribbon, breathing circle) become one
   field-note stamp component. **Folded into this build now** (owner's call)
   rather than deferred, because Watching/On-hold stay on this exact component
   per decision 2/7, so it's part of making those rooms feel finished, not a
   separate later pass. Note this component is also used outside My List
   (Discover, search results) — those surfaces inherit the change for free but
   aren't otherwise in scope this round.
   **BUILT** as `src/components/anime/StatusStamp.tsx` + `.k-stamp`, used by
   both `AnimeCard` and `FranchiseCard`. All six markers and their CSS are
   gone, along with the two ambient loops they carried (the spinning rewatch
   glyph, the breathing on-hold circle) and the perf-lite rules that existed to
   switch those off.
9. `/impeccable audit` (AA, states, responsive) + `/impeccable polish`.
   **DONE.** Contrast measured by canvas readback, not by eye:
   - Stamp word on its plate, worst case over the brightest possible cover:
     5.41:1 (dropped oxblood). First pass measured 3.90 and 4.29 for dropped
     and on-hold, so the word's mix moved to 60% hue / 40% ivory and the plate
     to 92% — both now clear AA with margin.
   - Launcher (census, doors, strip labels, on-now line) across all 8 plates:
     worst 6.57:1.
   - Ledger (title, date, tags, year rail, ghost rows) across all 8 plates:
     worst 5.02:1. Ghost rows first faded the TITLE to 0.55 opacity, which
     measured 3.8:1 on the two light plates — the fade now applies to the
     cover only and the name steps down to secondary ink instead.
   - No horizontal overflow at 390px on any of the three surfaces; the plan
     grid, ledger and launcher were checked at 390 and 1280.
   - `detect.mjs` reports only three pre-existing `transition: width` warnings
     on progress-bar fills, none in this round's code.

### 2i. Status marker unification (AnimeCard.tsx)
Audit finding (2026-07-27): `QueueCard` (Planned room) is already fully reskinned
to the Field Guide world; `AnimeCard.tsx` (the default card for Watching/On-hold/
search results) was never migrated — its six status markers (`.k-mark` pill,
`.k-mark--spin` pill, `.k-seal` circle, `.k-bookmark` ribbon-tab, `.k-ribbon`
diagonal banner, `.k-hold` centered breathing circle) predate the rework and use
shapes the design contract retired (fully-rounded pills, skeuomorphic
ribbon/bookmark, off-canvas bleed, decorative continuous animation).

**CONFIRMED replacement**: one unified rectangular field-note stamp, generalizing
the already-committed `specimen-tag-active` component token (today hardcoded to
vermilion) to per-status hue instead. Same shape and same corner (top-right,
matching where Completed's seal and Plan's bookmark already sit) for all six
statuses — near-square (`2px`) corners, keyline frame in the status hue,
low-alpha tint fill, bright-hue mono small-caps glyph + word. Colorblind-safe
per the contract's own Inked-State Rule (hue + glyph + word together, never hue
alone). On-hold gives up its dead-center placement and breathing-loop animation
to join the other five in the same corner slot. Dropped's off-canvas-bleeding
ribbon and Plan's clip-path bookmark both retire in favor of the same stamp.
Episode-progress caption (`.k-card__epcaption`, footer mono fraction) is
unaffected — already contract-compliant, no change needed there.

### 2j. Owner review round — FIXED 2026-07-28 (second pass)

The owner used the built surfaces and reported back. What came out of it:

**Two real click bugs, same root cause: a hover transform creating a stacking
context that trapped a control's z-index.**
1. The launcher's doors: the cover stack sat on top of the door's own stretched
   button and ate every click aimed at the obvious place to click. The stack is
   decoration; it takes `pointer-events: none` now.
2. Start / Done on a plan card did nothing, and the tap raised the quick menu
   instead. `.k-qcard__cover` gained `transform` on hover, which makes it a
   stacking context, which trapped `.k-qcard__acts { z-index: 1 }` inside it —
   and the card's stretched open-button `::after`, a later sibling, painted
   over the buttons. The lift moved to the card itself, so one stacking context
   holds the lot in DOM order. (The single Start button had the same defect
   before the split; nobody had a reason to notice.)
   Worth remembering: `elementFromPoint` reported the button as topmost in both
   cases. Only a real click, logged with its `clientX/Y` and target, showed the
   truth.

**Search moved off the top of the page** (owner: "search is in the way"). The
always-on field is gone. A search icon sits beside the My List title, opens the
field in its place, and results hang under the header as an overlay — the
launcher stays where it was, so closing the search returns you to the page you
never left. Capped at 40 rows: a panel is for finding one thing.

**Quick menu → non-modal examination panel** (owner picked this over in-place
expansion, full takeover, and a changed tap contract). `BottomSheet` gained a
`modeless` prop: on desktop with `dock`, there is no backdrop element at all
(an invisible one would still eat the clicks the panel is supposed to leave
alive), `aria-modal` drops, and an explicit X appears since there is no
backdrop left to dismiss with. The list behind stays live, so clicking another
card swaps what the panel shows instead of closing it. Mobile keeps the modal
sheet — a phone sheet has no "behind" worth preserving.

**Quick menu contents de-cluttered** (owner: "the overall list is completely
cluttered... I very much dislike the current spine"). The row carried ten
things: spine rail, sideways year, number badge, hover chevron, status pill
with caret, kind chip, "after #2" placement chip, episode counter, score,
sometimes a "Start here" label. It is now two lines and one control: number,
cover, italic name, one mono meta line, and the status stamp (or Add). The
spine is gone from this surface. The "after #N" placement label is gone
everywhere, including Anime Detail's Related tab — `placementLabel` is now
unused, like `stripFranchisePrefix` before it.

**Completed room → ledger table** (owner picked the trading-app shape over
month blocks, a contact sheet, and a de-spined list). Sortable Date / Title /
Watch / Score columns, 44px rows, the period you are looking at pinned above
the list (a sticky group header would mean two row heights and the virtualizer
measures one), year rail kept but only while date-sorted. The score column
drops below 560px.

**Rooms got the launcher's header** (owner: "the page hasn't been overhauled on
the top... no direction like the previous stages"). New `RoomHeader`: engraved
name, a mono census, and one plain line saying what the room is FOR
("Everything you mean to watch, in the order you mean to watch it"). Both
bespoke rooms use it.

Gates after this round: `tsc -b`, `eslint`, 179 vitest, `vite build` all green;
new surfaces measured at AA on all 8 plates (worst 6.92:1); no horizontal
overflow at 390px.

### 2k. Owner review round 2 — 2026-07-28 (third pass)

**Completed: two rejected structures before this one.** The spine was rejected,
then the sortable table was rejected outright ("OVERALL HATE IT"). Both failed
the same way: they turned a few thousand finished shows into rows of text when
the covers ARE the record, and neither gave a 3000-entry list any landmarks.
Structures were mocked up and the owner picked **the year index**: a column of
years (2026 · 68, 2025 · 63 …) beside a wall of that year's covers, with a
per-year census line. Every view is bounded — you pick a year and see that
year — so nothing is ever an endless scroll. Ghost records, the dropped filter
and rewatch tags all survive. On a phone the index lies down as a row of year
chips. The `YearRail` jump control is gone: the index replaced it.
**If this needs changing again, the thing to keep is BOUNDED VIEWS + covers;
the thing that failed twice is a single long list of text rows.**

**My order → a page, cap 15.** The owner asked for both. The old sheet was a
hand-rolled pointer drag INSIDE a sheet, and the two fought: dragging a row
down is the same gesture as swiping the sheet closed, so the sheet had to
disable its own dismissal mid-drag, rows were absolutely positioned and moved
by transform to stop React re-parenting them out from under pointer capture,
and the row height had to be a constant so a Y position could become an index.
Every one of those was a workaround for being in a sheet. `/list/plan/order` is
a real page with a `RoomHeader`; reordering is ↑/↓ buttons (the same call the
plan cards already made); add and remove now SAY what they did — silently
failing at the cap is most of why it felt broken — and remove is undoable.

**Quick menu → DIM's item popup.** Researched from the DIM source rather than
guessed: `ItemPopup.tsx` renders a `Sheet` when `isPhonePortrait` and a
Floating-UI popper otherwise, with `placement: 'right'`, `offset(8)`, `flip`,
`shift`, an arrow, and boundary padding; their `Sheet` is non-modal
(`aria-modal="false"`), drag-to-dismiss past 0.5 height or 120px/ms, spring
280/20/0.2. Konsou now matches that split in `ItemSurface`: `AnchoredPopover`
(preferred side right, flips left, clamps into the viewport, arrow tracks the
anchor's centre, closes on outside click / Escape / hardware back, repositions
on scroll and resize) on anything wider than an upright phone, and the existing
drag-to-dismiss sheet on a phone. No Floating-UI dependency was added — the
maths is ~60 lines.

**Typography.** The owner's report ("cool but hard to read or inconsistent")
was measurable: an on-screen audit found Garamond at 12px was the single most
common text in the app (55 elements), mono at 11px second (34), across 13
different font/size/style combinations on one screen. EB Garamond has a small
x-height and Courier Prime is a light wide typewriter; both need ~1-2px more
than a grotesque. Every step below 16px moved up one notch with its leading.
Two real inconsistencies also fell out of the audit and were fixed: the plan
card's watch-order number was set in the SERIF (the contract says every number
is mono), and the sidebar's account row was the one nav item in the reading
serif.

---

## 3. REMAINING SURFACES (after My List) — same loop each

Per-surface loop: critique current -> function/IA brief (owner approves) -> roll
5-7 structures (`concept-seed --scope surface --mode operate`) -> **owner picks
structure** (show visual mockups via `mcp__visualize__show_widget`, raster
image-gen is unavailable) -> build in the fixed world -> audit + polish. Cadence:
owner picks each structure and approves each function brief. Order:

1. ~~**My List**~~ (spec above) — DONE 2026-07-28, see 2g.
2. **Anime Detail** (`src/pages/AnimeDetail.tsx`) — immersive; the specimen's full
   plate + relation chain + tracking. Stresses the loupe/menu system.
3. **Discover** (`src/pages/Discover.tsx`) — landing spotlight + lanes + inline
   filter browse; the "more to watch" engine.
4. **Search** — folded into Discover today (redirect); decide if it stays.
5. **Airing** (`src/pages/Airing.tsx`) — Episodes calendar + New sequels segments.
6. **Stats** (`src/pages/Stats.tsx`) — may partly merge with the Completed ledger.
7. **Settings** (`src/pages/settings/*`) — backstage; appearance shows the 8 plates.

Global systems already done: nav + menu (Examination bench). Deferred refinements:
grid-card cover+label-strip restructure (risky — 2:3 sizing feeds the virtualized
grid row-height math); flatten glassy `.k-mark/.k-seal/.k-hold` markers to flat ink
stamps; photo-corners on hero/shelf; self-host EB Garamond + Courier Prime for full
offline (currently Google Fonts CDN); make the docked loupe fully non-modal.

---

## 3a. Known bugs (found during planning, 2026-07-27)

Not part of the My List function/structure work above — these are pre-existing
defects the owner hit while using the app, investigated during this planning
session and confirmed against the real code. Not yet scheduled into a build
order; flag for triage before or alongside whichever surface touches them.

**Franchise ordering picks season 2 as current while season 1 sits at the
bottom.** Two separate, independently confirmed root causes, likely both
contributing depending on which surface is in view:

1. `src/lib/franchise/grouping.ts` `pickDisplayEntry` (decides which entry a
   franchise card's Start/Complete/loupe act on, used by My List and
   `FranchiseCollection`) breaks ties between same-status entries by
   `added_at` — when the user added it to their list — not by story/watch
   order. If Season 2 was added to the list before Season 1, Season 2 becomes
   the card's "current" entry even though Season 1 is the franchise's actual
   start. The codebase already has a correct topological watch-order sort
   (`src/lib/franchise/watchOrder.ts` `orderForWatching`, tested, used
   elsewhere for Related/quick-menu lists) that `pickDisplayEntry` does not
   consult at all.
2. `src/pages/AnimeDetail.tsx` `getSeasonRows` (the Related/spine tab, and the
   source of `franchiseBase` used for name-stripping) sorts by pure release
   date via `orderByRelease` (`watchOrder.ts`), which is a deliberate,
   documented choice ("watch order is a curated community call with no source
   of truth") — but `orderByRelease`'s `dateKey` sinks any entry with a
   missing `startDate` to `Number.MAX_SAFE_INTEGER` (dead last). AniList data
   for older/less-popular seasons is often missing a start date. If Season 1's
   date is null while Season 2's is populated, Season 1 sorts to the very
   bottom of the spine, and `mainRows[0]` (used as the franchise's "base" name
   for stripping, see below) resolves to Season 2 instead of Season 1.

**Naming: franchise-prefix stripping reads as confusing / a title's front part
goes missing.** Traced to `src/lib/format.ts` `stripFranchisePrefix`, which
deliberately drops the franchise name from a season's title so lists don't
repeat "The Seven Deadly Sins:" on every row (well-tested, see
`format.test.ts`; it is conservatively guarded and falls back to the untouched
full title on any non-match, so a literal empty/garbled string could not be
reproduced in this pass). What's confirmed instead: this function is entirely
dependent on being handed the correct franchise "base" title, and root cause
#2 above is exactly the kind of bug that would feed it the wrong one —
whichever entry standard sort designates as first becomes the base every other
title gets compared against. **Open**: need one concrete franchise example
from the owner to confirm whether this is the same root cause manifesting
differently, or a second, separate bug.

**Naming — FIXED 2026-07-27.** Owner confirmed the concrete repro (Wind
Breaker season 2 showing as a bare "Season 2" with no franchise name) and
asked for franchise-prefix stripping turned off entirely so names stay
consistent with how they looked before this rework. `stripFranchisePrefix` is
no longer called anywhere: `FranchiseSheet.tsx`'s `SeasonRow` and `AddRow` and
`AnimeDetail.tsx`'s spine row all now show `preferredTitle(...)` directly, in
full, un-stripped. The `franchiseBase` prop/local was dead after this change
and was removed from both components (not just left unused) — `SeasonRow`,
`AddRow`, and their call sites no longer take/pass it; `AnimeDetail.tsx`'s
`franchiseBase` local (which depended on the buggy `mainRows[0]`, root cause
#2 above) was deleted along with it, which also incidentally removes that
particular symptom of root cause #2 (the naming one) even though the
underlying ordering bug in `getSeasonRows` itself is still unfixed. The
`stripFranchisePrefix` function and its tests (`format.test.ts`) are left
intact and passing, just unused, in case the behavior is wanted again later
in a more targeted form. Verified: `tsc -b` clean, `format.test.ts` (7 tests)
green.

**Ordering root cause #1 — FIXED 2026-07-28** (folded into the My List build
as planned). `pickDisplayEntry` now breaks same-status ties by story position
instead of `added_at`: the franchise root first (the chain walker resolves it
by walking PREQUEL edges to the start, so it is season 1 by construction),
then ascending anilist_id. It deliberately does NOT call `orderForWatching`:
that needs relation edges and per-node dates, and `groupEntries` is a pure
function that runs over the whole library on every render — it has neither.
Two regression tests cover the reported shape (season 2 added first no longer
speaks for the card) in `grouping.test.ts`.

**Still open** — ordering root cause #2, `AnimeDetail.tsx` `getSeasonRows`
sinking undated entries last via `orderByRelease`'s
`Number.MAX_SAFE_INTEGER`. Belongs to the Anime Detail surface pass (section
3, item 2).

---

## 4. How the new chat should start

1. Read memory `konsou_field_guide_resurface.md` + `DESIGN.md` + this file.
2. Load `/impeccable` (skill) for the surface loop; the world is FIXED — do not
   re-open identity, only structure/function.
3. My List is BUILT (2g). The next surface is **Anime Detail** (section 3,
   item 2), and it carries ordering root cause #2 with it (3a).
4. Run the per-surface loop in section 3: critique current -> function/IA brief
   (owner approves) -> roll structures -> owner picks -> build -> audit +
   polish. Two stop points per surface: the structure pick and comp approval.
5. Verification setup as in section 1. Screenshots DO work in the browser pane
   now (2026-07-28), alongside computed-style and canvas-readback checks.
