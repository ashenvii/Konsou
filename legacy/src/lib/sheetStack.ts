/**
 * Registry of currently-open sheets/modals, newest last. The Android back
 * handler consults it first: back closes the top sheet instead of navigating,
 * matching how every native app treats back while a bottom sheet is up.
 *
 * Also the registry two open overlays need to coexist correctly, which
 * neither `AnchoredPopover` nor `BottomSheet` could do alone: opening a
 * franchise's quick menu, then tapping a season's status stamp inside it,
 * stacks a second overlay on top of the first. Two things broke without a
 * shared registry:
 *
 *  - Both `.k-pop` and `.k-sheet-overlay` had a fixed CSS `z-index` (120 and
 *    100). Whichever opened SECOND still rendered at its own fixed value, so
 *    the status picker (100) rendered visually BEHIND the still-open quick
 *    menu (120) instead of on top of it — some of its own options were
 *    literally unclickable, covered by the menu they were opened from.
 *  - `AnchoredPopover`'s "click outside closes me" listener only knew its own
 *    element and its own anchor. A click on the status picker — a completely
 *    different overlay, portaled as a sibling, not a descendant — looked
 *    exactly like a click on the page behind everything, so trying to pick a
 *    status silently closed the quick menu underneath it as a side effect.
 *    Because that close happened through the popover's own listener rather
 *    than the status picker's own `onClose`, the status picker's "which title
 *    is this for" state never reset — so reopening the quick menu found it
 *    still set, and the picker reappeared already open.
 */
type Closer = () => void;

const stack: Closer[] = [];

/** Register an open sheet. Returns an unregister function for cleanup. */
export function registerSheet(close: Closer): () => void {
  stack.push(close);
  return () => {
    const i = stack.indexOf(close);
    if (i !== -1) stack.splice(i, 1);
  };
}

/** Close the most recently opened sheet. True if one was open. */
export function closeTopSheet(): boolean {
  const top = stack[stack.length - 1];
  if (!top) return false;
  top();
  return true;
}

// Comfortably above every static z-index already in use elsewhere in the
// app (the highest before this was 200, for the command palette), so a
// stacked overlay is never accidentally hidden by ordinary page chrome.
let nextZ = 1000;

/** A fresh z-index, higher than the last one handed out. Call once per
 *  overlay, when it opens — never on every render, or the stacking order
 *  would reshuffle on its own re-renders instead of staying fixed to when
 *  each one actually opened. */
export function acquireOverlayZIndex(): number {
  nextZ += 1;
  return nextZ;
}

const openOverlays = new Set<HTMLElement>();

/** Register an overlay's own root element while it is open (the popover box,
 *  the sheet's backdrop-and-dialog wrapper — whatever the "this counts as
 *  inside me" boundary is for that overlay). Returns an unregister function. */
export function registerOverlayElement(el: HTMLElement): () => void {
  openOverlays.add(el);
  return () => {
    openOverlays.delete(el);
  };
}

/** True if `target` is inside any currently-open overlay other than `self`.
 *  An overlay's own "click outside, close me" check should treat this as
 *  "not outside" — the click landed on a DIFFERENT live overlay, not on the
 *  page behind everything. */
export function isInsideAnotherOverlay(target: Node, self?: HTMLElement | null): boolean {
  for (const el of openOverlays) {
    if (el === self) continue;
    if (el.contains(target)) return true;
  }
  return false;
}
