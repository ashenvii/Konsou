<!-- INCUMBENT RECORD / ANTI-REFERENCE.
     This documents the world that shipped up to commit 1455eb6. It is being
     REPLACED by a full resurface (feat/mylist-rework). Captured with
     /impeccable document so the new world has an explicit record of what it
     departs from and what behaviour it must preserve. Do not treat this file
     as the target look once the replacement world is committed. -->
---
name: Konsou
description: Offline-first anime tracker — cover-art-forward dark shell, one accent that means "in your list."
colors:
  base: "oklch(8% 0.022 280)"
  surface: "oklch(11% 0.028 280)"
  surface-2: "oklch(15% 0.038 280)"
  surface-3: "oklch(19% 0.048 280)"
  border: "oklch(100% 0 0 / 8%)"
  border-strong: "oklch(100% 0 0 / 18%)"
  text-primary: "oklch(100% 0 0 / 90%)"
  text-secondary: "oklch(100% 0 0 / 60%)"
  text-tertiary: "oklch(100% 0 0 / 38%)"
  accent: "oklch(52% 0.27 290)"
  accent-glow: "oklch(65% 0.18 290)"
  accent-dim: "oklch(52% 0.27 290 / 15%)"
  status-watching: "oklch(64% 0.17 250)"
  status-completed: "oklch(72% 0.17 150)"
  status-plan: "oklch(80% 0.15 85)"
  status-on-hold: "oklch(60% 0.19 300)"
  status-dropped: "oklch(61% 0.21 25)"
  status-rewatching: "oklch(73% 0.13 195)"
  status-not-interested: "oklch(58% 0.015 280)"
  success: "oklch(72% 0.12 165)"
  warning: "oklch(72% 0.16 60)"
  error: "oklch(55% 0.20 10)"
  info: "oklch(62% 0.15 250)"
typography:
  display:
    fontFamily: "Plus Jakarta Sans, Noto Sans JP, Hiragino Sans, Yu Gothic UI, system-ui, sans-serif"
    fontSize: "34px"
    fontWeight: 800
    lineHeight: "42px"
    letterSpacing: "-0.03em"
  title:
    fontFamily: "Plus Jakarta Sans, Noto Sans JP, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: "28px"
  body:
    fontFamily: "Plus Jakarta Sans, Noto Sans JP, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: "20px"
  label:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "10px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "-0.01em"
rounded:
  sm: "4px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  sheet: "28px"
  full: "9999px"
spacing:
  1: "4px"
  2: "8px"
  3: "12px"
  4: "16px"
  6: "24px"
  8: "32px"
  12: "48px"
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "#ffffff"
    rounded: "{rounded.md}"
    padding: "0 16px"
    height: "40px"
  button-secondary:
    backgroundColor: "{colors.surface-2}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "0 16px"
    height: "40px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.md}"
    padding: "0 16px"
    height: "40px"
  chip:
    backgroundColor: "{colors.surface-2}"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.full}"
    height: "32px"
  chip-active:
    backgroundColor: "{colors.accent-dim}"
    textColor: "{colors.accent-glow}"
    rounded: "{rounded.full}"
    height: "32px"
---

# Design System: Konsou (incumbent record)

## Overview

**Creative North Star: "The Late-Night Cover Wall"**

The shipped world is a dark, tinted app shell built to disappear behind anime cover art. The scene it was drawn for is real and worth preserving: someone at home, late, in a low-light room, running Konsou next to whatever is playing on another screen. Everything answers that: near-black surfaces so the room stays dark, cover thumbnails as the loudest thing on every surface, and a single accent color that carries one job — signalling "this is in your list" — through a soft bloom under in-list cards.

It is competent and it is also generic. The surfaces are near-black with a low-chroma hue cast (violet by default), one accent with a glow, flat grey cards, pill chips, a floating bottom-nav pill, `Plus Jakarta Sans` for everything. Radii sit at the safe 8–16px middle. Depth is drop-shadow plus accent-glow bloom. None of it is wrong; all of it is the trained default for "modern dark app." This is the exact distribution the resurface is departing from. Read this file as the anti-reference: what the new world must not reach for by reflex.

What is genuinely load-bearing and must survive any reskin lives below in **Do's and Don'ts** and in the behaviour notes: state is never color-alone, AA contrast holds across all eight themes, and the eight-theme + overridable-accent architecture is a product capability, not decoration.

**Key Characteristics:**
- Dark by default; every theme carries a deliberate low-chroma hue cast, never neutral grey.
- One accent, user-overridable, meaning "in your list" — never decorative.
- Cover art is the hero; chrome recedes.
- Eight themes (6 dark, 2 light) from one token contract.
- State encoded redundantly: hue + glow/shape/label, never hue alone.

## Colors

A family of near-black (and two near-white) surfaces, each tinted toward one hue so the dark reads as a color and not as grey, with a single vivid accent floated on top.

