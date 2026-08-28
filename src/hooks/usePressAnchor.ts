import { useCallback, useRef, useState } from "react";
import type { PointerEvent as ReactPointerEvent } from "react";

/**
 * Remembers which element a press landed on, so a popover can point at it.
 *
 * The anchored popover needs a DOM node. The cards that open it only ever knew
 * their own id, and rewriting every one of their `onOpen` signatures to carry an
 * element would push a rendering concern into a dozen call sites. So the press
 * is recorded on the way DOWN, in capture, on one container: by the time the
 * click handler runs and asks for the anchor, it is already there.
 *
 * This shipped hand-rolled inside FranchiseCollection and nowhere else, which is
 * why the Overview's own quick menu had no anchor at all and opened as a panel
 * in the middle of the screen with no relation to the card you touched. It is a
 * hook now so the second surface is a call rather than a second copy.
 *
 * ## Two elements, not one
 *
 * `anchor` is what the panel POINTS AT and `opener` is what OPENED it, and they
 * are deliberately different: the panel points at the poster (a full-width row
 * has no room beside it, so a panel placed against the row itself goes
 * off-screen), while the thing you actually pressed is the whole row.
 *
 * Conflating them is a real bug and it shipped once. The popover ignores
 * outside-clicks that land on its anchor, so that the caller can decide whether
 * a second press means "close this" or "switch to the next card". With only the
 * poster registered, pressing the same row ANYWHERE ELSE looked like an outside
 * click: the popover closed itself, and then the row's own click handler ran
 * its toggle against an already-cleared state and opened it straight back up.
 * The panel flickered and stayed open, and only presses that happened to land
 * on the small cover would close it.
 *
 * @param cardSelector  What counts as "the card" — the outer clickable object.
 * @param posterSelector Optional. The art inside the card to point at instead.
 *   A card that spans the full width of its container has no room on either
 *   side, so a panel placed beside it goes off-screen or gets squeezed to a
 *   sliver. Pointing at the poster keeps the arrow honest and gives the panel
 *   somewhere to go. On a narrow grid card the two are near enough to the same
 *   thing that this is a no-op.
 */
export function usePressAnchor(cardSelector: string, posterSelector?: string) {
  const pressedAnchor = useRef<HTMLElement | null>(null);
  const pressedOpener = useRef<HTMLElement | null>(null);
  const [anchor, setAnchor] = useState<HTMLElement | null>(null);
  const [opener, setOpener] = useState<HTMLElement | null>(null);

  const notePress = useCallback(
    (e: ReactPointerEvent) => {
      const el = e.target as HTMLElement | null;
      const card = el?.closest(cardSelector) as HTMLElement | null;
      const poster = posterSelector
        ? card?.querySelector<HTMLElement>(posterSelector)
        : null;
      pressedAnchor.current = poster ?? card ?? null;
      pressedOpener.current = card ?? null;
    },
    [cardSelector, posterSelector],
  );

  /** Call from the click handler that opens the panel. Separate from the press
   *  so a press that turns out to be a drag or a scroll never moves a panel
   *  that is already open. */
  const commitAnchor = useCallback(() => {
    setAnchor(pressedAnchor.current);
    setOpener(pressedOpener.current);
  }, []);

  return { anchor, opener, notePress, commitAnchor };
}
