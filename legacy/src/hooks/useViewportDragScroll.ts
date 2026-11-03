import { useEffect } from "react";

/**
 * Desktop: grab anywhere on the page with the mouse and drag to pan the
 * nearest scrollable container, like touch panning. Registered once at the
 * app shell.
 *
 *  - Mouse only; touch already pans natively.
 *  - Walks up from the pressed element to the closest vertically scrollable
 *    ancestor, so it works on every page, in sheets, and in virtual lists.
 *  - A drag that actually moved swallows the click it would otherwise land
 *    on a card or button, same trick as the horizontal chip rows.
 *  - Form fields keep normal text-selection drags, the sheet handle keeps
 *    its drag-to-close, and native scrollbar drags are left alone.
 */

// Elements whose own drag behaviour must win over viewport panning.
const OPT_OUT =
  'input, textarea, select, [contenteditable=""], [contenteditable="true"], ' +
  ".k-sheet__handle-area, [data-nodrag]";

const DRAG_THRESHOLD = 5;

function findScrollable(from: HTMLElement | null): HTMLElement | null {
  for (let el = from; el; el = el.parentElement) {
    if (el.scrollHeight <= el.clientHeight + 1) continue;
    const overflowY = getComputedStyle(el).overflowY;
    if (overflowY === "auto" || overflowY === "scroll") return el;
  }
  return null;
}

export function useViewportDragScroll() {
  useEffect(() => {
    let scroller: HTMLElement | null = null;
    let startY = 0;
    let startTop = 0;
    let dragging = false; // pressed on a scrollable surface
    let moved = false; // passed the threshold: panning + click suppression
    let pendingTop = 0; // latest target, applied once per frame
    let rafId = 0;

    // Coalesce scrollTop writes to one per animation frame. A high-Hz mouse
    // fires several pointermove events per frame, and each imperative scrollTop
    // write forces a scroll event + layout; batching to the display cadence is
    // what makes the pan feel smooth instead of stuttery.
    const flush = () => {
      rafId = 0;
      if (scroller) scroller.scrollTop = pendingTop;
    };

    const onPointerDown = (e: PointerEvent) => {
      if (e.pointerType !== "mouse" || e.button !== 0) return;
      const target = e.target as HTMLElement | null;
      if (!target || target.closest(OPT_OUT)) return;

      const el = findScrollable(target);
      if (!el) return;

      // Presses on the native scrollbar gutters stay native.
      const rect = el.getBoundingClientRect();
      if (
        e.clientX >= rect.left + el.clientWidth ||
        e.clientY >= rect.top + el.clientHeight
      ) {
        return;
      }

      scroller = el;
      startY = e.clientY;
      startTop = el.scrollTop;
      dragging = true;
      moved = false;
    };

    const onPointerMove = (e: PointerEvent) => {
      if (!dragging || !scroller) return;
      const dy = e.clientY - startY;
      if (!moved) {
        if (Math.abs(dy) <= DRAG_THRESHOLD) return;
        moved = true;
        document.body.classList.add("is-grab-scrolling");
        window.getSelection()?.removeAllRanges();
      }
      pendingTop = startTop - dy;
      if (!rafId) rafId = requestAnimationFrame(flush);
    };

    const endDrag = () => {
      // Land on the final position before tearing down, in case a frame was
      // still pending.
      if (rafId) {
        cancelAnimationFrame(rafId);
        rafId = 0;
      }
      if (scroller && moved) scroller.scrollTop = pendingTop;
      dragging = false;
      scroller = null;
      document.body.classList.remove("is-grab-scrolling");
      // `moved` stays set until the click it spawned has been swallowed.
    };

    // Swallow the click a real drag would otherwise deliver to whatever the
    // pointer happened to be over. Capture phase so it dies before React.
    const onClickCapture = (e: MouseEvent) => {
      if (!moved) return;
      moved = false;
      e.preventDefault();
      e.stopPropagation();
    };

    // A press on a cover image starts a native image drag that steals the
    // pointer stream mid-pan; kill it while a grab is live.
    const onDragStart = (e: DragEvent) => {
      if (dragging || moved) e.preventDefault();
    };

    window.addEventListener("pointerdown", onPointerDown);
    window.addEventListener("pointermove", onPointerMove);
    window.addEventListener("pointerup", endDrag);
    window.addEventListener("pointercancel", endDrag);
    window.addEventListener("click", onClickCapture, true);
    window.addEventListener("dragstart", onDragStart);
    return () => {
      window.removeEventListener("pointerdown", onPointerDown);
      window.removeEventListener("pointermove", onPointerMove);
      window.removeEventListener("pointerup", endDrag);
      window.removeEventListener("pointercancel", endDrag);
      window.removeEventListener("click", onClickCapture, true);
      window.removeEventListener("dragstart", onDragStart);
      document.body.classList.remove("is-grab-scrolling");
    };
  }, []);
}