### Primary
- **Accent Violet** (`oklch(52% 0.27 290)`): the default accent. Used on in-list glow, active nav pills, primary buttons, active chips, focus rings. Overridable per user via `[data-accent]` (coral, violet, cobalt, crimson, sakura, amber, aqua, jade). Carried as decomposed `--color-accent-h/l/c` so glows can be rebuilt at any opacity.
- **Accent Glow** (`oklch(65% 0.18 290)`): the lighter partner used for accent-colored *text* on dim backgrounds (active chip labels, nav labels, toast actions) where the solid accent would fail contrast.

### Neutral (surfaces)
- **Void Base** (`oklch(8% 0.022 280)`): the default app background. Five more dark themes retint the same ladder — Ocean (218), Ember (34, the warm coal that memory calls the brand default), Forest (148), Midnight (258), Crimson (8) — and two light themes invert it: Paper (near-white manga page) and Ash (cool slate with white cards).
- **Surface / Surface-2 / Surface-3** (`oklch(11/15/19% …)`): the tonal-layering ladder. Cards, hover states, and raised chrome step up this ladder rather than relying on shadow alone.
- **Border / Border-strong** (`white / 8%` and `18%`): hairlines and dividers as translucent white, so they track surface lightness.

### Text
- **Text Primary / Secondary / Tertiary** (`white / 90% · 60% · 38%`): translucent white ramp on dark; ink ramp on the two light themes. Tertiary is deliberately pulled up to secondary in a few input placeholders because 38% fails AA.

### Tertiary (status — semantic)
- Six watch states each own a distinct hue so status reads at a glance: watching **blue** (250), completed **green** (150), plan **amber** (85), on-hold **purple** (300), dropped **red** (25), rewatching **teal** (195). Not-interested is a deliberately muted grey (`0.015` chroma) so a "won't watch" flag never shouts louder than a real state.

### Named Rules
**The One Accent Rule.** Exactly one accent is live at a time; it means "in your list," never "look here for decoration." Hover alone earns a depth shadow, not color.
**The No Neutral Grey Rule.** Every surface carries a hue cast (chroma ≥ 0.022 on dark themes). A pure grey background is a bug.
**The Redundant State Rule.** Status and in-list are never signalled by hue alone. Hue always pairs with a glow, a shape, or a text label so the interface holds up for colorblind users.

## Typography

**Display / Body Font:** `Plus Jakarta Sans` (with `Noto Sans JP` / `Hiragino Sans` / `Yu Gothic UI` for Japanese titles, then `system-ui`).
**Label/Mono Font:** none distinct; labels are the same family at small sizes with negative tracking.

**Character:** One geometric humanist sans doing every job. Body text sits at an unusually heavy `500` for a UI, wordmarks push to `800` with tight `-0.03em` tracking. Competent and completely conventional — this is one of the training-data default families the resurface is told to replace unless it truly cannot be.

### Hierarchy
- **Display** (800, 34px/42px, `-0.03em`): page-level titles, stat headline numbers.
- **Title** (600, 20px/28px): sheet titles, section headers, empty-state titles.
- **Body** (500, 14px/20px): the default. Everything unmarked is this.
- **Label** (600, 10–13px, tight tracking, occasional uppercase): nav labels, chips, metadata, badges.

### Named Rules
**The Heavy-Body Rule.** UI body copy is `500`, not `400`; the app never uses a truly light weight for reading text.

## Layout

Two shells off one breakpoint at 1024px. **Mobile:** a single scrolling column under a persistent 56px header, with a floating bottom-nav pill (max 360px, fully rounded, drop-shadowed) hovering above the content. **Desktop:** a collapsible left icon rail (64px collapsed → 220px on hover, absolutely positioned so hover-expand overlays content instead of reflowing it), content column to its right. Settings is a "backstage" mode: no rail, one centered 720px column.

Spacing is a strict 4px base unit (`--space-1..20`). The header is scroll-away: `useScrollElevation` writes `margin-top` inline (0 → -56px) so the header reclaims its own space as you scroll down and returns on the way up, gaining a soft shadow only once scrolled. Large collections are virtualized (absolute-positioned rows inside a measured inner). My List offers three densities (Grid / List / Compact).

## Elevation & Depth

Hybrid: tonal layering does most of the work, drop shadows and an accent bloom finish it. Surfaces step up the `surface → surface-2 → surface-3` ladder for rest-state depth; shadows are reserved for genuinely floating chrome (sheets, toasts, the nav pill, the command palette). The signature depth cue is the **in-list glow** — a colored bloom (`--glow-in-list`) whose hue tracks the live accent, layered over a black drop shadow, that marks a card as "in your list." Light themes swap the bloom for a 1px accent ring because bloom looks dirty on white.

### Shadow Vocabulary
- **Card** (`0 4px 16px oklch(0% 0 0 / 45%)`): resting cards and raised tiles.
- **Card-hi** (`0 6px 28px / 55%`): card hover.
- **Sheet** (`0 -8px 40px / 60%`): bottom sheet, lifting up off the page.
- **Pop** (`0 8px 32px / 52%`): toasts, popovers.
- **In-list glow** (`0 0 10px accent/28% , 0 4px 16px black/44%`): the in-list marker; hue follows `--color-accent`.

