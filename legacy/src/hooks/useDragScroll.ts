import { useEffect, useRef } from "react";

// Glide tuning: exponential decay per 16ms frame, and the speeds (px/ms)
// where a glide is worth starting / gets cut off.
const DECAY = 0.94;
const MIN_START_V = 0.15;
const MIN_KEEP_V = 0.03;

/**
 * Mouse drag-to-pan for horizontally scrollable rows (rows hide their
 * scrollbars): holding the left button drags the row like a touch swipe,
 * and a fast release glides with momentum the way a native fling does.
 * A drag that actually moved suppresses the click it would otherwise land
 * on a card or chip. Touch input is left alone — rows scroll natively there.
 *
 * The wheel is deliberately NOT touched: vertical wheel over a row keeps
 * scrolling the page (the row must never interrupt it), and trackpads emit
 * real horizontal deltas the browser applies natively.
 */
export function useDragScroll<T extends HTMLElement>() {
  const ref = useRef<T>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    let dragging = false;
    let moved = false;
    let startX = 0;
    let startLeft = 0;
    let pendingLeft = 0;
    let rafId = 0;

    // Velocity is an exponential moving average of the pointer's px/ms, so
    // one jittery final event can't fake a fling.
    let velocity = 0;
    let lastX = 0;
    let lastT = 0;
    let glideId = 0;

    // Coalesce scrollLeft writes to one per frame, same as the viewport
    // pan: a high-Hz mouse fires several pointermoves per frame and each
    // imperative write forces sync scroll work.
    const flush = () => {
      rafId = 0;
      el.scrollLeft = pendingLeft;
    };

    const stopGlide = () => {
      if (glideId) {
        cancelAnimationFrame(glideId);
        glideId = 0;
      }
    };

    const glide = (v: number, prevTime: number) => {
      glideId = requestAnimationFrame((now) => {
        const dt = now - prevTime;
        el.scrollLeft -= v * dt;
        const decayed = v * Math.pow(DECAY, dt / 16);
        const atEdge =
          el.scrollLeft <= 0 ||
          el.scrollLeft >= el.scrollWidth - el.clientWidth;
        if (Math.abs(decayed) > MIN_KEEP_V && !atEdge) glide(decayed, now);
        else glideId = 0;
      });
    };

    const onPointerDown = (e: PointerEvent) => {
      if (e.pointerType !== "mouse" || e.button !== 0) return;
      stopGlide();
      dragging = true;
      moved = false;
      startX = e.clientX;
      startLeft = el.scrollLeft;
      velocity = 0;
      lastX = e.clientX;
      lastT = e.timeStamp;
    };
    const onPointerMove = (e: PointerEvent) => {
      if (!dragging) return;
      const dx = e.clientX - startX;
      if (Math.abs(dx) > 4) moved = true;
      if (!moved) return;
      const dt = e.timeStamp - lastT;
      if (dt > 0) {
        const instant = (e.clientX - lastX) / dt;
        velocity = velocity * 0.8 + instant * 0.2;
        lastX = e.clientX;
        lastT = e.timeStamp;
      }
      pendingLeft = startLeft - dx;
      if (!rafId) rafId = requestAnimationFrame(flush);
    };
    const onPointerUp = (e: PointerEvent) => {
      if (rafId) {
        cancelAnimationFrame(rafId);
        rafId = 0;
        if (dragging && moved) el.scrollLeft = pendingLeft;
      }
      if (dragging && moved && Math.abs(velocity) > MIN_START_V) {
        // A held-then-released pointer shouldn't fling on stale speed.
        if (e.timeStamp - lastT < 80) glide(velocity, e.timeStamp);
      }
      dragging = false;
    };
    const onClickCapture = (e: MouseEvent) => {
      if (moved) {
        e.preventDefault();
        e.stopPropagation();
        moved = false;
      }
    };
    // A real wheel turn means the user took over; don't fight it.
    const onWheel = () => stopGlide();

    el.addEventListener("pointerdown", onPointerDown);
    window.addEventListener("pointermove", onPointerMove);
    window.addEventListener("pointerup", onPointerUp);
    el.addEventListener("click", onClickCapture, true);
    el.addEventListener("wheel", onWheel, { passive: true });
    return () => {
      if (rafId) cancelAnimationFrame(rafId);
      stopGlide();
      el.removeEventListener("pointerdown", onPointerDown);
      window.removeEventListener("pointermove", onPointerMove);
      window.removeEventListener("pointerup", onPointerUp);
      el.removeEventListener("click", onClickCapture, true);
      el.removeEventListener("wheel", onWheel);
    };
  }, []);

  return ref;
}
