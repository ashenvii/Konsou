# Overview rework — Night Market, locked direction

## Revision note (round 2)

Three corrections from the first comp round, all folded into the sections
below:

1. **This is a rework, not a reskin.** Nothing in the new Overview should
   trace back to the current Field Guide layout logic (band-then-pair,
   hero-always-present, the specific breakpoint math). The room list and
   their relative weight get decided fresh, in §1a below, before any more
   component art gets made.
2. **Corner language was one rule for two themes; it needs to be two
   rules.** Lantern is hand-painted signage — a small, real corner radius.
   Neon is cyberpunk — hard 90-degree edges, no radius at all. Collapsing
   both onto one `--radius-plate` value was the mistake.
3. **No invented glow on a flat placeholder.** A glow is light bouncing off
   *art* — when there's no real cover image in a comp, the box stays flat,
   no color, no radial fake-lighting. The glow rule only fires where art and
   CSS are actually compositing together.
4. **Function-honest copy.** "Order +1" / "close stall" was the reference's
   own labels ported literally. Konsou's actual actions (log an episode,
   mark complete, start watching) need real verbs — the market metaphor
   informs the visual language, not the button text.

This is the plan before the build. Every section below is decided in enough
detail that live mode can generate a variant against it and be judged right or
wrong, instead of "make it cooler." Nothing in here is built yet except where
marked BUILT (the two prototype theme blocks in tokens.css already exist and
are the base this plan writes on top of).

Read order for a fresh session: this file, then `tokens.css` lines 342-450 for
the two theme blocks as they stand today, then `Overview.tsx` for the current
component tree this plan is re-skinning.

---

## 0. What's locked, what's still open

**Locked (do not re-litigate):**
- World: Night Market. Two production themes, not one. A = Lantern (warm,
  red/gold). B = Neon (cool, magenta/teal).
- **CORRECTED 2026-08-11.** This bullet used to read "both themes reuse every
  existing component structure, this is a skin and composition pass, not a
  rebuild of Overview's layout logic." That was round 1's framing and it
  directly contradicted the round 2 revision note above ("this is a rework,
  not a reskin") and §1a ("supersedes the old band/pair/rail arrangement
  entirely"). The contradiction was live in this doc for a day and caused a
  real build error: Tonight got skinned onto the OLD tree because §0 said to.
  **The rework wins.** What is reused is Overview's DATA FLOW (the memos, the
  store reads, the grouping, the search index) and its leaf components where
  they still fit. What is replaced is the page's TREE: the band/pair/rail
  arrangement, the standalone Watching door, and the breakpoint math all go.
- Font: Space Grotesk 400 upright (serif slot), IBM Plex Mono (mono slot),
  italic forced off. Already in tokens.css for both.
- Radius, border width, glow mechanics: already specified in tokens.css
  (`--radius-plate: 8px`, `--card-border-width: 2px`), carry forward.

**Resolved 2026-08-11:** A and B (Lantern, Neon) are the ONLY themes going
forward — not two of the existing 8 Field Guide plates, not a 9th/10th
option alongside them. The other 8 plates (Herbarium, Nocturne, Cyanotype,
Foxing, Slate, Oxblood, Vellum, Specimen Card) are retired. Owner: more
themes get invented later, after the app is otherwise finished — this round
ships exactly two.

**Still open, needs your call before build (see §10):**
- Whether the "stall front" language extends only to the Watching band (the
  literal reference) or to all three room doors (Planned/Completed too).
- Which 2-3 Evetech/navbar borrowings actually get built this round vs. get
  logged as later spice (see §6).

---

## 0a. Scope note — two-theme decision reaches past Overview

Retiring the 8 Field Guide plates down to exactly Lantern/Neon is not an
Overview-only change, since themes are app-wide tokens. Concretely, this
touches, and needs its own explicit answer before the tokens.css cleanup
happens (not decided yet, flagged so it isn't missed):

- **`tokens.css`**: the 6 dead dark plates + 2 dead light plates get removed
  outright, not left dormant — per the app's own no-backwards-compat-shims
  rule, dead theme blocks are deleted, not kept unreachable.
- **`AppearanceSettings.tsx` / `settingsStore.ts`**: the theme picker UI
  collapses from an 8-plate grid to a 2-theme picker. `THEME_DEFAULT_ACCENTS`
  pairings need rework or removal depending on the accent-ink question below.
- **Resolved 2026-08-11: accent inks are dropped entirely.** No 8-ink picker,
  no personal-color axis. Each theme ships exactly one fixed accent, matching
  its own highlight hue — Lantern's accent = gold (`--color-highlight`,
  Lantern row in §2's table), Neon's accent = teal (`--color-highlight`,
  Neon row). This means every place in the codebase that currently reads a
  separate `--color-accent*` token distinct from the theme's own highlight
  hue collapses to just reading the highlight hue directly — `--color-accent`,
  `--color-accent-glow`, `--color-on-accent`, `THEME_DEFAULT_ACCENTS` and the
  whole ink-selection UI in `AppearanceSettings.tsx` are dead once this
  lands, not kept dormant. One live consequence to carry forward: §5a's
  "hover state swaps to the user's accent color at 55%" (line ~252) and the
  `--glow-in-list-hover` behavior in §5's states table both assumed a
  variable personal accent distinct from the highlight hue — with no
  personal accent left, that hover swap has nothing to swap TO, and needs a
  replacement rule (candidate: hover just intensifies the existing highlight
  hue rather than shifting to a different color at all). Flag this for the
  build step that touches §5's hover states — don't build the old "swap to
  user accent" behavior as originally written.
- **Any already-persisted theme value** for existing users (if this app has
  real users yet) — a saved `herbarium`/`nocturne`/etc. value needs a
  fallback to Lantern or Neon rather than resolving to nothing. Flag for the
  build step that actually does the tokens.css cleanup.

---

## 1. The two references, read precisely

**Reference A/B (mockup 1):** two labeled boxes per theme.
- A row card ("Frieren at the Funeral / open — ep 9 of 28") with a **thin
  outline in the accent hue** — red for Lantern, magenta for Neon — and a
  second, closed/greyed card beside it with no color at all.
- Below it, a **second, distinct box**: "STALL FRONT — OPEN", a different
  accent (gold for Lantern, teal for Neon), thicker treatment, holding the
  same title plus two real actions (`order +1`, `close stall`).

This is the exact distinction to carry through: **two different accent roles,
not one color reused everywhere.** Row-level membership (this thing is in
this list) uses the "signage" hue — red/magenta. The one thing that's
actually open for action right now uses a second hue — gold/teal — and gets
the heavier visual treatment (thicker line, its own glow, the buttons live
inside it, not beside it).

**Reference (mockup 2, "signature effect" catalogue):** five worlds compared
side by side, each stating its effect as one sentence: Lantern = warm
flicker-glow "like lit by a paper lantern." Neon = tube-glow bleed + a faint
reflection ghosted below, "like wet pavement." (Monsoon/Ember Row/Frost
Market are the other three worlds trialed in that round — not part of this
build, kept only as the pattern to imitate: **one physical, real-world light
source, stated as one sentence, that the CSS has to earn.**)

**Evetech screenshots:** not a color or theme reference — a **composition**
reference. What's worth stealing:
- The hero card: one big dark plate, a tiny eyebrow tag top-left ("PLUG & PLAY"
  — small-caps, colored dot, mono-ish), a huge two-line headline, one pill CTA
  bottom-left, and the product art bleeding off the right/bottom edge instead
  of sitting centered in a box. The art is lit from inside (the PC's own RGB
  fans) — same "real light source" logic as the Night Market worlds.
- The four-tile feature strip: each tile has its own eyebrow chip in a
  different hue (orange/AI, violet/mobile, green/builder, amber/flash), a
  bold headline, one sentence of body copy, one text-link-style CTA with an
  arrow. The hue difference between tiles is what makes four otherwise-equal
  boxes read as four different offers at a glance.
- What NOT to take: the literal e-commerce chrome (app store badges, "shop"
  language, aggressive drop-shadowed gradient buttons). Konsou is a personal
  library, not a storefront — the CTA energy has to translate to "log this,"
  "open this," not "buy this."

**Navbar collage:** not a redesign of Konsou's nav — Konsou's nav
(desktop Sidebar / mobile BottomNav) is settled and out of scope for this
pass. Worth one borrowing, logged in §6, nothing more.

---

## 1a. The room list and page structure — CONFIRMED 2026-08-10

Wireframed live over several rounds (see the artifact history in this
session), corrected twice against the owner's own hand-drawn box diagram.
This supersedes the old band/pair/rail arrangement entirely — nothing below
traces back to the current Overview.tsx layout logic.

**The anchors.** Planned and Completed are the two fixed anchors, always
present, always full weight. Everything else on the page is presence- or
width-dependent around them. This is the one load-bearing structural
difference from the old page, which had a single fixed subject (Hero) that
everything else arranged around — here there are two anchors, and Watching /
tonight / sequels / order are all supporting weight that can shrink, fold,
or disappear.

**Tonight — a hero, confirmed.** Full width, its own row, above everything
else. Carries a visual state skin sourced from where the subject came from:
"from Planned, not started" vs. "Watching now" — same underlying data and
logic (starting a show already flips its status), only the presentation
changes. Conditional: only renders when something is actively running or at
the head of the order: no hero-shaped hole when nothing's on. Info tiers by
width, most-protected first so nothing wrong survives shrinking: **state
chip → title → primary action → progress (bar, then fraction-only, then
gone) → secondary meta (season/studio/next-air), dropped first on mobile.**

**The watching strip — Tonight's second part, and the room's door.**
Directly under Tonight, full width, same row on both wide and medium
layouts: a small rail of covers-with-progress-hairlines for everything else
currently running (Tonight already claimed the head of the list), capped at
a handful, with a footer line that is the actual entry into the Watching
room ("N more watching · open Watching room →"). This is the answer to
"how do you get to Watching from here" — there is no separate Watching box;
the door lives at the foot of this strip. Mobile variant still open (see
§11.5): a scaled-down version of the same strip, or a single door line with
no covers at all, since Tonight has already spent the phone's art budget for
the day. Lean is toward the plain door line on mobile, not yet decided.

**The backdrop — Planned and Completed's shared frame, desktop only.**
Below Tonight and its strip: a **grouping backdrop**, a darker background
panel (the Evetech "deals section" pattern — a promo panel that visually
families several distinct tiles together without merging them into one
card). On desktop this backdrop holds Completed and Planned side by side,
**both always visible, no toggle, no tap-to-switch** — the two anchors
simply live inside one shared frame rather than floating as two independent
boxes. **My Order sits outside the backdrop**, its own column to the right
of it (not beside Tonight — an earlier draft had this wrong). Alerts/New
sequels sits in the row below, its width tracking the backdrop's column
only, not extending under My Order.

**Mobile — no backdrop, no toggle, doors instead.** The backdrop pattern
doesn't survive to phone width (can't fit two full cards side by side).
Instead: **Planned always shows in place, full**, when it has content — My
Order folds inside it as one more row rather than standing alone. Completed
collapses to a **real entry button**, accent/green ("completed" color
identity, standout), that navigates into the Completed room — not an
in-place toggle, not a tap-to-swap face. The one fallback: **if Planned is
empty, Completed expands to fill the slot instead of staying a button** —
there's nothing else to show there, so it takes the space rather than
sitting small next to a gap.

