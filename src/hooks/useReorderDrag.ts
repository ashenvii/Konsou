import { useCallback, useEffect, useRef, useState } from "react";
import type {
  CSSProperties,
  KeyboardEvent as ReactKeyboardEvent,
  PointerEvent as ReactPointerEvent,
  RefObject,
} from "react";

/**
 * Reorder a short list by dragging a grip, or by keyboard.
 *
 * The last attempt at this lived inside a sheet and lost, because dragging a
 * row down is the same gesture as swiping a sheet closed. Everything it grew to
 * survive that (the sheet disabling its own dismissal mid-drag, absolutely
 * positioned rows, a hard-coded row height so a Y could become an index) was a
 * workaround for the container, not for dragging. On a page none of it is
 * needed, and the real conflicts are different ones:
 *
 *  - The app pans any scroller when you drag the page (useViewportDragScroll).
 *    The grip carries `data-nodrag`, which is that hook's own opt-out, so the
 *    row body still scrolls the page and only the grip reorders.
 *  - Touch scrolling would claim the gesture first. `touch-action: none` on the
 *    grip alone, plus pointer capture, keeps the rest of the row native.
 *  - Fifteen rows are taller than a phone. Without edge autoscroll the list is
 *    only reorderable within one screenful, which is most of what "annoying"
 *    means. Dragging near either end of the scroller pulls it along.
 *  - React must not re-parent a row out from under the pointer capture. Rows
 *    keep their DOM order for the whole drag and move by transform; the capture
 *    lives on the grip, which never moves. One commit lands on release.
 *
 * Keyboard is not a lesser path: the grip is a real button, so Space or Enter
 * picks a row up, the arrows move it, Enter drops it and Escape puts it back.
 * That is what pays for deleting the old up/down buttons rather than trading a
 * working keyboard list for a mouse-only gesture.
 */

/** How close to an end of the scroller starts pulling it along. */
const EDGE = 64;
/** Autoscroll speed at the very edge, per frame. Ramps up across the zone. */
const EDGE_SPEED = 18;

interface RowRect {
  h: number;
  center: number;
}

interface Drag {
  from: number;
  to: number;
  /** Content-space offset of the dragged row from where it started. */
  dy: number;
  h: number;
}

export interface ReorderDrag {
  /** The ids in the order to render right now, gesture preview included. */
  order: number[];
  /** True while a row is held by pointer or keyboard. */
  active: boolean;
  rowProps: (index: number) => {
    className: string;
    style?: CSSProperties;
    "data-reorder-row": string;
  };
  gripProps: (index: number) => Record<string, unknown>;
  /** Polite live-region text describing the last thing that happened. */
  announcement: string;
}

function moveItem(arr: number[], from: number, to: number): number[] {
  const next = arr.slice();
  const [held] = next.splice(from, 1);
  next.splice(to, 0, held);
  return next;
}

function same(a: number[], b: number[]): boolean {
  return a.length === b.length && a.every((id, i) => b[i] === id);
}

