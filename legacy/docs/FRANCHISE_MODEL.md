# Franchise Domain Model

This is the source of truth for how Konsou understands "a franchise". Every
change to grouping, the quick menu, the Related tab, catch-up, or the sequel
radar MUST be checked against this document before it ships, and the test
protocol at the bottom must be re-run for any change to the walkers. The
repeated split-card and inconsistent-surface bugs all came from one root
mistake: multiple half-copies of this logic drifting apart. One model, one
walker per operation, written down.

Reference presentation: aniwave's franchise list (checked 2026-07-11 against
their DanMachi page) — one flat list, #1..#13 in watch order, mixing TV
seasons, OVAs, movies, specials and the Sword Oratoria spin-off, each row
carrying a format label (TV / OVA / MOVIE / TV SPECIAL), a year, and a
relation kind where informative (SIDE STORY, SUMMARY, SEQUEL). That is the
bar for how a franchise should read.

## The two operations

There are exactly TWO franchise operations, and they are deliberately
different. Confusing them is how bugs happen.

### 1. RESOLVE ROOT (identity) — `lib/franchise/cascade.ts`

Answers: "which single id does this entry group under on My List?"
Conservative by design — a wrong merge costs more trust than a missed one.

- Walks: SEQUEL, PREQUEL recursively; OTHER and PARENT only when the
  name-gate passes (`titlesShareFranchise`); side types (SIDE_STORY,
  SPIN_OFF, PARENT, SUMMARY) are collected one hop out but never expanded.
- Never walks: ALTERNATIVE (would merge Fate-scale universes into one card).
- Root selection (`findRootId`): heads = members with no in-map PREQUEL.
  Backbone heads (those owning an in-map SEQUEL edge) outrank side heads, so
  a pre-S1 special can never become the root. Among equals: earliest start
  date, then smallest id. This must be deterministic from EVERY start node.
- Self-heal (`reconcileSplitRoots` in listStore): a stored root is "suspect"
  if its relations show an anime PREQUEL, a name-gated OTHER, or a name-gated
  PARENT. Every stranding shape the walker can produce MUST be recognized
  here, or existing databases never converge.

### 2. LIST MEMBERS (presentation) — `lib/franchise/chain.ts` `walkFranchise`

Answers: "what does this franchise contain, in watch order?"
Inclusive by design — viewers expect to SEE the spin-off and the recap even
if it wouldn't share a card.

- Walks recursively: PREQUEL, SEQUEL, SIDE_STORY, SPIN_OFF, PARENT,
  ALTERNATIVE, plus name-gated OTHER. Caps: depth 6, 40 nodes.
- Excludes: manga/novel nodes, MUSIC format, and promotional shorts
  (`isPromoNode` in `lib/franchise/storySplit.ts`: a standalone PV/CM/
  Teaser/Trailer word in the title AND a short format). Advertising is not
  a member; excluding it in the walk keeps every surface agreeing it
  doesn't exist. The same gate applies to the detail page's direct
  relations and to Discover/search results.
- **Every surface that lists a franchise uses this one function.** The
  Related tab (`useRelationChain`) and the quick menu (`useFranchiseWalk`)
  share the same react-query cache key (`["relation-chain", id]`), so they
  cannot disagree. If a new surface needs the member list, it calls this —
  never a local re-derivation.