**Medium width — deliberately deferred.** Where My Order and the backdrop
land between wide and mobile is not decided. Reasoning, stated directly by
the owner: it's cheaper to move an already-built component as a whole unit
once it exists than to lock a breakpoint arrangement now and rework it
later. Build the components first; place them at medium once they're real
enough to judge.

**What still needs an answer, carried to §11:** the mobile watching-strip
variant (mini strip vs. plain door line), and whether "desktop always shows
both" in the backdrop holds at medium width too or only above some wider
point — tied to the same medium-width deferral above.

## 2. Color system — the two-hue rule, per theme

Both themes already define this in tokens.css; this section states the RULE
so every new bit of Overview follows it instead of guessing.

| Role | Lantern (A) | Neon (B) | Token |
|---|---|---|---|
| Signage / membership (row keyline, "you're in this list") | red, `oklch(64% 0.20 20)` | magenta, `oklch(62% 0.24 330)` | `--color-border` |
| Open-for-action / the one live thing | gold, `oklch(78% 0.15 82)` | teal, `oklch(76% 0.13 195)` | `--color-highlight` |
| Base ground | near-black warm, `oklch(13% 0.035 18)` | near-black cool, `oklch(11% 0.025 262)` | `--color-base` |

**Rule:** anything that is *a member of a list* (a row in the Watching sheet,
a card in a register, a chip in the sequel strip) gets the signage hue at low
weight — a 2px keyline, nothing more. Anything that is *the one thing open
right now* (the Hero subject, the door currently expanded, a stall-front
plate) gets the highlight hue, a thicker line, and the glow. The current
Field Guide world had one ink (vermilion) for everything, which is exactly
the flatness this pass is fixing — two hues per theme, each with one job.

**Correction (2026-08-10), read directly off the reference mockup, not
guessed:** the two hues aren't fully segregated per element — the reference
mixes them once each way, deliberately. The signage-bordered row's live
status word ("open") is set in the *highlight* hue even though the card's
own border is signage. The highlight-bordered stall-front's committing
action ("order +1") is filled in the *signage* hue even though the box's own
border is highlight. **Each surface borrows exactly one accent of the hue
it isn't — never the border, always one specific inline detail: the single
live/status word on a signage card, the single committing action on a
highlight card.** This is what makes the reference read richer than a
strictly segregated two-hue system; a card that only ever shows one hue in
one weight is what read flat in round 3's comp. Applies concretely: Tonight
(highlight-bordered) gets its primary action button **filled in the
signage hue**, not highlight. The watching strip's progress hairlines
(signage-bordered rows) pick up the **highlight** hue as their one live
accent, not signage.