export function useReorderDrag({
  ids,
  scrollerRef,
  listRef,
  onCommit,
  labelOf,
}: {
  ids: number[];
  /** The scrolling element the list lives in; drives edge autoscroll. */
  scrollerRef: RefObject<HTMLElement | null>;
  /** The list element holding the `[data-reorder-row]` children. */
  listRef: RefObject<HTMLElement | null>;
  /** Called once, on release, with the whole new order and the order it
   *  replaced — the caller can offer an undo back to `previous` without
   *  having to keep its own shadow copy of the pre-drag arrangement. */
  onCommit: (ids: number[], previous: number[]) => void;
  /** Name for the announcements, so a screen reader hears titles not numbers. */
  labelOf: (id: number) => string;
}): ReorderDrag {
  const [order, setOrder] = useState<number[]>(ids);
  const [drag, setDrag] = useState<Drag | null>(null);
  const [held, setHeld] = useState<number | null>(null);
  const [announcement, setAnnouncement] = useState("");

  const orderRef = useRef<number[]>(ids);
  const dragRef = useRef<Drag | null>(null);
  const rectsRef = useRef<RowRect[]>([]);
  const startRef = useRef<{ from: number; clientY: number; scrollTop: number } | null>(null);
  const pointRef = useRef(0);
  const rafRef = useRef(0);
  const heldRef = useRef<number | null>(null);
  const snapshotRef = useRef<number[] | null>(null);

  const commit = (next: number[], previous: number[]) => {
    orderRef.current = next;
    setOrder(next);
    onCommit(next, previous);
  };

  // The store is the truth whenever nothing is being held. Mid-gesture it is
  // not, or a background write would yank a row out of the hand holding it.
  useEffect(() => {
    if (startRef.current || heldRef.current != null) return;
    if (same(orderRef.current, ids)) return;
    orderRef.current = ids;
    setOrder(ids);
  }, [ids]);

  useEffect(
    () => () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
      document.body.classList.remove("is-reordering");
    },
    [],
  );

  /**
   * One frame of the drag. Everything reads from the last pointer position
   * rather than from the event, so a finger that has stopped moving still
   * autoscrolls, and a high-Hz mouse still costs one layout pass per frame.
   */
  const frame = useCallback(() => {
    rafRef.current = 0;
    const start = startRef.current;
    const scroller = scrollerRef.current;
    if (!start || !scroller) return;

    const box = scroller.getBoundingClientRect();
    const y = pointRef.current;
    const fromTop = y - box.top;
    const fromBottom = box.bottom - y;
    let push = 0;
    if (fromTop < EDGE) push = -Math.ceil(((EDGE - fromTop) / EDGE) * EDGE_SPEED);
    else if (fromBottom < EDGE) push = Math.ceil(((EDGE - fromBottom) / EDGE) * EDGE_SPEED);
    if (push !== 0) {
      const max = scroller.scrollHeight - scroller.clientHeight;
      scroller.scrollTop = Math.max(0, Math.min(max, scroller.scrollTop + push));
    }

    const rects = rectsRef.current;
    const from = start.from;
    // Viewport movement plus whatever the list scrolled underneath: together
    // they are how far the row has travelled through the content.
    const dy = y - start.clientY + (scroller.scrollTop - start.scrollTop);
    const center = rects[from].center + dy;
    let to = from;
    if (dy > 0) {
      while (to < rects.length - 1 && center > rects[to + 1].center) to += 1;
    } else {
      while (to > 0 && center < rects[to - 1].center) to -= 1;
    }

    const prev = dragRef.current;
    if (!prev || prev.to !== to || prev.dy !== dy) {
      const next = { from, to, dy, h: rects[from].h };
      dragRef.current = next;
      setDrag(next);
    }
    rafRef.current = requestAnimationFrame(frame);
  }, [scrollerRef]);

  const endDrag = (keep: boolean) => {
    if (rafRef.current) cancelAnimationFrame(rafRef.current);
    rafRef.current = 0;
    const d = dragRef.current;
    startRef.current = null;
    dragRef.current = null;
    setDrag(null);
    document.body.classList.remove("is-reordering");
    if (!keep || !d || d.to === d.from) return;
    const previous = orderRef.current;
    const next = moveItem(previous, d.from, d.to);
    commit(next, previous);
    setAnnouncement(`${labelOf(next[d.to])} moved to ${d.to + 1} of ${next.length}`);
  };

  const rowProps = (index: number) => {
    let ty = 0;
    let cls = "";
    if (drag) {
      if (index === drag.from) {
        ty = drag.dy;
        cls = "is-dragging";
      } else if (drag.from < drag.to && index > drag.from && index <= drag.to) {
        ty = -drag.h;
      } else if (drag.to < drag.from && index >= drag.to && index < drag.from) {
        ty = drag.h;
      }
    } else if (held === index) {
      cls = "is-held";
    }
    return {
      "data-reorder-row": "",
      className: cls,
      ...(ty !== 0 ? { style: { transform: `translateY(${ty}px)` } as CSSProperties } : {}),
    };
  };

  const drop = () => {
    const before = snapshotRef.current;
    const after = orderRef.current;
    const at = heldRef.current;
    snapshotRef.current = null;
    heldRef.current = null;
    setHeld(null);
    if (at == null || !before || same(before, after)) return;
    onCommit(after, before);
    setAnnouncement(`${labelOf(after[at])} dropped at ${at + 1} of ${after.length}`);
  };

  const gripProps = (index: number) => ({
    "data-nodrag": "",
    onPointerDown: (e: ReactPointerEvent) => {
      if (!e.isPrimary || (e.pointerType === "mouse" && e.button !== 0)) return;
      if (heldRef.current != null) return;
      const scroller = scrollerRef.current;
      const list = listRef.current;
      if (!scroller || !list) return;
      const rows = Array.from(
        list.querySelectorAll<HTMLElement>("[data-reorder-row]"),
      );
      if (rows.length !== orderRef.current.length) return;
      // offsetTop, not getBoundingClientRect: it is already in content space,
      // so it survives the autoscroll that is about to happen underneath.
      rectsRef.current = rows.map((el) => ({
        h: el.offsetHeight,
        center: el.offsetTop + el.offsetHeight / 2,
      }));
      // Stops the text selection and the native image drag that would otherwise
      // steal the pointer stream mid-gesture. Focus is taken back by hand so a
      // click-then-arrow still works.
      e.preventDefault();
      const grip = e.currentTarget as HTMLElement;
      // Capture keeps the move/up stream on the grip even when the pointer
      // outruns it, which it will on any real drag. It is an optimisation, not
      // the mechanism: if the browser refuses the id the drag still works off
      // the events it does deliver, so a throw here must not take the gesture
      // down with it.
      try {
        grip.setPointerCapture(e.pointerId);
      } catch {
        /* no capture available; the drag reads the events it gets */
      }
      grip.focus();
      startRef.current = { from: index, clientY: e.clientY, scrollTop: scroller.scrollTop };
      pointRef.current = e.clientY;
      document.body.classList.add("is-reordering");
      rafRef.current = requestAnimationFrame(frame);
    },
    onPointerMove: (e: ReactPointerEvent) => {
      if (!startRef.current) return;
      pointRef.current = e.clientY;
    },
    onPointerUp: () => endDrag(true),
    onPointerCancel: () => endDrag(false),
    onKeyDown: (e: ReactKeyboardEvent) => {
      const n = orderRef.current.length;
      const grip = e.currentTarget as HTMLElement;
      if (heldRef.current == null) {
        if (e.key === " " || e.key === "Enter") {
          e.preventDefault();
          snapshotRef.current = orderRef.current;
          heldRef.current = index;
          setHeld(index);
          setAnnouncement(
            `${labelOf(orderRef.current[index])} picked up, ${index + 1} of ${n}. Arrow keys move it, Enter drops it, Escape cancels.`,
          );
        }
        return;
      }
      if (
        e.key === "ArrowUp" ||
        e.key === "ArrowDown" ||
        e.key === "Home" ||
        e.key === "End"
      ) {
        e.preventDefault();
        // Home/End jump to the ends outright — reordering 15 items with
        // single-step arrows alone means moving the last one to the top
        // costs 14 keypresses. Same commit path as an arrow step; only the
        // target index differs.
        const to =
          e.key === "Home"
            ? 0
            : e.key === "End"
              ? n - 1
              : heldRef.current + (e.key === "ArrowUp" ? -1 : 1);
        if (to < 0 || to >= n || to === heldRef.current) return;
        const next = moveItem(orderRef.current, heldRef.current, to);
        orderRef.current = next;
        setOrder(next);
        heldRef.current = to;
        setHeld(to);
        setAnnouncement(`${labelOf(next[to])}, ${to + 1} of ${n}`);
        // The row it is riding has just moved; follow it rather than leaving
        // the held row off the end of a fifteen-row list.
        requestAnimationFrame(() => grip.scrollIntoView({ block: "nearest" }));
        return;
      }
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        drop();
        return;
      }
      if (e.key === "Escape") {
        e.preventDefault();
        e.stopPropagation();
        const before = snapshotRef.current;
        snapshotRef.current = null;
        heldRef.current = null;
        setHeld(null);
        if (before) {
          orderRef.current = before;
          setOrder(before);
        }
        setAnnouncement("Move cancelled");
      }
    },
    // Tabbing away mid-move keeps the arrangement rather than silently
    // discarding the work; Escape is the way to abandon it.
    onBlur: () => {
      if (heldRef.current != null) drop();
    },
  });

  return {
    order,
    active: drag != null || held != null,
    rowProps,
    gripProps,
    announcement,
  };
}
