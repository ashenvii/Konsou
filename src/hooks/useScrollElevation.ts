import { useEffect } from "react";

/**
 * One capturing scroll listener for the whole app. Whenever any vertical
 * scroll container (.konsou-scroll) inside a page moves, its owning .k-page
 * gets data-scrolled="true", which the stylesheet uses to give the page's top
 * chrome a solid background and a hairline so content reads as tucking under
 * it. Capturing is required because scroll events don't bubble.
 *
 * Deliberately DOM-only: it never changes any element's height, so the
 * virtualized lists and per-tab scroll restoration are untouched. One listener
 * covers every page, current and future, with no per-page wiring.
 */
export function useScrollElevation() {
  useEffect(() => {
    const onScroll = (e: Event) => {
      const el = e.target as HTMLElement | null;
      if (!el?.classList?.contains("konsou-scroll")) return;
      const page = el.closest(".k-page") as HTMLElement | null;
      if (!page) return;
      const scrolled = el.scrollTop > 4 ? "true" : "false";
      if (page.dataset.scrolled !== scrolled) page.dataset.scrolled = scrolled;
    };
    document.addEventListener("scroll", onScroll, { capture: true, passive: true });
    // Capture flag must match on removal (passive is irrelevant to matching).
    return () => document.removeEventListener("scroll", onScroll, true);
  }, []);
}
