import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import {
  arrow,
  computePosition,
  flip,
  offset as offsetMiddleware,
  shift,
  size as sizeMiddleware,
} from "@floating-ui/dom";
import type { Middleware, Placement, ReferenceElement } from "@floating-ui/dom";
import {
  acquireOverlayZIndex,
  isInsideAnotherOverlay,
  registerOverlayElement,
  registerSheet,
} from "@/lib/sheetStack";
import type { ReactNode } from "react";

/**
 * A popover pinned to the thing you clicked.
 *
 * Modelled on Destiny Item Manager's item popup, checked against the real
 * source at `reference/dim/` rather than from memory: `usePopper.ts`,
 * `ItemPopup.tsx`, `sidecar-position-middleware.ts`.
 *
 * Two things about DIM's popup were not obvious until that source was read, and
 * both are load-bearing:
 *
 * 1. **DIM never calls `autoUpdate`.** `reposition()` runs exactly once per
 *    open. There is no scroll listener, no ResizeObserver, nothing. Their popup
 *    is `position: absolute` in a document that scrolls, so once it is placed it
 *    simply travels with the page and genuinely leaves the screen alongside its
 *    card. The "sticks to the exact spot of the card" feeling is not something
 *    they compute — it is what happens when you stop computing.
 *
 *    We cannot copy the line, because DIM scrolls the document and Konsou
 *    scrolls inner containers, so `absolute` against the body would not travel
 *    with our lists. So this does the equivalent by hand: solve the placement
 *    ONCE, then on every scroll apply nothing but the anchor's own delta. No
 *    re-solve, no re-clamp. The panel keeps the exact relationship to the card
 *    it was given, including off the edge of the screen.
 *
 *    What this replaces is `autoUpdate`, which re-solved on every scroll tick
 *    and re-clamped the result with `shift`. The panel therefore *tracked* the
 *    card but never *left* with it: as the card scrolled away the panel slid
 *    along the viewport edge and stayed on screen. That sliding was the whole
 *    of the detached feeling.
 *
 * 2. **The verb rail lives INSIDE the floating element.** DIM's sidecar is a
 *    child of the popup, laid out as a flex row beside the body, with a
 *    middleware writing its vertical offset. Because it is inside, floating
 *    UI's collision math already accounts for its width and it can never be
 *    pushed off-screen on its own. See `sidecarOffset` below.
 *
 * Why anchored rather than a panel at the edge: the popup should belong to the
 * item, and the shortest path between "what I clicked" and "what opened" is no
 * distance at all. Everything else on the page stays where it was and stays
 * usable, so working down a list is one click per item.
 */

/** Gap between the anchor and the popover — also the arrow's size. */
const OFFSET = 10;
/** Keep this far away from the viewport edges. */
const EDGE = 12;
/** Keep clear of the page's top chrome — but a toolbar control IS that
 *  chrome, so the derivable padding below never lets this sit below the
 *  anchor's own top (the bug: clamping to a flat 64 pushed a filter panel
 *  below the button it belonged to, arrow pointing at nothing). */
const TOP_EDGE = 64;
/** How far down the popover's edge the arrow may sit, at minimum/maximum. */
const ARROW_PADDING = 14;
/** The arrow's drawn size, so the rail can be centred on it. */
const ARROW_SIZE = 10;
/** The verb rail's width, which the floating element has to account for
 *  because the rail is one of its children. Matches `.k-pop__rail` in ui.css;
 *  if one moves the other has to. */
const RAIL_W = 52;

export interface PopoverSize {
  width: number;
  /** Soft cap; `size` middleware tightens it further when the viewport is
   *  short, and the body scrolls inside whatever height lands. */
  maxHeight: number;
}

/** A reference with no real anchor (opened via keyboard shortcut, a row with
 *  no element to point at) — a virtual element centred in the viewport, so
 *  the popover behaves like a plain centred dialog instead of not appearing.
 *  Floating UI's reference type only requires `getBoundingClientRect`. */
