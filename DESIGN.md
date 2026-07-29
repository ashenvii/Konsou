<!-- ============================================================================
     DIRECTION CONTRACT — The Field Guide (committed 2026-07-25, feat/mylist-rework)
     This world REPLACES the old "warm near-black + one accent + glow" identity.
     The old world is preserved as anti-reference at docs/DESIGN.anti-reference.md.

     THESIS: Konsou is a naturalist's field guide to the anime you own. Each title
       is a mounted, numbered, annotated SPECIMEN; a franchise is a GENUS whose
       entries sit in watch (taxonomic) order; your list is a catalogue you keep,
       not a server's feed you borrow. It refuses the category default: the dark
       cover-grid with one neon accent and glowing cards.
     OWN-WORLD: Deep herbarium green-black examination table. Specimens are cover
       art MOUNTED behind a fine ivory keyline frame with photo-corners; a
       typewritten label carries the accession number + italic species name +
       field-note status stamp. Apparatus is letterpress mono; species names are
       engraved Garamond italic. One ink of record: vermilion (the collector's
       stamp) means "catalogued / in your collection." No glow, no pills, no
       rounded card shells: crisp plates, hairline rules, ink stamps.
     STORY: The collector opens their catalogue, scans the mounted plates, brings
       one under the loupe, stamps tonight's episode, and their watch-next run
       accumulates along the edge as a picked sequence. They leave knowing the
       record is theirs and permanent.
     FIRST VIEWPORT (My List / Overview): a header plate (collection title in
       Garamond, accession range + census in mono) over the examination field of
       mounted specimen plates; the Continue / watch-next run docks as a sequence
       strip on one edge (light-table staging). Primary action (log an episode)
       is the stamp on the specimen.
     FORM: grounded direction #6 of 7 (Naturalist specimen plate), light-table
       triage staging committed for Overview. Seed key 54104cfc, ASSIGNED INDEX 6.
============================================================================ -->
---
name: Konsou
description: The Field Guide — a naturalist's catalogue of the anime you own, kept on your own device.
colors:
  base: "oklch(16% 0.020 158)"
  surface: "oklch(20% 0.024 158)"
  surface-2: "oklch(25% 0.026 158)"
  surface-3: "oklch(30% 0.028 158)"
  keyline: "oklch(90% 0.030 90 / 24%)"
  keyline-strong: "oklch(90% 0.035 88 / 46%)"
  ink-primary: "oklch(93% 0.020 88 / 92%)"
  ink-secondary: "oklch(93% 0.018 88 / 66%)"
  ink-tertiary: "oklch(93% 0.016 88 / 44%)"
  accent-vermilion: "oklch(58% 0.19 32)"
  accent-vermilion-hi: "oklch(67% 0.19 34)"
  accent-vermilion-dim: "oklch(58% 0.19 32 / 16%)"
  stamp-watching: "oklch(62% 0.12 240)"
  stamp-completed: "oklch(68% 0.14 150)"
  stamp-plan: "oklch(75% 0.13 80)"
  stamp-on-hold: "oklch(58% 0.12 300)"
  stamp-dropped: "oklch(52% 0.13 25)"
  stamp-rewatching: "oklch(68% 0.10 195)"
  stamp-not-interested: "oklch(52% 0.012 158)"
  success: "oklch(68% 0.12 150)"
  warning: "oklch(74% 0.14 75)"
  error: "oklch(54% 0.18 25)"
  info: "oklch(62% 0.12 240)"
typography:
  plate:
    fontFamily: "EB Garamond, Noto Serif JP, Georgia, serif"
    fontSize: "32px"
    fontWeight: 500
    lineHeight: "38px"
    letterSpacing: "normal"
  species:
    fontFamily: "EB Garamond, Noto Serif JP, Georgia, serif"
    fontSize: "18px"
    fontWeight: 500
    lineHeight: "24px"
    fontStyle: "italic"
  field-note:
    fontFamily: "EB Garamond, Noto Serif JP, Georgia, serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "26px"
  label:
    fontFamily: "Courier Prime, ui-monospace, 'Courier New', monospace"
    fontSize: "12px"
    fontWeight: 700
    lineHeight: "16px"
    letterSpacing: "0.08em"
  accession:
    fontFamily: "Courier Prime, ui-monospace, 'Courier New', monospace"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "16px"
    letterSpacing: "0.02em"
rounded:
  plate: "2px"
  tag: "1px"
  inset: "3px"
  seal: "9999px"
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
    backgroundColor: "{colors.accent-vermilion}"
    textColor: "oklch(97% 0.02 88)"
    typography: "{typography.label}"
    rounded: "{rounded.plate}"
    padding: "0 20px"
    height: "40px"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.ink-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.plate}"
    padding: "0 20px"
    height: "40px"
  specimen-tag:
    backgroundColor: "{colors.surface-2}"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.label}"
    rounded: "{rounded.tag}"
    height: "26px"
  specimen-tag-active:
    backgroundColor: "{colors.accent-vermilion-dim}"
    textColor: "{colors.accent-vermilion-hi}"
    typography: "{typography.label}"
    rounded: "{rounded.tag}"
    height: "26px"
