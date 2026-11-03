import { useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { X } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { acquireOverlayZIndex, registerOverlayElement, registerSheet } from "@/lib/sheetStack";
import type { PointerEvent, ReactNode } from "react";

interface BottomSheetProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  /** Accessible name when the sheet draws its own header instead of using
   *  `title` (QuickMenu shows a cover + title block). Without this such a sheet
   *  is a modal dialog with no name at all. */
  ariaLabel?: string;
  children: ReactNode;
  /** Disable swipe/backdrop dismissal (e.g. while a keyboard is open inside). */
  dismissable?: boolean;
  /** Desktop only: dock as a right-side examination panel (the loupe) instead
   *  of a centered dialog. Mobile is unchanged (always a bottom sheet). */
  dock?: boolean;
  /**
   * The sheet stops claiming to be modal.
   *
   * With `dock` on a desktop width it goes the whole way and becomes a panel:
   * no backdrop, nothing trapped, the list behind it stays live — so picking
   * another card swaps what the panel shows instead of closing it and making
   * you start again. Closing becomes explicit: the X, Escape, or hardware back.
   *
   * Anywhere else (a phone) it keeps the backdrop, because a sheet there really
   * does cover the page, but it still reports `aria-modal="false"` and traps
   * nothing. That is DIM's own phone sheet, and it is what keeps the quick menu
   * one interaction rather than two that behave differently by screen width.
   */
  modeless?: boolean;
  /**
   * Pinned under the scrolling body, out of the scroll.
   *
   * This is where the desktop verb rail goes on a phone. A column of marks
   * beside the panel has no equivalent on a 390px screen — there is no beside —
   * so the verbs become a bar across the bottom, which is the same promise
   * (the acts are always reachable, the body is only ever what you read) in the
   * shape the screen allows. DIM makes exactly this swap: `ItemPopup` passes
   * its move locations to the phone `Sheet`'s `footer` and its sidecar to the
   * desktop popup.
   */
  footer?: ReactNode;
}