function virtualCentre(): ReferenceElement {
  return {
    getBoundingClientRect: () => {
      const x = window.innerWidth / 2;
      const y = window.innerHeight / 2;
      return {
        x,
        y,
        width: 0,
        height: 0,
        top: y,
        left: x,
        right: x,
        bottom: y,
      };
    },
  };
}

/**
 * How far down the panel the verb rail sits: centred on the arrow, and never
 * hanging off either end. Ported from DIM's `computeSidecarPosition`, with one
 * deliberate difference.
 *
 * DIM's version WRITES the offset straight onto the sidecar element
 * (`sidecarMenu.style.marginTop = ...`). That is right for them, because their
 * whole popup is positioned imperatively — `usePopper` assigns `left`/`top` to
 * the element by hand. It is wrong here for the same reason zeroing the
 * element before measuring was wrong (see the note in `solve`): this component
 * is React-controlled, and an imperative write to a node React owns is a value
 * living outside the render, waiting to be clobbered or ignored.
 *
 * So this returns the number instead and React applies it. Same arithmetic,
 * one owner. It also sidesteps DIM's own Safari footnote — their comment
 * records that `translateY` broke menus in the sidecar, which is why they
 * reached for `marginTop` in the first place — because the property never
 * changes hands here at all.
 *
 * Depends on `arrow` having run first, so it must come after it in the list.
 */
function sidecarOffset(selector: string): Middleware {
  return {
    name: "konsouSidecar",
    fn({ elements, rects, middlewareData }) {
      const rail = elements.floating.querySelector<HTMLElement>(selector);
      const arrowY = middlewareData.arrow?.y;
      if (!rail || arrowY === undefined) return {};
      // A read, not a write. Measuring the DOM inside a middleware is what
      // middleware is for; mutating it is what this one stopped doing.
      const railHeight = rail.offsetHeight;
      const centre = arrowY + ARROW_SIZE / 2;
      const top = Math.min(
        Math.max(centre - railHeight / 2, 0),
        Math.max(0, rects.floating.height - railHeight),
      );
      return { data: { top: Math.round(top) } };
    },
  };
}

/** What one solve produced, kept so later scroll ticks can translate rather
 *  than re-solve. */
interface Solved {
  placement: Placement;
  maxWidth: number;
  maxHeight: number;
  /** Where the solve put the panel, and where the anchor was at the time. The
   *  difference between the anchor's rect now and then is the whole of what a
   *  scroll tick has to apply. */
  x: number;
  y: number;
  refX: number;
  refY: number;
  /** The arrow's offset along whichever edge it sits on. Only one of the two
   *  is ever set: `arrow` returns `y` for the side placements and `x` for the
   *  vertical ones, and CSS pins the static side off `data-placement`. */
  arrowTop?: number;
  arrowLeft?: number;
  /** How far down the panel the verb rail sits. */
  railTop: number;
}