---

# Design System: Konsou — The Field Guide

## Overview

**Creative North Star: "The Field Guide"**

Konsou is a naturalist's field guide to the anime you own. The scene is unchanged and still binding: someone at home, late, in a low-light room, a second screen glowing, reaching for their catalogue. So the surface is the examination table in that dark room, a deep desaturated herbarium green-black, and the specimens laid on it are the bright, saturated objects: the cover art. Everything the interface does is a naturalist's act. You mount a specimen (add to list), you give it an accession number (it becomes a permanent record you own), you stamp field notes on it (watch status), you press the loupe over it (open detail), and you file a watch-order run of related species (a genus in taxonomic sequence). The founding why survives intact and finally has a form: your record is catalogued, numbered, dated, and yours, not a feed you borrow from a server that can vanish.

The world is deliberately not the category default. It refuses the dark cover-grid with one neon accent and glowing cards (that was the old Konsou, preserved as anti-reference), and it equally refuses the parchment-and-serif "cozy field guide" cliche the subject invites. There is no glow, no pill, no rounded card shell, no gradient text. Instead: crisp rectangular plates held in fine ivory keyline frames, engraved species names in Garamond italic, a letterpress monospace for every label and number, and exactly one ink of record, vermilion, the collector's stamp, spent sparingly. Depth comes from paper and mounting, not from bloom.

This is an Operate surface first. The taxonomy is a frame, never a toll: the one-tap episode log, instant load, undo, three densities, and every existing behaviour stay exactly as fast as before. The apparatus reads as care, not ceremony.

**Key Characteristics:**
- The specimen: cover art mounted behind a hairline keyline frame with photo-corners, labelled with an accession number and an italic species name.
- One ink of record: vermilion, meaning "catalogued / in your collection," never decoration; spent on under 10% of any screen.
- Stamps, not glows: state is a field-note stamp (glyph + label + hue), so it is legible without color.
- Letterpress apparatus: monospace numbers and labels; Garamond italic species names; no generic UI sans.
- Crisp plates, ruled hairlines: near-square corners, keyline borders, zero pills.
- Eight themes are eight plates/collections, all derived from this world; the default is Herbarium (green-black), not the old warm near-black.

## Colors

A deep, quiet, desaturated ground so the saturated specimens (covers) and the single vermilion stamp carry all the chroma. Neutral ink is warm ivory, the color of an aged label, not pure white.

### Primary
- **Vermilion Stamp** (`oklch(58% 0.19 32)`): the one ink of record. It is the accession stamp, the primary action, the "in your collection" mark, the active tag. Culturally it is the hanko seal and the correction/annotation ink; it is never spent on decoration. **Vermilion Bright** (`oklch(67% 0.19 34)`) is its legible-on-dim partner for accent text (active tag labels, the stamp reading on tinted grounds).

### Neutral (the table and the paper)
- **Herbarium Table** (`oklch(16% 0.020 158)`): the default ground, a deep desaturated botanical green-black. The examination table under lamplight. Never a pure neutral grey.
- **Mount / Surface ladder** (`oklch(20% / 25% / 30% …158)`): the plate mounts and raised chrome step up this green-slate ladder for rest-state depth.
- **Ivory Ink** (`oklch(93% 0.020 88 / 92 · 66 · 44%)`): the field-note text ramp, warm off-white like an aged label, in three weights.
- **Keyline** (`ivory / 24%` and `/ 46%`): the fine ruled frames and dividers. The plate frame is drawn with the keyline, not a shadow.

### Tertiary (field-note stamps — semantic state)
Each watch state is a stamp with a distinct hue AND a distinct glyph AND a word, so it never depends on color: Watching = **field blue** (240), Completed = **catalogued green** (150), Plan = **ochre** (80, "to collect"), On-hold = **pressed violet** (300), Dropped = **released oxblood** (25, browner and deeper than the vermilion accent so the two never collide), Rewatching = **re-observed teal** (195). Not-interested is a muted grey-green (`0.012` chroma): a quiet "not collecting," never louder than a real stamp. All are inked (desaturated toward paper), not neon.

### Named Rules
**The One Ink Rule.** Vermilion is the only color of record; it means catalogued / active and nothing else. It appears on under 10% of any screen. Its rarity is what makes a stamp read as a stamp.
**The Warm-Ivory Rule.** Neutral text is warm ivory, never pure white; the interface is printed on aged paper, not lit on glass.
**The Inked-State Rule.** Status hues are desaturated toward ink; a state is always a stamp (hue + glyph + label), never a bare color chip.