// Dragging past this fraction of the sheet height (or flicking faster than
// the velocity threshold) commits the close; anything less springs back.
const CLOSE_FRACTION = 0.3;
const FLICK_VELOCITY = 0.55; // px per ms, downward
// Downward pull inside the scroll body, while already scrolled to the top,
// needed before we take the gesture over as a sheet drag instead of a scroll.
//
// This was 6px, which is finger jitter rather than an intention: reaching the
// top of a scrollable sheet and continuing to drag dismissed it instantly, so
// the only way to read content was to scroll down first and back up. The
// sheet now holds still through a deliberate pull before it starts following
// the finger, which is the resistance a nested scroll needs to feel safe.
const PULL_ENGAGE_SLOP = 56; // px

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
  ariaLabel,
  children,
  dismissable = true,
  dock = false,
  modeless = false,
  footer,
}: BottomSheetProps) {
  // Modeless is a desktop arrangement: it needs a "behind" that is still worth
  // interacting with, and a phone sheet covers everything. Read once per open
  // rather than watched, so a resize mid-session can't swap the panel's whole
  // interaction model under the user.
  const asPanel =
    modeless &&
    dock &&
    typeof window !== "undefined" &&
    window.matchMedia("(min-width: 1024px)").matches;
  const overlayRef = useRef<HTMLDivElement>(null);
  const sheetRef = useRef<HTMLDivElement>(null);
  const backdropRef = useRef<HTMLDivElement>(null);
  const bodyRef = useRef<HTMLDivElement>(null);
  // Assigned once per open, not per render, and registered as a live overlay
  // so another overlay opened from inside this one (or vice versa — a status
  // picker opened from a franchise quick menu) stacks in the order they
  // actually opened, and neither treats a click on the other as a click on
  // the page behind everything. See sheetStack.ts.
  const zIndexRef = useRef(0);
  if (open && zIndexRef.current === 0) zIndexRef.current = acquireOverlayZIndex();
  if (!open) zIndexRef.current = 0;
  const drag = useRef<{
    startY: number;
    lastY: number;
    lastT: number;
    velocity: number;
  } | null>(null);
  // Read through a ref by the touch listeners so toggling it never forces them
  // to re-register in the middle of a gesture.
  const dismissableRef = useRef(dismissable);
  dismissableRef.current = dismissable;
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
    // Android back closes this sheet instead of navigating. When the sheet is
    // locked (dismissable=false) back is still swallowed here — so it never
    // falls through to a page navigation — but it does nothing, keeping "only
    // the buttons close this" true on hardware back too.
    const unregister = registerSheet(() => {
      if (dismissableRef.current) onCloseRef.current();
    });
    return () => {
      window.removeEventListener("keydown", onKey);
      unregister();
      cancelAnimationFrame(raf.current);
    };
  }, [open, dismissable]);

  useEffect(() => {
    if (!open) return;
    const el = overlayRef.current;
    if (!el) return;
    return registerOverlayElement(el);
  }, [open]);

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

    // Classify ONCE, here, and never revisit it. A gesture that begins with
    // content still scrolled, or on something that owns its own drag, is a
    // scroll for its entire life no matter where the finger ends up. Deciding
    // this per-move is what let a drag turn into a dismiss halfway through.
    const onStart = (e: TouchEvent) => {
      const target = e.target as HTMLElement | null;
      if (
        !dismissableRef.current ||
        closing.current ||
        e.touches.length !== 1 ||
        body.scrollTop > 0 ||
        // Anything that runs its own drag (the My Order grip) opts out, so the
        // sheet never competes with it for the same finger.
        target?.closest("[data-sheet-nodrag]")
      ) {
        done = true;
        return;
      }
      startY = e.touches[0].clientY;
      engaged = false;
      done = false;
    };
    const onMove = (e: TouchEvent) => {
      if (done || closing.current) return;
      // Locked mid-gesture (a row drag started): abandon quietly rather than
      // keep tracking toward a dismiss.
      if (!dismissableRef.current) {
        done = true;
        return;
      }
      const y = e.touches[0].clientY;
      const dy = y - startY;
      if (!engaged) {
        // Upward means the user is scrolling; that settles it for good.
        if (dy < 0) {
          done = true;
          return;
        }
        // Below the threshold the sheet holds completely still. This is the
        // resistance: nothing moves until the pull is unmistakably a dismiss.
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
    // Deliberately NOT keyed on `dismissable`. Re-registering these listeners
    // mid-gesture wipes startY/engaged/done, and the next touchmove then reads
    // a delta of hundreds of pixels from a zeroed origin and dismisses the
    // sheet instantly. That is exactly what locking the sheet during a My Order
    // row drag used to trigger. `dismissable` is read through a ref instead, so
    // the listeners survive the whole gesture.
  }, [open]);

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
    <div
      ref={overlayRef}
      className={`k-sheet-overlay crossfade${dock ? " k-sheet-overlay--dock" : ""}${asPanel ? " k-sheet-overlay--panel" : ""}`}
      role="presentation"
      style={{ zIndex: zIndexRef.current }}
    >
      {/* A modeless panel has no backdrop at all — not a transparent one. An
          invisible full-screen layer would still eat every click meant for the
          list it is supposed to leave usable. */}
      {!asPanel && (
        <div
          ref={backdropRef}
          className="k-sheet-backdrop"
          onClick={() => dismissable && !closing.current && onCloseRef.current()}
        />
      )}
      <div
        className={`k-sheet${dismissable ? "" : " k-sheet--modal"}${dock ? " k-sheet--dock" : ""}${asPanel ? " k-sheet--panel" : ""}`}
        role="dialog"
        aria-modal={asPanel || modeless ? "false" : "true"}
        aria-label={ariaLabel ?? title}
        tabIndex={-1}
        ref={sheetRef}
      >
        {/* No grab handle on a locked sheet: it can't be dragged, so it
            shouldn't advertise that it can. */}
        {dismissable && (
          <div
            className="k-sheet__handle-area"
            onPointerDown={onPointerDown}
            onPointerMove={onPointerMove}
            onPointerUp={onPointerUp}
            onPointerCancel={onPointerUp}
          >
            <div className="k-sheet__handle" />
          </div>
        )}
        {/* Every closable sheet carries an explicit exit, not just the handle.
            The handle is a gesture you have to already know about, and it is
            the one gesture that competes with everything else on a phone: a
            sheet full of a scrolling list, a draggable order row, or a
            horizontal rail all want the same finger. The X never competes with
            any of them, so on a small window it — with Escape and hardware
            back — is the reliable way out, and the drag stays as the shortcut
            for people who reach for it. Desktop popovers don't get one (see
            AnchoredPopover): there, clicking off the panel or clicking the
            card again is the way out, with nothing covering the page. */}
        {dismissable && (
          <button
            type="button"
            className="k-sheet__close"
            onClick={() => onCloseRef.current()}
            aria-label={asPanel ? "Close panel" : "Close"}
          >
            <Icon icon={X} size={17} />
          </button>
        )}
        {title && <div className="k-sheet__title">{title}</div>}
        <div className="k-sheet__body konsou-scroll" ref={bodyRef}>
          {children}
        </div>
        {/* Outside the body on purpose: a verb you have to scroll to is not
            always reachable, which is the one thing this bar is for. */}
        {footer && <div className="k-sheet__footer">{footer}</div>}
      </div>
    </div>,
    document.body,
  );
}
