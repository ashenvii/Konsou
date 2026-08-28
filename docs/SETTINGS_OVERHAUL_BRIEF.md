# Settings overhaul — design brief (logged, not built)

Status: **draft, pending two decisions** (see Open decisions). Logged 2026-08-02 at the
owner's request ("log a complete overhaul of settings and all pages"). Nothing in this
document has been implemented; the settings work done on 2026-08-02 was corrective
(splitting Support / What's new / About into real pages, widening the desktop column),
not this overhaul.

Companion to `docs/KONSOU_RESURFACE_PLAN.md`. The visual world is already committed in
`DESIGN.md` (the Field Guide); this brief does not reopen it.

---

## 1. Job and audience

Settings is **Operate** mode, backstage. Nobody opens it to browse. They arrive with one
of four errands, in rough order of frequency:

1. **Change how it looks** (theme, accent, title language, density). The most common by
   far, and the only errand people repeat for pleasure.
2. **Rescue their data** (sign in, sync, back up, import, export). Rare, high stakes,
   usually under stress: a new device, a failed sync, a list that looks wrong.
3. **Tune the radar** (which alerts, how loud).
4. **Find out about the app** (version, what changed, how to help, source).

They reach it from one place on each platform: the account tab on the phone's tab ledger,
the rail's account row on desktop. It is a mode, not a tab — all primary chrome stands
down when you enter it, and that stays.

## 2. Outcome and proof

Success is that an errand takes one screen and no reading. The failure this overhaul
exists to fix is that the hub is currently a **flat list of six identical rows** whose
labels are categories, not errands, so the frequent errand (appearance) and the rare
frightening one (sync/backup) are presented with exactly the same weight and shape.

Product-specific truth this must carry, which a generic settings screen would not:

- **The list is local and the sync is the user's own Drive.** Settings is where that
  promise is either visible or invisible, and right now it is invisible: there is no
  at-a-glance answer to "is my data safe and where is it".
- **Score is optional; nothing is mandatory.** Settings must never read as a
  configuration checklist to complete.
- **Eight themes are a first-class feature**, not a preference toggle. They are the most
  expressive thing the app lets you do and deserve better than a row.

## 3. Selected direction (proposed)

**Thesis: the hub becomes a status board, not a menu.**

Each destination row grows a live line of state read from the store, so the hub answers
the question before you open the row:

- Account → signed-in identity, or "Local only".
- Sync → last successful sync, relative ("synced 4 minutes ago"), or the error if the
  last attempt failed.
- Library → entry count and backup age.
- Appearance → the current theme and accent, shown as the actual swatch pair.
- Notifications → how many alert kinds are on.
- About → version, and a mark when a newer one exists.

This is the field-guide move applied to backstage: a specimen label states what the thing
IS, not just what it is called. It also collapses the two most common trips (checking
sync, checking theme) into zero trips.

**Sub-pages keep the ruled-card language they have now** (`Section` / `Row` / `LinkRow`);
that vocabulary is correct and consistent as of 2026-08-02 and is not up for redesign. The
work is in the hub, in Appearance, and in Library & Sync.

**Appearance becomes a preview surface.** Choosing a theme currently means reading eight
names. It should mean seeing eight plates: each swatch shows the real base/surface/accent
triad, and the page previews a real specimen card in the selected theme rather than
describing it. Accent and theme are independent (they already are in tokens.css) and the
UI should make that obvious instead of hiding it in two separate rows.

**Library & Sync leads with the reassurance**, not the actions: what is on this device,
when it last reached Drive, and how to get it back. Import/export/backup are consequences
of that state, arranged under it.

## 4. Scope and boundaries

**In scope:** the hub (`SettingsHub`), `AppearanceSettings`, `LibrarySettings`,
`NotificationsSettings`, `AccountSettings`, and the shared parts in
`components/settings/parts.tsx`.

**Out of scope / do not touch:**

- `DESIGN.md`'s world. No new visual direction.
- The Support / What's new / About trio, redone 2026-08-02. They are current.
- The backstage shell rule (all primary nav stands down inside `/settings`).
- The settings column width and header alignment, fixed 2026-08-02.
- Any storage, sync, or migration behaviour. This is a presentation overhaul; it reads
  existing store state and changes no writes.

**Anti-goals:** a search field over settings (six destinations do not need one); a
first-run settings tour; grouping into "Basic / Advanced"; any row that exists only to
show a toggle that 99% of people never move.

## 5. States and ranges

Every hub status line must have a defined empty and error form, because most of them are
empty on a fresh install:

- Never signed in (the default, and not a problem to be fixed) → "Local only", stated
  plainly, never as a warning.
- Never synced / sync failing / sync in progress.
- 0 entries, ~50 typical, 6,500 stress-tested (`devdata/`), so counts need thousands
  separators and must not reflow the row.
- Update available vs up to date vs update check failed offline.
- Offline entirely: every status line must degrade to a last-known value with its
  timestamp rather than a spinner or a dash.

## 6. Interaction and layout

- Hub: one column of destination rows on phone; the same column, centred at
  `--settings-col`, on desktop. No multi-column hub — six destinations do not earn a grid,
  and a grid would make the status lines compete.
- Status lines are read-only text in the row; the row's whole job stays "go here".
- Appearance's theme picker is a grid of real swatch plates, keyboard-navigable as a
  radio group, with the current one marked by keyline + check, never colour alone.
- Nothing in settings may signal state by colour alone (the AA commitment in `PRODUCT.md`,
  and the reason the 2026-08-02 token audit exists).

## 7. Constraints

- Web frontend inside Tauri; must hold at 320px and at a maximised desktop window.
- WCAG 2.1 AA across all eight themes, including the two light plates. Verify with the
  canvas-based probe recipe, not by eye.
- Offline-first: no settings surface may block on a network call.
- Reduced motion: any preview animation must resolve to its end state instantly.

---

## Open decisions (needed before this is buildable)

1. **How far does the hub status board go?** Every row carrying live state is the full
   version; a lighter version puts state only on Account/Sync (where it reduces real
   anxiety) and leaves the rest as plain rows.
2. **Does Appearance stay one page or split?** Theme + accent + title language + density
   is four unrelated choices on one page; the preview-led direction above assumes they
   stay together with the preview as the spine.