## Typography

**Species / Display Font:** `EB Garamond` (with `Noto Serif JP` for Japanese titles, then `Georgia`). Engraving-era, botanically authentic, with a real italic for the binomial rule.
**Label / Number Font:** `Courier Prime` (with `ui-monospace` / `Courier New`). The typewritten specimen label and the index-card number.

**Character:** The two voices of a specimen plate. The engraved species name (Garamond, italic for titles the way taxonomy italicises a binomial) and the typewritten label glued beneath it (mono, tracked, often small-caps). There is deliberately no workhorse UI sans; the apparatus IS the mono. This replaces the incumbent's single generic `Plus Jakarta Sans`.

### Hierarchy
- **Plate** (Garamond, 500, ~32px): collection and page titles, the guide's headings.
- **Species** (Garamond italic, 500, ~18px): the anime title on a specimen, franchise/genus names. Titles are set italic, the binomial convention.
- **Field-note** (Garamond, 400, ~16px/26px): synopsis and notes, set for reading at 62–72ch.
- **Label** (Courier Prime, 700, ~12px, `0.08em`, small-caps): nav, tags, buttons, status stamps, section labels. Uppercased and tracked so mono reads as letterpress, not code.
- **Accession** (Courier Prime, 400, ~13px, tabular): accession numbers, episode counts, dates, any figure that should align in a column.

### Named Rules
**The Binomial Rule.** A title (the species) is set in Garamond italic; its accession number and status are set in mono. The two voices never swap jobs.
**The Letterpress Rule.** Mono labels are uppercased and tracked (`≥0.06em`); mono numbers are natural-case and tabular. Never set a paragraph of reading text in mono.

## Layout

