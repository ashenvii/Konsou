---
name: Konsou
description: A flat, square, dark anime tracker where cyan pop marks the chosen thing and teal marks what is done or live.
colors:
  ground: "#0D0E12"
  surface: "#1C232B"
  raised: "#14181E"
  line: "#3A3D44"
  ink: "#C5C6CA"
  ink-soft: "#A9AAAE"
  ink-muted: "#8E8F94"
  pop: "#6AFBEE"
  support: "#46A29F"
  red: "#EF5A5F"
  key-face: "#2E343C"
  key-slab: "#242A31"
  well-edge: "#14161A"
typography:
  heading:
    fontFamily: "IBM Plex Sans, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1
  label:
    fontFamily: "IBM Plex Sans, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1
  caption:
    fontFamily: "IBM Plex Sans, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1
  figure:
    fontFamily: "IBM Plex Mono, ui-monospace, monospace"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1
  count:
    fontFamily: "IBM Plex Mono, ui-monospace, monospace"
    fontSize: "11px"
    fontWeight: 700
    lineHeight: 1
rounded:
  square: "0px"
spacing:
  space-1: "4px"
  space-2: "8px"
  space-3: "12px"
  space-4: "16px"
  space-5: "24px"
components:
  button-primary:
    backgroundColor: "{colors.pop}"
    textColor: "{colors.ground}"
    rounded: "{rounded.square}"
    height: "36px"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
    height: "36px"
  field:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
    height: "36px"
  popover:
    backgroundColor: "{colors.raised}"
    textColor: "{colors.ink-soft}"
    rounded: "{rounded.square}"
  key-cap:
    backgroundColor: "{colors.key-face}"
    textColor: "{colors.ink-soft}"
    rounded: "{rounded.square}"
---

<!-- Generated from lib/design/tokens.dart and the shipped components, 2026-11-13. Tokens in the frontmatter are normative; change them in tokens.dart and notes/design/tokens.md first. -->

# Design System: Konsou

## Overview

One flat dark ground, square edges, and almost no color, so that the few marks that do carry color (pop cyan for the chosen thing, support teal for what is done or live) read at once. It is an Operate surface: the user is scanning hundreds of entries and changing a status in two keystrokes, so familiarity and speed outrank expression. Personality lives in details: the Nekomimi, the key caps, the live edge under a hovered control.

**Key Characteristics:**
- One dark ground with two fill steps above it. No gradients inside content, no rounded corners.
- Color is rare and carries meaning. Pop chooses, support is done or live, red removes.
- Plex Sans for words, Plex Mono for numbers and labels. Weights regular and bold only.
- Hairline separation through tone, not lines. Hover is a live edge, not a box.

## Colors

A near-black blue-grey ground with cool grey inks, one bright pop and one quiet support color. All five main colors are scheme 12 of visme.co/blog/website-color-schemes, picked by the owner on 2026-11-21.

