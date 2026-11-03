<!-- ============================================================================
     DIRECTION CONTRACT - The Night Market (current world, feat/mylist-rework)
     Supersedes "The Field Guide", which was retired 2026-08-10 and whose text
     is preserved in git history. The pre-Field-Guide world (warm near-black +
     one accent + glow) remains the anti-reference at docs/DESIGN.anti-reference.md.

     THESIS: Konsou is a night market you keep. The record is a lit stall front
       in a dark street: signage, hand-lettered numbers, a shutter, a torn chit.
       Cover art is the goods. Everything the interface does is a stallholder's
       act: you light what is open tonight, you count what you have taken, you
       tear off what is finished, you queue what is next.
     OWN-WORLD: A near-black street with ONE lit SUBJECT per surface, and at most
       one further lit mark on an anchor that records something live. Two hues per
       world and no more: SIGNAGE (the hue that names a thing) and HIGHLIGHT (the
       hue that means live, counted, yours). Apparatus is mono; subjects are
       Space Grotesk. No third accent, no per-theme accent picker, and no glow
       anywhere the two rules above do not put one.
     STORY: You open the street, one stall is lit (tonight's episode), you log it,
       the rest of the market is legible but unlit, and what you finished has been
       torn off and filed. You leave knowing the record is yours and permanent.
     FIRST VIEWPORT (My List): Tonight lit by the PAGE, not by a plate; the
       Watching drawer under it; Planned with the watch order folded in; the
       Completed board as a wall of the covers you have finished.
     FORM: two plates of one world, Lantern (default) and Neon. Not eight themes.
============================================================================ -->
---
name: Konsou
description: The Night Market, a lit stall front on a dark street, in two plates, Lantern and Neon.
worlds:
  lantern:
    label: Lantern
    default: true
    base: "oklch(13% 0.035 18)"
    sunk: "color-mix(in oklab, black 22%, base)"
    surface: "color-mix(in oklab, ink 3.5%, base)"
    surface-2: "color-mix(in oklab, ink 6%, base)"
    surface-3: "color-mix(in oklab, ink 9%, base)"
    signage: "oklch(64% 0.25 16)"
    highlight: "oklch(83% 0.17 84)"
    line: "oklch(90% 0.02 88 / 10%)"
    line-strong: "oklch(90% 0.02 88 / 22%)"
    corner: "4px"
  neon:
    label: Neon
    default: false
    base: "oklch(11% 0.025 262)"
    sunk: "color-mix(in oklab, black 26%, base)"
    signage: "oklch(66% 0.29 346)"
    highlight: "oklch(82% 0.15 196)"
    corner: "0px"
ink:
  raw: "oklch(90% 0.02 88)"
  title: "oklch(90% 0.02 88)"
  meta: "oklch(90% 0.02 88 / 62%)"
  label: "oklch(90% 0.02 88 / 55%)"
  on-signage: "{world.base}"
  on-highlight: "{world.base}"
typography:
  subject:
    fontFamily: "Space Grotesk, Noto Sans JP, ui-sans-serif, system-ui, sans-serif"
    fontSize: "44px"
    lineHeight: "50px"
    fontWeight: 500
    letterSpacing: "-0.01em"
  title:
    fontFamily: "Space Grotesk, Noto Sans JP, ui-sans-serif, system-ui, sans-serif"
    fontSize: "26px"
    lineHeight: "32px"
    fontWeight: 500
  body:
    fontFamily: "Space Grotesk, Noto Sans JP, ui-sans-serif, system-ui, sans-serif"
    fontSize: "14px"
    lineHeight: "20px"
    fontWeight: 400
  label:
    fontFamily: "IBM Plex Mono, ui-monospace, Courier New, monospace"
    fontSize: "10px"
    lineHeight: "14px"
    letterSpacing: "0.08em"
    textTransform: "uppercase"
  figure:
    fontFamily: "IBM Plex Mono, ui-monospace, Courier New, monospace"
    fontSize: "11.5px"
    lineHeight: "16px"
    fontVariantNumeric: "tabular-nums"
ramp: [10, 11.5, 12.5, 14, 16, 20, 26, 34, 44]
rounded:
  tag: "{world.corner} * 0.25"
  sm: "{world.corner} * 0.5"
  md: "{world.corner}"
  lg: "{world.corner} * 1.5"
  xl: "{world.corner} * 2"
  sheet: "{world.corner} * 3"
  full: "9999px"
spacing:
  1: "4px"
  2: "8px"
  3: "12px"
  4: "16px"
  5: "20px"
  6: "24px"
  8: "32px"
  10: "40px"
  12: "48px"
motion:
  instant: "100ms"
  fast: "150ms"
  normal: "200ms"
  push: "220ms"
  sheet: "300ms"
  hero: "400ms"
  ease-out: "cubic-bezier(0, 0, 0.2, 1)"
  ease-standard: "cubic-bezier(0.2, 0, 0, 1)"
  ease-spring: "cubic-bezier(0.34, 1.56, 0.64, 1)"
  ease-stamp: "cubic-bezier(0.22, 0.9, 0.28, 1)"
  wave-lap: "6s"
  wave-steps: ["0.34s", "0.68s", "1.02s"]
---

# Design System: Konsou, the Night Market

## Overview

**Creative North Star: "The Night Market"**

Konsou is a night market you keep. The scene it is drawn for has not changed and is still binding: someone at home, late, in a low-light room, a second screen glowing, reaching for their own record. So the surface is a dark street, and the record is a lit stall front on it. Cover art is the goods on the shelf. Everything the interface does is a stallholder's act: you light what is open tonight, you count what you have taken, you tear off what is finished, and you queue what is next.

The world exists to answer a measured problem, not a mood. An audit of the built app found the whole tonal ladder spanning 15 L\* with a 74 point void above it, 94.5% of on-screen characters sitting in a 12 to 14px band, and no dominant object anywhere. That is what "it doesn't feel like an app" measures as. The Night Market fixes it structurally: one lit subject per surface, a ladder with real range under it, and a display step nothing else is allowed to touch.

**Key characteristics:**

- **Two hues, and only two.** Every world states a **signage** hue (names a thing, marks a boundary, identifies a room) and a **highlight** hue (means live, counted, yours). There is no third accent and no accent picker. The old per-theme accent-ink system is deleted.
- **One lit SUBJECT per surface, and a small number of lit MARKS.** The `--live-*` group is the only real glow in the app. A surface has exactly one subject wearing it (on My List that is Tonight), and an anchor may carry a quieter one where the anchor is itself a record of something live. Two is the ceiling and it has to be earned; three means the surface has no subject.
- **Two plates, not eight themes.** Lantern (default) and Neon are two renditions of one world, not two palettes on a neutral chassis. They differ in ground, in both hues, in corner, and in how their motion behaves.
- **The world owns motion.** Timing, the wave, and whether the wave faults are world properties in layer 2, not per-component decisions.
- **Ink on a filled hue is dark.** Both hues are bright fills. Measured, near-white on them reads 3.52:1 and 1.57:1. The world's own ground on them reads 5.26:1 and 11.8:1.
- **Cover art is the loudest thing.** Chrome is ink and hairline on near-black around it.

## The library: three layers

`src/styles/tokens.css` is the whole colour and measurement system and it has exactly three layers. The rule for which layer a value belongs in is the only rule to hold.

| Layer | What it holds | Who edits it |
| --- | --- | --- |
| 1, primitives | Space, the type ramp, motion durations, eases, layout. True in every world. | Nobody, unless the app's structure changes. |
| 2, world | What a theme *is*: grounds, ink, its two hues, its line, its corner, its faces, its rhythm. | Adding a world means copying this block and changing values. Nothing else. |
| 3, parts | What components read: `--plate-*`, `--row-*`, `--chip-*`, `--seal-*`, `--door-*`, `--field-*`, `--overlay-*`, `--record-*`. | Restyle every plate in the app with one line here. |

**Components never reach past layer 3 for a colour.** They ask for `--plate-bg`, never for a hue. A component that has to break the rule overrides a layer 3 token on itself, locally, so the exception stays visible where it happens instead of becoming a hardcoded colour buried thousands of lines into a stylesheet.

## Colors

### The two hues

**Signage** names a thing. It is the hue on a room's frame, a chevron, a door, a filed mark, a seal. It is a boundary colour and it has to clear 3:1 where it is drawn, which is why it lives on containers and never on a 12px string.

**Highlight** means live, counted, yours. It is the episode you logged, the count on the record, the meter fill, the nav mark, the one glowing element.

| | Lantern | Neon |
| --- | --- | --- |
| Ground | `oklch(13% 0.035 18)` warm near-black, red cast | `oklch(11% 0.025 262)` blue-black |
| Signage | `oklch(64% 0.25 16)` coral | `oklch(66% 0.29 346)` magenta |
| Highlight | `oklch(83% 0.17 84)` amber | `oklch(82% 0.15 196)` cyan |
| Corner | `4px` | `0px`, hard, no exceptions |
| Light | lit, and it flickers | static, and it burns |

### The grounds

Surfaces are **mixed from the base**, never written as literals, so a world states its base once and the whole stack stays in tune with it: `surface` at 3.5% ink, `surface-2` at 6%, `surface-3` at 9%, and `sunk` at 22% (Lantern) or 26% (Neon) black. `sunk` is the recessed ground, darker than the base, used to family several distinct tiles without merging them into one card.

### The ink tiers, and the floor under them

Warm ivory `oklch(90% 0.02 88)`, in three tiers, measured with a canvas probe because `getComputedStyle` hands back oklab and breaks naive contrast maths.

- **Title / body**, full ink: 14.6:1 on a plate.
- **Meta**, 62%: 5.96:1.
- **Label**, 55%. The old faint tier sat at 40% and measured 3.08:1, which is under AA for the body text that every "meta" and "label" line in this app actually is. 52.5% is the exact point it clears 4.5:1; 55% is that plus headroom for the lighter grounds.

### Named rules

**The Two-Hue Rule.** A world has a signage hue and a highlight hue. Anything that wants a third colour is either status data or it is wrong.

**The Ink-on-Fill Rule.** Ink that sits on a filled hue is the world's own base, dark, in both worlds. The ivory-on-accent habit came from an accent that used to sit ten points darker and it fails now.

**The One-Lit-Subject Rule.** `--live-glow` is the only real glow, and the surface's subject always wears it. A second, quieter one is allowed on an anchor that records something live, which is why Completed carries one: a count that is still growing is live in the sense the highlight hue means. Nothing else gets it, and a third is always a mistake.

**The Boundary Rule.** A hue identifies the container, not the words in it. Labels read in neutral ink.

**Status is data, not decoration.** The seven status hues are the one place the two-hue rule does not reach, deliberately. Hue says which state, chroma says how live it is, and every one carries a glyph and a word so it never depends on colour. All sit at L 62%, which clears 4.5:1 on every ground in both worlds. They predate the two-hue world and have not been retuned against it; that is a known open item, recorded at the end of `tokens.css`.

## Typography

**Subjects and body:** `Space Grotesk`, with `Noto Sans JP` for Japanese titles.
**Apparatus:** `IBM Plex Mono`. Every number, label, count, date and figure.

The ramp is nine steps: 10 / 11.5 / 12.5 / 14 / 16 / 20 / 26 / 34 / 44. It was retuned for these two faces, which have a much larger x-height than the faces the ramp was originally cut for and read the same at 1 to 2px smaller. The built surface had drifted to twelve ad hoc sizes because each was transcribed off a mockup one at a time; they collapse onto these nine.

### Named rules

**The Subject Rule.** 44px is the display step and it is reserved for the ONE thing a surface is about. Never a section heading. A scale is not a hierarchy until something reaches the top of it.

**Figures are not headings, and the ramp does not govern them.** A serial set large is a MARK, the way a number painted on a shutter is, and it is sized by the object it is printed on rather than by the type ramp. Completed's count is 98px because that is what the chit takes; it does not make Completed the surface's subject and it does not compete with Tonight, because a figure and a title are not read against each other. The rule the ramp still holds over it: a figure never borrows the display face, and a heading never borrows the figure's size.

**The Apparatus Rule.** Mono labels are uppercased and tracked at `0.08em`. Mono figures are natural case and tabular. Reading text is never set in mono, and a figure is never set in the display face.

**The Serial Rule.** A large figure that reads as a serial (the Completed count) carries no group separator. Grouping at 90px and above in a mono face splits one number into two, because the separator occupies a full character cell.

## Layout

Two shells off 1024px. **Desktop:** a left icon rail, the surface filling the rest. **Mobile:** a single scrolling field under a compact header, with a bottom tab ledger.

Breakpoints are **structural reveals only**. Anything that is merely "bigger" is `clamp()` or `auto-fill`, never a media query. The one exception on My List is 720px, below which Completed reduces to a door whenever anything is planned.

### The scroll law

Wheel and page scroll are never interrupted. Desktop rails pan by drag with scrollbars hidden. Any new rail copies the `.k-queue` contract rather than inventing its own.

## Elevation and depth

Ground, not bloom. Depth is carried by the ladder (`sunk` under `base` under `surface` under `surface-2` under `surface-3`) and by hairlines, with two shadow steps for things that genuinely lift.

- **Plate:** `0 1px 2px oklch(0% 0 0 / 40%), 0 8px 20px oklch(0% 0 0 / 26%)`
- **Plate raised:** `0 2px 5px oklch(0% 0 0 / 44%), 0 14px 30px oklch(0% 0 0 / 34%)`
- **Overlay:** `0 12px 40px oklch(0% 0 0 / 50%)`; sheets `0 -8px 40px oklch(0% 0 0 / 55%)`

**Parallax is a depth cue and it is used honestly.** Where two layers move at different rates (the Completed board's wall against its linework), the mismatch is the cue. Moving them together is one flat picture sliding.

## Shapes

The corner is a world property. Lantern is `4px` and every radius step in layer 1 is a multiple of it; Neon collapses all of them to `0px`. The only fully round elements are seals, avatars and spinner rings.

## Components

### Plates and doors
A plate is `--plate-bg` with `--plate-line` and `--plate-radius`. A door is a plate whose line is signage: it says "this opens". Where a whole card is one action, the card is the button and carries no second control.

### Rows
Rows are transparent at rest and take `--row-bg-hover` on hover. A list of rows is separated by ground and hairline, not by a card each.

### The record
`--record-wait` and `--record-void` are the two tiers under the highlight fill on an episode record, and they hold their order on all three grounds the record sits on: bare plate, scrim over a bright cover, and the lit page. Measured 5.98 / 5.10 / 4.02 and 4.21 / 3.83 / 3.17. `--record-void` is the faintest fill that still clears the 3:1 graphics bar on the thinnest of those grounds.

### Signature surfaces
- **Tonight** is lit by the PAGE above 720px. It has no plate of its own; the wash, the lamp and the grain are page layers and every other block on the surface is opaque so it hides them. The pointer lamp is MOVED by transform, never redrawn.
- **The Watching drawer** sits flush under Tonight and runs the world's wave across its cards.
- **Planned** carries the watch order folded into it at every width.
- **The Completed board** is a wall of the covers you have finished, behind a veil that thins where your hand is, with a chit torn off it in Lantern and a half-drawn shutter over it in Neon.

## Motion

**Motion is a world property.** Layer 2 states the lap and the steps; Lantern completes the wave every time, Neon runs the same wave and occasionally faults. The fault cannot live in CSS because CSS cannot be random, so the scheduler is in the component and the world only says whether it is allowed.

Users control this in Settings, Appearance, Motion, which has its own mode independent of the OS setting.

### Rules that any autonomous surface must obey

1. Anything that advances on its own needs a pause control.
2. It pauses on hover AND on focus, checked on the tick rather than trusted to events.
3. It is still under reduced motion.
4. `prefers-reduced-motion` is TRUE on the development machine, so an animation that looks fine there may never have run.

### Physical motion is modelled, not guessed
Where an element imitates a real mechanism, the timing comes from the mechanism. The Completed board's tiles are split-flap units: they fall under gravity on a parabolic ease-in, arrest, and rebound a few degrees, with per-tile perspective and a shading ramp that darkens the face as it turns away from the light. A constant-speed rotate with no shading reads as a generic CSS card flip, which is what it was before it was measured against the reference. See `src/styles/night-market.css` for the curve and the sources behind it.

## Do's and Don'ts

### Do
- **Do** keep every behaviour and its speed: instant SQLite load, one-tap log with undo, sign-in-once, Drive sync, sequel radar, virtualisation, the scroll-away header, sheet on mobile and dialog on desktop.
- **Do** encode state as hue AND glyph AND word.
- **Do** hold WCAG 2.1 AA in both worlds; measure with a canvas probe, never with `getComputedStyle` maths.
- **Do** give every surface one subject, at the display step, and let it win by enough that nobody has to compare.
- **Do** add a world by copying the layer 2 block. If you had to touch layer 1 or a component, the world is wrong or the token is in the wrong layer.
- **Do** delete the old surface before building the new one. Reworks that edit the old page or nest its components in new wrappers inherit its bugs.

### Don't
- **Don't** bring back the anti-reference: no accent-glow bloom on every card, no fully rounded pills, no gradient text, no coloured left borders, no `Plus Jakarta Sans`.
- **Don't** add a third hue, a per-theme accent, or a theme that is a palette rather than a world.
- **Don't** signal any state by colour alone.
- **Don't** put `overflow: hidden` on a card whose focus ring, glow or line invert paints outside its box. The clip belongs to the art layer and only to it.
- **Don't** drive a per-frame scroll value through a `:root` CSS variable. Measured at roughly 40ms per frame.
- **Don't** write `calc(8px * var(--x))` and expect it to animate. It is silently inert in the target webviews and `@property` does not save it.
- **Don't** add a token to silence a check. A value earns its place by the world and by measurement.
