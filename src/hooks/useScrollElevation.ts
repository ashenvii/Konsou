import { useEffect } from "react";

/**
 * How far the page scrolls while the header's background ramps from nothing to
 * solid.
 *
 * Twelve pixels, and it is meant to look like almost none. Ionic's
 * `handleHeaderFade` uses ten (`const fadeDuration = 10`, header.utils.ts) and
 * that is the number the iOS behaviour it copies feels like: the bar is not a
 * fade you sit and watch, it is the surface arriving the instant content starts
 * moving underneath it. Anything long enough to perceive as an animation reads
 * as lag on a control that is supposed to feel welded to your finger.
 *
 * This replaces a two-state collapse at 72px down / 40px up that transitioned
 * `font-size` and `line-height` between two sizes over 200ms. Nothing in any
 * reference implementation resizes text on scroll: measured live, Apple Music's
 * album title is 26px with `transform: none` both at rest and 500px down the
 * page. See useHeaderLede for the full account and for the surfaces that get
 * the complete treatment rather than only this ramp.
 */
const FADE_PX = 12;

/**
 * One capturing scroll listener for the whole app.
 *
 * Two jobs off the same event. Elevation: whenever any vertical scroll
 * container (.konsou-scroll) inside a page moves, its owning .k-page gets
 * data-scrolled and <html> gets data-page-scrolled, and the stylesheet uses
 * those to give the chrome a hairline + shadow so content reads as tucking
 * under it. Bar: a header that marks itself with data-collapsing-header gets a
 * `--bar` custom property between 0 and 1, and the stylesheet paints its
 * background and hairline at that opacity.
 *
 * A header that stays exactly one height and grows a surface underneath itself,
 * rather than one that resizes. The previous version transitioned `font-size`
 * and `line-height` between a full and a slim state, and both of those are
 * layout properties: every frame of that animation re-laid-out the header and
 * reflowed the scroller beneath it, on the main thread, during a scroll. This
 * moves `opacity` on a background layer and nothing else.
 *
 * The custom property is written as a bare number and read as `opacity:
 * var(--bar)` with no arithmetic around it, which sidesteps the constraint that
 * shaped the old design: `calc()` drops a custom property used as a multiplier
 * in the WebKit build, and `@property` is not dependably present either. That
 * ruled out sizing a header off a scroll-linked variable, and it was read at
 * the time as ruling out continuity altogether. It does not. A var substituted
 * directly into a property that accepts a bare number needs no arithmetic at
 * all, so this behaves identically on WebView2, WebKitGTK and Android WebView.
 *
 * Everything here is synchronous rather than batched into a frame. The work
 * is a scrollTop read and, only when a threshold is actually crossed, two
 * attribute writes — cheaper than the bookkeeping needed to defer it, and it
 * keeps working where rAF is throttled.
 *
 * Sheet scrollers are ignored: scrolling inside an overlay says nothing about
 * the page behind it.
 */
export function useScrollElevation() {
  useEffect(() => {
    // The header is cached per page so the hot path is not a DOM query per
    // scroll event. Re-resolved whenever the cached node has left the
    // document, which is what a route change looks like from here.
    const headers = new WeakMap<HTMLElement, HTMLElement>();

    const onScroll = (e: Event) => {
      const el = e.target as HTMLElement | null;
      if (!el?.classList?.contains("konsou-scroll")) return;
      if (el.closest(".k-sheet")) return;

      const page = el.closest<HTMLElement>(".k-page");
      if (!page) return;

      const top = el.scrollTop;

      const scrolled = top > 4 ? "true" : "false";
      if (page.dataset.scrolled !== scrolled) page.dataset.scrolled = scrolled;
      const root = document.documentElement;
      if (root.dataset.pageScrolled !== scrolled) root.dataset.pageScrolled = scrolled;

      let header = headers.get(page);
      if (!header?.isConnected) {
        const found = page.querySelector<HTMLElement>("[data-collapsing-header]");
        if (!found) return;
        headers.set(page, found);
        header = found;
      }

      // A header with a large title of its own is driven by an
      // IntersectionObserver on that title instead (useHeaderLede), which knows
      // where the title actually ends rather than guessing at a pixel count.
      // Both writing --bar would mean the last one to fire wins.
      if (header.dataset.lede === "true") return;

      // Clamped, written as a bare number, and read by CSS as `opacity:
      // var(--bar)` with no arithmetic wrapped around it. There is no threshold
      // and no hysteresis any more because there is no longer a layout change
      // to be hysteretic about: this moves one compositor-only property, so
      // crossing back and forth over a boundary costs nothing and cannot
      // feed back into the scroll height the way the old collapse could.
      const v = top <= 0 ? 0 : Math.min(1, top / FADE_PX);
      // Two decimals: past that the string churns every frame for a difference
      // no display can show.
      const next = v.toFixed(2);
      if (header.dataset.bar !== next) {
        header.dataset.bar = next;
        header.style.setProperty("--bar", next);
      }
    };

    document.addEventListener("scroll", onScroll, { capture: true, passive: true });
    return () => {
      document.removeEventListener("scroll", onScroll, true);
      delete document.documentElement.dataset.pageScrolled;
    };
  }, []);
}