Two shells off the 1024px breakpoint, both staged as an examination surface. **Desktop:** a left **index rail** (the guide's tabbed edge) replaces the old icon sidebar; the examination field fills the rest; on My List / Overview the watch-next run docks as a **sequence strip** on the right edge (the light-table staging). **Mobile:** a single scrolling field under a compact header plate, with a bottom **tab ledger** replacing the floating pill.

Specimens lay out on a strict column grid with generous gutters (the mounting margin). Three densities are three renditions of the guide: **Plate** (mounted cover grid), **Ledger** (accession | species | stamp | count rows), **Index card** (dense contact-sheet). Spacing keeps the 4px base unit; rhythm always gives more space above a heading than below it. The scroll-away header behaviour is preserved exactly (inline margin-top, no root variable).

## Elevation & Depth

Paper, not bloom. Depth is the language of a mounted specimen: the plate sits on the table via a fine **keyline frame** and **photo-corners**, with at most a soft contact shadow beneath, as a real card resting on felt. Raised chrome (sheets, the loupe/detail, menus) lifts with a restrained drop shadow. The old accent-glow bloom is removed entirely; membership is signalled by the keyline frame + accession number + stamp, not by colored light.

### Shadow Vocabulary
- **Contact** (`0 1px 2px oklch(0% 0 0 / 40%), 0 8px 20px oklch(0% 0 0 / 28%)`): a specimen resting on the table.
- **Lifted** (`0 12px 40px oklch(0% 0 0 / 50%)`): the loupe/detail sheet, menus, the dialog.
- **Pressed:** logging/stamping momentarily removes the contact shadow (the specimen is pressed to the table under the stamp), then restores it.

### Named Rules
**The No-Glow Rule.** Nothing glows. In-collection is the keyline frame, the accession number, and the stamp, never a bloom. On light themes the frame simply inks darker; it never becomes a ring of colored light.

## Shapes

A crisp, ruled, rectangular form language: the opposite of the incumbent's pills. Corners are near-square (`plate 2px`, `tag 1px`, `inset 3px`); the only fully-round element is a **seal** (the circular stamp/avatar). Specimen plates and cards carry a **hairline keyline frame** (single rule, occasionally a fine double-rule for genus groups) and **photo-corner** marks at the four corners of a mounted cover. Tags and buttons are small rectangles with a keyline, some with a punched hole or a clipped corner (the tie-on specimen tag). Dividers are ruled hairlines, not gaps alone. The signature silhouette is **the mounted plate**: keyline rectangle + photo-corners + a typewritten label strip.

## Components

### Buttons
- **Shape:** rectangular, `2px` radius, keyline-defined; label set in tracked mono small-caps.
- **Primary (the stamp):** vermilion fill, ivory label; press animates a quick stamp (scale-down + settle), not a glow.
- **Secondary:** transparent with a keyline frame; hover inks the frame stronger and fills a faint mount tint.
- **Danger:** transparent with an oxblood keyline; hover fills a faint oxblood wash.

### Tags (replaces chips)
- **Style:** small rectangular **specimen tags**, `1px` radius, keyline frame, mono small-caps label; a filter tag reads like a tie-on label.
- **State:** active tags fill vermilion-dim with a vermilion-bright label and a stronger keyline; removable tags carry a small punched-hole close mark.

### Specimen (the signature component; replaces the card)
- **Corner Style:** near-square (`2px`), a hairline **keyline frame**.
- **Composition:** cover art mounted inside the frame with **photo-corner** marks; beneath it a typewritten **label strip** carrying the accession number (mono, tabular), the species name (Garamond italic), and the field-note **status stamp** (glyph + label, inked hue). Episode progress reads as a mono fraction on the label, not a bar.
- **Depth:** Contact shadow at rest; the keyline brightens and the plate lifts a hair under the loupe (hover/focus).
- **In collection:** the presence of the frame + accession number + stamp IS the membership signal. Nothing glows.

### Inputs / Fields
- **Style:** a ruled **catalogue field**: bottom keyline rule (or full keyline frame), mono input text, no pill. The search field reads like a blank on a catalogue card.
- **Focus:** the rule thickens to vermilion; keyboard focus is a 2px vermilion outline, 3px offset, `:focus-visible` only.
- **Placeholders:** ivory-secondary (not tertiary) to hold AA.

### Navigation
- **Desktop index rail:** a tabbed edge; items are mono small-caps labels with a small specimen glyph; the active item carries a vermilion **tab marker** (a filled edge notch) plus vermilion label, never a filled pill. Active is marked by shape (the notch) and ink, not color alone.
- **Mobile tab ledger:** a bottom row of mono labels + glyphs on a mount surface with a top keyline; the active tab draws a vermilion underscore rule and vermilion label. Badges are a small oxblood **seal** with a mono count.

### Signature: the Loupe (detail / sheet)
Opening a specimen brings it **under the loupe**: on mobile a sheet rises (behaviour preserved) framed as a magnified plate with a heavier keyline and the full field-note; on desktop it recenters as a mounted dialog. The handle/dismiss behaviours are unchanged; only the skin (keyline plate, mono apparatus, Garamond species name) changes.

### Motion (ink and paper)
The world's native motion is the naturalist's hand: **stamp, mount, file, loupe.** Give the surface this motion once, orchestrated, not scattered hovers.
- **Stamp:** logging an episode presses the specimen (contact shadow out), thuds the vermilion count/stamp in with a tiny overshoot, restores. Undo lifts the stamp.
- **Mount:** adding to the list draws the keyline frame on and drops the photo-corners in.
- **Loupe:** hover/focus lifts the plate a hair and brightens the keyline; open magnifies into the sheet/dialog.
- **File:** status change flips the stamp; re-sorting slides rows like filed cards.
- **Eases:** a firm **stamp** ease (fast-in, slight overshoot) for commits; a calm **settle** for everything else. Reduced motion: stamps resolve instantly to the stamped state, keylines draw without tracing, spinners/progress keep their real duration (as the incumbent already handles).

## Do's and Don'ts

### Do:
- **Do** keep every behaviour and its speed: instant SQLite load, one-tap stamp-to-log with undo, sign-in-once, Drive sync, sequel radar, three densities, virtualization, scroll-away header, native sheet-on-mobile / dialog-on-desktop.
- **Do** encode state as a stamp: hue + glyph + word, legible with color removed (colorblind-safe, a PRODUCT.md commitment).
- **Do** hold WCAG 2.1 AA across all eight themes, including the two light plates; watch ivory-tertiary text and mono at 12px.
- **Do** make cover art the specimen and the loudest thing on the field; chrome is ruled ivory around it.
- **Do** spend vermilion like ink: the stamp, the primary action, the active mark, and little else (under 10% of a screen).
- **Do** derive all eight themes from this world in tokens.css; the default is Herbarium (green-black), and the light themes are the printed page (aged vellum / museum card), not the old warm near-black.
- **Do** set titles in Garamond italic (the binomial) and every number/label in tracked mono.

### Don't:
- **Don't** bring back any device from the anti-reference: no accent-glow bloom, no fully-rounded pills, no rounded glowing card shells, no `Plus Jakarta Sans`, no gradient text, no colored left-borders.
- **Don't** render the field-guide world as cream/parchment + serif + lamplight; the default ground is a deep saturated herbarium green-black, not a cozy paper cliche.
- **Don't** signal any state by color alone.
- **Don't** let the taxonomy slow the task: the stamp-to-log must stay one tap, and the apparatus must never sit between the user and a fast nightly pass.
- **Don't** set reading text in mono, or numbers/labels in the serif.
- **Don't** add a token just to silence a check; a value earns its place by the world and by legibility.
