import { useCallback, useEffect, useLayoutEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { registerSheet } from "@/lib/sheetStack";
import type { ReactNode } from "react";

/**
 * A popover pinned to the thing you clicked.
 *
 * Modelled on Destiny Item Manager's item popup, which is the interaction the
 * owner asked for by name. DIM's rule: phone portrait gets a drag-to-dismiss
 * sheet, everything else gets a Floating-UI popper anchored to the item with
 * `placement: 'right'`, an 8px offset, `flip` and `shift` inside a boundary,
 * and an arrow pointing back at what you clicked. This is that, without the
 * dependency — the maths is a preferred side, a flip when the side is too
 * tight, a clamp into the viewport, and an arrow offset.
 *
 * Why anchored rather than a panel at the edge: the popup should belong to the
 * item, and the shortest path between "what I clicked" and "what opened" is no
 * distance at all. Everything else on the page stays where it was and stays
 * usable, so working down a list is one click per item.
 */

/** Gap between the anchor and the popover — also the arrow's size. */
const OFFSET = 10;
/** Keep this far away from the viewport edges (and from the top chrome). */
const EDGE = 12;
const TOP_EDGE = 64;

export interface PopoverSize {
  width: number;
  /** Hard cap; the body scrolls inside it. */
  maxHeight: number;
}

interface Placement {
  left: number;
  top: number;
  /** Which side of the anchor it landed on, for the arrow. */
  side: "right" | "left";
  /** Arrow offset down the popover's edge, in px. */
  arrowTop: number;
  maxHeight: number;
}

function place(anchor: DOMRect, size: PopoverSize): Placement {
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  const width = Math.min(size.width, vw - EDGE * 2);

  // Preferred side is right, exactly like DIM. Flip left when the right side
  // cannot hold the popover.
  const roomRight = vw - anchor.right - OFFSET - EDGE;
  const side: "right" | "left" = roomRight >= width ? "right" : "left";
  const left =
    side === "right"
      ? anchor.right + OFFSET
      : Math.max(EDGE, anchor.left - OFFSET - width);

  // Vertically centred on the anchor, then shifted back inside the viewport —
  // `shift` in Floating UI terms.
  const maxHeight = Math.min(size.maxHeight, vh - TOP_EDGE - EDGE);
  const wanted = anchor.top + anchor.height / 2 - maxHeight / 2;
  const top = Math.max(TOP_EDGE, Math.min(wanted, vh - EDGE - maxHeight));

  // The arrow stays on the anchor's centre even after the shift, so it keeps
  // pointing at the thing you clicked rather than at the popover's middle.
  const anchorCentre = anchor.top + anchor.height / 2;
  const arrowTop = Math.max(14, Math.min(anchorCentre - top, maxHeight - 14));

  return { left, top, side, arrowTop, maxHeight };
}

export function AnchoredPopover({
  anchor,
  open,
  onClose,
  size,
  ariaLabel,
  children,
}: {
  /** The element the popover belongs to. */
  anchor: HTMLElement | null;
  open: boolean;
  onClose: () => void;
  size: PopoverSize;
  ariaLabel?: string;
  children: ReactNode;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [placement, setPlacement] = useState<Placement | null>(null);

  const reposition = useCallback(() => {
    // No anchor (opened from a keyboard shortcut, a row with no element to
    // point at): behave like a plain centred dialog rather than not appearing.
    const rect =
      anchor?.getBoundingClientRect() ??
      new DOMRect(window.innerWidth / 2, window.innerHeight / 2, 0, 0);
    setPlacement(place(rect, size));
  }, [anchor, size]);

  // Measure before paint so the popover never shows in the wrong spot first.
  useLayoutEffect(() => {
    if (!open) return;
    reposition();
  }, [open, reposition]);

  // Follow the anchor: a scroll or a resize moves what this belongs to.
  useEffect(() => {
    if (!open) return;
    const onMove = () => reposition();
    window.addEventListener("resize", onMove);
    window.addEventListener("scroll", onMove, true);
    return () => {
      window.removeEventListener("resize", onMove);
      window.removeEventListener("scroll", onMove, true);
    };
  }, [open, reposition]);

  // Escape, hardware back, and a click anywhere outside all close it. Nothing
  // is trapped: the page behind stays live, which is the point.
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    const onDown = (e: PointerEvent) => {
      const el = ref.current;
      const target = e.target as Node | null;
      if (!el || !target) return;
      if (el.contains(target)) return;
      // A click on the anchor itself is the caller's business (it may be a
      // toggle, or the next card in the list).
      if (anchor?.contains(target)) return;
      onClose();
    };
    window.addEventListener("keydown", onKey);
    // Capture: a card's own handler must not swallow the dismiss.
    window.addEventListener("pointerdown", onDown, true);
    const unregister = registerSheet(() => onClose());
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("pointerdown", onDown, true);
      unregister();
    };
  }, [open, onClose, anchor]);

  if (!open || !placement) return null;

  return createPortal(
    <div
      ref={ref}
      className={`k-pop k-pop--${placement.side}`}
      role="dialog"
      aria-modal="false"
      aria-label={ariaLabel}
      style={{
        left: placement.left,
        top: placement.top,
        width: Math.min(size.width, window.innerWidth - EDGE * 2),
        maxHeight: placement.maxHeight,
      }}
    >
      <span className="k-pop__arrow" style={{ top: placement.arrowTop }} aria-hidden />
      <div className="k-pop__body konsou-scroll">{children}</div>
    </div>,
    document.body,
  );
}
