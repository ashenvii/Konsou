# My List rework, implementation plan

Status: in progress on `feat/mylist-rework`. Design is locked (shaped via
/impeccable, 2026-07-14/15). This doc is the build order, not the design
rationale; the "why" lives in the founding-why and rework-direction notes.

## The model in one paragraph

My List stops being one flat scrolling page. It becomes a differentiated
**Overview** (Watching = live progress cards, Want-to-watch = poster rail,
Completed = a record drawer) whose bands are doors into **dedicated rooms**,
one per status, pushed onto the My List tab's existing per-tab back stack.
Cards carry no controls; tapping any card opens the **quick menu**, which is
the single action surface for +1/-1/status/edit and, for a franchise, the
whole series in watch order. Minor statuses never get a room: on-hold is a
Paused group inside Watching, dropped is a filter inside Completed,
not-interested stays invisible.

## Locked decisions

1. Franchises render per room: a room shows the members whose status matches
   it (S1 in Completed, S2 in Watching). The quick menu is the only place the
   series unifies across statuses. Validate against `FRANCHISE_MODEL.md`.
2. The card is a door. No inline controls. Tap opens the quick menu.
3. Minor statuses stay as states, never as tabs/rooms. Paused (on-hold) group
   in Watching; Dropped filter in Completed; rewatch and sequel are card cues;
   not-interested invisible.
4. Plan is a rerankable queue, sortable by length (needs a persisted order
   and per-title duration).
5. The add law: no add ever hardcodes a status. Every add surface (Discover,
   the Plan room's Add, the franchise quick menu's "+ Add" on untracked
   members) shares one search + one add flow + the already-watched guard, and
   always offers the real status choice. Entry points set a default, never a
   lock.

## Build phases

### Phase 0, foundation (do first)
- [ ] Confirm the status vocabulary is unchanged (it is). No new enum value,
      so no `lib.rs` CHECK-constraint migration needed for statuses. Verify
      before assuming.
- [ ] Data audit for Phase 4/5: does the schema store a plan-order/priority
      column, and per-title runtime/duration? If not, add via migration
      (episodes exist; duration likely does not). One rebuild-style migration
      per the v10 precedent if a CHECK is involved.

### Episode entry (applies everywhere episodes are edited)
- [ ] The episode count must be DIRECTLY EDITABLE, not just +/- stepping. A
      300-episode series can't require 300 taps. Tap the number to type it;
      commit on blur/Enter via setEpisodes (which clamps + fires the
      complete-at-finale prompt). Shared EpisodeStepper used by QuickMenu,
      FranchiseSheet's SeasonRow, and EditSheet.

### Phase 1, the quick menu (load-bearing, build first)
- [ ] New `QuickMenu` component that replaces `FranchiseSheet` and folds in
      what `EditSheet` / `StatusSheet` / `CatchUpSheet` do.
- [ ] Single form: cover, title, big episode stepper (+/-), status chip row
      (all statuses incl. not-interested), optional score, open-details link.
- [ ] Franchise form: watch-order list, stepper on the current season,
      completed check on finished members, "+ Add" (status choice, per the
      add law) on untracked members, main-story-only completion ring.
- [ ] Wire to `listStore` actions (setEpisodes, setStatus, etc.). Reuse the
      complete-at-max prompt centralized in `setEpisodes`.
- [ ] Consolidation map: retire `FranchiseSheet`; migrate `EditSheet`,
      `StatusSheet`, `CatchUpSheet` callers to `QuickMenu`; delete the dead
      ones once callers are moved.

### Phase 2, the rooms + routing
- [ ] Routes for `/mylist/watching`, `/mylist/plan`, `/mylist/completed`,
      pushed within the My List tab stack (every navigate passes
      `replace: true`, per the nav-stacks contract).
- [ ] `RoomShell` with back header, per-room sort, and a 2-way view toggle
      (rich vs compact; drop the current 3rd density).
- [ ] Watching room: active cards + Paused (on-hold) collapsed group.
- [ ] Completed room: recent-first grid grouped by finish date + Dropped
      filter chip.
- [ ] Card component slimmed to a door (remove inline controls; tap ->
      QuickMenu).

### Phase 3, the Overview
- [ ] Differentiated bands: Watching (live cards), Want-to-watch (rail),
      Completed (record drawer). Each band header opens its room.
- [ ] Each band renders only a bounded recent slice (cheap at any size).
- [ ] Default landing: Overview, but remember and reopen the last room.

### Phase 4, the Plan room
- [ ] Persisted rank (drag to reorder). Sorts: my order, by length, recently
      added. Length needs the duration data from Phase 0.
- [ ] "Add something to watch" -> the shared add flow (Phase 5), default Plan.

### Phase 5, the add law (central)
- [ ] One `AddFlow` (search + result rows + guard + status choice) shared by
      Discover, the Plan room, and the franchise "+ Add". Confirm the existing
      one-title-everywhere guard, centralize it, make sure every entry point
      shows the "Finished 2024 / already on your list" verdict.

## Grouping impact (Phase 1/2)

`grouping.ts` currently builds one group per franchise with a single
`displayEntry`. Per-room rendering needs the group to expose members filtered
by a room's status (or a helper that, given a group and a status, returns the
members to show). This must not change the resolve-root / list-members
contract in `FRANCHISE_MODEL.md`; re-run the live-API fixtures after.

## Deferred (decide in-build, non-blocking)

Desktop wide-column layout, per-room empty/first-run states, global-search
result grouping. None gate the structure.

## Perf guardrails (do not regress)

Instant SQLite render, franchise grouping as one O(n) pass on entries change
only, virtualized rooms, no per-frame layout thrash, no per-frame `:root` CSS
var writes. Target smooth at 4000+ entries on Android.