### Primary
- **Pop Cyan** (#6AFBEE): the chosen state and the primary button. A cyan icon with no fill marks the selected item; in the rail a cyan mark sits on its edge.

### Secondary
- **Support Teal** (#46A29F): done and live things: the rail badge, status dots, a finished title's check, tags, the hover edge.

### Tertiary
- **Remove Red** (#EF5A5F): remove, exclude, sync lost. Never the only cue. Not in the scheme; lifted from #E94D52 on 2026-11-21 to pass 4.5:1 on Panel Slate (about 4.7).

### Neutral
- **Night Ground** (#0D0E12): the page, rail and top bar.
- **Panel Slate** (#1C232B): fields, secondary buttons, panels, skeletons.
- **Raised Slate** (#14181E): menus and popovers.
- **Divider Slate** (#3A3D44): the hairline inside menus. Decoration only.
- **Ink** (#C5C6CA), **Soft Ink** (#A9AAAE), **Muted Ink** (#8E8F94): main, secondary and meta text. Soft and Muted are Ink stepped toward the ground.
- **Key Face** (#2E343C) and **Key Slab** (#242A31, the hairline tone, so the key's side shows against the ground): the two steps of a key cap. **Well Edge** (#14161A): the top cut of the dropped search well.

### Named Rules
**The Rare Color Rule.** Pop, support and red together cover a small part of any screen. If a screen needs a second place to look, it is wrong.
**The No Color Alone Rule.** Every state has a shape, word or position as well as its color. The Completed check is a check mark first and teal second.
**The Muted Ink Rule.** Muted Ink (#8E8F94) is about 5.9:1 on the ground, 4.8:1 on Panel Slate and 5.4:1 on Raised Slate, so it passes 4.5:1 on every fill. Check any new fill before putting meta text on it.

## Typography

**Display Font:** none. **Body and labels:** IBM Plex Sans (with system-ui). **Numbers and tags:** IBM Plex Mono.

**Character:** a technical, even pair. The mono carries counts and "EP 07 / 24" so numbers line up and read as data.

### Hierarchy
- **Heading** (700, 18px, 1.0): page and section heads.
- **Label** (400 or 700, 14px, 1.0): buttons, tabs, menu rows, titles.
- **Caption** (400, 12px, 1.0): meta lines under a title.
- **Figure** (Mono 400, 12px) and **Count** (Mono 700, 11px): progress, counts, key caps.

### Named Rules
**The Four Sizes Rule.** 11, 12, 14 and 18 are the only sizes. Weights are regular and bold only.
**The Wrapping Text Rule.** Text that can wrap onto a second line (toast messages, long titles, notes) uses a line height of 1.4 (`lineHeightWrapped`, `AppText.paragraph`). Single-line labels stay at 1.0 inside their fixed control. No extra word or letter spacing anywhere; the text stays compact.

## Layout

A 4-point rhythm (4, 8, 12, 16, 24). The top bar is 36, the Windows rail 48 with 36 square items. Controls are 36 tall; on touch every pressable is hit over at least 48 by 48 while keeping its drawn size. The Library grid is auto-fill with a 168 minimum card; list rows are 72. The Library header's grid and list switch and the top search sit on the window's centre line, not the page's. Responsive changes are structural (rail on desktop, bottom bar on phones), never fluid type.

**Android target (parked until the desktop app is complete, owner 2026-11-13; desktop components and icons are built to be reused on it):** a bottom navigation bar with labels on compact width, a rail on expanded width, edge-to-edge with window insets, system Back always honored, snackbars for transient feedback. Desktop is never weakened by this.

## Elevation & Depth

Flat by default. Depth comes from tone steps (ground, panel, raised), not shadow. The only shadow is under popovers and the toast (blur 24, drop 8, 55% black). The dropped search well is the one inset effect: a darker top edge and a faint lip.

### Named Rules
**The Flat At Rest Rule.** Nothing has a box, border or shadow at rest. State appears on hover, focus or selection only.

## Shapes

Radius is 0 everywhere. No pills, no circles except the mascot's own geometry. Icons are drawn on a 16-unit grid with only 90 and 45 degree lines; the Nekomimi is the one exception and keeps its own painting. Stars have sharp points.

## Components

### Buttons
- **Shape:** square, 36 tall.
- **Primary:** pop fill, Ground text.
- **Secondary:** Panel Slate fill, Ink text. A transparent variant exists for the one-time green shimmer.
- **Hover / Focus:** hover is the live edge (faint teal wash and a 2px teal line underneath) and brighter text; focus is a 2px Ink ring on every pressable.

### Menus and popovers
- **Style:** Raised Slate, status names left, counts or shortcut keys right, a divider between groups, an optional footnote. One `AppMenu` serves every dropdown, including the sort and the status switcher.

### Inputs / Fields
- **Style:** Panel Slate, 36 tall, Soft Ink icon, an Esc hint. The top search is the dropped well: Ground fill, 2px Well Edge top, faint lip, centred, with key caps.

### Key caps
- **Style:** a Key Face over a 4px Key Slab, mono 11 bold, joined by a muted plus. They size to whatever keys the user sets.

### Navigation
- **Style:** the Windows rail holds icons only, cyan mark on the active item, teal count badge on Watching. Each icon shows its name in a hover tip beside it (a Raised Slate panel, Ink text, no click taken). Android gets labels on the bottom bar.

### Toast
- **Style:** bottom, max 480 wide, an optional 2px timer bar, actions and a star rating. Pauses on hover.

## Do's and Don'ts

### Do:
- **Do** take every color, size and space from `tokens.dart`. `check` fails otherwise.
- **Do** give every state a shape or word as well as a color.
- **Do** keep text at 4.5:1 or better on its own fill, and test at font scale 1.3.
- **Do** build a look once and reuse it; extract before copying.
- **Do** respect reduce motion: change the state, skip the animation.

### Don't:
- **Don't** round anything or add a border, box or shadow at rest.
- **Don't** use Muted Ink on Panel Slate or Raised Slate.
- **Don't** let an icon pass redraw the Nekomimi.
- **Don't** add a modal where an inline or popover answer exists.
- **Don't** add a token or color without the owner's approval.
