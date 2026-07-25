import { useEffect } from "react";

// The header's collapsible content height (matches --topbar-height). The offset
// slides between 0 (shown) and -HEADER_H (folded).
const HEADER_H = 56;
// Past this fraction of the fold, the Tonight strip (My List) counts as hidden.
const TONIGHT_HIDE_AT = 0.6;

/**
 * One capturing scroll listener for the whole app, doing three jobs:
 *
 * 1. Elevation: whenever any vertical scroll container (.konsou-scroll) inside a
 *    page moves, its owning .k-page gets data-scrolled, and <html> gets
 *    data-page-scrolled — the stylesheet uses these to give the page chrome and
 *    the global header a hairline + shadow so content reads as tucking under.
 *
 * 2. Scroll-away header: the header slides up 1:1 with scroll (reclaiming its
 *    space via margin-top) and returns as you scroll up, the way Spotify treats
 *    its header. Driven as a continuous inline CSS var (--header-shift), NOT a
 *    CSS transition — so it stays smooth even under reduced motion, where a
 *    transition would be zeroed into an abrupt jump (the old "snap"). Tracked
 *    per scroll container, so each page keeps its own header state and returning
 *    to a page restores it alongside the scroll position.
 *
 * 3. The Tonight strip still folds on a binary signal (data-chrome-hidden),
 *    derived from the same offset.
 *
 * Sheet scrollers are ignored — scrolling inside an overlay says nothing about
 * the page behind it. The virtualized lists and per-tab scroll restoration are
 * untouched: only the header's own margin moves.
 */
export function useScrollElevation() {
  useEffect(() => {
    const lastTops = new WeakMap<HTMLElement, number>();
    const shifts = new WeakMap<HTMLElement, number>();

    // Cache the header element and write its offset INLINE. The offset must not
    // live in a custom property on <html>: changing a root custom property
    // invalidates computed style for the entire document (measured at ~40ms per
    // scroll frame on a populated page), which is the whole scroll-jank story.
    // An inline margin on the header alone is ~0.5ms and scoped to the header.
    let headerEl: HTMLElement | null = null;
    const getHeader = () => {
      if (!headerEl || !headerEl.isConnected) {
        headerEl = document.querySelector(".k-header");
      }
      return headerEl;
    };

    const setChromeHidden = (hidden: boolean) => {
      const root = document.documentElement;
      const now = root.dataset.chromeHidden === "true";
      if (hidden !== now) {
        if (hidden) root.dataset.chromeHidden = "true";
        else delete root.dataset.chromeHidden;
      }
    };

    const onScroll = (e: Event) => {
      const el = e.target as HTMLElement | null;
      if (!el?.classList?.contains("konsou-scroll")) return;

      const scrolled = el.scrollTop > 4 ? "true" : "false";
      const page = el.closest(".k-page") as HTMLElement | null;
      if (page && page.dataset.scrolled !== scrolled) page.dataset.scrolled = scrolled;
      const root = document.documentElement;
      if (root.dataset.pageScrolled !== scrolled) root.dataset.pageScrolled = scrolled;

      // Chrome reaction only follows page-level scrollers, never sheets.
      if (el.closest(".k-sheet")) return;

      const prev = lastTops.get(el) ?? el.scrollTop;
      const delta = el.scrollTop - prev;
      lastTops.set(el, el.scrollTop);

      let shift = shifts.get(el) ?? 0;
      if (el.scrollTop <= 0) {
        shift = 0;
      } else if (delta > 0) {
        // Folding hands the header's space to this scroller, which SHRINKS
        // its max scroll. Do that with less runway below than the fold would
        // release and the browser clamps scrollTop, feeding a fake upward
        // delta back into this handler — the fold seesaws every wheel tick
        // (the search-jitters-over-the-header bug on short pages). So the
        // fold only deepens while the runway can absorb what it releases;
        // otherwise it holds where it is.
        const capacity = HEADER_H + shift;
        const runway = el.scrollHeight - el.clientHeight - el.scrollTop;
        if (runway > capacity) {
          shift = Math.max(-HEADER_H, shift - delta);
        }
      } else {
        // Scrolling up always brings the header back; unfolding only grows
        // the max scroll, so it can never trigger the clamp loop.
        shift = Math.min(0, shift - delta);
      }
      shifts.set(el, shift);
      const header = getHeader();
      if (header) header.style.marginTop = shift ? `${shift}px` : "";

      setChromeHidden(shift <= -HEADER_H * TONIGHT_HIDE_AT);
    };

    document.addEventListener("scroll", onScroll, { capture: true, passive: true });
    // Capture flag must match on removal (passive is irrelevant to matching).
    return () => {
      document.removeEventListener("scroll", onScroll, true);
      const root = document.documentElement;
      delete root.dataset.chromeHidden;
      delete root.dataset.pageScrolled;
      const header = getHeader();
      if (header) header.style.marginTop = "";
    };
  }, []);
}
