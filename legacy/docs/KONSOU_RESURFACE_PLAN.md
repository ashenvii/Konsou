# Konsou resurface, master plan (SUPERSEDED, kept as history)

> **STALE. Do not take sequencing, tokens or surface decisions from this file.**
> It plans the **Field Guide** world, which was retired on 2026-08-10 and replaced
> by the **Night Market** (two worlds, Lantern and Neon). Everything below about
> eight plates, herbarium green-black, vermilion, EB Garamond, Courier Prime,
> photo-corners, specimen cards and accession numbers describes a world that is no
> longer in the codebase. `src/pages/Overview.tsx` and `RoomDoor.tsx`, which it
> names throughout, were deleted on 2026-08-12.
>
> Read instead, in order:
>
> 1. `DESIGN.md`, the current direction contract, derived from the shipped surface.
> 2. `docs/OVERVIEW_NIGHT_MARKET_PLAN.md`, the only active plan.
> 3. `src/styles/tokens.css`, which is the source of truth for every value.
>
> What is still worth reading here: the measured audits (the tonal ladder, the
> 12-14px type band, the contrast probes) and the behaviour constraints. Those are
> facts about the app and they survived the world change. The visual program did not.

Branch: `feat/mylist-rework`. Platform: Tauri 2 + React 19 (web frontend). Owner
preferences: no em dashes anywhere; nothing should read AI-generated; plain, direct.
---

## 0. STATE AS OF 2026-08-06 — start here

My List is marked DONE 2026-07-28 in section 2g below. That is still true of its
FUNCTION. Its SURFACE has since been through four more rounds, and section 2g does
not describe what is on screen now. Read
`memory/konsou_overview_doors_wash_0806.md` before section 2g, not after.

What changed, in one line each:

1. **Doors.** Room entry was a caption with a chevron taking 2.04% of the page.
   `src/components/list/RoomDoor.tsx` now renders a drawer front (registers) or a
   mounted plate (band, sequel rail), present in every state including empty.
   Doors are 12.39% of the page.
2. **The ladder, app-wide.** Every surface used to sit between L\* 3.9 and 19.1
   with text at L\* 93, a 74-point empty middle. `tokens.css` now runs
   L\* 1.8 / 12.3 / 22.5 / 27.2 on all six dark plates, and the two light plates
   were inverted so the PAGE drops and the mounts stay near-white. The ink ramp
   moved with it (secondary 66→78%, tertiary 54→70%, keyline 46→56%).
3. **A subject.** `Hero` in Overview.tsx: tonight's show at the new `--text-4xl`
   display step with a 56px filled seal. It leads at every width; the reading
   order no longer inverts by breakpoint.
4. **The watch tile.** Its label came off the cover art (no scrim, no rule across
   the poster, photo-corners back to the keyline ivory).

**Verified:** 0 contrast failures across 2,673 checks (8 themes x 8 accents x
every ground), no overflow or undersized targets at 320/390/768/1160/1440,
184 tests, typecheck, eslint, build, detector all clean.

**NOT verified: nobody has looked at it.** Screenshots time out in the preview
pane (see `memory/konsou_web_preview_testing.md`), so all of the above is
measurement. **The next session's first job is to run the app and look at it,
especially the default Herbarium plate at night.** If the plates read too lifted,
that is one number in `tokens.css` and it is much cheaper to change before more
work stacks on it.

The remaining backlog lives in the STILL OPEN section of
`memory/konsou_overview_doors_wash_0806.md`. Nothing on it is blocking.

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

### 2l. Owner review round 3 — 2026-07-29

Eleven items came back from real use. Nine were defects or directed changes and
were fixed in this pass; the tenth (My Order) is planned in 2m below because the
owner's complaint about it was specifically that the last pass rebuilt it with no
plan. What the nine were, and what each traced to:

1. **The anchored popover was placed using its CAP, not its height.**
   `place()` centred on `size.maxHeight` (720), so the bottom-edge clamp pinned
   every popover to the top of the window whichever card was clicked, and the
   arrow — clamped to the cap as well — pointed below the box at nothing. It now
   measures: a first pass places against the cap, a `useLayoutEffect` re-places
   against the real `offsetHeight`, and both land before paint so nothing jumps.
   A `ResizeObserver` follows content that grows. Verified: popover height 305px
   for 303px of content, arrow lands inside the clicked card's rect.
2. **A second, related placement bug fell out of the same fix.** `TOP_EDGE = 64`
   exists to keep a popover clear of the page's top chrome, but a toolbar
   control IS that chrome — the filter panel opened *below* the button it
   belonged to. The upward limit now never sits below the anchor's own top.
