import { useEffect } from "react";
import type { RefObject } from "react";

/**
 * A slim bar that takes over from a large title as the title scrolls away.
 *
 * This is the iOS large-title behaviour, the one Spotify, Apple Music and every
 * native music app use, and it is copied rather than invented. The readable
 * reference is Ionic's `ion-header` with `collapse="condense"`
 * (core/src/components/header/header.utils.ts and header.tsx); the behaviour was
 * checked against Apple Music's web player, where the album `h1` measures 26px
 * with `transform: none` at scroll 0 AND at scroll 500. It never resizes. It
 * simply moves from `top: 87` to `top: -413` and leaves.
 *
 * That is the whole thing our header had wrong. It was one element trying to be
 * both sizes, transitioning `font-size` and `line-height` between them. Nothing
 * in the real implementations resizes any text at all:
 *
 * - The large title is ORDINARY CONTENT inside the scroller. It scrolls off the
 *   way a paragraph does, because that is what it is.
 * - The slim bar is a separate, permanent element. Its title is hidden until
 *   the large one has gone, then crossfades in over 200ms.
 * - Only a background LAYER fades, never the bar's own text, so the controls
 *   stay legible the entire way. Ionic paints it on an absolutely positioned
 *   `.header-background` with `transform: translateZ(0)`; we use a `::before`
 *   for the same reason, to keep it on its own compositor layer.
 *
 * The trigger is an IntersectionObserver on the large title, NOT a scroll
 * threshold, which is the second thing we had wrong. A number picked in advance
 * cannot know where the title actually ends, so the bar arrived early on a short
 * page and late on a tall one. Watching the element means the handover happens
 * exactly when the thing it is handing over from leaves the screen.
 */

/**
 * Ionic's own threshold ladder, verbatim.
 *
 * The ladder is what makes this feel continuous rather than switched. A single
 * threshold gives one callback and therefore one jump; nine give the ramp nine
 * steps on the way through, which at 60fps is under the eye's ability to see a
 * step at all. Nothing here is scroll-linked in the sense of running per frame,
 * and it does not need to be: the browser fires these off its own compositing,
 * so the ramp costs no scroll handler.
 */
const THRESHOLDS = [0, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1];

/**
 * Where the ramp starts and finishes, as a share of the large title still on
 * screen. Both numbers are Ionic's (`handleToolbarBorderIntersection`):
 *
 *   scale = ((1 - intersectionRatio) * 100) / 75
 *
 * with a hard 0 while the ratio is still above 0.9. So the bar stays completely
 * transparent until a tenth of the title has gone, then reaches full strength
 * once three quarters of it has. The dead zone at the top is deliberate and
 * worth keeping: without it the bar flickers on every one-pixel rubber-band at
 * the top of the page.
 */
const DEAD_ZONE = 0.9;
const RAMP_OVER = 0.75;

export function useHeaderLede(
  barRef: RefObject<HTMLElement | null>,
  ledeRef: RefObject<HTMLElement | null>,
  scrollRef: RefObject<HTMLElement | null>,
  /**
   * Whether the elements are actually in the tree yet.
   *
   * Not optional politeness. The page returns a skeleton while the list loads
   * and an empty state when there is nothing in it, and neither of those trees
   * contains a bar or a lede — so on every cold launch this effect ran once
   * against three null refs, returned, and with a stable dep list never ran
   * again. The bar would sit at --bar 0 for the rest of the session. Overview
   * has the identical trap written up on its band's ResizeObserver, which is
   * how this one got caught before it shipped.
   */
  ready: boolean,
) {
  useEffect(() => {
    const bar = barRef.current;
    const lede = ledeRef.current;
    const root = scrollRef.current;
    if (!ready || !bar || !lede || !root) return;

    // Claims this header for the observer. useScrollElevation runs a cruder
    // scroll ramp on every other collapsing header in the app and skips any
    // that carries this, so the two can never both be writing --bar.
    bar.dataset.lede = "true";

    const set = (v: number) => {
      // A plain number straight onto the custom property, consumed by CSS as
      // `opacity: var(--bar)` with no arithmetic around it. Ionic writes
      // `opacity: calc(var(--opacity) * var(--opacity-scale))` because it has a
      // second, author-settable opacity to compose with; we have no such
      // requirement, and a var used as a bare multiplicand inside calc() is
      // exactly the pattern that silently does nothing in the WebKit and
      // Android WebView builds this app ships on.
      bar.style.setProperty("--bar", String(v));
      // The bar's title only exists once the large one has gone. Kept as an
      // attribute rather than a second custom property so the crossfade is a
      // CSS transition between two states, not another thing to interpolate.
      const gone = v > 0.99;
      if ((bar.dataset.ledeGone === "true") !== gone) {
        bar.dataset.ledeGone = gone ? "true" : "false";
        // And it leaves the accessibility tree with it. While the lede is on
        // screen the page has a real h1 saying "My List" and this would be a
        // second, identical, invisible one; once the lede has gone this is the
        // only name on the surface and has to be readable. Ionic does exactly
        // this to its inactive header's title (setHeaderActive, header.utils.ts)
        // rather than hiding the whole header, which would take the header's
        // focusable controls out of the tree along with it.
        const title = bar.querySelector("[data-bar-title]");
        if (title) title.setAttribute("aria-hidden", gone ? "false" : "true");
      }
    };

    // Written before the first set() rather than left to it. set() only touches
    // the attribute when the value CHANGES, so starting from absent meant the
    // resting state was "attribute missing" and the scrolled state was "true" —
    // legible enough to CSS, which only asks about "true", and not at all
    // legible to anyone reading the DOM trying to work out whether the hook is
    // running.
    bar.dataset.ledeGone = "false";
    set(0);


    const io = new IntersectionObserver(
      (entries) => {
        const e = entries[entries.length - 1];
        // Gone entirely: hold at full. Ionic reaches the same state by a second
        // observer calling setToolbarBackgroundOpacity with no argument, which
        // removes the property and lets it default to 1.
        if (!e.isIntersecting) return set(1);
        // `scrollTop <= 0` is not redundant with the dead zone. Safari settles
        // a released rubber-band at scrollTop 1 rather than 0, which leaves the
        // bar faintly painted at the top of a page nobody has scrolled. Ionic
        // carries the same guard for the same reason.
        const v =
          e.intersectionRatio > DEAD_ZONE || root.scrollTop <= 0
            ? 0
            : Math.min(1, (1 - e.intersectionRatio) / RAMP_OVER);
        set(v);
      },
      { root, threshold: THRESHOLDS },
    );
    io.observe(lede);

    return () => {
      io.disconnect();
      delete bar.dataset.lede;
      delete bar.dataset.ledeGone;
      bar.style.removeProperty("--bar");
    };
  }, [barRef, ledeRef, scrollRef, ready]);
}
