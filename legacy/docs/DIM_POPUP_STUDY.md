# DIM's item popup vs ours — what we're actually missing

Sourced from the real DIM checkout at `reference/dim/` (gitignored), 2026-08-02.
Primary files: `src/app/dim-ui/usePopper.ts`, `src/app/item-popup/ItemPopup.tsx`,
`src/app/item-popup/sidecar-position-middleware.ts`, `src/app/dim-ui/ClickOutside.tsx`.

Written because the owner's read was "DIM feels like a sticky page at the exact
spot of the card you opened, even scrolling off screen" and ours does not.
That instinct is correct and the cause is one line.

---

## 1. The positioning strategy (this is the whole feeling)

`usePopper` takes a `fixed?: boolean` and does:

```ts
const strategy = fixed ? 'fixed' : 'absolute';
```

`ItemPopup` **does not pass `fixed`**, so the item popup is `position: absolute`,
portaled into the document. Absolute means it is positioned against the document's
initial containing block — so when the page scrolls, **the popup scrolls with it**
and genuinely leaves the viewport alongside its card.

Ours is `strategy: "fixed"` plus `autoUpdate`, which re-solves the position on
every scroll tick and re-clamps it into the viewport with `shift`. The panel
therefore *tracks* the card but never *leaves* with it: as the card scrolls away
the panel slides along the edge and stays on screen. That is the "detached"
feeling.

**Important structural difference before copying this:** DIM scrolls the
document. Konsou scrolls inner containers (`.k-collection`, `.k-years__wall`), so
`position: absolute` against the body would not scroll with our list either.
Matching DIM here means one of:

- **(a)** render the popover *inside* the scrolling container, absolutely
  positioned within it, so it moves with the content for free; or
- **(b)** keep fixed + `autoUpdate` but drop the viewport clamping so the panel
  is allowed to travel off-screen with its anchor.

(a) is closer to DIM and gets scroll-linked movement with no per-frame work, but
it means the panel is subject to the scroller's `overflow: hidden` and stacking —
a real constraint given `.konsou-scroll` deliberately clips both axes. (b) is a
much smaller change. Neither is a five-minute job; this is its own session.

## 2. `autoPlacement` rather than `flip` with a fallback list

```ts
isAuto ? autoPlacement({ padding: resolvedPadding }) : flip({ padding: resolvedPadding })
```

DIM's default is `placement: 'auto'` → `autoPlacement`, which evaluates every
side and picks the one with the most room. `ItemPopup` overrides to `'right'`,
which then uses plain `flip` (all four sides considered), not a hand-listed
fallback set.

Ours passes `fallbackPlacements: ["left", "bottom-start", "top-start"]`. That is
now correct-ish but is a list I maintain by hand. Worth revisiting.

## 3. Padding is computed from the real chrome

```ts
const headerHeight = parseInt(document.querySelector('html')!.style.getPropertyValue('--header-height'), 10);
const resolvedPadding = padding ?? {
  left: 10, top: headerHeight + (boundaryElement ? boundaryElement.clientHeight : 0) + 5, right: 10, bottom: 10,
};
```

The popup can never slide under the sticky header or a caller-named boundary
element, because the boundary is measured live rather than assumed. Ours
hardcodes `TOP_EDGE = 64` with a derivation comment. DIM writes `--header-height`
from a `useSetCSSVarToHeight(headerRef, '--header-height')` in `Header.tsx`, i.e.
the header publishes its own height and everything else reads it. **That pattern
is worth stealing on its own**, independent of the popup.

## 4. `useLayoutEffect`, not `useEffect`

DIM positions in `useLayoutEffect` so the work happens before paint.
**Adopted 2026-08-02.** (Their own TODO notes that `computePosition` is still
async, so a microtask remains — this reduces the jump, it does not remove it.)

Do **not** also copy their "zero left/top before measuring" trick: DIM writes
position imperatively throughout, so it is measuring against its own stale
offsets. Our component is React-controlled, and an imperative write races the
next render — tried it, and the panel sat pinned at x=0 for every scroll tick
until each async measurement resolved. Reverted.

## 5. The placement is exposed to CSS as an attribute

```ts
contentsElement.setAttribute('data-popper-placement', finalPlacement);
```

Arrow orientation is then pure CSS, keyed off that attribute, for all four sides.
Ours carries a `side` union in React state and only styles two sides (a third,
`"vertical"`, currently just hides the arrow). Their approach is less code and
supports every placement.

## 6. The sidecar — the desktop action rail

`computeSidecarPosition` is a custom Floating UI middleware that positions a
**second** element (`DesktopItemActions`) alongside the popup, kept on screen
independently of the popup body. This is the persistent side action rail noted
as missing in an earlier session. It is why DIM's desktop popup can offer a
column of verbs without lengthening the panel.

## 7. Dismissal

`ClickOutside` wraps only the popup *body*, not the arrow, and DIM relies on it
plus `Escape`. There is no close X on desktop — matching what the owner asked us
to do. Our overlay-stack registry (`sheetStack.ts`) has no DIM equivalent; ours
is arguably better for nested overlays.

---

## Recommended order if we take this on

1. `--header-height` published by the header, consumed by the popover padding
   (small, independently useful, removes a hardcoded 64).
2. `data-popper-placement` attribute + CSS arrows for all four sides (removes
   the `side` state and the vertical special case).
3. The scroll-linked anchoring decision, (a) or (b) above — the actual "feels
   attached" fix, and the one that needs its own session and a careful look at
   `.konsou-scroll`'s clipping.
4. The sidecar rail, if we want desktop verbs beside the panel.
