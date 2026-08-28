# Konsou logging system — brief (scoped, not built)

Written 2026-08-01. Two separate systems, deliberately not one: a technical
debug log for triage, and a user-facing activity record for "what did I do."
They share almost no requirements — retention, audience, privacy posture, and
where they live are all different — so treating them as one feature would
compromise both. Owner direction: debug log lives in Settings and is meant to
be attached to a bug report; the user log lives somewhere on the surface,
deliberately low-profile ("a unique discovery"), not a headline feature.

Companion to `docs/KONSOU_RESURFACE_PLAN.md` §2n, which is where this need
surfaced (no way to reverse a status change past the 5-second undo window, and
no record anywhere of what happened before that). Read that section first for
the concrete gap this closes.

---

## 1. Debug / diagnostic log (Settings, technical)

**Who reads it.** Not the end user in the normal case — the owner, when a user
says "it did something weird" and the owner needs to know what actually
happened on THAT device. Every device is different (Tauri desktop on Windows
vs Linux, Android, different SQLite states, different sync timing), so this
has to capture enough to reconstruct a session without the owner being able to
reproduce it locally.

**What it captures.** Structured, append-only events, not free-text console
spam:
- Store mutations that change persisted state: every `updateStatus`,
  `updateStatusUndoable`, `setEpisodes`, `reorderPlan`, `setPlanNumber`,
  `addToPlanOrder`, `remove`, `clearAll`, `importEntries` call — the
  anilist_id, the before/after values that matter (status, plan_rank,
  episodes_watched), and a monotonic sequence number, not just a timestamp
  (device clocks lie, see `konsou_rate_limit_swr` / clock-skew memory).
- Sync events: push/pull attempts, conflict resolutions, merge decisions
  (`merger.ts` already produces decision data — this log is where it goes
  instead of the void).
- Errors: any caught exception, any `toast.error(...)` call site, any AniList
  request that failed or hit the rate limiter — with the request shape, not
  just "something failed."
- Environment snapshot at session start: platform (Windows/Linux/Android/web
  shim), app version, screen size, theme, whether this is the Tauri SQLite
  backend or the web localStorage shim (a huge source of past bugs per
  `konsou_franchise_grouping`/`konsou_open_bugs` memory — the shim has no
  schema constraints the real DB enforces).

**Where it lives.** A dedicated SQLite table (`debug_log`), same pattern as
`completion_log`: append-only, ring-buffered rather than unbounded — cap at
something like the last 5,000 events or 14 days, whichever is smaller, so it
never becomes a second database to maintain. Ring-buffer means old rows are
deleted automatically, not retained forever; this is diagnostic, not a
permanent record, and that's the right trade — it never needs to survive a
factory reset or sync to another device (it's explicitly per-device local
noise, the opposite of `completion_log`'s cross-device permanence).

**Where it surfaces.** Settings → a new "Diagnostics" section (near Sync
status / About, not buried under Appearance). One action: **"Export
diagnostic report."** Produces a single file (JSON or a small zip if it needs
to bundle more than the log — e.g., current `PRODUCT.md`-adjacent app version,
platform, and the last N log rows) that the user attaches when they report a
bug. Not automatic upload anywhere — Konsou's whole positioning is "you own
your data, no backend," so a diagnostic log that phones home on its own would
contradict the product's founding claim (`project_konsou` memory). Export is
a deliberate, user-initiated action, same posture as the existing backup
export.

A secondary, smaller action: **"Clear diagnostic log"** — since it's already
a ring buffer this rarely matters, but a user should be able to wipe it
without wiping their actual list data, for the same privacy-first reason
export isn't automatic.

**What it must NOT capture.** No account credentials, no OAuth tokens, no raw
AniList API keys — device/session metadata and this app's own state only.
Anime titles and personal notes DO end up in the log (that's the point, it's
what makes a bug reproducible), so the export flow should say plainly what's
in the file before the user shares it, the same way any "download my data"
flow should.

**Precedent.** This is the same shape as Android's own Developer Options bug
report (bundles `dumpstate`/`logcat` into a shareable zip) and Apple's crash
log capture — an established, unsurprising pattern, not a novel one. Konsou's
version is far smaller in scope (one app's own state transitions, not the
whole OS), which is the right size for a single-developer-maintained app.

---

## 2. User-facing activity record (hidden, discoverable)

**The actual ask** (from `docs/KONSOU_RESURFACE_PLAN.md` §2n): no way to
reverse a status change once the 5-second undo toast closes, and no way to
answer "what did I do in this app last week." This is the feature that answers
both — a real record, not a bigger undo button.

