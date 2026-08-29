import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { ChevronRight } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { getCoverUrl } from "@/lib/format";
import { resolveMotionMode } from "@/lib/motion";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { PointerEvent as ReactPointerEvent } from "react";
import type { CompletionEvent } from "@/types/list";

/**
 * THE TILE, IN REAL PIXELS.
 *
 * The comp was drawn on a 1040px stage where fourteen columns gave a 73.7px
 * cell. Fourteen columns were then wired in as a constant, and the card the
 * app actually renders is 544px wide at 1280, so every tile came out 37 x 95:
 * a sliver. That is not a small drift, it breaks the premise. The whole reason
 * this card is a wall and not a list is CompletedRoom.tsx's own line, that the
 * covers "ARE the record and the thing you recognise", and a 37px slice of a
 * cover is not recognisable as anything.
 *
 * So the comp's CELL is the constant and the column count falls out of it.
 */
const TILE_W = 72;
/** Height over width. The comp's cell was 73.7 x 100. Close to cover art (1.5)
 *  without going so tall that a four-row wall needs a card nobody has. */
const TILE_RATIO = 1.36;
/** The free list has to stay deep enough that the same handful of covers do
 *  not keep coming back around, so the wall is not allowed to eat the pool. */
const MAX_TILES = 110;

/** How many finished covers the board draws from. NOT the whole archive: a turn
 *  a second against thousands of covers is a network request a second, forever. */
const POOL = 140;

const TURN_EVERY_MS = 1000;
/** The lite tier turns, it just turns less. A phone is sniffed onto that tier
 *  by default, and a board that never moves there is not this card. At 800ms a
 *  turn, a 1s cadence leaves something animating 80% of the time; 2.4s takes
 *  that to a third, which is what the tier is actually buying. */
const TURN_EVERY_LITE_MS = 2400;
/**
 * WHAT A FLAP ACTUALLY COSTS, and it is not the 500ms this had.
 *
 * Measured against the reference rather than guessed. The documented default
 * for a split-flap component is an 800ms flip on cubic-bezier(.215,.61,.355,1)
 * over a 550px perspective, with the two halves hinged on opposite edges
 * (hello-mat.com/design-engineering/component/split-flap-display). Ours was
 * 500ms over a 900px perspective shared by the whole wall, with no shading at
 * all, which is the recipe for the generic card-flip it looked like: too fast
 * to read as mass, too flat to read as a hinge, and evenly lit through a
 * rotation that should take the face away from the light and bring it back.
 *
 * Kept in sync with --turn-takes in night-market.css.
 */
const TURN_TAKES_MS = 800;

interface Tile {
  /** Pool indices for the two faces, and which one is showing. */
  a: number;
  b: number;
  flipped: boolean;
}

/** Which way the flap that is currently moving is falling. A real flap only
 *  ever falls one way, so "up" runs 180 to 360 rather than back to 0. */
type Turn = { i: number; dir: "down" | "up" } | null;

/**
 * Completed, as a wall of the covers you have finished.
 *
 * THE COVERS ARE THE RECORD, which is CompletedRoom.tsx's own phrase about the
 * two designs it threw away: a spine and a table "both made a few thousand
 * finished shows into rows of text, when the covers ARE the record and the
 * thing you recognise." The room is a year index beside a wall of covers, and a
 * card previews its room.
 *
 * THE WALL IS A SHOWCASE, NOT NAVIGATION. No tile is clickable and none is
 * focusable: fifty-six tab stops on an overview card is not a feature, and
 * clickable-but-not-focusable would be a mouse-only one. The whole card is one
 * door into the room, and the room is where covers are properly navigable and
 * virtualised.
 */
