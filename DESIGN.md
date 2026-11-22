---
name: Konsou
description: A flat, square, near-black anime tracker where one garnet pop marks the chosen thing and everything else is ink.
colors:
  ground: "#09090B"
  surface: "#131315"
  raised: "#0E0E10"
  line: "#3A383B"
  ink: "#F6F4F5"
  ink-soft: "#CFC9CC"
  ink-muted: "#9A9296"
  pop: "#E0526A"
  on-pop: "#1A0509"
  star: "#F2B33D"
  red: "#FF453A"
  key-face: "#2C2B2E"
  key-slab: "#222124"
  well-edge: "#151517"
typography:
  heading:
    fontFamily: "Chakra Petch, IBM Plex Sans JP, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1
  label:
    fontFamily: "IBM Plex Sans JP, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1
  caption:
    fontFamily: "IBM Plex Sans JP, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1
  figure:
    fontFamily: "Share Tech Mono, ui-monospace, monospace"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1
  count:
    fontFamily: "Share Tech Mono, ui-monospace, monospace"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1
rounded:
  square: "0px"
  cover: "3px"
  key: "5px"
  well: "6px"
spacing:
  space-1: "4px"
  space-2: "8px"
  space-3: "12px"
  space-4: "16px"
  space-5: "24px"
components:
  button-primary:
    backgroundColor: "{colors.pop}"
    textColor: "{colors.on-pop}"
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

<!-- Generated from lib/design/tokens.dart and the shipped components, 2026-11-13; colours and fonts updated 2026-11-22 for the garnet console, whose shapes (keys, wells, lamps) are not built yet, see notes/DECISIONS.md "Garnet console". Tokens in the frontmatter are normative; change them in tokens.dart and notes/design/tokens.md first. -->

# Design System: Konsou

## Overview

One flat dark ground, square edges, and almost no color, so that the few marks that do carry color (garnet pop for the chosen thing, true red for remove) read at once. It is an Operate surface: the user is scanning hundreds of entries and changing a status in two keystrokes, so familiarity and speed outrank expression. Personality lives in details: the Nekomimi, the key caps, the live edge under a hovered control.

**Key Characteristics:**
- One dark ground with two fill steps above it. No gradients inside content, no rounded corners.
- Color is rare and carries meaning. Pop chooses, ink marks done and live by shape, red removes.
- Chakra Petch for labels, Plex Sans JP for words and Japanese names, Share Tech Mono for every number.
- Hairline separation through tone, not lines. Hover is a live edge, not a box.

## Colors

A neutral near-black ground with warm-white inks and one garnet pop. Black and garnet, picked by the owner on 2026-11-22 from a live rig; pop is lightened a notch from the pasted D83B55 to pass 4.5:1. There is no glow and no glass.