**Placement: deliberately not a nav tab.** The owner was explicit: "hidden but
easily found," "a unique discovery," not front-and-center. Reading this
against the Field Guide world (a naturalist's specimen catalogue, `DESIGN.md`)
gives a natural, in-world answer rather than a generic "Activity" menu item:
a catalogue keeps a **ledger** of its own handling, the way a real museum
accession log records who touched what and when — separate from the specimens
themselves. Candidate homes, in order of fit:

1. **A drawer off the account seal in the Sidebar/index edge** (the same seal
   that already opens Settings) — tap-and-hold, or a secondary action next to
   it. Consistent with "the index rail is the whole edge" (already-committed
   nav work), doesn't add a new top-level destination, and sits exactly where
   someone poking around the app's chrome would eventually find it.
2. **A line inside Stats**, since Stats already is the "totals and history"
   surface and nobody would be surprised to find a log there — but this risks
   duplicating what `completion_log`-driven Stats already shows for
   completions specifically, and the owner already once said Stats
   shouldn't be duplicated onto the Completed room (§2j.6) — the same
   argument likely cuts the other way here (don't duplicate Stats' content
   into a new drawer either). Worth a mockup pass to compare directly against
   option 1 before deciding.
3. **A gesture on the app's own wordmark/brand seal** (long-press "Konsou" to
   reveal the ledger) — closest to "unique discovery," but the least
   discoverable of the three, and discoverability without being prominent is
   the actual brief, not obscurity for its own sake.

This needs the same structure-pick step every other surface in this rework
got (§2g-§2m): mockup 2-3 placements, owner picks, before building. Not
decided here.

**What it shows.** A reverse-chronological list of status-changing actions —
Start, Done, hold, drop, remove, plan add/remove, rewatch — each with what
changed, when, and (this is what makes it more than a log) an **undo action on
each row for some bounded window**, not just the 5 seconds the toast gives you
today. A day-old accidental Start is exactly the case that prompted this
brief; the record has to be more than read-only or it doesn't solve the
problem that was actually reported.

Reasonable bound: undo-from-the-record available for 24-48 hours after the
action (configurable later if it matters), after which the row is still
visible (the record itself doesn't expire on the same clock) but reverses via
the normal status-change flow instead of a one-tap undo — an old action
un-doing itself instantly would have surprising side effects (episode counts,
ledger rows, plan-order slots may have moved on since).

**Schema.** A new `activity_log` table, same append-only shape as
`completion_log` (2h) rather than `debug_log`'s ring buffer — this one IS
meant to be a permanent, cross-device record, because "what did I do last
Tuesday" is exactly the kind of question that shouldn't have a shorter memory
than the app's own list. Columns: `anilist_id`, denormalized title/cover (so a
removed title's history still renders, same ghost-record trick
`completion_log` already uses), `action` (start / complete / hold / drop /
plan_add / plan_remove / rewatch / remove), `at`, `before`/`after` state
needed to reverse it, and `reversed_at` (null until undone, so a
already-undone row shows as such rather than inviting a second undo).

Sync: append-only + immutable rows again means a straight union merge, no new
conflict logic — same reasoning `completion_log`'s merge already uses (2h).

**What this deliberately does NOT do**, to keep it from creeping into a second
Stats/Completed room: no aggregates, no charts, no filtering UI beyond maybe
a search (the same room-search pattern already used elsewhere). It is a
ledger, not a dashboard — reading `docs/KONSOU_RESURFACE_PLAN.md` §2k's lesson
(Completed's own history: two rejected structures, both because they turned a
few thousand entries into rows of text with no landmarks) argues for a bounded
view here too if this ever gets long — likely by day/week grouping, decided
at the structure-pick step, not here.

**Comparative precedent.** Trakt shipped "Drop Show" in 2025 specifically to
let a show leave Up Next/Progress/Calendars *without losing watch history* —
functionally the same principle `completion_log`'s ghost records already
implement, and validates that a mature competitor arrived at the same
"removal isn't erasure" answer independently. General activity-feed/timeline
UX pattern literature (reverse-chronological, grouped by recency) applies
directly to the display shape, once a placement is picked.

---

## 3. Build order, once a placement is picked

Not scheduled yet — this is a scoping brief, per the owner's request, not a
green light. When it is picked up:

1. `debug_log` migration + ring-buffer write path, wired into the existing
   store action call sites (`updateStatus`, `updateStatusUndoable`,
   `setEpisodes`, `reorderPlan`, sync manager, the toast.error call sites).
2. Settings → Diagnostics section: export + clear.
3. `activity_log` migration (mirrors `completion_log`'s shape/merge), wired
   into the same call sites as (1) but the permanent, cross-device table.
4. Structure-pick for the user-facing surface (mockups, owner picks) —
   sequenced after (3) exists, since the room needs real data to design
   against, same as Completed's own build order in §2g.
5. The undo-from-the-record action, bounded window, wired to the same
   `updateStatusUndoable`-style restore logic already proven out in this
   session's My Order work.
6. Gates: `tsc -b`, eslint, vitest (new store + migration tests, mirroring
   `completion_log`'s 3 cargo + 6 store + 6 merge + 3 shim tests), AA on all 8
   plates once a surface exists to measure.