3. **No way to close it but empty space.** DIM's item popup carries an explicit
   X and now so does this one (`.k-pop__close`, same mark and corner as the
   docked panel's). Clicking outside is a shortcut, not an affordance: on a wall
   of covers there may be no empty space to click and nothing says the click
   would work.
4. **Two quick menus on two different code paths.** `FranchiseSheet` went
   through `ItemSurface`; `QuickMenu` reached past it straight to
   `BottomSheet dock modeless`, so the same job behaved differently on the same
   screen width — and 2k's claim that `ItemSurface` owns this decision was not
   actually true. `QuickMenu` now goes through `ItemSurface` too, with an
   optional `anchor` (AnimeDetail passes the tracking panel, the thing the menu
   edits). On a phone both are now `aria-modal="false"` drag-to-dismiss sheets,
   which is DIM's own phone behaviour.
5. **The phantom scrollbars.** Two causes. CSS computes a `visible` axis to
   `auto` as soon as the other axis is not visible, so `.konsou-scroll`
   declaring only `overflow-y` gave every scroller in the app a horizontal
   scrollbar the moment any child spilled sideways. And something was spilling:
   `.k-fhead` carries a negative side margin to bleed through the sheet body's
   gutter, but the popover body has no gutter, so in a popover it was 40px wider
   than its own container. Fixed both — the bleed is now scoped to
   `.k-sheet__body > .k-fhead` — and panel bodies hide their bar, since a 15px
   gutter down the edge of a plate reads as a seam in the plate.
6. **Room headers carried Stats' job.** `RoomHeader`'s mono census and its
   "what this room is for" line are both gone (owner picked name-and-controls
   only). Completed's second census line went with them: the year index already
   prints that year's count beside the year. Note this did drop the per-year
   rewatch count, which lived nowhere else — say so if it is wanted back.
7. **Start / Done belonged to no theme.** They were `oklch(0% 0 0 / 72%)` glass
   with pure-white keylines and ink. They are field-note plates now, the same
   ones the status stamp uses two corners away: the examination plate, a warm
   ivory keyline, ivory ink. Measured over the brightest cover art possible —
   label 13.31:1, keyline 3.30:1 (raised from 24% to 38% alpha to clear 3:1,
   because that boundary is what tells a thumb where one button ends).
8. **The year index was unreachable at narrow widths.** Under 720px it becomes a
   horizontal strip that hides its scrollbar — with no drag-pan handler, so on a
   narrow desktop window the older years could not be reached by any input the
   app offered. It now follows the rail contract (`useDragScroll`, verified
   panning to scrollLeft 750 of 750), snaps per year, and the chips went from
   two-line 30px baseline rows to one-line 44px targets. The active year also
   scrolls itself into view: with fourteen-plus years the strip opened at the top
   while the year on screen was off the end of it.
9. **No search inside a room** (item 8) and **filters rebuilt as one
   cross-page component** (item 11), both below.

**Room search.** `RoomHeader` gained it, in the header's own row: the icon
replaces the title with the field, so opening and closing never moves the list.
All three rooms have it (Planned, Completed, Watching), each scoped to its own
room and each saying so when it finds nothing ("My List's own search looks
across every status"). Completed searches the *record*, so a ghost row for a
removed title is still findable — the point of keeping it. Grouping moved into
its own memo in Plan and Status rooms with a precomputed haystack per card, so
typing does not re-group the library per keystroke.

**Filters → one component, every page.** `RoomFilters` is deleted.
`FilterMenu` (in `components/ui`, not `components/list`, because it is not a
list feature) takes the sections a page declares as data — `choice` for sort,
`toggles` for tags, `switch` for one on/off — and owns how they look and where
they appear. Where is `ItemSurface`: the anchored popover on a desktop width,
the sheet on a phone, the same decision the quick menu makes, so the app has one
positioning system rather than one per feature. The button and the panel ship
together so a page never holds a ref and an open flag to place a filter panel.
The old sheet was also still dressing its sort control as a fully-rounded pill,
a shape this world retired; everything in the new one is a ruled row, which is
also the only shape that scales to a vocabulary of hundreds of tags.
`DiscoverFilterSheet` was deliberately left alone — Discover is its own surface
pass (section 3) and `FilterMenu` is built to take it when that comes.

### 2m. My Order — full plan (owner-directed) — BUILT 2026-08-01

The owner's complaint, verbatim in substance: reorganising entries is annoying,
hold-to-add still exists, and the previous pass "didn't plan or anything and
just build/rebuilder it without direction". So this is the direction, agreed
before any code.

**What it is for.** One thing only: knowing what you watch next, and in what
order, without having to re-decide it every time you open the app. It is the
one deliberately-ordered thing in an app whose founding law is that My List is a
memory, not a resume-queue. That is why it is capped and small.

**Confirmed decisions (owner, 2026-07-29).**
- Ordering: **real pointer drag, on the page.** The 1..15 numbers stay.
- Getting in: **a visible ⊕ in the card's number slot.** Press-and-hold comes
  off the plan cards entirely.

**What exists.** `plan_rank` (migration 11), `UP_NEXT_CAP = 15`, and a store
that is already correct: `commitPlanOrder` is a single dense committer that
forces the ranked set to exactly 1..N, releases orphans, and refuses to exceed
the cap however the data arrived — `reorderPlan(ids)`, `setPlanNumber`,
`addToPlanOrder` all funnel through it. **No schema or store work is needed for
any of this.** The page (`OrderPage.tsx`) is ↑/↓ buttons; the card
(`useHoldToAdd` in `QueueSlider.tsx`, ~140 lines of timers, slop tracking and
click suppression) is the hold.

**Why the last drag attempt failed, so this one does not repeat it.** It was a
hand-rolled pointer drag *inside a sheet*, and dragging a row down is the same
gesture as swiping the sheet closed. Every workaround it grew (the sheet
disabling its own dismissal mid-drag, absolutely-positioned rows moved by
transform so React could not re-parent them out from under pointer capture, a
constant row height so a Y could become an index) was a workaround for being in
a sheet. It is a page now. The remaining conflicts are real but different, and
each has an answer:

| Conflict | Answer |
|---|---|
| The app's drag-anywhere-to-scroll (`useViewportDragScroll`) | The drag starts **only** from a grip, which opts out via the existing `[data-sheet-nodrag]` convention. Dragging the row body still scrolls the page. |
| Native touch scrolling claiming the gesture | `touch-action: none` on the grip only, plus pointer capture. The rest of the row keeps native scroll. |
| 15 rows are taller than a 390px phone | Edge autoscroll while dragging within ~60px of the viewport top/bottom. Without this the order is only reorderable within one screenful, which is most of what "annoying" means. |
| React re-parenting mid-capture | Rows keep DOM order; the drag moves them by transform (FLIP) and commits one `reorderPlan(ids)` on release. Capture lives on the grip, which never moves in the DOM. |
| Touch and keyboard parity | The grip is a real button: Space/Enter picks up, ↑/↓ move, Enter drops, Escape cancels and restores. This *keeps* the current keyboard capability instead of trading it for a mouse-only gesture, and it is why the ↑/↓ buttons can go. |
| Reduced motion (this dev machine has it on) | No lift or spring; the row moves and the list settles instantly. The gesture must not depend on the animation to be legible. |

**The card's ⊕.** The number slot becomes the control rather than a badge that
only appears once numbered. Empty slot on a planned card = a ⊕ stamp; tap
appends at the next free number and the slot becomes that number; tap a number
to open the existing `NumberPicker`. At the cap the ⊕ is disabled and says so
on press (reuse the existing `full` label path — silently doing nothing is most
of why the old one felt broken). Every add is undoable through
`toast.action`, matching Start/Done. Deleting `useHoldToAdd` also removes a
gesture that had to fight a flinging list, its 170ms engage window, its slop
tracking and its click-suppression hack.

**What gets deleted, not left unreachable:** `useHoldToAdd`, the `.k-qhold`
sweep and label CSS, the `onQuickAdd` prop and its `PlanRoom` callback, and
`OrderPage`'s `move()` plus its ↑/↓ column.

**Risk to watch:** the ⊕ appears on every planned card, which is the exact
argument the code comment at `QueueSlider.tsx:220` makes against it ("an
affordance on all 1200 cards was noise"). That comment was written when the slot
was a *badge*; the owner has now asked for the slot to be a control. If it reads
as noise on a full wall of covers, the fallback is to show ⊕ only on hover/focus
on pointer devices and always on touch — cheap, and does not change the model.

**Build order.** (1) `OrderPage` drag + keyboard + autoscroll, behind no flag,
`reorderPlan` unchanged. (2) Card ⊕ slot + undo. (3) Delete the hold and the
↑/↓ path. (4) Gates: `tsc -b`, eslint, vitest, and a drag verified in the
browser pane at 1280 and 390 — including one drag that requires autoscroll,
since that is the case the old sheet could not do at all.

**BUILT 2026-08-01.** All four steps, `reorderPlan` and the store untouched as
predicted. The drag lives in a new `src/hooks/useReorderDrag.ts` rather than in
the page, because it is a gesture with its own lifecycle and the page is a list
with a search box under it.

- **The grip is the number.** Not a handle parked beside one: the figure you
  are moving is the thing you grab, so the row has one control for one idea.
  Ruled bars sit next to it as the affordance. It carries `data-nodrag` (that
  is `useViewportDragScroll`'s actual opt-out attribute — §2m's text above says
  `data-sheet-nodrag`, which is `BottomSheet`'s and does nothing on a page) and
  `touch-action: none`; the row body keeps `touch-action: auto`, so a finger
  anywhere else still scrolls natively. Verified both computed values.
- **Measured, not assumed.** The drag measures every row's `offsetTop` once on
  pointer-down. `offsetTop` is content space, so it survives the autoscroll
  that is about to move everything underneath; `getBoundingClientRect` would
  not. Travel is `clientY` delta plus the scroller's own delta, which is what
  keeps the row under the finger while the list moves.
- **One rAF loop drives the whole gesture**, reading the last pointer position
  rather than the event. That is what makes autoscroll work under a finger that
  has stopped moving, and it coalesces a high-Hz mouse to one layout pass per
  frame (the same rule the app already applies to drag-pan).
- **Undoing the hold.** `useHoldToAdd` (~90 lines of timers, slop tracking and
  a click-suppression hack), the `.k-qhold` sweep and label CSS, and the
  `onQuickAdd` prop are gone. So is `OrderPage`'s `move()` and its ↑/↓ column.
  Also removed as already-dead-by-then: `QueueCard`'s `onMove` /
  `canMoveEarlier` / `canMoveLater` and the `.k-qcard__move` CSS — nothing had
  passed `onMove` since the carousel came out, and `FranchiseCollection` was
  still declaring and forwarding it.
- **The ⊕ reveals on hover/focus and is always shown on touch**, not always
  visible as the plan text above says. Owner's call, and it lands the slot in
  the same reveal Start and Done already use, so the card has one set of
  controls that appear together instead of three behaviours.

**Two things the plan did not anticipate, both found by measuring:**

1. **The order page's number failed AA on both light plates.** It was
   `--color-accent-glow`, which is tuned for a dark ground: 2.74:1 on Vellum
   and Specimen Card. It is ink now, and the vermilion moved to the row
   actually in your hand. That is also the better reading of the One Ink Rule:
   on a plan CARD the vermilion number means membership (this one is in the
   order, those are not), but on this page every row is in the order, so
   fifteen stamps down a column carry no information. The grip bars moved
   tertiary → secondary for the same reason (2.96:1 on Specimen Card for the
   only thing saying the row can be moved).
2. **`--color-bg` is not a token.** The row background was written against it
   and silently resolved to nothing, which would have let a lifted row read
   through the one beneath it. It is `--color-base`.

**Verified in the browser pane**, seeded list, both widths:
- Mouse drag at 1280: row 8 → 5, committed to the store, announced.
- Autoscroll drag: pointer held still in the bottom edge zone, `scrollTop`
  climbed 0 → 663 of 950 and carried the row from position 1 to 12 — further
  than one 739px screenful, the case the old sheet could not do at all.
- Touch-pointer drag at 390: position 1 → 4, committed. No horizontal overflow
  on either surface at 390; grip is 47×44.
- Keyboard: pick up, three arrows, Enter — committed at 4 of 12 with focus
  still on the grip. Escape after two moves restored the list and left the
  store untouched.
- Card ⊕: adds at the next free number with an Undo that round-trips; at the
  cap it carries `aria-disabled` and says "full at 15. Remove one to add
  another." instead of doing nothing. A real click hits the slot and does NOT
  raise the quick menu (the §2j stacking-context trap has not come back).
- Contrast by canvas readback on all 8 plates: worst 5.22:1 (held row's
  number), instruction line 6.44, number 6.09, grip bars 6.44, title 12.62.
  Held-row accent edge 3.18:1 against the 3:1 floor for a state boundary. The
  ⊕ over the brightest cover art possible: glyph 16.81:1, keyline 6.58:1,
  at-cap dimmed glyph 5.27:1.
- Gates: `tsc -b`, eslint, 179 vitest, `vite build` all green. `detect.mjs`
  reports only the pre-existing `transition: width` progress-bar warning.

**Environment notes for the next pass.** The browser pane's `left_click_drag`
does fire real `pointermove` (an earlier probe of mine simply forgot to listen
for it), so mouse drags CAN be driven end to end. Its `key` action, however,
sends keydown with an empty `key` and `code`, so keyboard paths have to be
driven by dispatched `KeyboardEvent`s. `@media (hover: none)` cannot be
exercised by resizing, since the pane keeps a mouse; the rule was verified to
exist and matches the one `.k-qcard__acts` already relies on.

**Still open from 2m's own risk note:** whether the ⊕ reads as noise in real
use. It is now hover-gated on pointer devices, which was the fallback, so the
remaining question is only about touch, where it is always visible.

### 2m-1. Self-review fixes — 2026-08-01

Ran /code-review, a dual-subagent /impeccable critique (31/40 heuristic
score), and an audit against §2m's shipped code, then validated the
franchise-grouping question above against real data. Four findings acted on
in this pass, owner-approved:

- **No undo on a completed reorder.** Remove and add both got a `toast.action`
  undo; a completed drag or keyboard drop didn't. `useReorderDrag.ts`'s
  `onCommit` now carries the pre-move order alongside the new one
  (`onCommit(next, previous)`), so `OrderPage.tsx` can fire "Reordered — Undo"
  without keeping its own shadow copy. Verified: End-key jump + Enter drop,
  Undo restores the exact prior order.
- **⊕ slot under the touch-target floor.** `.k-qcard__num` (shared by the
  numbered stamp and the ⊕ slot) was 42×42; both are 44×44 now, kept the same
  size deliberately so a card doesn't visibly resize the instant it gets
  numbered.
- **No Home/End for keyboard reordering.** Moving item 15 to 1 cost 14
  arrow-presses. `useReorderDrag.ts`'s held-row branch now handles `Home`/
  `End` alongside `ArrowUp`/`ArrowDown` through the same commit path; the
  on-page instruction line mentions it.
- **"My order" named two different things.** `PlanRoom.tsx`'s `order` sort
  option and the dedicated `/list/plan/order` page shared the exact string —
  picking the sort just re-sorts the grid, the page manages the 15-item
  shortlist itself. Sort label renamed to "Numbered first."

Two findings surfaced but not acted on: the ⊕ slot's `aria-disabled` (not
native `disabled`) at the cap is a deliberate, previously-verified choice
(matches `OrderPage`'s own always-clickable-at-cap pattern, the toast still
fires) that both the code-review and critique passes independently flagged
as under-documented — worth a comment, not a behavior change, left for a
later pass. A theoretical multi-pointer race in `onPointerDown` (guards
`heldRef`, not `startRef`, so a second simultaneous pointer on a different
grip could stomp shared drag state) is real but needs true multi-touch or
mouse+touch-simultaneous input to trigger — noted, not fixed this round.

Gates after this round: `tsc -b`, eslint, 179 vitest (incl. the updated
grouping fallback test), `detect.mjs` clean (same one pre-existing
progress-bar warning). Verified in browser: sort menu shows "Numbered first",
End-jump + undo round-trip, watching/completed episode-counter gate both
render correctly.

### 2n. Plan-card foresight for airing status — FIXED 2026-08-01

Owner's own testing surfaced this while asking about My Order: an unaired
title and a currently-airing title sat in the plan grid with Start/Done
looking exactly like any finished show's, and only found out they were
impossible by tapping and reading the toast bounce afterward.
`statusValidation.ts`'s guard was already centralized and already correct
(`updateStatus` in `listStore.ts` has always refused the write) — the bug was
that `QuickMenu`'s and `FranchiseSheet`'s status pickers grey out the
impossible option in advance via `getDisabledStatuses`, and `QueueSlider`'s
plan card was the one control that never asked.

Fixed by checking `statusBlockReason` directly in `QueueCard` against
`displayEntry.airing_status` and passing the result to `disabled` +
`aria-label` + `title` on each button. An unaired card now disables both
Start and Done; a currently-airing card disables only Done. The disabled
label reads the real reason ("This show hasn't aired yet…" / "…still airing,
so it can't be marked completed."), not a generic greyed-out button with no
explanation. New `.k-qcard__act:disabled` rule dims to 42% ink and swaps the
cursor; measured 3.68:1 over the brightest possible cover, which is below the
4.5 body-text floor by design — WCAG exempts disabled-control text for
exactly this reason, and washing it out IS the disabled signal; pushing it to
4.5 would blur the one thing this fix exists to make visible.

Verified in the browser: a seeded `RELEASING` card disables only Done with the
airing reason; a seeded `NOT_YET_RELEASED` card disables both with the
not-yet-aired reason; clicking a disabled button is inert (status unchanged
in the store). Gates green, `detect.mjs` unchanged (same pre-existing
progress-bar warning).

**Noted, not built this round (owner: "just note it, don't build yet").**
Two related gaps surfaced in the same conversation, both real:

1. **No way to reverse a status change once the 5-second undo toast closes.**
   Every status-change action (Start, Done, hold, drop, plan add/remove) has
   exactly one safety net: the toast's Undo button, live for 5 seconds. After
   that the only path back is reopening the card and picking a different
   status by hand through the quick menu. There is no "my last action" or any
   longer grace window.
2. **No activity log across the app.** `completion_log` (2h) is the only
   append-only record that exists, and it only records completions and
   rewatches. A Start, an on-hold, a drop, a plan add/remove, or an accidental
   status flip leaves no trace once its column is overwritten — `started_at`
   holds whatever the current run's start time is, not a history of every
   time it was set. "What did I touch in this app last week" has no answer
   anywhere in the app today, not on Overview, not in Stats, not in Settings.

If either is picked up later, decide it as its own owner-approved brief (a
longer undo window is a small, contained change; a real activity log is
schema-level work closer in shape to 2h's `completion_log` than to a UI
tweak) — not folded into an unrelated build.

**Scoped 2026-08-01** as `docs/LOGGING_SYSTEM_BRIEF.md` — two separate
systems: a per-device `debug_log` ring buffer exported from a new Settings
Diagnostics section for bug reports, and a permanent, cross-device
`activity_log` (completion_log's shape) that answers "what did I do" with a
bounded undo window, surfaced somewhere deliberately low-profile (candidate
placements listed, not decided — needs the usual structure-pick step). Not
built.

### 3a-1. Franchise grouping — mixed-status season bug, found 2026-08-01

Owner asked how grouping/ordering handles a franchise where seasons carry
different statuses (some untracked, one completed, one planned, one dropped)
— confirmed CORRECT for the common case and found one real, if narrow, bug
in the uncommon one. Investigated `grouping.ts`, `watchOrder.ts`,
`FranchiseCard.tsx`, `FranchiseSheet.tsx`.

**Correct today:** `pickDisplayEntry`'s priority ladder (watching/rewatching
> planned > on_hold > completed > dropped) resolves a mixed-status franchise
to the right "current" entry whenever ANYTHING is active or planned — a
franchise with S1 untracked, S3 completed, S4 planned, S5 dropped correctly
shows S4 as the card's display entry (root-cause-#1's story-position
tie-break, fixed 2026-07-28, only matters for TIES between same-status
entries, and this case has none). Rooms scope by status (Planned room shows
only the planned member as a card; Completed only the completed one), by
design — opening the loupe (`FranchiseSheet`) re-resolves full franchise
membership independently and correctly shows every season regardless of
which room you opened it from, including untracked ones as "Add" rows via
the live AniList walk.

**Bug found:** `pickDisplayEntry`'s terminal fallback (nothing active,
planned, or on hold — everything tracked is completed or dropped) is:
```
const root = sortedEntries.find((e) => e.anilist_id === rootId);
return root ?? sortedEntries[0];
```
`sortedEntries` is sorted by `added_at` (groupEntries.ts:123). When the
franchise's TRUE root season was never tracked — never added, or muted
not_interested (groupEntries drops not_interested entirely, so it hits this
same path) — `find` fails and the fallback silently reverts to whichever
tracked entry was added to the list FIRST CHRONOLOGICALLY, not whichever is
story-earliest. This is the exact bug class root-cause-#1 already fixed
(added_at winning over story position), reintroduced specifically in this one
fallback branch. It is not an oversight nobody thought about — `grouping.test.ts`
has a test asserting exactly this added_at-order behavior ("falls back to the
earliest member when the root is not tracked"), so it is tested and
intentional, just narrower than the fix that inspired it.

**How often it actually happens, checked against real data**
(`devdata/konsou-real-list.json`, 6500 real AniList-backed entries): 1,049
multi-season franchises, 39 with an untracked root, 6 of those with every
tracked member completed/dropped (the exact trigger condition) — and of those
6, half (3) produce a visibly wrong card: **Kyoukaisenjou no Horizon II's
cover and status represent the franchise card instead of the original
Horizon**, because II happened to be added to the list before I. Rare (0.3%
of multi-season franchises in this dataset), narrow, but real and reproduced
with an actual title, not a hypothetical.

**FIXED 2026-08-01.** The terminal fallback now calls `earliest(() => true)`
(the same story-rank helper the function already uses above it) instead of
indexing `sortedEntries[0]`. `grouping.test.ts`'s "falls back..." test
(renamed to "falls back to story position, not added_at, when the root is not
tracked") now asserts the story-correct pick (id 2) instead of the
added_at-earliest one (id 3) it used to assert. `tsc -b`, eslint, and all 179
vitest tests (including the updated assertion) green.

**Also confirmed, real but separate — FIXED 2026-08-01.** `EpisodeCounter`
had no status gate at all — `AnimeDetail.tsx`'s tracking panel rendered it
unconditionally regardless of `entry.status`, so a user COULD manually
decrement a completed entry's episode count from the detail page, producing
a live `status: "completed"` + `episodes_watched` below `total_episodes` —
the literal "watched season 3 halfway but it says complete" case asked
about. (This never corrupted Stats or the ledger — `completion_log` captures
`episodes_at_completion` immutably at the moment of completion, per 2h — and
`SeasonBar`'s segment fill hardcodes 100% for `status === "completed"`
regardless of the live count, so the season bar never visibly broke either.
What DID go stale: `FranchiseCard`'s footer episode count, which sums raw
`episodes_watched` across all entries, and `FranchiseSheet`'s `SeasonRow`
meta line, which prints the raw `watched / total`.) The tracking panel now
renders the editable `EpisodeCounter` only while `watching`/`rewatching` —
the same gate `FranchiseSheet`'s `SeasonRow` already used — and a plain mono
`watched / total` reading (`.k-track__epstatic`) otherwise, so a completed
entry has no control that could produce the mismatch. Verified in browser:
watching shows the editable counter, completed shows the static reading.

### 2o. Owner review round 4 — 2026-08-01

Seven items. Four were concrete, fixable bugs (fixed below); three (the
quick-menu shell's DIM fidelity, a full Watching-card rework, and where the
two meet) are real open design work, scoped here and NOT built — they need
the same critique-then-build process every other surface in this rework has
gone through, not a blind pass.

**FIXED — episode logging past what has actually aired.** Repro: a 12-episode
show airing only up to episode 5 let the app log all the way to 12 and mark
it complete. Root cause: `episodes_watched` was only ever clamped to
`total_episodes`; nothing clamped it to `aired_episodes` (the field already
existed, computed by `airedEpisodes()` in `format.ts`, refreshed on a detail
visit or the background airing scan — but never READ anywhere). Worse, the
RELEASING → completed guard has a deliberate escape hatch for exactly this
case ("AniList's status can lag a finale" — `finishedByCount` in
`listStore.ts`), which the missing clamp let a user walk straight through:
push watched to the total by hand, and Complete goes through despite the show
still airing. Fixed at the single choke point every caller already goes
through — `listStore.setEpisodes` — with a ceiling of
`min(total_episodes, aired_episodes)` while `airing_status === "RELEASING"`,
plus an error toast ("Only 5 of 12 episodes have aired so far.") so hitting it
explains itself rather than silently doing nothing. `useEpisodeIncrement`'s
optimistic rapid-tap accumulator got the same ceiling (a separate `ceiling`
option, kept apart from `total` because `total` still has to drive the
"reached the finale" prompt correctly — catching up to today's episode is not
a finale). `EpisodeCounter` gained an `airedCeiling` prop so its own +/- and
typed-entry paths agree with the store, and disables the "+" with "No new
episode yet" instead of just bouncing a toast after the tap — same
foresight-over-bounce pattern as the plan card's Start/Done guard (2n).
Threaded into all three `EpisodeCounter` call sites (`AnimeDetail.tsx`,
`QuickMenu.tsx`, `FranchiseSheet.tsx`'s `SeasonRow`) and, since they call
`incrementEpisodes` directly rather than through the counter widget, into the
Watching room's `HeroCard` "+Ep" button and Overview's on-now +1 stamp too —
both got the same ceiling computation for their own `atMax` gate, so a
still-airing card everywhere in the app now looks disabled at the true
ceiling instead of only the eventual one. Verified end to end in the browser:
a seeded 12-total/5-aired/RELEASING entry allows 3→4→5, then locks with "No
new episode yet" and stays locked. Gates green throughout.

**FIXED — search-field focus rings looked wrong, reported by users.** Traced,
not guessed: three different search fields (`RoomHeader`'s room search,
`FilterMenu`'s tag-search find box, `CommandPalette`) each suppressed their
input's own `outline` on focus but never gave the field container anything to
replace it with, so keyboard focus was either invisible (`RoomHeader`,
`FilterMenu`) or fell through to the bare global `:focus-visible` default
drawn tight around a borderless, background-less input crammed inline next to
a search icon (`CommandPalette`) — a small floating rectangle that read as a
stray line clipping across its own row rather than a field lighting up. The
ONE correct implementation already existed (`OrderPage`'s `.k-ordadd__search`:
container has a real border, `:focus-within` thickens it to accent, the input
itself always sets `outline: none`) — the fix was applying that exact pattern
to the three broken ones. Also hardened the global default itself:
`:focus-visible` → `:where(:focus-visible)` in `global.css`, so any
component's own focus treatment always wins outright rather than depending on
which stylesheet happens to load later (a bare `.some-class{outline:none}`
used to be able to TIE with the global rule on specificity, with source order
deciding the winner — `.k-input` was one such case). Verified live via real
keyboard `Tab` navigation (the only way to trigger genuine `:focus-visible`;
programmatic `.focus()` does not) on both `RoomHeader`'s field and
`CommandPalette`: outline gone, container border/rule correctly thickens to
the real accent color. Gates green, detector clean.

**FIXED — `NumberPicker` was the one quick menu left on the old shell.** Owner
correctly named this: "that menu didn't get a repolish and was unaffected
during the overhaul." Confirmed in code — `NumberPicker.tsx` called
`<BottomSheet>` directly, bypassing `ItemSurface` entirely, so tapping a
numbered card's badge opened a full-width mobile-style sheet on EVERY window
size, while every other quick menu (`QuickMenu`, `FranchiseSheet`,
`FilterMenu`) had already been migrated to `ItemSurface`'s anchor-on-desktop /
sheet-on-phone split (2k, 2l item 4). Fixed by threading the tapped element
through as an anchor (`QueueCard`'s number button now passes
`e.currentTarget`, same pattern `FranchiseCollection` already uses for its
own card-open anchor) and swapping `NumberPicker`'s render from `BottomSheet`
to `ItemSurface`. Verified in the browser at both widths: 1280px opens a
320px anchored popover (`.k-pop`) next to the card, picking a slot commits
and closes it correctly; 390px still gets the drag-to-dismiss sheet. Gates
green, detector clean.

**SCOPED, NOT BUILT — quick-menu shell fidelity + Watching card overhaul.**
The owner asked to study DIM's real source (not go from memory) and adapt it,
and to fully rework the Watching card. Cloned DIM's actual repo to
`reference/dim/` (gitignored, eslint-ignored — a third-party reference clone,
never Konsou's own code, never committed) so this and future passes can read
the real thing instead of guessing. Findings from `reference/dim/src/app/
item-popup/ItemPopup.tsx`, `.m.scss`, `dim-ui/usePopper.ts`, `dim-ui/Sheet.tsx`:

- **We already have DIM's core shape**, contrary to how it reads in daily use.
  `ItemSurface` IS the single shell every quick menu should draw from (DIM's
  own `ItemPopup` is the same idea: one component, phone gets `<Sheet>`,
  everything else gets a positioned popover) — confirmed above that
  `NumberPicker` was the one holdout, now fixed. `AnchoredPopover`'s hand-rolled
  placement (right-preferred, flip, shift, arrow-follows-anchor) was already
  explicitly modeled on DIM's `usePopper` (which wraps `@floating-ui/dom`'s
  `autoPlacement`/`flip`/`shift`/`arrow` middleware) rather than copied from
  it — a considered trade-off (documented at the time: "~60 lines" instead of
  a dependency), but §2l's two placement bugs found in this exact code (cap
  vs. real height, the toolbar upward-limit) are the kind of bug a
  battle-tested positioning library exists specifically to not have. Worth an
  explicit owner decision next round: keep hardening the hand-rolled version,
  or adopt `@floating-ui/dom` now that real bugs have surfaced twice.
- **What DIM does that we don't: the shell's CONTENT changes shape between
  desktop and phone, not just its container.** DIM's desktop popup keeps a
  PERSISTENT side column of action buttons next to the popup
  (`DesktopItemActions`, always visible, never behind a hover/reveal) while
  the phone `<Sheet>` folds the equivalent controls into a header strip and a
  footer — two genuinely different layouts built from the same data, not one
  layout resized. Our `QuickMenu`/`FranchiseSheet` render the identical
  children in both the popover and the sheet — same content, different
  wrapper — which is very likely the concrete thing behind "even if the
  window is big you compared to small is the same as our old one." This is
  the one real structural gap between our shell and DIM's, and it's a
  genuine design decision (what would a Konsou-specific "desktop gets more"
  treatment even be?), not a bug to patch.
- **Visual distinctness at rest.** DIM's popup carries a rarity-tinted
  near-black background per item, a colored arrow, and (desktop only) a
  `box-shadow: 0 0 0 1px border, drop-shadow` — real separation from the
  app chrome behind it. Worth measuring whether `.k-pop`'s current keyline +
  shadow reads with the same separation over a busy background, or gets lost
  the way the owner described ("blends in").
- **`reference/dim/`** is the concrete artifact to open directly for the next
  pass rather than working from this summary — `item-popup/ItemPopup.tsx` +
  `.m.scss` for the shell, `dim-ui/Sheet.tsx` for the phone sheet (motion/react
  spring physics, drag-to-dismiss thresholds — already matched in our own
  `BottomSheet` per 2k), `dim-ui/usePopper.ts` for the desktop positioning.

**Watching card (`HeroBinge.tsx`'s `HeroCard`, the Watching room's variant)
not reworked, per owner's own framing as a full overhaul, not a patch.** Two
small parity fixes landed on it anyway (above): the "+Ep" button's disabled
state now respects the aired ceiling, matching the store-level fix. Structural
rework — visual language, layout, what "add ep and such" should look like in
the current world — needs the same critique → brief → structures → owner
picks → build loop as every other surface, seeded by the DIM findings above
(does a wider window unlock more here too?) plus a fresh look at the card
against the committed Field Guide world now that the plan-card and Completed
ledger have both been through full rebuilds and this one hasn't.

**Episode-release / aired-cap interaction — code-reviewed, real gap found and
FIXED 2026-08-01.** Owner asked specifically how a real episode releasing
interacts with the aired-episode ceiling (2n's earlier fix), and how a
long-running series with no fixed total (One Piece, 1000+ episodes) is
handled — not a hypothetical, a direct request to simulate it.

Traced every place `aired_episodes` gets written. Two existed already: a
visit to that title's own `AnimeDetail` page (patches that one entry), and a
visit to the Airing tab's Episodes panel (patches every watching/rewatching/
plan_to_watch entry it fetches a schedule for, in one batch). Neither is
guaranteed — someone who only ever logs episodes from the Watching room's own
card, QuickMenu, or Overview's on-now stamp would never trigger either path,
so `aired_episodes` would freeze at whatever it was when the title was added
and eventually start blocking episodes that had genuinely aired since. The
periodic background scan (`runScheduledScan`, already running for sequel
detection and the plan-to-watch "started airing" alert) covered neither case —
`scanPlanToWatchAirings` only ever touched `plan_to_watch` entries checking
for a NOT_YET_RELEASED → RELEASING flip, nothing for an already-watching one.

**Fixed**: extended that same function (reusing its existing batched
`getAiringStatusBatch` call rather than adding a second network round-trip
per scan cycle) to also silently refresh `aired_episodes`/`total_episodes`/
`airing_status` for every watching/rewatching entry currently RELEASING, no
notification, value-guarded so an unchanged count writes nothing. Now the
ceiling stays caught up on the same background cycle as everything else,
regardless of which screen the user happens to visit.

**Also found in the same pass**: the error toast that fires when someone hits
the ceiling read `Only ${ceiling} of ${max} episodes have aired so far`,
where `max` falls back to `Number.MAX_SAFE_INTEGER` whenever `total_episodes`
is null — exactly One Piece's own shape (AniList reports no fixed total for
an ongoing long-runner). Fixed: the "of N" clause is only printed when a real
total exists.

**Long-running series themselves need no special handling** — `airedEpisodes()`
already resolves from `nextAiringEpisode.episode - 1` independent of whether
`total_episodes` is known, so a null total was never the actual risk; the
toast leaking the sentinel number was the only real symptom of it.

**Verified**: 5 new tests in `src/lib/sequel/airingScan.test.ts` — the
existing plan-to-watch notification path still fires correctly after the
refactor, a watching entry's aired count silently advances with no
notification, a null-total/1084-aired-episode entry (the One Piece shape)
resolves to 1085 with no invented total, an unchanged count writes nothing,
and a non-RELEASING watching entry never even calls the network. Live in the
browser: a null-total entry at 1084/1084 shows "Only 1084 episodes have aired
so far." with no giant sentinel number, and stays clamped. 184 vitest total,
`tsc -b`/eslint/detector all clean.

**Gates for this whole round:** `tsc -b`, eslint, 184 vitest, `detect.mjs`
clean on every touched file. Everything fixed above verified live in the
browser at 1280 and 390 where relevant.

**Positioning engine decision — ACTIONED 2026-08-01: adopted `@floating-ui/dom`
(1.8.0, matching `reference/dim/`'s own pinned version)**, replacing
`AnchoredPopover.tsx`'s hand-rolled placement math. `computePosition` with
`offset`/`flip` (right, falling back to left only — the only two sides the
CSS draws an arrow for) /`shift` (a *derivable* padding function, since the
upward clamp has to stay keyed to the anchor's own top, the exact §2l
toolbar bug) /`size` (replaces the manual `vh - topLimit - EDGE` cap math,
captured into React state via `apply` rather than left as an out-of-band DOM
mutation) /`arrow`. `autoUpdate` replaces the hand-rolled resize/scroll/
ResizeObserver trio outright. One real catch while wiring it up: `.k-pop`'s
own CSS is `position: fixed`, so `computePosition` needs
`strategy: "fixed"` explicitly — floating-ui's default is `"absolute"`, and
using that default would have placed everything at the right coordinates for
the wrong box model. Verified live: offset-right placement lands exactly
`anchor.right + 10`, the toolbar-anchor clamp still lands the popover at the
button's own top instead of a flat 64, and a real content measurement came
back 305px for 303px of content — the exact number recorded when this bug
was first fixed, now reproduced through the library instead of hand-rolled
math. `tsc -b`, eslint, 179 vitest, detector all clean; no new npm audit
findings (the 5 pre-existing high-severity advisories are unrelated deps —
eslint's `brace-expansion`, `js-yaml`, `postcss`, `react-router` — not
touched).

### 2p. Shell icon "cages" — audited + FIXED 2026-08-01

Owner: icons in the shell (headers, bottom nav, sidebar — explicitly not
cards) read like they're each trapped in their own box, unlike DIM's bare
feel, and the box makes the icon itself look tiny and cramps the app's own
spacing. Audited every shell chrome piece rather than guessing which one:

- `Sidebar.tsx` (`.k-sidebar__icon`, `.k-sidebar__item`) — already bare. The
  22px nav icon has no box of its own; the ROW gets a background on hover and
  a 3px accent notch when active, never a filled pill around the icon.
- `BottomNav.tsx` (`.k-bottomnav__icon`) — already bare, same story: an
  accent rule across the top edge marks the active tab, not a box.
- `Header.tsx` — minimal (mobile-only; desktop's header was already removed
  per the Examination-bench work). The one icon button is the account avatar,
  a circular seal with its own frame — a different, intentional pattern
  (an avatar/seal, not a plain icon control), left alone.
- `DetailTopBar` (`AnimeDetail.tsx`'s back/share buttons, class `.k-icon-btn`)
  — already correct: bare at rest, a background only appears on
  `:hover:not(:disabled)`.
- **`.k-roomhead__filter`** (`RoomHeader`'s search-toggle AND filter/sort
  button, reused a third time by `PlanRoom`'s "My order" door) — the actual
  cage. A permanently visible `border: 1px solid` + filled `background` sat
  around a 17px glyph in a 40×40 box, at rest, not just on interaction —
  sitting in the same header row as `.k-roomtop__back`, which was already
  bare. This was a second, inconsistent icon-button convention living beside
  the app's own correct one (`.k-icon-btn`), not a deliberate choice.

**Fixed**: `.k-roomhead__filter` now matches `.k-icon-btn`'s already-correct
rule — border and background are transparent at rest, and only appear on
hover, on `[aria-expanded="true"]` (the FilterMenu trigger's own open state),
or via the `--on` modifier (a real state signal — an active filter or a
populated "My order" door — kept visible, since that is information, not
decoration). Nothing invented: this is the app's own existing correct pattern
applied to the one place that had drifted from it.

Verified live: `.k-roomhead__filter`'s computed border/background are fully
transparent at rest across all three reuses (room search, "My order" door,
filter/sort), the FilterMenu trigger correctly shows the surface tint once
`aria-expanded="true"`, no console errors. `tsc -b`, eslint, 184 vitest,
detector all clean (pure CSS change, no logic touched).

Not audited further this round: Discover/Airing/Stats page headers have no
icon buttons of their own beyond what RoomHeader/FilterMenu already provide
(checked, none found) — if a future surface pass on Discover adds its own
icon controls, hold them to `.k-icon-btn`'s rule, not a fresh box.

### 2q. HUGE BUG — nested quick-menu overlays — FOUND + FIXED 2026-08-01

Owner: opening the quick menu, then tapping a season's status stamp to
change its status, showed the status picker (Watching/Completed/Planned/
Dropped/etc.) appearing UNDER the quick menu, and closing it (or clicking
outside) left it "persistent" — reopening the quick menu brought the status
picker back up already open, unprompted.

Reproduced exactly, live, before touching anything: seeded a 2-season
franchise, opened it from the Watching room, tapped a season's status stamp.
Screenshot confirmed the status picker's third column (`Plan to Watch`,
`Rewatching`) rendered visibly behind the still-open quick menu. A real click
at that exact spot did nothing — clamped, no status change, no error — the
click was silently absorbed by the quick menu sitting on top. Closing via an
outside click and reopening the quick menu brought the status picker straight
back up, unprompted, exactly as reported.

**Three compounding root causes, all in the shared shell** (`AnchoredPopover`,
`BottomSheet`, `StatusSheet` — none of this was specific to franchises or to
the Watching room; anywhere a quick menu opens a status picker on top of
itself hits the same bug):

1. **Static, conflicting z-index.** `.k-pop` (the quick menu popover) was
   fixed at `z-index: 120`; `.k-sheet-overlay` (`StatusSheet`'s `BottomSheet`)
   was fixed at `100`. Whichever opened SECOND still rendered at its own
   fixed number — a status picker opened from inside an already-open quick
   menu rendered BEHIND it, not on top, regardless of open order.
2. **Outside-click misattribution.** `AnchoredPopover`'s "click outside,
   close me" listener only knew its own element and its own anchor. A click
   anywhere on the status picker — a different overlay, portaled as a
   sibling, not a descendant — looked exactly like a click on the page
   behind everything, so trying to use (or dismiss) the status picker
   silently closed the quick menu underneath it as a side effect.
3. **State never reset.** Because the outer close happened through the quick
   menu's own listener rather than through the status picker's own `onClose`,
   the status picker's "which title is this for" state (`pendingStatusId` in
   `FranchiseSheet`) never got reset. The picker didn't visually persist — the
   STATE did, invisibly, so the next open found it still set and the picker
   reappeared already open.

**Fixed** by extending `sheetStack.ts` (previously just the hardware-back
registry) into a small shared overlay registry:
- `acquireOverlayZIndex()` — a shared incrementing counter (based at 1000,
  clear of every static z-index already in the app), handed out once per
  open, not per render. `AnchoredPopover` and `BottomSheet` both now apply
  this as an inline `zIndex`, overriding their CSS classes' static values, so
  whichever overlay opened LAST always paints on top — matching how DIM's own
  `Sheet` takes an explicit `zIndex` prop for the identical reason (stacking
  a sheet on another sheet, or on the item popup).
- `registerOverlayElement()` / `isInsideAnotherOverlay()` — both components
  register their own root element while open; `AnchoredPopover`'s outside-
  click check now also ignores a click that lands inside a DIFFERENT
  registered overlay, so a click meant for the status picker can never be
  mistaken for a click on the page behind everything.

No component using these primitives needed its own fix — `FranchiseSheet`,
`QuickMenu`, and every other `ItemSurface`/`StatusSheet` consumer inherits
the fix automatically, since it lives in the shared shell, not in any one
caller.

**Verified live**, the exact original repro: quick menu re-opened, status
stamp tapped, all 7 status options now measured on top (`elementFromPoint`
resolves to the option itself, not the quick menu, at every one); a real
click on the previously-dead "Plan to Watch" spot correctly changed the
entry's status (confirmed in the store); closing via an outside click now
closes only the topmost overlay (an improvement over the old both-close-at-
once — matches native modal-stacking convention) and leaves the status
picker's own state properly reset; reopening the quick menu no longer
resurrects the status picker. `tsc -b`, eslint, 184 vitest, detector all
clean; no console errors at any step.

### 2r. `/impeccable harden` — airing-limited "+" buttons had no toast

Owner: the Watching room and Overview had no toast when a still-airing show
hit the aired-episode ceiling (2n) and someone tried to log another episode.

Root cause: `HeroCard`'s "+Ep" and Overview's on-now "+1" both used native
`disabled={atMax}`. A natively disabled button never fires its `onClick` at
all — so even though both already called `incrementEpisodes`, which routes to
`listStore.setEpisodes` (already showing "Only N of M episodes have aired so
far." per 2o), the click never happened, so the toast that was already
correctly wired up never got a chance to fire. `EpisodeCounter`'s own "+"
(QuickMenu, FranchiseSheet, AnimeDetail) had a second, different version of
the same gap: `useEpisodeIncrement`'s rapid-tap accumulator guards BEFORE
ever calling `setEpisodes` at all (by design — that guard is what makes a
burst of taps safe), so even an un-disabled click would never reach the
store's toast either.

**Fixed**, matching the `aria-disabled`-not-`disabled` pattern this session
already established for the plan card's ⊕ slot: both buttons now stay
clickable when blocked ONLY by the aired ceiling (a genuinely finished run —
`atMax` for its own total, nothing airing-limited about it — keeps native
`disabled`, since there is nothing left to explain). `useEpisodeIncrement`
gained an `onBlocked` callback, fired from the exact guard that used to
return silently, so `EpisodeCounter` can toast "No new episode yet." itself
since its own accumulator never reaches the store to trigger one on its own.

**Verified live**, all three surfaces, same seeded entry (12 total, 5 aired,
RELEASING): `HeroCard`'s "+Ep" → `"Only 5 of 12 episodes have aired so
far."`; Overview's on-now stamp → the same; `EpisodeCounter`'s "+" in
QuickMenu → `"No new episode yet."`; all three confirmed `aria-disabled`
(not natively `disabled`) and watched count stayed clamped at 5 after the
click. Re-verified the genuinely-finished case (12/12, FINISHED) still gets
real `disabled` with no `aria-disabled` — no regression there. `tsc -b`,
eslint, 184 vitest, detector all clean (same 3 pre-existing progress-bar
warnings, unrelated).

### 2s. `/impeccable adapt` — Overview's fluid responsive rework — 2026-08-02

Owner: the wide-Overview pass (doors capped, Watching field as a `HeroCard`
grid, the sequence strip) looked right at the two widths it was built at, but
scaling across the real range exposed the actual defect — the whole app is
binary breakpoint swaps (35× `min-width: 1024px`, 3 total `clamp()` uses
project-wide), so Overview had exactly three states (phone / "not-phone" /
1280px-wide) with a dead 700–1279px zone that rendered identically to a
phone at 3x the width.

Studied `reference/dim`'s own tile grids
(`TileGrid.m.scss`/`CollectiblesGrid.m.scss`:
`grid-template-columns: repeat(auto-fill, minmax(var(--tile-grid-width, 250px), 1fr))`)
and the Spotify Queue-panel precedent the owner supplied: **breakpoints gate
structural reveals (a panel appears, a density tier changes); everything else
(spacing, grid column count) should be content-driven (`auto-fill`/`minmax`)
or fluid (`clamp()`), never a breakpoint swap.**

**Fixed** against that model:
- Two new fluid tokens in `tokens.css` — `--gutter` and `--gap-section`,
  both `clamp()` over a 375px–1600px range (matches `--launch-max`'s own
  ceiling). Additive to the existing fixed `--space-*` scale, which stays
  fixed on purpose: component-internal spacing (button padding, icon gaps)
  shouldn't grow just because the window is wider — only page/section-level
  spacing reaches for these. Reach for `--gutter` for page-edge padding and
  `--gap-section` for the gap between major stacked blocks on a page; keep
  `--space-*` for everything inside a component.
- `.k-onnow--field .k-onnow__field`'s column count (previously a manual
  2-at-1280px/3-at-1680px breakpoint swap) is now one
  `repeat(auto-fill, minmax(340px, 1fr))` rule — reflows continuously with
  no per-breakpoint math and no edit needed for a bigger monitor. **This is
  the pattern to reach for on any future grid of same-sized cards** —
  `FranchiseCollection` already does the JS/`ResizeObserver` equivalent of
  this and didn't need changing.
- `WatchingShelf`'s `"field"` variant now reveals at `isDesktop` (1024px)
  instead of `isWide` (1280px), independently of the sequence strip's own
  gate — the strip stays a genuine structural reveal at 1280px (new content
  appearing, the Spotify Queue-panel equivalent), but the field itself had
  no reason to wait for it.
- `.k-strip__item` width: `clamp(76px, 6vw, 96px)` replacing its own
  1280px breakpoint swap.

**Verified live** at a full width sweep (320/900/1150/1400/1900px, each a
fresh reload — matchMedia is stale on resize alone in this pane): no
horizontal scroll at any width, gutter/gap grow continuously (16px→26px→…),
the Watching field appears at 1024px with real `HeroCard`s (not a copy of the
phone line), the sequence strip only appears at 1280px as designed, and
`auto-fill` alone produced a 3rd field column at 1900px with zero rule for
it. `tsc -b`, eslint, 184 vitest, detector all clean (2 pre-existing findings
elsewhere in `pages.css`, unrelated to this pass). Not touched this pass,
flagged as the next candidate for the same treatment: Sidebar/BottomNav/
AppShell's own breakpoint logic, and the rest of the app's `--space-*`/
`--text-*` scale (deliberately left fixed — see above).

### 2t. 2s corrected — the real composition, not just fluid spacing — 2026-08-02

Owner pushback on 2s, with a screenshot: at max window the fluid tokens were
real but invisible — the actual defect (a huge blank rectangle beside the
capped door pair, and dead space below "Add something") was never touched.
Root cause: doors sat on their own full-width row (capped at 700px to stay
square) with the field stacked in a second row below, so the whole width
beside the doors and above the field was just empty table.

Before rebuilding, checked the specific repos the owner named (AniTrack,
VoidX3D's Anime-Tracker, etc.) by reading their actual source, not their
READMEs — worth recording since their claims didn't hold up: AniTrack's
entire "explicit breakpoint system" is one CSS rule shrinking a `minmax` at
two breakpoints; VoidX3D's Anime-Tracker has **zero** media queries in its
whole stylesheet. Their "fully responsive" claims are marketing copy over the
same single `auto-fill` grid rule already in Konsou. Not useful references
for "different component trees per tier" — none of them actually do that.

**Rebuilt** as three real lanes instead of doors-row-then-field-row: an index
rail (doors stacked, not side by side — a rail this width can't fit two
squares across) beside a field column beside the sequence-strip dock, all
three sharing one row so nothing sits beside empty table. Bumped
`FIELD_ROWS_WIDE` 6→9 (only at `isWide`; the 1024–1279 tier stays at 6, since
more items there is just more scrolling, no extra width to spend it on) and
the Up Next dock 8→12, so the page's content reaches further down the
viewport instead of stopping short.

**The no-Watching gap** (owner interrupt, mid-build): the field column only
ever showed Watching, so someone who only uses Planned/Completed hit the
exact blank-column defect just fixed, but permanently. Owner picked a
cascade: Watching first, then the Planned queue (`PlannedField`, reusing
`QueueCard` — the plan room's own poster card, same reuse discipline as
`HeroCard`), then a plain invitation (`EmptyField`) only when both are empty.
Verified live by flipping the seed's own statuses in place (watching→planned,
then planned→completed) and reloading — all three states confirmed correct.

**The new block, not a resize**: `ThisWeek`, gated to `isWide` — hours
watched, titles finished, titles added, all real numbers from
`completionStore`'s dated events and the list's own `added_at` (explicitly
NOT a fabricated "streak"; the ledger only dates a *finish*, not every
episode tap, so "hours this week" honestly means watches completed this
week).

**A real bug found and fixed mid-build**: `grid-row: 1 / span 2` placement
(the whole session's approach up to this point) reintroduced the exact same
dead-space class of bug it was supposed to fix, because CSS auto-tracks size
against every item touching a row — doors (single-row) forced row 1 to its
own full 616px height, and the field (spanning that row) sat top-aligned in
a taller area than its own content needed, stranding `ThisWeek` ~294px below
where it should render. **Fixed by abandoning row-spanning entirely**: each
column is now its own `flex-direction: column` wrapper (`.k-col-doors`,
`.k-col-field` in Overview.tsx) that stacks to whatever height its own
content needs, independent of its neighbors. Grid-row spanning across columns
of unequal, dynamic content is the trap to remember here — a column that owns
its own flow is the fix, not a bigger `grid-template-rows` guess.

Verified live: `.k-onnow` → `.k-thisweek` gap is exactly `--gap-section`
(40px), not the 294px the row-spanning version produced; exactly one
`.k-launch__add` renders at every tier (it moved from a trailing page element
to living inside `.k-col-doors` at `isWide`, so it needed an explicit
`!isWide`/`isWide` split to avoid rendering twice). `tsc -b`, eslint, 184
vitest, detector all clean (same pre-existing findings).

### 2u. The desk — Overview's desktop-max overhaul (owner-picked) — 2026-08-02

Owner, after 2s and 2t both failed to satisfy: *"components still feel exactly
the same… it doesn't feel representing, organized… completed and planned is
most important… desktop mode feels small insignificant… no hierarchy,
disconnected… no new information revealed… no new functions for desktop users
running max sizing windows."*

They were right, and 2t had actively made it worse: the two surfaces this app
exists for (the record, and the queue) had been demoted to 300px count-plates
in a side rail, while Watching — the one status **nobody is obliged to use** —
took the entire middle. Hierarchy exactly inverted against the founding why.

**Process correction, and the real lesson of this whole session:** §3 of this
very document and the `konsou_completed_room_direction` memory both say to
show mockups and let the owner pick a structure before building this surface.
Three passes were built without doing that, and all three were rejected. The
fourth started by rolling four structures as wireframes
(`mcp__visualize__show_widget`), all of which led with Planned/Completed; the
owner picked **B, the archive desk**, scope desktop-max only.

Also checked the reference repos the owner named by reading their actual
source rather than their READMEs, and they do not support their own claims:
AniTrack's "explicit breakpoint system" is one rule shrinking a `minmax` at
two breakpoints; VoidX3D's Anime-Tracker has **zero** media queries in its
entire stylesheet. Neither builds different component trees per tier. Not
useful references; recorded so nobody re-derives that.

**Built** — `.k-desk`, a genuinely separate component tree at `isWide`, not
the launcher rearranged (the launcher still renders unchanged below 1280):
- **What's on now** is a strip across the top that keeps its one-tap log
  (a hard constraint from the surface brief) but stops being the main event.
  Its rows lay out in content-driven columns, since three ruled lines each
  stretched across 1700px is the same "resized, not adapted" failure.
- **The archive is the surface**: `Archive`, the completion ledger sliced by
  year, with a year index (each year + its count) and that year's covers as
  the content, capped at `ARCHIVE_WALL` with an honest "N more in YYYY" into
  the room. Reuses the Completed room's own decision (a year is the landmark;
  every view bounded, every view counted) without duplicating the room —
  filters, dropped, ghosts, search and the two renditions stay the room's.
- **The plan docks the right edge** as a working rail: `PlanDock` lists the
  hand-numbered watch order, falls back to the plan's own order when nothing
  is numbered (with the index rendered softer, so an accident never
  impersonates a decision), shows the backlog's **weight in hours** (turning
  a dead 1,253 into something you can decide against), and carries a direct
  route into the order page that was two navigations deep.
- `ThisWeek` (from 2t) stays, under the archive.

**New at desktop-max that exists nowhere else:** the year index, per-year
counts, the cover wall, backlog hours, and the order-page route. That was the
owner's actual complaint — no new information or function at max width — and
it is what the previous three passes never delivered.

**Verified live** at 390 / 1150 / 1913px (fresh reload each; matchMedia is
stale on resize alone in this pane): mobile and desktop-normal are untouched
(launcher + doors + 6-card field, one add button, no horizontal scroll); at
1913 the desk shows an 8-year index built from a multi-year seeded ledger,
year switching works (clicked 2022 → 17 covers; 2025 → 24 + "7 more in
2025"), archive and dock start at the same top, this-week sits exactly one
`--gap-section` under the archive, the wall auto-fills to 10 columns, and the
page overflows the viewport rather than ending in dead space. `tsc -b`,
eslint, 184 vitest all clean; detector shows only the 2 pre-existing findings
elsewhere in `pages.css`.

**Not done:** mobile and desktop-normal keep today's launcher by the owner's
own scope choice. `UpNextRun` was deleted (superseded by `PlanDock`).

### 2v. The desk, revised — plates lead the greeting tab — 2026-08-03

Owner on 2u: *"the execution is good but the experience on full desktop is more
complicated than any other view… Completed and planned doesn't feel like it's
the header, fancy, sections… it feels like a wall of info and not presented…
so boring to look at, not a Konsou recognize panel. When you open MyAnimeList
you know it's MAL. I liked what I have in the smaller panels, just a bit more
flair."*

Diagnosis: 2u deleted the one device the app is **recognised** by. The door
plate — mounted covers behind a keyline, photo-corners, engraved count,
NEXT/LAST line — is Konsou's signature, and at desk width it had been replaced
with a mono text label over a grid of cover tiles. Correct information,
zero identity: a spreadsheet, not a field guide.

Rolled three masthead treatments as mockups first (per §2u's own lesson).
Owner picked **both plates lead**, and reframed the content in free text:
- **My Order is genuinely useful on big desktop — keep it out.**
- **Watching: minimal but still functional**, don't hide it; its depth belongs
  in the room, not on the launcher.
- **Completed must NOT be shown outright here** — the archive gets its own
  room and its own dashboard later ("like a prestige"), so exploding it on the
  greeting tab was the wrong call.
- **Sequels off the desk** (they have the Airing tab).
- **My List is the greeting tab, so it has to look good.**

**Built:**
- `.k-desk__lead` — the two plates side by side at desk scale, equal width,
  heading the page: `height: clamp(240px, 20vw, 360px)`, count at
  `clamp(38px, 3.4vw, 56px)`, and a new `coverCount` prop on `RoomDoor` so the
  desk fans **6** covers where the phone fans 4. Same component, same world,
  bigger job — no second hand-built copy (see the build-once rule).
- The `Archive` component and all its plumbing (year rail, cover wall,
  `ArchiveCover`, the archive memo, `archiveYear` state, `ARCHIVE_WALL`)
  **deleted**. Completed's depth is the room's, not the launcher's.
- `SequelStrip` removed from the desk (unchanged below 1280).
- Watching slimmed: still every title and still one-tap logging, but a ruled
  line in `auto-fill` columns — 254px of header in 2t, 89px now.
- `PlanDock` retitled: it is **"My order"** with the numbered count and its
  door goes to the order page, because the Planned plate above already carries
  the room and its count — "Planned 24" twice on one screen was the redundancy
  that made it read as a wall. Its footer is now the way into the whole room
  (`All 24 planned`), and backlog hours stay.

**Verified live** at 390 / 1150 / 1913px (fresh reload each): mobile and
desktop-normal are unchanged (launcher, 2 doors at 4 covers, 6-card field, one
add button, no horizontal scroll); at 1913 the desk shows two 689×360 plates
with 6 fanned covers and a 56px count leading at the same top as the dock,
the slim strip at 89px, and the composition fills ~89% of the viewport with
no scrolling and no gap beside anything. `tsc -b`, eslint, 184 vitest clean;
detector shows only the 2 long-standing findings elsewhere in `pages.css`.

**Next for this surface:** the Completed room's own "prestige dashboard" pass,
which is where the year index and the record's depth actually belong.

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
3. My List is BUILT (2g), including My Order (2m, built 2026-08-01). The next
   surface is **Anime Detail** (section 3, item 2), and it carries ordering
   root cause #2 with it (3a).
4. Run the per-surface loop in section 3: critique current -> function/IA brief
   (owner approves) -> roll structures -> owner picks -> build -> audit +
   polish. Two stop points per surface: the structure pick and comp approval.
5. Verification setup as in section 1. Screenshots DO work in the browser pane
   now (2026-07-28), alongside computed-style and canvas-readback checks.