### Primary
- **Pop Garnet** (#E0526A): the chosen state, the primary button, the hover edge, your score and the rail badge. A garnet icon with no fill marks the selected item; in the rail a garnet mark sits on its edge. Text on a pop fill is **On Pop** (#1A0509).

### Secondary
- None. Done and live things are shown by shape in Ink (a filled check, a filled square), not by a second hue.

### Tertiary
- **Star Gold** (#F2B33D): the star beside MyAnimeList's score, so it reads as the ordinary rating star and apart from the user's own garnet one. Nothing else uses it.
- **Remove Red** (#FF453A): remove, exclude, sync lost. Never the only cue. A true red, the same one other apps use, whatever the app color. The orange-red tried on 2026-11-22 read as orange and was dropped.

### Neutral
- **Night Ground** (#09090B): the page, rail and top bar.
- **Panel Slate** (#131315): fields, secondary buttons, panels, skeletons.
- **Raised Slate** (#0E0E10): menus and popovers.
- **Divider Slate** (#3A383B): the hairline inside menus. Decoration only.
- **Ink** (#F6F4F5), **Soft Ink** (#CFC9CC), **Muted Ink** (#9A9296): main, secondary and meta text. Soft and Muted are Ink stepped toward the ground.
- **Key Face** (#2C2B2E) and **Key Slab** (#222124, so the key's side shows against the ground): the two steps of a key cap. **Well Edge** (#151517): the top cut of the dropped search well.

### Named Rules
**The Rare Color Rule.** Pop and red together cover a small part of any screen. If a screen needs a second place to look, it is wrong.
**The No Color Alone Rule.** Every state has a shape, word or position as well as its color. The Completed check is a check mark in Ink, no hue.
**The Muted Ink Rule.** Muted Ink (#9A9296) is 6.6:1 on the ground, 6.1:1 on Panel Slate and 6.4:1 on Raised Slate, so it passes 4.5:1 on every fill. Check any new fill before putting meta text on it.

## Typography

**Labels:** Chakra Petch 600 (headings, titles, tabs, buttons), 2% tracking, falling back to Plex Sans JP for kana and kanji. **Running text and Japanese names:** IBM Plex Sans JP, regular and bold. **Every number and key cap:** Share Tech Mono, one weight, the LED digits. Three families, one job each (owner, 2026-11-22).

**Character:** a console. Chakra Petch's squared letters label the controls; Share Tech Mono reads like an LED display; Plex Sans JP keeps long text and Japanese names calm and matched.

### Hierarchy
- **Heading** (700, 18px, 1.0): page and section heads.
- **Label** (400 or 700, 14px, 1.0): buttons, tabs, menu rows, titles.
- **Caption** (400, 12px, 1.0): meta lines under a title.
- **Figure** (Mono 400, 12px) and **Count** (Mono 700, 11px): progress, counts, key caps.

### Named Rules
**The Five Sizes Rule.** 12, 16, 20, 24 and 32 are the only sizes. Weights: Plex Sans JP regular and bold, Chakra Petch 600, Share Tech Mono regular.
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
- **Shape:** a raised key, 36 tall: a Key Face over a 3 deep Key Slab, a soft shadow, corners 5. Pressed or selected, it sinks to a 1 slab.
- **Primary:** pop face over the Pop Slab (#8A2537), On Pop text in Chakra Petch.
- **Secondary:** Key Face, Ink text. Icon buttons (view switch, plus and minus, arrows) are the same key; the selected view stays pressed in with a pop icon.
- **Hover / Focus:** hover is the live edge (faint pop wash and a 2px pop line underneath) and brighter text; focus is a 2px Ink ring on every pressable.

### Menus and popovers
- **Style:** Raised Slate, status names left, counts or shortcut keys right, a divider between groups, an optional footnote. One `AppMenu` serves every dropdown, including the sort and the status switcher.

### Inputs / Fields
- **Style:** Panel Slate, 36 tall, Soft Ink icon, an Esc hint. The top search is a sunk well: Well Fill, rounded 5, shaded at the top, a faint lit lip below, centred, with key caps.

### Key caps
- **Style:** a Key Face over a 4px Key Slab, mono 11 bold, joined by a muted plus. They size to whatever keys the user sets.

### Navigation
- **Style:** the Windows rail is the faceplate: a flat strip (Rail Fill) with a dark cut and a faint lit lip on its edge. It holds icons only; the active icon is garnet over a soft glow, with a 3 wide lit garnet edge on the window side. Garnet count badge on Watching. The title bar above is a raised strip (Bar Top to Bar Bottom) with a lit top line and a dark cut under it. Each icon shows its name in a hover tip beside it (a Raised Slate panel, Ink text, no click taken). Android gets labels on the bottom bar.

### Toast
- **Style:** bottom, max 480 wide, an optional 2px timer bar, actions and a star rating. Pauses on hover.

### Wordmark while loading
- **Style:** while details or covers load in the background, the Konsou wordmark takes turns with the count (4 s each), turning over as a split flap in 360 ms with a small bounce and a shade on the turning half; the count's digits are LED garnet and each flaps on its own as it ticks (240 ms). Waiting on MAL turns the count Ink with a pause mark. When all is in it reads "All loaded" for 2 s, then rests on Konsou. A click while it loads lists each job with a lamp. Reduce motion swaps the faces in place.

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