export function CompletedBoard({
  events,
  fallbackCovers,
  archived,
  hours,
  thisYear,
  rewatched,
  since,
  onOpenRoom,
}: {
  events: CompletionEvent[];
  fallbackCovers: (string | null)[];
  archived: number;
  hours: number;
  thisYear: number;
  rewatched: number;
  since: number | null;
  onOpenRoom: () => void;
}) {
  const reducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  /* Read by the wall sync below, to place the tear under the last line the
     card prints. */
  const headRef = useRef<HTMLSpanElement>(null);
  const ledgerRef = useRef<HTMLSpanElement>(null);
  /* The paint-budget tier, which is a SEPARATE axis from reduced motion:
     see lib/motion.ts. A machine that asks for stillness is not necessarily
     a slow one, and a slow one has not asked for stillness. */
  const lite = resolveMotionMode(useSettingsStore((s) => s.motionMode)) === "lite";
  const wallRef = useRef<HTMLSpanElement>(null);
  const cardRef = useRef<HTMLButtonElement>(null);
  const countRef = useRef<HTMLSpanElement>(null);

  /**
   * THE POOL, AND THE TWO WAYS IT USED TO GO THIN.
   *
   * It took the completion log if there was one AND the entry covers if there
   * was not, all or nothing. A log with nine events therefore drew a
   * forty-tile wall out of nine pictures, each one showing four or five times,
   * while the chit above it said two hundred. That state is not exotic: it is
   * what a restored backup, a fresh import, or the v12 reconstruction leaves
   * behind. On a card whose whole claim is that you own your record, the wall
   * visibly contradicted its own number.
   *
   * The log also carries one row PER WATCH, so a title finished three times
   * held three pool slots. The free list guarantees distinct indices, never
   * distinct pictures, so the same cover could sit on the wall three times
   * with nothing to prevent it.
   *
   * The log leads because it is the record and it is ordered by recency. The
   * entries top it up. Both are deduped, by id first and then by URL, because
   * two ids can share art.
   */
  const pool = useMemo(() => {
    const urls: string[] = [];
    const seenId = new Set<number>();
    const seenUrl = new Set<string>();
    const take = (raw: string | null | undefined, id?: number) => {
      if (urls.length >= POOL) return;
      if (id !== undefined) {
        if (seenId.has(id)) return;
        seenId.add(id);
      }
      const url = getCoverUrl({ medium: raw ?? undefined });
      if (!url || seenUrl.has(url)) return;
      seenUrl.add(url);
      urls.push(url);
    };
    for (const e of events) take(e.cover_url, e.anilist_id);
    for (const c of fallbackCovers) take(c);
    return urls;
  }, [events, fallbackCovers]);

  /** How many tiles the card's real box asks for. Starts at a sane guess so the
   *  first paint is a wall rather than an empty box. */
  const [tileCount, setTileCount] = useState(40);

  /**
   * THE BOARD, AND WHY IT KEEPS AN EXPLICIT FREE LIST.
   *
   * The first version picked a random pool index and retried up to twelve times
   * if it was already on the wall. That produced exactly the three faults you
   * can watch happen: the same title showing in two places, a tile turning to
   * the picture it already had, and a tile turning twice because the retry
   * budget ran out and it wrote back what was there. Randomness with a retry
   * budget is a guess. Taking from `free` and returning the outgoing index to
   * it makes a duplicate and a no-op turn impossible rather than unlikely.
   */
  const [board, setBoard] = useState<{ tiles: Tile[]; free: number[] }>(() => ({
    tiles: [],
    free: [],
  }));
  /**
   * The moving flap is held OUT of `board`, because it changes twice per turn
   * and the wall does not. Merged into that state it re-rendered all ninety
   * tiles to start one animation and all ninety again to end it.
   */
  const [turn, setTurn] = useState<Turn>(null);

  useEffect(() => {
    const n = pool.length;
    setBoard({
      tiles: Array.from({ length: tileCount }, (_, i) => ({
        a: n > 0 ? i % n : -1,
        b: -1,
        flipped: false,
      })),
      free: Array.from({ length: n }, (_, i) => i).slice(tileCount),
    });
    setTurn(null);
  }, [pool.length, tileCount]);

  useEffect(() => {
    /* REDUCED MOTION STOPS THE WALL, and it is the only thing that does. The
       lite tier used to stop it too, which meant no phone ever saw the board
       turn; it slows the cadence instead now, and the CSS keeps the flap.
       Whatever stops the animation must also stop this interval, or a tile
       changes picture instantly with no motion to explain it, and a snap is
       worse than either a turn or stillness. */
    if (reducedMotion || pool.length <= tileCount + 4) return;
    let clearTimer = 0;
    let last = -1;
    const tick = () => {
      /* PAUSED UNDER THE HAND, and checked here rather than wired to events,
         which is the contract DESIGN.md states for anything that advances on
         its own. Without it the tile you are holding the pointer over to see,
         inside a hole barely wider than one cover, is the tile that can turn
         away from you. :focus-within covers the keyboard for the same reason. */
      const el = cardRef.current;
      if (el && el.matches(":hover, :focus-within")) return;

      let i = Math.floor(Math.random() * tileCount);
      if (i === last) i = (i + 7) % tileCount;
      last = i;
      let dir: "down" | "up" = "down";
      setBoard((prev) => {
        if (prev.free.length === 0 || prev.tiles.length === 0) return prev;
        const slot = Math.floor(Math.random() * prev.free.length);
        const next = prev.free[slot];
        const tile = prev.tiles[i];
        const outgoing = tile.flipped ? tile.b : tile.a;
        dir = tile.flipped ? "up" : "down";

        const tiles = prev.tiles.slice();
        /* Written to the face that is NOT showing, then turned to. Nothing is
           swapped mid-animation, so there is no midpoint to snap at. */
        tiles[i] = tile.flipped
          ? { a: next, b: tile.b, flipped: false }
          : { a: tile.a, b: next, flipped: true };

        const free = prev.free.slice();
        free[slot] = outgoing;
        return { tiles, free };
      });
      setTurn({ i, dir });
      /* The keyframes are filled both ways and land on exactly the resting
         transform, so dropping the class here is invisible. It only has to
         happen before the same tile is picked again. */
      clearTimer = window.setTimeout(() => setTurn(null), TURN_TAKES_MS);
    };
    /* An interval, not a chain of timeouts. A self-rescheduling timeout is one
       missed cleanup from forking, and a forked chain does not look broken, it
       just runs at some other rate: measured once at a ragged 1s/2s alternation
       averaging 1.4s against a 1s setting. */
    const id = window.setInterval(tick, lite ? TURN_EVERY_LITE_MS : TURN_EVERY_MS);
    return () => {
      window.clearInterval(id);
      window.clearTimeout(clearTimer);
    };
  }, [reducedMotion, lite, pool.length, tileCount]);

  /**
   * PARALLAX IN PIXELS, NOT A GUESSED MULTIPLIER.
   *
   * The first version derived the drift in CSS from --gx with a hardcoded
   * factor, which is only right at one card size: on a 365px-tall card the
   * vertical factor produced a 25px swing where 7 was intended, so the
   * linework, which deliberately does not drift, ended up wildly out of
   * register with the tiles instead of marginally. Normalising against the
   * card's real box costs one handler and is exact at every width.
   */
  const onMove = useCallback((e: ReactPointerEvent<HTMLElement>) => {
    const el = cardRef.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    el.style.setProperty("--nm-px", (-((e.clientX - r.left) / r.width - 0.5) * 2).toFixed(3));
    el.style.setProperty("--nm-py", (-((e.clientY - r.top) / r.height - 0.5) * 2).toFixed(3));
  }, []);
  const onLeave = useCallback(() => {
    cardRef.current?.style.setProperty("--nm-px", "0");
    cardRef.current?.style.setProperty("--nm-py", "0");
  }, []);

  /**
   * THE ONE PLACE THE CARD'S REAL BOX IS READ.
   *
   * Three things all need it and none of them can be expressed in CSS alone:
   * the column count (a fr unit has no size until runtime), the linework's
   * period (a repeating gradient needs the tile pitch in real pixels, and
   * deriving it from `100% / 14` drifts by the gap), and the count's size.
   */
  useEffect(() => {
    const wall = wallRef.current;
    const card = cardRef.current;
    if (!wall || !card) return;
    const sync = () => {
      const box = wall.getBoundingClientRect();
      if (box.width < 1) return;
      const gap = parseFloat(getComputedStyle(wall).columnGap) || 0;
      const pad = gap; /* the wall's own padding is one gap on each side */

      const inner = box.width - pad * 2;
      const cols = Math.max(3, Math.round((inner + gap) / (TILE_W + gap)));
      const colW = (inner - gap * (cols - 1)) / cols;
      const rowH = Math.round(colW * TILE_RATIO);
      /* Ceil, so the last row is cut by the card's edge. That crop is what
         says the wall carries on past it. */
      const rows = Math.max(2, Math.ceil((box.height - pad * 2 + gap) / (rowH + gap)));

      card.style.setProperty("--nm-cols", String(cols));
      card.style.setProperty("--nm-row-h", `${rowH}px`);
      card.style.setProperty("--nm-cell-w", `${colW + gap}px`);
      card.style.setProperty("--nm-cell-h", `${rowH + gap}px`);
      setTileCount(Math.min(MAX_TILES, cols * rows));

      /* WHERE THE PAPER ENDS, below 1130 where it is a band across the top
         rather than a panel down the side. The tear has to fall under the
         last printed line, and the only thing that knows where that is is the
         ledger's own box: the head grows with the count's fitted size and the
         ledger wraps or does not depending on how many digits it is carrying.
         Above 1130 nothing reads this, and publishing it costs one write. */
      const printed = ledgerRef.current ?? headRef.current;
      if (printed) {
        const cardTop = card.getBoundingClientRect().top;
        const end = printed.getBoundingClientRect().bottom - cardTop;
        card.style.setProperty("--nm-paper-h", `${Math.round(end + 14)}px`);
      }
    };
    sync();
    const ro = new ResizeObserver(sync);
    ro.observe(wall);
    return () => ro.disconnect();
  }, []);

  /**
   * THE COUNT FITS, MEASURED, RATHER THAN FITTING BY LUCK.
   *
   * 98px is the tuned size and it stays the ceiling. It was also within 0px of
   * overflowing its column at four digits, so a fifth would have run straight
   * out of the chit. Shrinking only when it has to keeps the tuned value
   * everywhere it actually fits.
   */
  useEffect(() => {
    const n = countRef.current;
    const card = cardRef.current;
    if (!n || !card) return;
    /**
     * GUARDED ON THE WIDTH, or this observer feeds itself. Shrinking the count
     * changes the head's height, the head's height is what sizes the card below
     * the phone breakpoint, and a resized card wakes this observer again. It
     * would then clear the size it just set, measure an overflow, set it back,
     * and oscillate every frame. The head's width does not depend on the font
     * size, so it is the one thing here that is safe to key off.
     */
    let lastAvail = -1;
    const fit = () => {
      const head = n.parentElement;
      if (!head) return;
      /* clientWidth INCLUDES padding, and the head carries 16 left and 12
         right, so taking it raw claimed 28px the count does not have and the
         fitted size still overflowed. */
      const hs = getComputedStyle(head);
      const avail = Math.round(
        head.clientWidth - parseFloat(hs.paddingLeft) - parseFloat(hs.paddingRight),
      );
      if (avail === lastAvail) return;
      lastAvail = avail;
      /* The ceiling is the tuned value and it lives in the stylesheet, so it is
         read back rather than restated here. */
      card.style.removeProperty("--count-px");
      const max = parseFloat(getComputedStyle(card).getPropertyValue("--count-size"));
      const want = n.scrollWidth;
      if (!Number.isFinite(max) || avail <= 0 || want <= avail) return;
      card.style.setProperty("--count-px", `${Math.floor(max * (avail / want))}px`);
    };
    fit();
    /* The HEAD, not the card. The card is stretched to its neighbour's height
       by the row it sits in, so changing the chit's width resizes the head
       without resizing the card at all, and an observer on the card sleeps
       through exactly the change it exists to answer. */
    const ro = new ResizeObserver(fit);
    const head = n.parentElement;
    if (head) ro.observe(head);
    return () => ro.disconnect();
  }, [archived]);

  const sinceLabel = since ? new Date(since).getFullYear() : null;
  const days = Math.round(hours / 24);
  const face = (i: number) =>
    pool[i] ? { backgroundImage: `url("${pool[i]}")` } : undefined;

  /**
   * THE COUNT IS A SERIAL, so it carries no group separator.
   *
   * `toLocaleString` on this machine groups with a space, and at 98px in a
   * monospace a space is a full character cell: "2 563" rendered as a 2 and a
   * 563 with 62px of nothing between them, which is what read as broken
   * spacing. Grouping is right everywhere it is a quantity you compare. It is
   * wrong on a stamped serial, and this figure is a serial: it is the chit's
   * number. The accessible name below still says it the grouped way, because
   * that is a quantity being read aloud.
   */
  const serial = String(archived);

  return (
    /* THE WHOLE CARD IS THE DOOR. It carries exactly one action, so there is no
       second control for a full-face button to crowd out, which is the trap the
       Planned card records. NO overflow:hidden here: §5a's line invert paints
       at inset:-2px, outside this box, and a clip on the host erases it. That
       is the documented reason Tonight refuses a clip as well, and it is why
       the outer edge kept breaking on reworked cards. The clip belongs to the
       art layer and only to it. */
    <button
      type="button"
      ref={cardRef}
      className="nm-card nm-card--completed nm-board"
      data-fx
      onClick={onOpenRoom}
      onPointerMove={onMove}
      onPointerLeave={onLeave}
      /* THE WHOLE RECORD, because aria-label REPLACES the contents it is put
         on. The card holds seven figures and the old label announced one of
         them; hours, days, kept-since, this year and rewatched were all
         inside the button and unreachable. Grouped here, unlike the
         serial on the face, because this one is being read aloud as a
         quantity. */
      aria-label={[
        `Completed, ${archived.toLocaleString()} titles.`,
        `${hours.toLocaleString()} hours, ${days.toLocaleString()} days.`,
        `${thisYear.toLocaleString()} this year, ${rewatched.toLocaleString()} rewatched.`,
        sinceLabel ? `Kept since ${sinceLabel}.` : "",
        "Open the room.",
      ]
        .filter(Boolean)
        .join(" ")}
    >
      <span className="nm-board__clip" aria-hidden>
        <span className="nm-board__wall" ref={wallRef}>
          {board.tiles.map((t, i) => (
            <i
              key={i}
              className={
                (t.flipped ? "is-back" : "") +
                (turn?.i === i ? ` is-turning is-${turn.dir}` : "")
              }
            >
              <b style={face(t.a)} />
              <b style={face(t.b)} />
            </i>
          ))}
        </span>
        <span className="nm-board__veil" />
        <span className="nm-board__lines" />
        <span className="nm-board__slats" />
        <span className="nm-board__stub" />
      </span>

      <span className="nm-board__head" ref={headRef}>
        <span className="nm-board__issuer">Konsou &middot; Completed</span>
        <span className="nm-board__rule" />
        <span className="nm-board__n" ref={countRef}>
          {serial}
        </span>
        <span className="nm-board__rule" />
        {/* THE OVERPRINT. A count says how many; it does not say that anything
            finished. "Closed" is the one word an archive can carry that a plan
            never can, and it is set in signage because a stamp says filed
            rather than happening. It crosses the lower rule, which is what a
            stamp does to a chit, and it is deliberately NOT laid over the
            digits: in the comp it sat on them and the two read as a collision
            rather than as ink over paper. */}
        <span className="nm-board__closed" aria-hidden>
          Closed
        </span>
        <span className="nm-board__sub">
          {hours.toLocaleString()} hrs &middot; {days.toLocaleString()} days
        </span>
        {sinceLabel && <span className="nm-board__since">Kept since {sinceLabel}</span>}
      </span>

      {/* The app's own door chip, the same shape the Watching drawer carries,
          so the two anchors open their rooms with one gesture rather than two. */}
      <span className="nm-board__go">
        <span className="nm-board__goword">Open</span>
        <Icon icon={ChevronRight} size={15} />
      </span>

      <span className="nm-board__ledger" ref={ledgerRef}>
        <span>
          <em>This year</em>
          <b>{thisYear.toLocaleString()}</b>
        </span>
        <span>
          <em>Rewatched</em>
          {rewatched.toLocaleString()}
        </span>
      </span>
    </button>
  );
}
