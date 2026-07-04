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
const CLOSE_FRACTION = 0.35;
const FLICK_VELOCITY = 0.6; // px per ms, downward

/**
 * The container for all modal interactions. Bottom sheet on mobile, centered
 * dialog on desktop (CSS-switched). Dismiss via backdrop tap, Escape, or by
 * dragging the handle: the sheet tracks the finger live and the backdrop fades
 * with it, so you can peek at the content behind and drag back up to cancel.
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
  const drag = useRef<{
    startY: number;
    lastY: number;
    lastT: number;
    velocity: number;
  } | null>(null);
  const closing = useRef(false);
  const raf = useRef(0);
  const pendingDy = useRef(0);

  // Latest onClose without re-registering with the sheet stack per render.
  const onCloseRef = useRef(onClose);
  useEffect(() => {
    onCloseRef.current = onClose;
  }, [onClose]);

  useEffect(() => {
    if (!open) return;
    closing.current = false;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && dismissable) onClose();
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
  }, [open, onClose, dismissable]);

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
      window.setTimeout(onClose, 170);
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

  const onPointerDown = (e: PointerEvent<HTMLDivElement>) => {
    if (!dismissable || closing.current) return;
    e.currentTarget.setPointerCapture(e.pointerId);
    drag.current = { startY: e.clientY, lastY: e.clientY, lastT: e.timeStamp, velocity: 0 };
    const sheet = sheetRef.current;
    const backdrop = backdropRef.current;
    if (sheet) {
      sheet.style.transition = "none";
      // Promote to its own layer for the duration of the gesture so the
      // WebView composites the move instead of repainting the sheet.
      sheet.style.willChange = "transform";
    }
    if (backdrop) {
      backdrop.style.transition = "none";
      backdrop.style.willChange = "opacity";
    }
  };

  const onPointerMove = (e: PointerEvent<HTMLDivElement>) => {
    const d = drag.current;
    const sheet = sheetRef.current;
    if (!d || !sheet || closing.current) return;
    const dy = Math.max(0, e.clientY - d.startY);
    const dt = e.timeStamp - d.lastT;
    if (dt > 0) d.velocity = (e.clientY - d.lastY) / dt;
    d.lastY = e.clientY;
    d.lastT = e.timeStamp;

    // Pointermove fires faster than the display refreshes; batch the style
    // writes into one rAF per frame so the gesture stays smooth on weak GPUs.
    pendingDy.current = dy;
    if (!raf.current) {
      raf.current = requestAnimationFrame(() => {
        raf.current = 0;
        if (!drag.current || closing.current) return;
        const y = pendingDy.current;
        // Track the finger; fade the backdrop out proportionally so the
        // content behind shows through mid-drag (the "peek").
        sheet.style.transform = `translateY(${y}px)`;
        const backdrop = backdropRef.current;
        if (backdrop) {
          const height = sheet.offsetHeight || 1;
          backdrop.style.opacity = String(Math.max(0, 1 - y / height));
        }
      });
    }
  };

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
        onClick={() => dismissable && !closing.current && onClose()}
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
        <div className="k-sheet__body konsou-scroll">{children}</div>
      </div>
    </div>,
    document.body,
  );
}