### Named Rules
**The Glow-Means-Owned Rule.** The accent bloom is the "in your list" signal and nothing else. Hover raises the black shadow (`card` → `card-hi`); only membership adds color.

## Shapes

A conventional soft-rounded language. Radii climb `4 / 8 / 12 / 16px` for controls and cards, `28px` for the top corners of bottom sheets, and `9999px` for pills (chips, nav pill, bottom-nav items, avatars, the search field). Buttons are 8px, cards 12–16px, chips fully round. Borders are single translucent-white hairlines. There is no distinctive silhouette, clip, or corner treatment — everything is a rounded rectangle or a pill. This uniform middle-radius softness is part of what reads as generic and is open for the resurface to replace with a real form language.

## Components

### Buttons (`.k-btn`)
- **Shape:** 8px radius (`--radius-md`), three heights (32 / 40 / 48px), `600` weight, `scale(0.97)` on press.
- **Primary:** solid accent fill, white text, a soft accent-colored shadow (`0 2px 12px accent/30%`); hover is `brightness(1.08)`.
- **Secondary:** `surface-2` fill, hairline border; hover steps to `surface-3`.
- **Ghost:** transparent, secondary text; hover fills `surface-2`.
- **Danger:** transparent with a color-mixed error border; hover fills a faint error wash.

### Chips (`.k-chip`)
- **Style:** fully-rounded, 32px tall, `surface-2` fill, hairline border, secondary text.
- **State:** active chips fill `accent-dim`, border to a 50%-accent mix, label to `accent-glow`. Removable chips carry a 22px round close target.

### Cards / Containers
- **Corner Style:** 12–16px.
- **Background:** `surface` / `surface-2`, stepping to `surface-3` on hover.
- **Shadow Strategy:** `card` at rest → `card-hi` on hover; `glow-in-list` when the item is in the user's list.
- **Border:** optional hairline.
- **Internal Padding:** 12–20px off the 4px scale.

### Inputs / Fields
- **Style:** fully-rounded search "pill" (`.k-hsearch`, 40px) or borderless palette input; `surface-2` fill, hairline border.
- **Focus:** border shifts to solid accent (`:focus-within`). Keyboard focus rings are a 2px accent outline with 3px offset, shown only for `:focus-visible`.
- **Placeholders:** pulled to secondary (not tertiary) text to hold AA.

### Navigation
- **Desktop sidebar:** 64px icon rail, hover-expands to 220px with labels fading in via `max-width` + opacity transitions. Active item fills `accent-dim` with `accent-glow` text and icon.
- **Mobile bottom nav:** a floating fully-rounded pill; active item fills `accent-dim`, text/icon go `accent-glow`. Unread badges are a red (`--color-error`) dot, top-right, with a pop animation.

### Signature: Bottom Sheet (`.k-sheet`)
Mobile-first modal that rises from the bottom (`translateY(100%) → 0`, 300ms) with a 28px top-corner radius, a grab handle, and pull-to-close; on desktop (≥1024px) it recenters as a 440px pop-in dialog with a 16px radius and no handle. This is the app's primary "more detail / confirm / edit" surface and its one genuinely characterful component.

### Motion
Durations `100 / 150 / 200 / 220 / 300 / 400ms`; eases are a standard `out`, `in`, Material-ish `standard`, and one `spring` (`cubic-bezier(0.34, 1.56, 0.64, 1)`) used sparingly. Reduced-motion is handled with real care: crossfades survive, hold-to-confirm fill keeps its true duration (it is progress, not decoration), spinners and the support heartbeat keep animating because Windows reports `reduce` whenever desktop "animation effects" are off.

## Do's and Don'ts

These are the load-bearing invariants. Everything about *the look* above is anti-reference; everything here is a constraint the new world inherits.

### Do:
- **Do** keep state redundantly encoded: hue always pairs with glow, shape, or label (colorblind-safe). This is a PRODUCT.md accessibility commitment.
- **Do** hold WCAG 2.1 AA contrast across all eight themes, including the two light ones. Placeholders and tertiary text are the usual failure points.
- **Do** preserve the eight-theme + overridable-accent architecture as a real capability driven from `src/styles/tokens.css`.
- **Do** let cover art be the loudest element on any list surface; chrome supports it.
- **Do** keep every behaviour: instant SQLite load, one-tap episode logging with undo, sign-in-once, Drive sync, sequel radar, three list densities, virtualization, scroll-away header, native affordances (bottom sheet on mobile / dialog on desktop).
- **Do** respect reduced-motion the way the incumbent does: keep progress and liveness cues, drop decorative movement.

### Don't:
- **Don't** treat this file's *look* as the target. Near-black-plus-one-glow, flat grey cards, uniform 8–16px radii, and `Plus Jakarta Sans` are the distribution being replaced.
- **Don't** ship a neutral grey surface; every theme must carry a deliberate hue.
- **Don't** use the accent as decoration. It means "in your list" / active, nothing else.
- **Don't** signal any state by color alone.
- **Don't** let expression bury the task: this is an Operate surface first. Scanability and familiar affordances outrank flourish.
