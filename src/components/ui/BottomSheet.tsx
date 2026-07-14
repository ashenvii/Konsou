import { useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { registerSheet } from "@/lib/sheetStack";
import type { PointerEvent, ReactNode } from "react";

interface BottomSheetProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: ReactNode;
  /** Disable swipe/backdrop dismissal (e.g. while a keyboard is open inside). */
  dismissable?: boolean;
}

// Dragging past this fraction of the sheet height (or flicking faster than
// the velocity threshold) commits the close; anything less springs back.
const CLOSE_FRACTION = 0.3;
const FLICK_VELOCITY = 0.55; // px per ms, downward
// Downward pull inside the scroll body, while already scrolled to the top,
// needed before we take the gesture over as a sheet drag instead of a scroll.
// Small enough to feel immediate, large enough that a tap never triggers it.
const PULL_ENGAGE_SLOP = 6; // px

/**
 * The container for all modal interactions. Bottom sheet on mobile, centered
 * dialog on desktop (CSS-switched). Dismiss via backdrop tap, Escape, dragging
 * the handle, or pulling down anywhere in the body once it is scrolled to the
 * top. The sheet tracks the finger live and the backdrop fades with it.
 */
export function BottomSheet({
  open,
  onClose,
  title,
  children,
  dismissable = true,
}: BottomSheetProps) {
  const sheetRef = useRef<HTMLDivElement>(null);
  const backdropRef = useRef<HTMLDivElement>(null);
  const bodyRef = useRef<HTMLDivElement>(null);
  const drag = useRef<{
    startY: number;
    lastY: number;
    lastT: number;
    velocity: number;
  } | null>(null);
  const closing = useRef(false);
  const raf = useRef(0);
  const pendingDy = useRef(0);

  // Latest close/settle without re-registering listeners each render.
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;
  const settleRef = useRef<(dy: number) => void>(() => {});
  const beginRef = useRef<(clientY: number, t: number) => void>(() => {});
  const trackRef = useRef<(clientY: number, t: number) => void>(() => {});

  useEffect(() => {
    if (!open) return;
    closing.current = false;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && dismissable) onCloseRef.current();
    };
    window.addEventListener("keydown", onKey);
    sheetRef.current?.focus();
    // Android back closes this sheet instead of navigating.
    const unregister = registerSheet(() => onCloseRef.current());
    return () => {
      window.removeEventListener("keydown", onKey);
      unregister();
      cancelAnimationFrame(raf.current);
    };
  }, [open, dismissable]);

  // Pull-to-close from inside the scroll body. Native (not React) touch
  // listeners because the body must call preventDefault to stop the browser
  // from claiming a downward drag as a scroll — React attaches touchmove as
  // passive, where preventDefault is a no-op. Only engages once the content is
  // at the top and the finger has moved down past the slop, so normal scrolling
  // and taps are untouched. Desktop (centered dialog, no handle) opts out.
  useEffect(() => {
    if (!open) return;
    const body = bodyRef.current;
    if (!body) return;
    if (window.matchMedia("(min-width: 1024px)").matches) return;

    let startY = 0;
    let engaged = false;
    let done = false;

    const onStart = (e: TouchEvent) => {
      if (!dismissable || closing.current || e.touches.length !== 1) {
        done = true;
        return;
      }
      startY = e.touches[0].clientY;
      engaged = false;
      done = false;
    };
    const onMove = (e: TouchEvent) => {
      if (done || closing.current) return;
      const y = e.touches[0].clientY;
      const dy = y - startY;
      if (!engaged) {
        // Content can still scroll up, or the pull is upward: it's a scroll.
        if (body.scrollTop > 0 || dy < 0) {
          done = true;
          return;
        }
        if (dy < PULL_ENGAGE_SLOP) return;
        engaged = true;
        beginRef.current(y, e.timeStamp); // anchor here so there's no jump
      }
      // We own the gesture now: stop the scroller from also moving.
      e.preventDefault();
      trackRef.current(y, e.timeStamp);
    };
    const onEnd = (e: TouchEvent) => {
      if (engaged && drag.current) {
        const y = e.changedTouches[0]?.clientY ?? startY;
        settleRef.current(Math.max(0, y - drag.current.startY));
      }
      engaged = false;
      done = false;
    };

    body.addEventListener("touchstart", onStart, { passive: true });
    body.addEventListener("touchmove", onMove, { passive: false });
    body.addEventListener("touchend", onEnd);
    body.addEventListener("touchcancel", onEnd);
    return () => {
      body.removeEventListener("touchstart", onStart);
      body.removeEventListener("touchmove", onMove);
      body.removeEventListener("touchend", onEnd);
      body.removeEventListener("touchcancel", onEnd);
    };
  }, [open, dismissable]);

  if (!open) return null;

  const settle = (dy: number) => {
    const sheet = sheetRef.current;
    const backdrop = backdropRef.current;
    if (!sheet) return;
    const height = sheet.offsetHeight || 1;
    const v = drag.current?.velocity ?? 0;
    drag.current = null;
    cancelAnimationFrame(raf.current);
    raf.current = 0;
    sheet.style.willChange = "";
    if (backdrop) backdrop.style.willChange = "";

    if (dy > height * CLOSE_FRACTION || v > FLICK_VELOCITY) {
      // Commit: finish the slide from where the finger left off, then close.
      closing.current = true;
      sheet.style.transition = "transform 180ms ease-in";
      sheet.style.transform = "translateY(105%)";
      if (backdrop) {
        backdrop.style.transition = "opacity 180ms ease-in";
        backdrop.style.opacity = "0";
      }
      window.setTimeout(() => onCloseRef.current(), 170);
    } else {
      // Spring back to rest.
      sheet.style.transition = "transform 200ms cubic-bezier(0.16, 1, 0.3, 1)";
      sheet.style.transform = "";
      if (backdrop) {
        backdrop.style.transition = "opacity 200ms ease-out";
        backdrop.style.opacity = "";
      }
    }
  };
  settleRef.current = settle;

  // Core drag start: seed the tracking state and promote the sheet to its own
  // layer so the WebView composites the move instead of repainting it.
  const beginDragAt = (clientY: number, t: number) => {
    drag.current = { startY: clientY, lastY: clientY, lastT: t, velocity: 0 };
    const sheet = sheetRef.current;
    const backdrop = backdropRef.current;
    if (sheet) {
      sheet.style.transition = "none";
      sheet.style.willChange = "transform";
    }
    if (backdrop) {
      backdrop.style.transition = "none";
      backdrop.style.willChange = "opacity";
    }
  };
  beginRef.current = beginDragAt;

  const trackDrag = (clientY: number, t: number) => {
    const d = drag.current;
    const sheet = sheetRef.current;
    if (!d || !sheet || closing.current) return;
    const dy = Math.max(0, clientY - d.startY);
    const dt = t - d.lastT;
    if (dt > 0) d.velocity = (clientY - d.lastY) / dt;
    d.lastY = clientY;
    d.lastT = t;

    // Moves fire faster than the display refreshes; batch the style writes into
    // one rAF per frame so the gesture stays smooth on weak GPUs.
    pendingDy.current = dy;
    if (!raf.current) {
      raf.current = requestAnimationFrame(() => {
        raf.current = 0;
        if (!drag.current || closing.current) return;
        const y = pendingDy.current;
        // Track the finger; fade the backdrop out proportionally so the content
        // behind shows through mid-drag (the "peek").
        sheet.style.transform = `translateY(${y}px)`;
        const backdrop = backdropRef.current;
        if (backdrop) {
          const height = sheet.offsetHeight || 1;
          backdrop.style.opacity = String(Math.max(0, 1 - y / height));
        }
      });
    }
  };
  trackRef.current = trackDrag;

  // The handle uses pointer events: it has touch-action:none so the browser
  // never steals the drag, and pointer capture keeps tracking off-element.
  const onPointerDown = (e: PointerEvent<HTMLDivElement>) => {
    if (!dismissable || closing.current) return;
    e.currentTarget.setPointerCapture(e.pointerId);
    beginDragAt(e.clientY, e.timeStamp);
  };
  const onPointerMove = (e: PointerEvent<HTMLDivElement>) =>
    trackDrag(e.clientY, e.timeStamp);
  const onPointerUp = (e: PointerEvent<HTMLDivElement>) => {
    const d = drag.current;
    if (!d || closing.current) return;
    settle(Math.max(0, e.clientY - d.startY));
  };

  return createPortal(
    <div className="k-sheet-overlay crossfade" role="presentation">
      <div
        ref={backdropRef}
        className="k-sheet-backdrop"
        onClick={() => dismissable && !closing.current && onCloseRef.current()}
      />
      <div
        className="k-sheet"
        role="dialog"
        aria-modal="true"
        aria-label={title}
        tabIndex={-1}
        ref={sheetRef}
      >
        <div
          className="k-sheet__handle-area"
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
        >
          <div className="k-sheet__handle" />
        </div>
        {title && <div className="k-sheet__title">{title}</div>}
        <div className="k-sheet__body konsou-scroll" ref={bodyRef}>
          {children}
        </div>
      </div>
    </div>,
    document.body,
  );
}