- Ordering is ALWAYS `orderForWatching(members, edges)` — the topological
  watch-order sort. Position numbers (#1..#N) come from that ordering.

## Catch-up ("Have you already watched…?") — `priorSideEntries`

Fires only when the entry being added has a non-empty PREQUEL chain, and
offers only content that is BOTH:
1. attached to the prequel chain — never the added entry's own side content
   (adding S1 must never ask about S1's OVA: it airs after S1 and the user
   is only starting the show), and
2. already finished AND first aired before the added entry started (when the
   added entry's date is known).

Consequence, by construction: **adding a franchise's first season asks
nothing.** DanMachi is the canonical test: adding S1 → no prompt; adding
S2 (Jul 2019) → offer the 2016 OVA, Sword Oratoria (2017), Arrow of the
Orion (Feb 2019); never Play Back (2022) or later OVAs.

## Presentation contract (quick menu + Related tab)

- Two sections, one shared derivation (`lib/franchise/storySplit.ts`):
  - **Main story** — the SEQUEL/PREQUEL-connected component that best
    claims to be "the show" (`mainStoryIds`: TV-bearing component first,
    then size, then earliest air date; seed-independent so both surfaces
    always agree). Rows are numbered `#1..#N` in watch order. A movie that
    continues the plot (SEQUEL-linked) is main story; a retelling or side
    event is not, regardless of format.
  - **Extras & side stories** — everything else the member walk found
    (OVA / ONA / specials / side stories / spin-offs / summaries).
    Un-numbered; each row carries its kind chip plus a placement chip
    ("before #1" / "after #2", `placementLabel` from air dates) answering
    "where would this fall if I wanted to watch it". Rationale: community
    consensus on extras is judge-per-title and watch after the season they
    accompany — so the app says what an extra IS and WHERE it goes, and
    never hides it or numbers it like a season.
- Every row: cover, title (user's title-language preference), kind chip when
  not a plain TV season, year.
- Ownership is the loudest signal: tracked rows solid with a status edge
  bar; untracked rows hollow (dashed) with a "NOT ON YOUR LIST" label and an
  Add button. Header leads with "X of Y on your list".
- "Up next" (accented) is the first untracked MAIN-STORY member in watch
  order; extras only become "up next" once the main story is fully
  accounted for. A not-interested member renders dimmed on BOTH surfaces
  (quick menu row and Related-tab row), never as an Add row.
- not_interested is a **mute flag on ONE entry, not a status and not a card**.
  It never forms or joins a card on My List (`groupEntries` drops it), so
  muting one member CANNOT change how the rest of the franchise's card looks;
  it isn't a peer in the My List status filter or the Stats "By Status"
  breakdown (those enumerate `WATCH_STATUSES`); and it never runs the
  franchise cascade (marking one member must not tag or regroup siblings).
  The row still lives in the store map, so franchise views render it dimmed
  and the surfacing filters can skip it. The ONLY thing it does: keep that
  specific entry out of Schedule, Alerts (radar seeds are completed/dropped
  only + suggestions skip in-list ids), Tonight, catch-up, and Discover/
  search. Changing it to any real status un-mutes it into that status
  (allowed from any surface — no lock); re-picking Not Interested unselects
  the mute and returns the title to untracked (undoable remove).
- Destructive actions: never per-row. Row removal lives in the row's status
  sheet; whole-franchise removal is hold-to-confirm.

## Edge semantics cheat sheet (AniList)

| Edge | Meaning | Root resolve | Member list | Notes |
|---|---|---|---|---|
| SEQUEL / PREQUEL | main story chain | walk | walk | the backbone |
| SIDE_STORY / SPIN_OFF | side content | collect 1 hop | walk | Oratoria-type spin-offs are members, not roots |
| PARENT | child → its series | walk if name-gated | walk | a special's ONLY link back (the Jobless split) |
| SUMMARY | recap/compilation | collect 1 hop | walk | aniwave labels these SUMMARY |
| OTHER | grab-bag | walk if name-gated | walk if name-gated | Edgerunners 2's only edge |
| ALTERNATIVE | retelling/universe | NEVER | walk | walking it in resolve merges Fate into one card |
| CHARACTER / ADAPTATION / manga / MUSIC | not watchable content | never | never | |

The name-gate (`titlesShareFranchise`): 8+ char shared prefix, or bigram
similarity ≥ 0.6, across romaji/english/native variants. It is what lets
"Mushoku Tensei: … Eris no Goblin Toubatsu" climb to "Mushoku Tensei" while
keeping "Fate/kaleid liner Prisma Illya" out of "Fate/stay night".

## Test protocol (run before shipping ANY walker change)

Live-AniList diagnostic scripts (pattern in the session scratchpad:
`mt_diag.mjs`, `danmachi_diag.mjs`) — mirror the walker, hit the real API:

1. **Root determinism**: resolve the root starting from EVERY member of the
   fixture franchises. All must agree on one id.
2. **Member-set consistency**: run the member walk from two different
   members; the sets must be identical.
3. **Catch-up**: adding the first season offers nothing; adding a later
   season offers exactly the prior-aired, finished side content.

Canonical fixtures (cover every edge shape):
- **Mushoku Tensei** — PARENT-linked special (the Jobless split shape).
- **DanMachi** — deep season chain + per-season OVAs + movie + spin-off TV
  (Sword Oratoria) + summaries; compare against aniwave's 13-entry list.
- **Cyberpunk: Edgerunners** — OTHER-only continuation.
- **Fate/stay night** — must NOT merge with Prisma Illya (root resolve) and
  Zero must sort before stay night (watch order).

## Change log

- 2026-07-11: PARENT edge added to root-resolve + self-heal + radar
  (Jobless split). Member walk unified behind `walkFranchise`; quick menu
  rebuilt on it (was a third divergent copy). Catch-up restricted to
  genuinely prior content (DanMachi S1 bug). Aniwave presentation adopted.
- 2026-07-12: Flat #1..#N list split into Main story + Extras (one shared
  derivation in `storySplit.ts`; numbering now covers the story only, in
  release/watch order; extras carry placement chips). MUSIC + promo shorts
  excluded from the member walk, direct relations, and Discover/search.
  Related tab now dims not-interested rows like the quick menu. Vinland
  Saga is the reference case: main story = S1, S2 (+S3 when tagged); the
  mid-S2 recap ONA lives under Extras as "summary · after #2".
- 2026-07-12 (pt2): not_interested reworked from a status/card into a pure
  per-entry MUTE flag — `groupEntries` drops it entirely (no standalone
  card, never joins a group), so marking a franchise member not-interested
  no longer spawns a duplicate card, flips the parent's shown status, or
  leaves "two cards for one franchise" (all reported bugs). The cascade is
  skipped for not-interested adds, and the earlier NI status-lock was
  removed: you can change a muted entry straight to any real status.
  Excluded from My List filter, Stats By Status, and the total/seasons
  tally via new `WATCH_STATUSES`.
