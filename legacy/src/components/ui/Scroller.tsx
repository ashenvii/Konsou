import { forwardRef } from "react";
import type { ReactNode } from "react";

/**
 * The app's scroll surface. One component, every scroller.
 *
 * It scrolls natively. There is no thumb element, no scroll listener, no
 * pointer handling and no geometry maths in here — the browser's own scrollbar
 * does the work and the stylesheet skins it (see `.k-scroller` in global.css).
 *
 * That is a deliberate correction. The first version of this hid the native
 * scrollbar and drew its own thumb, and it was wrong twice over. It felt
 * invented, because it was: a hand-rolled thumb has to re-implement drag,
 * click-the-track-to-page, keyboard paging, momentum, the platform's own sizing
 * curve and its show/hide timing, and every one of those is a chance to be
 * subtly unlike the scrollbar in every other window on the machine. And the
 * reason it was reached for had already evaporated — it existed to give the
 * element a full-width content box, because the header bar used to be
 * positioned against the PAGE and so overhung the content by the scrollbar's
 * width. Moving that bar inside the scroller fixed the alignment properly, at
 * which point the reserved width stopped mattering and the custom thumb was
 * solving a problem that no longer existed.
 *
 * Native scrolling with a skin over it is the whole ambition. If something is
 * missing, style `::-webkit-scrollbar` — do not start drawing.
 *
 * WHY IT IS STILL A COMPONENT
 *
 * Because a class you paste onto each scroller drifts the moment one surface
 * wants a different inset, and because this is where scroll behaviour goes when
 * the app eventually needs more of it (restoration, edge fades). Every surface
 * draws its scrolling from here and adapts through props; no surface builds its
 * own, and a surface needing behaviour this lacks gets that behaviour added
 * here behind a prop rather than forked into a second component.
 *
 * Adoption is per-surface: anything still on a bare `.konsou-scroll` keeps
 * working untouched and converts when it is reworked.
 */

export interface ScrollerProps {
  children: ReactNode;
  /** Applied to the scrolling element itself, so callers control its padding
   *  and flex behaviour without wrapping it in another box. */
  className?: string;
}

export const Scroller = forwardRef<HTMLDivElement, ScrollerProps>(function Scroller(
  { children, className = "" },
  ref,
) {
  // `konsou-scroll` stays on the element: it carries the app's scroll law
  // (contained overscroll, no sideways pan, no scroll anchoring) and is what
  // useScrollElevation's one capturing listener looks for.
  return (
    <div ref={ref} className={`k-scroller konsou-scroll ${className}`.trim()}>
      {children}
    </div>
  );
});