Accent inks (the user's pickable color, currently 8 "inks" like coral/violet)
stay a separate axis — they tint the CTA/action controls (the +1 stamp, the
Start button), not the world's own signage/highlight pair. Don't collapse
these into one variable; they answer different questions ("what world am I
in" vs "what's my personal color").

---

## 3. Line, glow, and corner rules

Already correct in tokens.css, restated as the rule so new markup matches it
instead of falling back to the old Field Guide's 8%-alpha hairline:

- **Border width: 2px**, not 1px. This is a painted stall board / a neon tube,
  not a ruled ledger line. `--card-border-width: 2px`.
- **Radius is a per-theme decision, not one shared value.** Lantern is
  hand-painted signage — a small real radius (roughly 3-4px, enough to read
  as a board corner, not enough to feel soft/rounded-app). Neon is
  cyberpunk — **0 radius, hard 90-degree corners, everywhere**, no
  exceptions for buttons or chips. Each theme gets its own
  `--radius-plate` value; do not share one token across both the way the
  prototype block currently does (tokens.css has both at 8px today — that's
  the thing this correction fixes).
- **Glow only exists where art and CSS are actually compositing.** A glow is
  light bouncing off cover art — if a comp or a component has no real art in
  the slot (a placeholder, a missing cover), that box stays flat: no color,
  no radial fake-lighting standing in for a picture that isn't there. The
  signature effects in §5 apply to the *plate* (border, shadow, ambient
  edge), never as a simulated light source painted onto empty space.
- **Glow is a layered shadow, not a filter blur.** Each theme's
  `--shadow-card` stacks: a tight drop shadow (depth), a soft wide spread
  (ambient), then one or two colored glow rings sized 12-20px at 20-30%
  alpha in the theme's hue(s). Neon gets two glow layers (magenta + teal)
  because it's lit by two tube colors; Lantern gets one (red only — the gold
  is reserved for the open-highlight state, never ambient on every card).
- **Hover state** (`--glow-in-list-hover`) swaps the ring to the user's
  accent color at 55% and intensifies — this is where the personal accent
  finally appears on a list row, on interaction only, not at rest.
- **The open/highlight state is a different shadow set entirely**, not the
  same shadow turned up — it should read as a different light source, not a
  brighter version of the same one.

---

## 4. Typography and the "closed" state

- Space Grotesk 400 upright everywhere text currently uses the serif slot.
  Italic is force-disabled (`font-style: normal !important` on both theme
  scopes) — carry this forward, it's already the fix for the "hard to read"
  feedback on EB Garamond italic.
- Mono stays IBM Plex Mono for numbers/labels/eyebrow tags — this is also
  where the Evetech eyebrow-chip borrowing lands (see §6): small-caps mono,
  a colored dot, tight tracking.
- **Closed / not-open state** (reference A/B's greyed second card,
  "Mushishi — closed — visited"): no border color at all, text drops to
  `--color-text-tertiary`, no glow. This is the visual language for anything
  finished/inactive on Overview — a completed door's rows when not the
  active room, a paused Watching entry, etc. Don't invent a third border
  color for "closed" — the absence of the signage hue *is* closed.

---

## 5. Signature effect spec (per theme, one sentence each, CSS-earned)

**Lantern — "lit by an actual paper lantern."**
- A warm flicker-glow on the open/highlight element only (never ambient on
  every card — a whole page of flickering lanterns is noise, one lit stall
  is a scene). Implementation: an `@keyframes` on `--shadow-card-hi`'s glow
  alpha, slow (3-5s), irregular easing (not a clean sine — two overlaid
  sine waves at different periods reads as a real flame, one clean pulse
  reads as a loading spinner). Respect `prefers-reduced-motion` — this
  machine has it on, so this effect must hold its brightest frame statically
  rather than disappear, matching the existing `konsou-stamp` pattern.

**Neon — "tube-glow bleed at the edges, a faint reflection ghosted below,
like wet pavement."**
- Two parts. (1) Edge bleed: already in `--shadow-card`/`--shadow-card-hi` as
  the dual magenta+teal glow layers — static, no flicker, tube light doesn't
  flicker like flame does. (2) The reflection: a `::after` pseudo-element
  under the open/highlight plate only, a vertically-flipped, heavily
  blurred, low-opacity (10-15%) copy of the plate's own glow color, no
  content — pure light-bleed, not a mirrored duplicate of the card. This is
  the one genuinely new piece of CSS this plan requires (mockup 2 shows it
  as a faint ghosted rectangle under the Neon card that Lantern's mockup
  doesn't have).

Both effects are **theme-level CSS on the highlight/open state class**, not
per-component — so a Hero, a stall-front plate, and (if extended) an open
door all inherit the same signature automatically once they carry the
"open" modifier class.

---

## 5a. Cursor hover mechanism — LOCKED, canonical implementation

**This section is binding.** Two separate effects that must not be conflated:

- **The line invert** (rounds 6-13) — a masked `::after` border overlay. **This works. Do not replace it.** Round 15 rewrote it as a plain whole-border `color-mix()` and that was a regression: the entire outline flipped hue the moment the cursor came within range, instead of only the stretch of line near the cursor. The mask is precisely what makes the effect *local*. Reverted in round 16.
- **The glow shift** (round 16) — the actual outstanding request, and the only thing round 16 changed. The two components that already had a glow (Tonight, pulsing; Completed, static) now have that existing glow's *colour* driven by cursor proximity, so the halo shifts hue in step with the line instead of staying frozen while the border beside it changes.

**Two rules that were violated and cost several rounds:**
1. **Glow belongs to Tonight and Completed only.** No other component has one, at rest or on hover. Round 15 put a `box-shadow` on the generic `[data-fx]::after`, which sprayed a glow onto the strip, Planned and the order rail. Wrong.
2. **Change only what was asked.** The glow request did not license rewriting the line mechanism. When one effect is broken and an adjacent one works, fix the broken one in isolation.

**Scope: cards, Tonight, the watching strip, and the order rail.** Buttons/icons were built and pulled back out in round 13 as scope creep. Don't re-add without being asked.

**How the line invert works.** A duplicate of the element's own outline in the opposite hue sits at `inset:-2px` (aligned with the real border, since absolute insets measure from the *padding* edge), radially masked around the cursor so only the nearby stretch shows.

**How the glow shift works.** JS computes `--fx-mix` per `[data-fx]` element on every mousemove: 0% when the cursor is `FX_RADIUS` (190px) or more from the element's box, 100% when inside, linear in between via distance-to-rect. Tonight and Completed each declare `--glow-hue: color-mix(in oklab, var(--sign) var(--fx-mix, 0%), var(--hi))` and their existing `box-shadow` reads that — so the glow already there changes colour, rather than a second glow being layered on top.

**Failure history, so nobody re-treads it:**
1. `overflow:hidden` clipped the border-aligned pseudo at `inset:-2px` (rounds 6-9).
2. `filter:drop-shadow(...)` blurred the border into a haze (round 7).
3. Adding `box-shadow` to the shared `[data-fx]::after` gave every component a glow (rounds 14-15).
4. Replacing the masked overlay with a whole-border `color-mix()` made the invert global instead of local (round 15).
5. A suspected `mask-image` luminance-vs-alpha trap (`konsou_css_mask_image_luminance_trap.md`) was **not** the problem — for a gradient image `mask-mode: match-source` resolves to alpha, so opaque black reveals correctly.
6. **THE ACTUAL ROOT CAUSE, found round 19: `mask-clip`.** It defaults to `border-box`, which clips the element's entire painted output to its own box *before the mask image is consulted at all* — an outer `box-shadow` included. So the glow was being erased outright, no matter what the mask said. This is why the border invert rendered for a dozen rounds while the glow never once did: **the border paints inside the box, the glow paints outside it.** Fix: `mask-clip: no-clip`.
   - Round 18's `mask-repeat: no-repeat` + enlarged `mask-size`/`mask-position` are also required (default `repeat` tiling would mask the outer region with a neighbouring tile whose bright spot is an element-width away), but on their own they fixed nothing, because the clip removed the glow first. All four declarations are needed together.
   - **Method note, and the real lesson from rounds 6-19:** every single check based on `getComputedStyle` reported correct values the entire time the effect was invisible. Computed style proves a declaration *parsed*, never that it *rendered*. What finally settled it in one step was swapping the glow to opaque lime and screenshotting: invisible with the default clip, obvious with `no-clip`. **When a visual effect is disputed, change it to an unmistakable colour and look — do not report computed values as evidence.**

```css
[data-fx]{position:relative;}

/* LINE INVERT + LOCALIZED GLOW — one masked layer carries both. The mask
   is load-bearing, and so are the repeat/size/position declarations: see
   failure #6 above, they are what let the outer glow render at all. */
[data-fx]::after{
  content:"";position:absolute;inset:-2px;pointer-events:none;
  border-radius:inherit;border:3px solid var(--fx-opp,transparent);
  /* All four mask declarations are load-bearing — see failure #6. */
  -webkit-mask-clip:no-clip; mask-clip:no-clip;
  -webkit-mask-repeat:no-repeat; mask-repeat:no-repeat;
  -webkit-mask-size:calc(100% + 120px) calc(100% + 120px);
  mask-size:calc(100% + 120px) calc(100% + 120px);
  -webkit-mask-position:-60px -60px; mask-position:-60px -60px;
  -webkit-mask-image:radial-gradient(150px circle at calc(var(--gx,-9999px) + 60px) calc(var(--gy,-9999px) + 60px), black 0%, black 55%, transparent 82%);
  mask-image:radial-gradient(150px circle at calc(var(--gx,-9999px) + 60px) calc(var(--gy,-9999px) + 60px), black 0%, black 55%, transparent 82%);
}

/* Background wash, own hue. No glow here — see rule 1 above. */
[data-fx]::before{
  content:"";position:absolute;inset:-2px;pointer-events:none;border-radius:inherit;
  background:radial-gradient(230px circle at var(--gx,-999px) var(--gy,-999px), var(--fx-own,transparent) 0%, transparent 88%);
  opacity:.11;
}

@media (hover:none){[data-fx]::after,[data-fx]::before{display:none;}}

/* AMBIENT GLOW — always on, STATIC in its resting hue. Only Tonight and
   Completed have one. Do not drive these off --fx-mix: that makes the
   whole halo flip at once, which is not the effect (round 16's error). */
.world--a .tonight{
  box-shadow:0 1px 2px oklch(0% 0 0/40%),0 14px 30px oklch(0% 0 0/34%),0 0 26px 4px color-mix(in oklab, var(--hi-a) 38%, transparent);
  animation:flicker 4.4s ease-in-out infinite;
}
.world--b .tonight{
  box-shadow:0 1px 2px oklch(0% 0 0/40%),0 14px 30px oklch(0% 0 0/34%),0 0 20px 2px color-mix(in oklab, var(--sign-b) 28%, transparent),0 0 30px 5px color-mix(in oklab, var(--hi-b) 22%, transparent);
}
.card.completed{
  box-shadow:0 0 18px 2px color-mix(in oklab, var(--hi) 32%, transparent);
}

/* LOCALIZED GLOW SHIFT — rides the same masked ::after as the line, so
   it is revealed only in the cursor's radius, in the opposite hue.
   Round 19 shipped this as one flat 0 0 34px 9px for every component —
   an invented shape with no relationship to the real glow it sits over,
   which read as a second glow stacked on top rather than the same glow
   recolouring. Round 20's fix: every rule's blur/spread/alpha numbers are
   copied EXACTLY from the matching ambient glow above, changing only the
   colour source. Tonight's flicker needs its OWN synced animation
   (flickerOpp) with identical duration/keyframe percentages/blur/spread
   to the real `flicker` — two independently-running animations with
   identical timing stay in lockstep, so the masked layer is always the
   same size as the real pulse, not just at rest. */
.world--a .tonight::after{ animation:flickerOpp 4.4s ease-in-out infinite; }
@keyframes flickerOpp{
  0%,100%{box-shadow:0 0 26px 4px color-mix(in oklab, var(--fx-opp) 38%, transparent);}
  45%{box-shadow:0 0 20px 2px color-mix(in oklab, var(--fx-opp) 22%, transparent);}
  70%{box-shadow:0 0 30px 5px color-mix(in oklab, var(--fx-opp) 44%, transparent);}
}
@media (prefers-reduced-motion:reduce){.world--a .tonight::after{animation:none;box-shadow:0 0 28px 4px color-mix(in oklab, var(--fx-opp) 40%, transparent);}}
.world--b .tonight::after{ box-shadow:0 0 20px 2px color-mix(in oklab, var(--fx-opp) 28%, transparent); }
.card.completed::after{ box-shadow:0 0 18px 2px color-mix(in oklab, var(--fx-opp) 32%, transparent); }
```

```js
document.querySelectorAll('.world').forEach(function(world){
  var fxEls = world.querySelectorAll('[data-fx]');
  var FX_RADIUS = 190;
  world.addEventListener('mousemove', function(e){
    fxEls.forEach(function(el){
      var r = el.getBoundingClientRect();
      el.style.setProperty('--gx', (e.clientX - r.left) + 'px');
      el.style.setProperty('--gy', (e.clientY - r.top) + 'px');
      var dx = Math.max(r.left - e.clientX, 0, e.clientX - r.right);
      var dy = Math.max(r.top - e.clientY, 0, e.clientY - r.bottom);
      var dist = Math.sqrt(dx * dx + dy * dy);
      var mix = Math.max(0, Math.min(1, 1 - dist / FX_RADIUS));
      el.style.setProperty('--fx-mix', Math.round(mix * 100) + '%');
    });
  });
  world.addEventListener('mouseleave', function(){
    fxEls.forEach(function(el){
      el.style.setProperty('--gx', '-999px');
      el.style.setProperty('--gy', '-999px');
      el.style.setProperty('--fx-mix', '0%');
    });
  });
});
```

**Per-element wiring** — each element declares `--fx-opp` (the hue its line inverts to) and `--fx-own` (the hue of its background wash) alongside a plain, static `border`:

| Element | Resting border | `--fx-opp` (line inverts to) | `--fx-own` (wash) | Glow |
|---|---|---|---|---|
| Tonight | `--hi`, solid | signage | highlight | pulsing, shifts |
| Watching strip | `--sign-line`, translucent | highlight | signage | none |
| Planned card | `--sign-line`, translucent | highlight | signage | none |
| Completed card | `--hi`, solid | signage | highlight | static, shifts |
| My Order rail | `--sign-line`, translucent | highlight | signage | none |

**Verified 2026-08-10** in-browser with real cursor hover, not injected values: at 51px from Completed's box, `--fx-mix` computed to 73% (matching `1 − 51/190` exactly), Completed's shadow resolved from `oklab(0.83 …)` (highlight gold) at rest to `oklab(0.64 0.240315 0.0689093 …)` (signage red) with the cursor on it, Tonight's third shadow layer made the same transition, and the strip, Planned and order rail all reported `box-shadow: none` in both states. Screenshot confirms the halo visibly changing colour.

**Border width is 2px everywhere, no exceptions.**

## 6. What to borrow from Evetech and the navbar collage, precisely

Keep this list short. Every item states which Overview element it lands on
and why it survives translation from e-commerce to a personal library.

1. **Eyebrow chip** (Evetech's "PLUG & PLAY", "AI POWERED" tags) → the Hero
   subject's kicker ("Tonight" / "Paused" / "Caught up"). Currently plain
   text; give it the chip treatment — small-caps mono, a small filled dot in
   the highlight hue, tight pill or rounded-8px background at low alpha.
   This is a direct, honest fit: the kicker already says "what state is this"
   in one word, exactly what an eyebrow chip is for.
2. **Art bleeding off the edge, lit from inside** (Evetech's PC hero) → the
   Hero subject's cover art. Currently a bounded cover image; let it bleed
   past the plate's right/bottom edge slightly (not fully off-canvas — this
   is a card in a scroll, not a full-bleed hero section) so the art feels
   larger than its box, and let the theme's glow read as light coming off
   the art itself rather than a decoration drawn around a rectangle.
3. **Per-tile hue differentiation** (Evetech's four-chip strip, each a
   different color) → the sequel strip / SequelStrip cards. Right now every
   alert in that rail likely shares one tint. If each alert can carry a
   distinct low-saturation hue keyed to *why* it's surfaced (new season vs.
   airing-now vs. finale), the strip reads as several different kinds of
   news at a glance instead of one repeated card. Flag this as a real
   function question, not just a color swap — needs the alert data to
   actually carry a "reason" field distinct enough to hue.
4. **Navbar collage — one borrowing, FOLDED INTO THIS PASS (resolved
   2026-08-11, reversing the original "log it, don't build" call):** the
   active-tab pill (Nexora #2, Spherix #10 — a filled rounded background
   behind the current tab, not just an underline or color change). Confirmed
   against the real code: Sidebar's active state today is a 3px accent notch
   on the rail edge (`.k-sidebar__item--active::before`) plus a faint
   `--color-accent-dim` background wash; BottomNav's is a sliding 2px
   underline (`.k-bottomnav__indicator`). Both retire in favor of a filled
   rounded-background pill behind the active tab, in the theme's highlight
   hue. Full build spec in §7h.

Explicitly rejected: app-store badges, "Shop"/"Browse"/"Buy" verb language,
drop-shadowed gradient-fill buttons (Konsou's buttons are flat plates with a
keyline, not gradients — that's a different world's language and clashes
with the painted-signage read).

---

## 7. Component-by-component construction, in page reading order

**REWRITTEN 2026-08-11 against §1a's confirmed structure and every decision
resolved since.** §1a owns the STRUCTURE (what's on the page, how it
reflows); this section owns the SKIN (color, glow, corner, typography) for
each piece of that structure, in reading order, plus the nav shell folded in
per §6.4. Three global corrections carried through every subsection below,
so they aren't repeated per item:

- **No "user accent" anywhere.** §0a dropped the personal accent-ink axis
  entirely. Every place the old §7 (or the older Field Guide contract) said
  "brightens toward the user's accent" or `--color-accent*` now reads as the
  theme's own highlight hue (gold Lantern / teal Neon) — there is no second
  color to distinguish it from anymore. Where the old behavior was
  specifically an *interaction-only* accent (hover states, below), the
  replacement is an intensified/brightened version of the resting hue, not a
  hue swap — see the hover-state note under 7d.
- **Radius and corner language are per-theme**, not shared — small real
  radius on Lantern, hard 0-radius on Neon, per §3. Applies to every plate
  in every subsection below without restating it each time.
- **The cursor hover mechanism (§5a) is binding wherever it applies.** Any
  element below marked `[data-fx]` in its own per-element wiring table row
  gets exactly the masked line-invert + (where noted) glow-shift described
  in §5a — do not reinvent hover behavior per component.

Old tree for reference (being fully replaced, not extended):
`k-census` bar → `k-lede` → `k-ov` → `k-ov__main` [`bandBlock` → `k-ov-pair`
→ `SequelStrip` → add button] → `k-ov__side` [`OrderRail`, ≥1100px].

New tree per §1a: `k-census` bar → `k-lede` → **Tonight** (hero) →
**watching strip** (Tonight's door into the Watching room) → **backdrop**
[Completed, Planned side by side, desktop AND medium per the resolved
medium-width decision] + **My Order** (own column beside the backdrop) →
**alerts band** (SequelStrip, width tracks the backdrop column only) → nav
shell (Sidebar/BottomNav, folded in per §6.4).

### 7a. `k-census` bar (sticky) + search
- Unchanged from the old §7a. Border under the bar (if any) uses the
  signage hue at low alpha — it's chrome, not a lit stall. Search field
  focus ring: highlight hue.

### 7b. `k-lede` (title + census line)
- Unchanged from the old §7b. Title in Space Grotesk 400, larger display
  step, no border, no glow. Census number can take the eyebrow-chip mono
  treatment from §6.1 at small scale.

### 7c. Tonight (hero) + its watching strip
This is reference A/B's stall-front plate, now explicitly two parts per
§1a: the hero card itself, and the strip directly beneath it that doors into
the Watching room.

**Tonight, the hero:**
- **Highlight hue** border (gold/teal), 2px+, plus the FULL signature glow
  effect from §5 — this is the one element per theme allowed the signature
  effect (flicker for Lantern, edge-bleed+reflection for Neon) at rest,
  unprompted.
- Kicker ("Tonight" / "Paused" / "Caught up") becomes the eyebrow chip
  (§6.1): small-caps mono, filled dot in the highlight hue, low-alpha
  rounded-8px background.
- Cover art bleeds slightly past the plate's right/bottom edge (§6.2) —
  bounded, not full-bleed, since this is a card in a scroll.
- Info tiers by width per §1a, most-protected first: state chip → title →
  primary action → progress (bar → fraction-only → gone) → secondary meta,
  dropped first on mobile.
- The primary action sits *inside* the plate's bottom edge, not floating
  beside it, matching reference A/B's "order +1" placement.
- **Color correction from §2, applied here concretely:** the primary action
  button is filled in the **signage** hue, not highlight, even though the
  plate's own border is highlight — this is §2's one-borrowed-accent rule in
  its most load-bearing instance (Tonight is the highlight-bordered surface
  that borrows one signage-hue detail).
- `[data-fx]` wiring (§5a table): resting border `--hi` solid, `--fx-opp`
  signage, `--fx-own` highlight, glow pulsing/shifts (Lantern flicker /
  Neon static-but-color-shifting per §5a's canonical block).

**The watching strip (Tonight's door):**
- Small rail of covers-with-progress-hairlines for everything else
  currently running, capped at a handful, footer line as the literal entry
  into the Watching room ("N more watching · open Watching room →").
- **Signage hue** keyline only, translucent, no highlight, no glow — this is
  membership (things also playing), not the one open thing; Tonight above
  already claimed that.
- Progress hairline meters pick up the highlight hue as their one live
  accent per §2's crossover rule — progress-in-motion reads closer to
  "open" than "filed," so this is the deliberate exception.
- `[data-fx]` wiring: resting border `--sign-line` translucent, `--fx-opp`
  highlight, `--fx-own` signage, no glow.
- Mobile variant confirmed 08-10: the mini strip (scaled-down covers +
  hairlines), not a plain door line.

### 7d. The backdrop — Planned + Completed (`RoomDoor` variant="front", ×2)
- Darker background panel families the two doors together without merging
  them into one card (the Evetech "deals section" pattern). **Always shows
  both, no toggle, on desktop AND medium width** (resolved 2026-08-11 — one
  rule from medium through wide, no separate medium arrangement).
- Both doors: **signage hue**, same treatment as each other — two stall
  fronts in the row, closed unless opened. No highlight hue on either at
  rest; Tonight is still the page's one highlight element.
- Whether opening a door (navigating into PlanRoom/CompletedRoom) carries
  the highlight hue into the destination room's own header is **still open**
  — logged in §11, not decided.
- Dated rows inside each register, once opened: signage only, same as the
  watching strip's rows, never highlight.
- `[data-fx]` wiring: resting border `--sign-line` translucent, `--fx-opp`
  highlight, `--fx-own` signage, no glow — identical wiring to the watching
  strip, since both are "membership, not the open thing."
- **Mobile (no backdrop):** Planned always shows in place, full, when it has
  content, with My Order folded in as one more row. Completed collapses to a
  real accent/green entry button. Fallback: if Planned is empty, Completed
  expands to fill the slot instead of sitting small next to a gap. (Structure
  per §1a; skin follows the same signage-only rule as the desktop doors,
  except the mobile Completed button, which keeps its own established
  "completed" color identity per the app's existing status-color contract,
  not the Night Market signage/highlight pair — it's shell chrome pointing
  into a room, not a stall.)

### 7e. My Order (own column beside the backdrop)
- Standing list, own column to the right of the backdrop, not beside
  Tonight (an earlier draft had this wrong, corrected in §1a).
- Same signage-only rule as 7c's strip / 7d's doors — no highlight anywhere
  in this rail. The row at the head of the rail (rank #1) is explicitly
  **not** given the highlight hue, even though it's tempting as "the next
  open stall": the Hero already IS rank #1 whenever nothing's watching (see
  `Overview.tsx`'s fallback logic), so a second highlight element here would
  double-state the same fact.
- `[data-fx]` wiring: resting border `--sign-line` translucent, `--fx-opp`
  highlight, `--fx-own` signage, no glow.
- Placement at medium width (720-1099px) needs a look once the backdrop is
  real on screen — likely falls out of the resolved backdrop rule directly
  (its own column beside an unchanged backdrop) but confirm, don't assume
  (§11).

### 7f. Alerts band — `SequelStrip`
- Sits in the row below the backdrop, width tracking the backdrop's column
  only, not extending under My Order (per §1a).
- Base card treatment: signage hue keyline, per §2.
- **Per-card hue differentiation is SKIPPED this round** (resolved
  2026-08-11, §11) — no "reason" field on alert data, no per-card hue. The
  strip stays one hue. Revisit later as its own small pass if still wanted.

### 7g. Hover state, restated without the accent axis
Old §7d/8 described hover as "border brightens toward the user's accent."
With accent inks gone (§0a), there is nothing to swap to — the resting hue
IS the only hue. Replacement rule for every `[data-fx]` element listed above
(strip, backdrop doors, My Order — the ones without their own ambient glow):
on hover, the masked line-invert in §5a still fires exactly as specified
(it already flips to the *opposite* Night Market hue — signage↔highlight —
not to a personal accent, so §5a's mechanism needs no change here). What
changes is only the OLD non-`[data-fx]` fallback behavior
(`--glow-in-list-hover`, which read the now-dead `--color-accent`) — that
token and its call sites are dead once §0a's tokens.css cleanup lands, and
any component still referencing it directly (rather than through the
`[data-fx]` mechanism) needs to move onto `[data-fx]` or lose its hover
treatment. Audit target for the build step: grep `--glow-in-list-hover` and
`--color-accent` usage outside tokens.css before deleting the tokens.

### 7h. Nav shell — Sidebar + BottomNav active-tab pill (folded in per §6.4)
Confirmed against real code (`src/styles/layout.css`): Sidebar's active
state today is a 3px notch (`.k-sidebar__item--active::before`) plus a
`--color-accent-dim` wash; BottomNav's is a sliding 2px underline
(`.k-bottomnav__indicator`) with `--color-accent-glow` ink. Both use the now
-dead accent tokens regardless of this pass, so this needed doing anyway.
- **Sidebar**: `.k-sidebar__item--active` gets a filled rounded-background
  pill (using `--radius-plate`'s theme-specific value, small radius on
  Lantern / hard 0 on Neon) in the highlight hue at low-alpha fill, ink at
  full highlight hue, replacing the 3px notch entirely — not layered
  alongside it.
- **BottomNav**: `.k-bottomnav__item[aria-current="page"]` gets the same
  filled pill treatment behind the icon+label, replacing the sliding
  underline indicator (`.k-bottomnav__indicator` retired).
- Scope stays exactly the active-tab pill. No other Sidebar/BottomNav
  structure, spacing, or icon treatment changes in this pass.
- Both retarget their color source from `--color-accent*` to the theme's
  highlight hue token directly, consistent with 7g's audit note.

---

## 8. States summary (quick-reference table)

**Updated 2026-08-11** — "hover: user accent" is gone with the accent-ink
axis (§0a); hover is now the `[data-fx]` masked line-invert per §5a/§7g,
which flips signage↔highlight locally around the cursor rather than
swapping to a personal color.

| State | Border hue | Border width | Glow | Signature FX |
|---|---|---|---|---|
| List member, at rest | signage | 2px | none | none |
| List member, hover (`[data-fx]`) | localized invert to highlight (§5a) | 2px | localized, opposite-hue (§5a) | none |
| Closed / inactive | none (tertiary text only) | 2px, no color | none | none |
| The one open/highlight element (Hero only) | highlight | 2px+ | full `--shadow-card-hi` | flicker (A) / edge-bleed+reflection (B) |

---

## 9. Responsive — REWRITTEN 2026-08-11

This section used to say "no new breakpoints, carry forward 719px and 1100px
untouched, this pass is a skin, not a layout change." Same round 1 leftover
as §0's corrected bullet: it contradicted §1a's structure and the
medium-width decision in §11. Replaced with the real rule.

**Two breakpoints, both structural reveals** (per the app-wide responsive law
in `konsou_overview_desk_overhaul` — a breakpoint exists only where the tree
genuinely changes shape; everything else is `clamp()`/`auto-fill`):

- **Below 720px (phone).** No backdrop: it cannot hold two full cards at this
  width. Planned shows in place, full, with My Order folded inside it as one
  more row. Completed collapses to a real entry button. If Planned is empty,
  Completed expands to fill the slot instead of sitting small next to a gap.
  Tonight drops its secondary meta row first; the watching strip shows the
  scaled-down mini strip (covers + hairlines), not a plain door line.
- **720px and up (medium through wide, ONE rule).** The backdrop appears and
  holds Completed + Planned side by side, always both, no toggle, at every
  width above this line (resolved §11, 2026-08-11 — medium does not get its
  own arrangement). My Order sits as its own column beside the backdrop. The
  alerts band's width tracks the backdrop's column only, never extending
  under My Order.

The old 1100px rail breakpoint is **retired**: it existed because My Order
was a sticky rail that folded into the Planned card below that width, and
§1a replaced that arrangement with a real column. There is no longer a width
at which the order has two different homes.

If a color or glow rule reads badly at 390px, still fix the rule, not the
breakpoint — that part of the old text survives.

---

## 10. Build sequencing

Per standing rule: mockups before build. Order:

1. **This doc gets your sign-off**, including the open questions in §0.
2. **Static comp round**, not live code: 2-3 flat HTML/CSS mockups of the
   Hero subject alone (the highest-stakes single element, since it carries
   the full signature effect) in both themes, side by side, so the flicker
   vs. edge-bleed distinction is judged on the real component shape before
   it touches Overview.tsx.
3. Once the Hero is picked, `/impeccable live` against the running app for
   the Hero specifically — this is a "signature single-component moment"
   per your own standing note on when live mode earns its cost, not a
   rough-concept pass.
4. Roll the confirmed Hero treatment down through 7d-7h mechanically (they
   all reuse the same signage/highlight/closed rule set from §2/§8, so once
   the Hero is right the rest is application, not new design).
5. Full-page verify: both themes, 390/1100/1440, reduced-motion on (this
   machine's default), AA contrast pass matching the rigor of every prior
   round in `KONSOU_RESURFACE_PLAN.md`.

---

## 11. Open decisions — need your answer before build starts

**Resolved since round 1** (kept here for the record, not re-asked):
who's in the room list and their relative weight (§1a); Tonight as a hero;
the watching strip + door replacing a standalone Watching box; the backdrop
pattern for Completed+Planned on desktop, always both, no toggle; My Order's
column placement on wide; mobile's Planned-always / Completed-as-button
logic and its Planned-empty fallback; **mobile watching-strip variant —
the mini strip (covers + progress hairlines, scaled down), not the plain
door line** (2026-08-10).

**Resolved 2026-08-11:** A/B (Lantern, Neon) are the ONLY themes — the other
8 Field Guide plates are retired, not kept alongside. This means the theme
picker in Settings/Appearance collapses from 8 plates + 8 inks down to a
2-theme picker (Lantern/Neon), and every token-dependent surface across the
app (not just Overview) now renders only in one of these two worlds. Flagged
here because this is bigger than an Overview-scoped decision — see the new
§0a below for what it touches.

**Resolved 2026-08-11:** medium width keeps the desktop rule — backdrop
shows Completed + Planned side by side, always both, no toggle, just
narrower. One rule from medium through wide, no separate medium
arrangement. My Order's own placement at medium (its column, relative to
the now-unchanged backdrop) still needs a look once the backdrop is real in
`Overview.tsx` — likely falls out of the desktop rule directly (My Order
stays its own column beside the backdrop) but confirm once it's on screen
at 720-1099px, don't assume.

**Resolved 2026-08-11:** sequel-strip per-card hue (§6.3) is SKIPPED this
round. No "reason" field, no per-card hue — the strip stays one hue for now.
Revisit later if still wanted, as its own small pass, not folded back in
here.

**Resolved 2026-08-11:** nav active-tab pill (§6.4) IS folded into this
pass, reversing §6's own original "out of scope, log it" note. Build target:
Sidebar's active tab (currently a 3px accent notch, no fill per
`konsou_shell_icon_cages` precedent — the icon itself already reads bare)
and BottomNav's active tab (currently an accent rule across the top edge)
both gain a filled rounded-background pill behind the active tab, in the
theme's highlight hue (gold Lantern / teal Neon, matching §0a's now-fixed
per-theme accent), replacing the notch/rule. Scope stays exactly the pill —
nothing else about Sidebar/BottomNav's structure changes. Sequenced with
the rest of §7's walkthrough rewrite (item 6 below) since it's shell chrome,
not part of Overview's own component tree.

**Resolved 2026-08-11:** §7's component walkthrough is REWRITTEN (see §7
above) against §1a's confirmed structure, folding in the nav pill (7h) and
removing every "user accent" reference in favor of the theme's fixed
highlight hue (§0a). §7g also flags a concrete audit target for the build
step: grep `--glow-in-list-hover` and `--color-accent*` usage across the
codebase before tokens.css's cleanup deletes those tokens, since any
component still reading them directly (not through `[data-fx]`) will
silently lose its hover treatment otherwise.

**No open decisions remain.** Every item in this section is resolved. What's
left is execution: build §7's rewritten skin into `Overview.tsx` +
Sidebar/BottomNav, then the tokens.css cleanup from §0a (delete the 8 dead
plates, the accent-ink system, `--glow-in-list-hover`), then full-page
verify per §10.

**BUILT 2026-08-11: Tonight (§7c), real components, both themes.** Live in
`src/pages/Overview.tsx` + `src/styles/pages.css` + `src/styles/tokens.css`,
not just the static comp:
- Per-theme radius correction (§3): `--radius-plate` split to `4px`
  (Lantern) / `0px` (Neon), no longer shared.
- Eyebrow chip kicker (§6.1): tracked mono pill, highlight-hue dot and
  low-alpha fill; hard-cornered on Neon per §3's no-exceptions rule.
- Seal (primary action) now fills in the **signage** hue on both themes,
  the plate border stays **highlight** — §2's one-borrowed-accent crossover,
  concretely built rather than just specified.
- The `[data-fx]` cursor mechanism (§5a) is wired for real: a `useEffect` in
  `Overview.tsx` publishes `--gx`/`--gy`/`--fx-mix` on pointermove, and the
  shared `[data-fx]::after`/`::before` CSS block in `pages.css` is global
  (not Overview-scoped), so every later `[data-fx]` host in §7's wiring
  table (watching strip, backdrop, My Order) can opt in with zero new JS.
  Verified live in the running app, not just read from computed styles:
  dispatching a pointermove over the plate resolved `--fx-mix` to 100%, the
  masked `::after` border to the signage hue, the `::before` wash to
  highlight.
- Lantern flickers (synced `flicker`/`flickerOpp` keyframes, reduced-motion
  holds the brightest frame per §5); Neon stays static (no animation) — the
  old ad hoc `k-hero2-open-flicker` ring on the click-catcher button is
  gone, replaced by the plate's own ambient glow per §5a's canonical shape.
- Watching strip (§7c's second half): progress-hairline fill and the
  running fraction both moved to the highlight hue, overriding the generic
  room-status tint, per §2's progress-in-motion crossover.
- **One real bug found and fixed by verifying in-browser rather than trusting
  the CSS on paper**: the first pass reused `--color-border-strong` for the
  seal fill and `--fx-opp`, assuming it meant "signage, strong variant" in
  both themes. It doesn't — Neon's `--color-border-strong` was already
  pointed at the *highlight*-adjacent teal for hover emphasis (a pre-existing,
  deliberate token from the original Night Market prototype), so the seal
  and the fx ring were rendering the same hue as the plate's own border on
  Neon, silently defeating the whole crossover. Fixed with a new dedicated
  token, `--color-signage-solid` (opaque signage hue, one per theme), used
  for exactly this "solid signage fill" purpose. Re-verified live on both
  themes after the fix: Lantern seal/ring `oklch(0.64 0.2 20)`, Neon plate
  border `oklch(0.76 0.13 195)` (highlight) against seal/ring
  `oklch(0.62 0.24 330)` (signage) — a real two-hue crossover on both.
- Gates: `tsc -b` clean, 184 vitest green, detector clean (same 3
  pre-existing warnings — two `transition:width` progress-bar rules and one
  side-tab/bounce-easing finding elsewhere in the file, none touched by this
  build).

**Caveat on the above, found the same day:** this build landed the skin on
the OLD page tree, because §0's since-corrected bullet told it to. The
token work, the `[data-fx]` mechanism and the plate skin itself are all
sound and transfer as-is (Tonight stays a full-width hero with art plus
plate in §1a too, so the CSS holds; only its place in the tree moves). One
claim made in review and then checked: Tonight's *conditional* render was
listed as missing, and it is not — the existing `hero` resolves to `null`
when nothing is running and nothing is at the head of the order, which is
exactly §1a's rule. That row was wrong; nothing to fix there.

**BUILT 2026-08-11 (same day): §1a's tree, for real.** `Overview.tsx`'s page
tree is now the confirmed structure, not the old one wearing new paint:

- **The watching strip replaces the standalone Watching door.** `WatchRow`
  (full-width rows) is deleted; `WatchStrip` + `WatchTile` are covers with
  progress hairlines in a drag-panned rail, and the door is the footer line
  at the foot of the strip. The room now has exactly one entrance on this
  page. **One deliberate addition to §1a's spec, flagged rather than done
  silently:** each tile keeps a log stamp (hover/focus reveal on pointer,
  always visible on touch, the ⊕ slot's own established rule). §1a describes
  covers-and-hairlines only, but one-tap logging is a founding-why
  guarantee and these are the running shows — dropping it would have quietly
  cost the page most of its logging surface.
- **The backdrop exists** (`.k-ov-back`): a real darker ground with a
  signage keyline that families Planned + Completed without merging them.
  Deliberately a ground with two registers ON it, not a card containing
  cards. `.k-ov-pair` is deleted.
- **My Order is its own column** (`.k-ov-order`), beside the backdrop, not
  beside Tonight.
- **The alerts band tracks the backdrop's column only** — measured at 1027px:
  backdrop 571, alerts 571, page 895. It does not run under the order.
- **Phone tree** (`.k-ov-stack`): no backdrop, Planned in place full with
  the order folded inside it, Completed as a real entry button
  (`CompletedDoor`). The Planned-empty fallback is verified working — with
  nothing planned, the Planned register and the Completed door both
  disappear and Completed expands into the full register.

**§11's deferred medium-width question is now ANSWERED, and it came out the
opposite way to that section's own prediction.** §11 guessed My Order would
"stay its own column beside the backdrop" at 720-1099 and said to confirm on
screen rather than assume. Confirmed on screen: it cannot. With the order
holding a 300px column at 1027px wide, the backdrop is left 571, each
register gets 261 after padding and gutter, and at 261 the room doors clip
their own names ("Pla…", "Com…"). **Resolution: the backdrop keeps its rule
unchanged (both anchors, side by side, no toggle, every width from 720 up);
My Order drops below the backdrop and runs full width between 720 and 1099.**
Note this is not the retired 1100 rail reveal returning — that gate decided
whether the order was a standing rail or was folded INSIDE the Planned card,
two different homes. Here it is the same standing component either way and
only its grid placement changes, which is exactly the "move a built
component as a whole unit" the owner asked for instead of a guessed
breakpoint. Verified after the fix: registers 422px each at 1027, no
clipping.

**Verified live, both themes**, at 1440 / 1027 / 375: no horizontal overflow
at 375; the phone tree and its empty-Planned fallback both correct; §5a's
rule 1 (*"glow belongs to Tonight and Completed only"*, the thing round 15
broke) holds — the strip's `::after` computes `box-shadow: none` while
Tonight's computes a real glow, and the strip's line inverts to highlight
with a signage wash, the exact inverse of Tonight's. Gates: `tsc -b`,
eslint over all of `src`, 184 vitest, detector all clean (same pre-existing
progress-bar and side-tab warnings, none new).

**BUILT 2026-08-12: the real page.** The old `Overview.tsx` and `RoomDoor.tsx`
are DELETED (RoomDoor had exactly one importer). `src/pages/NightMarket.tsx`
+ `src/styles/night-market.css` are the index route: new files, `nm-`
prefixed classes, importing no existing component, token or stylesheet.

- **Structure** from `overview_structure_v2.html`, **skin and composition**
  from `overview_skin_wide.html`. Where the two disagree on Tonight's
  internals (structure_v2 puts the action before a separate meta2 line;
  skin_wide merges meta into one line with the action last), skin_wide wins.
- **Verified against the comp by measurement, not by eye**: the comp was
  copied into `public/`, served, and diffed element by element. Every
  value matches (tonight 216, cover 120x168, chip 23, bar 5, act 37,
  card 150, order cov 26x36, tile 64, backdrop:order 2.4:1).
- **Real, not mock**: store-driven throughout. Log episode verified writing
  through — Ep 11 -> 12, bar 39% -> 43%, persisted to the store.
- **Theme follows the app setting** (`colorTheme`), Lantern or Neon. The
  world-switcher tabs were review scaffolding and are gone.

**Three real bugs, all found by measuring rather than looking:**
1. **The app's global typography leaked in.** The comp is a bare document
   at 16px with `line-height: normal`; the page inherited the app's 15px
   and its leading, inflating every text box (chip 23 -> 32, strip 121 ->
   141). Every single mismatch traced to this. Fixed by re-stating
   `font-size` and `line-height` on `.nm`.
2. **A reset out-specified the rules it supported.** `.nm button {}` scores
   0,1,1 and beat every single-class rule in its own file, silently
   stripping padding from the action button (37px rendering at 21px) and
   the order rows. Fixed with `:where(.nm button)` at zero specificity.
3. **The sequel band ended on a ragged edge.** Backdrop and band were two
   sibling flex rows each resolving their own 2.4:1 — but the backdrop's
   16px padding is a non-shrinkable floor inside a flex row, so it landed
   759 while the bare band landed 752. They now share one column
   (`.nm-main`), which is also the truer reading of the structure doc.
   A 4th, phone-only: the anchor card outside the backdrop row had no flex
   parent to stretch against and collapsed to 120px in a 347px column.

**Responsive, all three verified after a real reload** (matchMedia is stale
on resize in the preview pane — reload at the target width or it lies):
wide 1440 (backdrop + order side by side), medium 1027 (order full width
below, cards 436 each), phone 375 (no backdrop, Planned in place, order
folded under, Completed as a door, no horizontal overflow). The phone
Planned-empty fallback is verified: Planned card and Completed door both
disappear and Completed expands into the slot.

**Deviations from the comp, deliberate and flagged:**
- The `grouping backdrop` label is dropped. It reads as an annotation
  describing the pattern to a mockup reviewer, not product copy.
- Tonight's meta says `Ep n / m` plus an honest status (`still airing`,
  `paused`, `not started`) rather than the comp's `airs weekly · next ep
  in 3d` — the entry carries no next-airing countdown, and inventing one
  would be fabricating data.
- The second sequel tile is `Airing now` (RELEASING entries you are
  watching) rather than `Airing tonight`, for the same reason: no schedule
  data on the entry to support "tonight".
- Two measurements differ from the comp by design: `act` width 114 vs 120
  and `strip` height 121 vs 124. The comp file has no font link, so served
  standalone it falls back to Trebuchet MS; the app loads real Space
  Grotesk, which §0 locks. Matching those numbers would mean rendering the
  wrong typeface.

Gates: `tsc -b`, eslint over all of `src`, 184 vitest, detector clean (its
one finding, `overused-font: Space Grotesk`, is the brief's own locked
font, and the brief outranks a saturated-pattern warning).

**Not yet wired:** cross-status search, the franchise quick-menu/loupe, and
the import sheet all lived on the old page and have no home on this one
yet.

**Resolved 2026-08-12:**
- **Search: an icon beside the census line.** Tapping it replaces the census
  with the field in place; results hang beneath as an overlay so the page
  never moves. This carries forward the lesson the old page paid for
  ("search is in the way") rather than re-litigating it.
- **Touching a title opens the quick menu**, not the detail page. The loupe
  keeps the page you were on; navigating costs a trip back.
- **Import sheet**: belongs to the empty state, which is the only place it
  ever appeared. Fold it in there.

**Open, and worth deciding before the loupe is wired:** the quick menu is a
SHARED app-wide shell (`ItemSurface` -> anchored popover on desktop, sheet
on a phone), used by Planned, Completed, Watching and Anime Detail as well.
Reusing it is architecturally right — it is the app's one positioning
system and rebuilding it per surface is how an app grows five of them. But
its SKIN is still Field Guide, so it will open on this page wearing the old
world. Skinning it is an app-wide pass, not an Overview one, and doing it
scoped to this page only would create the two-worlds problem deliberately.
Decide: wire it now and skin the loupe as its own pass, or hold the loupe
until that pass happens.

**Next step:** the nav pill (§7h), then the tokens.css cleanup from §0a
(delete the 8 dead plates, the accent-ink system, `--glow-in-list-hover`,
and audit `--color-accent*` call sites per §7g before deleting), then
full-page verify per §10 (AA contrast on both themes, reduced-motion).