export function AnchoredPopover({
  anchor,
  open,
  onClose,
  size,
  ariaLabel,
  opener = null,
  sidecar,
  children,
}: {
  /** The element the popover belongs to. */
  anchor: HTMLElement | null;
  open: boolean;
  onClose: () => void;
  size: PopoverSize;
  ariaLabel?: string;
  /** The whole card that opened this, when that is a bigger thing than the
   *  anchor. See the dismiss handler for why the two have to be separate. */
  opener?: HTMLElement | null;
  /** The verb rail: a column of marks beside the panel, on the side facing the
   *  card. Omitted entirely when a surface has no verbs to offer. */
  sidecar?: ReactNode;
  children: ReactNode;
}) {
  const floatingRef = useRef<HTMLDivElement>(null);
  const arrowRef = useRef<HTMLSpanElement>(null);
  // Assigned once per open, not per render: two popovers opened one after the
  // other must keep the order they opened in even while both re-render for
  // unrelated reasons (a status change, a resize).
  const zIndexRef = useRef(0);
  if (open && zIndexRef.current === 0) zIndexRef.current = acquireOverlayZIndex();
  if (!open) zIndexRef.current = 0;

  const solvedRef = useRef<Solved | null>(null);
  const [style, setStyle] = useState<{
    left: number;
    top: number;
    maxWidth: number;
    maxHeight: number;
    placement: Placement;
    arrowTop?: number;
    arrowLeft?: number;
    railTop: number;
  } | null>(null);

  const hasSidecar = sidecar != null;
  // Read as PRIMITIVES, and the placement effect depends on these rather than
  // on `size`. That is not a micro-optimisation, it is the fix for the panel
  // moving and resizing under you when you changed a status inside it.
  //
  // `size` arrives as an object literal — ItemSurface declares it as a default
  // parameter, `size = { width: 460, maxHeight: 720 }`, so it is a NEW object
  // on every single render. With it in the dependency list, the layout effect
  // tore down and re-ran on every re-render of the surface, which includes
  // every store change the panel is subscribed to. Re-running the effect clears
  // `solvedRef` and forces a full re-solve, and because changing a status also
  // changes the panel's content height, `flip` and `shift` legitimately
  // returned a different answer than they had on open. So the panel jumped to a
  // new place and a new size as a direct consequence of using it.
  //
  // Solving once is the whole contract of this component (see the note at the
  // top about DIM never calling autoUpdate). An object identity in the deps
  // quietly broke that contract everywhere except the first frame.
  const sizeW = size.width;
  const sizeH = size.maxHeight;

  // Layout effect, not effect: positioning has to be computed before the
  // browser paints, or the panel is painted once at its unpositioned origin
  // and again where it belongs — the visible "pop in" of a panel arriving in
  // the wrong place and jumping. This is what DIM's own usePopper does, for
  // the same reason. (Their TODO notes `computePosition` is still async, so a
  // microtask remains; this reduces the jump, it does not remove it.)
  useLayoutEffect(() => {
    if (!open) return;
    const floating = floatingRef.current;
    if (!floating) return;
    const reference: ReferenceElement = anchor ?? virtualCentre();

    let cancelled = false;
    solvedRef.current = null;

    /** The full placement decision. Runs on open and on a window resize, and
     *  at no other time — see the note at the top of the file. */
    const solve = () => {
      // NOTE: DIM zeroes the element's left/top before measuring, because it
      // writes position imperatively and would otherwise measure against its
      // own stale offsets. Doing that here is actively wrong: this component
      // is React-controlled, and an imperative write races the next render.
      const refRect = reference.getBoundingClientRect();
      // One padding object for every middleware that takes one, resolved once,
      // the way DIM resolves `resolvedPadding`. Not a tidiness point: `shift`
      // was being told the top edge is 64 while `size` was told it is 12, so
      // `size` reported 696px of room, the panel took it, and then `shift`
      // pushed the panel down to clear the chrome and hung 17px of it off the
      // bottom of the screen. Two middlewares solving the same geometry
      // against two different boxes can only agree by accident.
      const padding = {
        top: Math.min(TOP_EDGE, Math.max(EDGE, refRect.y)),
        bottom: EDGE,
        left: EDGE,
        right: EDGE,
      };
      // `size`'s own API is built around mutating the floating element inside
      // `apply`, but this component is otherwise fully React-controlled, so
      // the numbers are captured here and folded into the same `setStyle` call
      // as everything else the position resolves.
      let available = { width: sizeW, height: sizeH };
      void computePosition(reference, floating, {
        // `.k-pop`'s own CSS is `position: fixed` (viewport-relative, ignoring
        // page scroll — the panel lives in a portal at document body, not
        // inside whatever scrolls). The coordinates floating-ui hands back
        // have to be computed for that same strategy.
        strategy: "fixed",
        placement: "right" as Placement,
        middleware: [
          offsetMiddleware(OFFSET),
          // Beside the anchor first, then below/above it. The vertical
          // fallbacks are not decoration: an anchor as wide as its container
          // (a ledger row spanning the whole list) has room on NEITHER side,
          // and with side placements alone flip picked the least-bad one and
          // put the panel off-screen at a negative x, squeezed to whatever
          // sliver was left. A wide anchor has to go under itself.
          flip({
            fallbackPlacements: ["left", "bottom-start", "top-start"],
            padding,
          }),
          shift({ padding }),
          sizeMiddleware({
            padding,
            apply: ({ availableHeight, availableWidth }) => {
              available = {
                width: Math.min(sizeW, availableWidth),
                height: Math.min(sizeH, availableHeight),
              };
            },
          }),
          arrowRef.current && arrow({ element: arrowRef.current, padding: ARROW_PADDING }),
          // After `arrow`, which it reads.
          hasSidecar && sidecarOffset(".k-pop__rail"),
        ].filter(Boolean) as Middleware[],
      }).then(({ x, y, placement, middlewareData }) => {
        if (cancelled) return;
        const arrowTop = middlewareData.arrow?.y;
        const arrowLeft = middlewareData.arrow?.x;
        const railTop =
          (middlewareData.konsouSidecar as { top?: number } | undefined)?.top ?? 0;
        solvedRef.current = {
          placement,
          maxWidth: available.width,
          maxHeight: available.height,
          x,
          y,
          refX: refRect.x,
          refY: refRect.y,
          arrowTop,
          arrowLeft,
          railTop,
        };
        setStyle({
          left: x,
          top: y,
          maxWidth: available.width,
          maxHeight: available.height,
          placement,
          arrowTop,
          arrowLeft,
          railTop,
        });
      });
    };

    /**
     * A scroll tick. Applies the anchor's own movement and nothing else.
     *
     * Deliberately synchronous and free of `computePosition`: there is no
     * decision to make here. The panel was placed against this card and it
     * stays placed against this card, off the screen if that is where the card
     * went. Re-solving is what made it slide along the edge instead.
     */
    const track = () => {
      const s = solvedRef.current;
      if (!s) return;
      const r = reference.getBoundingClientRect();
      const dx = r.x - s.refX;
      const dy = r.y - s.refY;
      if (dx === 0 && dy === 0) return;
      setStyle({
        left: s.x + dx,
        top: s.y + dy,
        maxWidth: s.maxWidth,
        maxHeight: s.maxHeight,
        placement: s.placement,
        arrowTop: s.arrowTop,
        arrowLeft: s.arrowLeft,
        railTop: s.railTop,
      });
    };

    /** A resized window is a different room, so the placement decision is
     *  genuinely stale and gets made again. This is the one thing that re-runs
     *  the solve while the panel is open. */
    const onResize = () => {
      solvedRef.current = null;
      solve();
    };

    solve();

    // Capture, because scroll does not bubble and Konsou scrolls inner
    // containers rather than the document — a scroll on `.k-collection` never
    // reaches window on the bubble phase.
    window.addEventListener("scroll", track, { capture: true, passive: true });
    window.addEventListener("resize", onResize);
    return () => {
      cancelled = true;
      window.removeEventListener("scroll", track, { capture: true });
      window.removeEventListener("resize", onResize);
    };
  }, [open, anchor, sizeW, sizeH, hasSidecar]);

  // Registered while open so a DIFFERENT overlay's own "click outside, close
  // me" check can tell this apart from the page behind everything — see
  // sheetStack.ts. Tapping a season's status stamp inside an open franchise
  // quick menu opens a second overlay (the status picker) on top of the
  // first; without this, a click anywhere on that second overlay looked
  // exactly like an outside click to the first one, closing the quick menu
  // as a side effect of trying to use the thing it opened.
  useEffect(() => {
    if (!open) return;
    const el = floatingRef.current;
    if (!el) return;
    return registerOverlayElement(el);
  }, [open]);

  // Escape, hardware back, and a click anywhere outside all close it. Nothing
  // is trapped: the page behind stays live, which is the point.
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    const onDown = (e: PointerEvent) => {
      const el = floatingRef.current;
      const target = e.target as Node | null;
      if (!el || !target) return;
      if (el.contains(target)) return;
      // A press on the thing that opened this is the caller's business — it may
      // mean "close me", or it may mean "switch to the next card", and only the
      // caller knows which. So this hands it back rather than guessing.
      //
      // BOTH the anchor and the opener, and that is the fix for a real bug.
      // The anchor is the poster; the opener is the whole row. Checking only
      // the anchor meant pressing the same row anywhere except its small cover
      // read as an outside click: this closed the panel, and then the row's own
      // click handler ran its toggle against the freshly-cleared state and
      // opened it right back. The panel could not be dismissed by clicking the
      // card it belonged to unless you happened to hit the artwork.
      if (anchor?.contains(target)) return;
      if (opener?.contains(target)) return;
      // A click on a DIFFERENT overlay (the status picker this popover just
      // opened, say) is not a click on the page behind everything.
      if (isInsideAnotherOverlay(target, el)) return;
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
  }, [open, onClose, anchor, opener]);

  if (!open) return null;

  const placement = style?.placement ?? "right";

  return createPortal(
    <div
      ref={floatingRef}
      className="k-pop"
      // The resolved placement, exposed to CSS the way DIM exposes
      // `data-popper-placement`. Arrow orientation and the rail's side are then
      // pure CSS for every placement, which is what let the two vertical
      // fallbacks finally draw an arrow at all — they used to collapse into a
      // `side: "vertical"` React state whose only behaviour was to hide it.
      data-placement={placement}
      role="dialog"
      aria-modal="false"
      aria-label={ariaLabel}
      style={{
        left: style?.left ?? 0,
        top: style?.top ?? 0,
        // The rail is a child, so the floating element is wider than the panel
        // the caller asked for. Saying so here is what lets floating-ui's own
        // collision math keep the rail on screen rather than discovering it
        // after the fact.
        width: size.width + (hasSidecar ? RAIL_W : 0),
        maxWidth: (style?.maxWidth ?? size.width) + (hasSidecar ? RAIL_W : 0),
        maxHeight: style?.maxHeight ?? size.maxHeight,
        // Overrides `.k-pop`'s static z-index: two overlays stacked one from
        // the other (a status picker opened from inside a franchise's quick
        // menu) must paint in the order they opened, not by which CSS class
        // happens to declare the bigger number.
        zIndex: zIndexRef.current,
        // Visible only once placed: the first frame has nothing to measure
        // yet, and painting at (0,0) at full width for one frame is more
        // visible than a frame of nothing.
        visibility: style ? "visible" : "hidden",
      }}
    >
      {/* The frame is the flex row. It reverses when the panel sits to the
          RIGHT of the card, so the rail always ends up on the side facing the
          card rather than on the far side of the panel from it — DIM's
          `flex-direction: row-reverse` on `[data-popper-placement^='right']`.
          That one rule is most of why their verbs feel attached to the item
          instead of parked next to a dialog. */}
      <div className="k-pop__frame">
        {/* No close mark on a desktop popover, by the same rule DIM follows and
            the platform conventions behind it: this panel covers nothing, so
            clicking anywhere off it closes it, clicking the card again toggles
            it shut, and Escape works from the keyboard. A phone sheet DOES
            cover the page and does get an explicit X (see BottomSheet). */}
        <div className="k-pop__body konsou-scroll">{children}</div>
        {hasSidecar && (
          <div className="k-pop__rail" style={{ marginTop: style?.railTop ?? 0 }}>
            {sidecar}
          </div>
        )}
      </div>
      {/* Kept mounted whatever the placement, so the arrow middleware always
          has a target to measure. */}
      <span
        ref={arrowRef}
        className="k-pop__arrow"
        style={{ top: style?.arrowTop, left: style?.arrowLeft }}
        aria-hidden
      />
    </div>,
    document.body,
  );
}
