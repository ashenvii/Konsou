import { memo, useEffect, useRef, useState } from "react";
import type { MouseEvent as ReactMouseEvent, PointerEvent as ReactPointerEvent } from "react";
import { Check, ChevronLeft, ChevronRight, Play } from "lucide-react";
import { haptic } from "@/lib/haptics";
import { AnimeCover } from "./AnimeCover";
import { Icon } from "@/components/ui/Icon";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { FranchiseGroup } from "@/lib/franchise/grouping";

/**
 * The plan card: a mounted poster with its watch-order number and the two
 * ways out of the plan on its footer. Rendered by the plan room inside the
 * virtualized grid.
 */

/** How long the card must be held before it commits. Long enough to be
 *  deliberate, short enough not to feel like the app has stalled. */
// Nothing is shown for this long after touch-down. A scroll or a tap releases
// (or moves) inside this window and draws no fill at all, which is what stops
// the "trippy" flash while flinging. Only a finger that stays put past it is
// treated as an intent to hold.
const HOLD_ENGAGE_MS = 170;
// The fill then sweeps over this, and commits when full. Total ~700ms, matched
// to the Hold-to-remove button so both gestures feel the same.
const HOLD_FILL_MS = 520;
/** Movement past this many px means the finger is scrolling, not holding. */
const HOLD_SLOP = 10;

type HoldPhase = "idle" | "holding" | "done" | "full";

/**
 * Press-and-hold a card to append it to the watch order.
 *
 * The alternative was opening My Order and searching, which is right when you
 * know what you want but wrong when you are browsing and just spotted
 * something. This is the browse-time path: no menu, no typing.
 *
 * The hold is what makes it safe next to a scrolling list. A tap still opens
 * the card, a drag still scrolls, and only a stationary press commits, so the
 * gesture cannot fire by accident while flinging through a thousand posters.
 */
function useHoldToAdd(rootId: number, onQuickAdd?: (rootId: number) => boolean) {
  const [phase, setPhase] = useState<HoldPhase>("idle");
  const engage = useRef<ReturnType<typeof setTimeout> | null>(null);
  const commit = useRef<ReturnType<typeof setTimeout> | null>(null);
  const reset = useRef<ReturnType<typeof setTimeout> | null>(null);
  const origin = useRef<{ x: number; y: number; id: number } | null>(null);
  // A completed hold must swallow the click it would otherwise deliver to the
  // open-button stretched across the poster, or committing would also navigate.
  const consumed = useRef(false);

  const clearTimers = () => {
    for (const t of [engage, commit]) {
      if (t.current) {
        clearTimeout(t.current);
        t.current = null;
      }
    }
  };

  useEffect(
    () => () => {
      clearTimers();
      if (reset.current) clearTimeout(reset.current);
    },
    [],
  );

  // Abandon a hold that never reached commit (finger lifted, or moved into a
  // scroll). Leaves a finished done/full state alone so its label can linger.
  const cancel = () => {
    clearTimers();
    origin.current = null;
    setPhase((p) => (p === "holding" ? "idle" : p));
  };

  const handlers = {
    onPointerDown: (e: ReactPointerEvent) => {
      if (!onQuickAdd || !e.isPrimary || origin.current) return;
      // A new press means any previous hold is finished with. Without this the
      // flag survives a completed hold that the platform never followed with a
      // click (long-press often suppresses it on Android), and the next real
      // tap on the card gets eaten instead.
      consumed.current = false;
      // The handlers live on the card so the whole poster is holdable, and the
      // open affordance is itself a button stretched across that poster, so it
      // must NOT be excluded. The controls layered on top of it must: holding
      // Start for half a second should start the show, not quietly file it in
      // the watch order (and then swallow the tap that was meant for Start).
      const control = (e.target as HTMLElement | null)?.closest("button, a, [role='button']");
      if (control && !control.classList.contains("k-qcard__open")) return;
      origin.current = { x: e.clientX, y: e.clientY, id: e.pointerId };
      // Show nothing yet. Only if the finger is still here and still after the
      // engage delay does the fill begin, and the commit is armed for the fill
      // duration on top of that.
      engage.current = setTimeout(() => {
        engage.current = null;
        setPhase("holding");
        commit.current = setTimeout(() => {
          commit.current = null;
          origin.current = null;
          consumed.current = true;
          const added = onQuickAdd(rootId);
          setPhase(added ? "done" : "full");
          haptic(added ? "success" : "light");
          reset.current = setTimeout(() => setPhase("idle"), added ? 900 : 1400);
        }, HOLD_FILL_MS);
      }, HOLD_ENGAGE_MS);
    },
    onPointerMove: (e: ReactPointerEvent) => {
      const o = origin.current;
      if (!o || e.pointerId !== o.id) return;
      if (Math.abs(e.clientX - o.x) > HOLD_SLOP || Math.abs(e.clientY - o.y) > HOLD_SLOP) {
        cancel();
      }
    },
    onPointerUp: (e: ReactPointerEvent) => {
      const o = origin.current;
      if (o && e.pointerId !== o.id) return;
      cancel();
    },
    onPointerCancel: cancel,
    onClickCapture: (e: ReactMouseEvent) => {
      if (!consumed.current) return;
      consumed.current = false;
      e.preventDefault();
      e.stopPropagation();
    },
  };

  return { phase, handlers, enabled: !!onQuickAdd };
}

/** One poster with its Start action. Exported so the Plan room renders the same
 *  card in its virtualized grid. */
function QueueCardImpl({
  group,
  onOpen,
  onMove,
  canMoveEarlier,
  canMoveLater,
  onNumber,
  planNumber,
  onQuickAdd,
}: {
  group: FranchiseGroup;
  onOpen: (rootId: number) => void;
  /** Only supplied for cards sitting in Up Next, where order is hand-made. */
  onMove?: (rootId: number, dir: -1 | 1) => void;
  canMoveEarlier?: boolean;
  canMoveLater?: boolean;
  /** Open the watch-order number picker for this card. */
  onNumber?: (rootId: number) => void;
  /** The number currently stamped on this card, if any. */
  planNumber?: number | null;
  /** Press-and-hold to append this card to the watch order. Returns false when
   *  the order is full, so the card can say so instead of failing silently. */
  onQuickAdd?: (rootId: number) => boolean;
}) {
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const updateStatusUndoable = useListStore((s) => s.updateStatusUndoable);

  const { displayEntry, rootId, entries } = group;
  const hold = useHoldToAdd(rootId, onQuickAdd);
  const rootEntry = entries.find((e) => e.anilist_id === rootId) ?? entries[0];
  const title = preferredTitle(
    {
      romaji: rootEntry.title_romaji,
      english: rootEntry.title_english,
      native: rootEntry.title_native,
    },
    titleLanguage,
  );
  const cover = getCoverUrl({ medium: displayEntry.cover_url ?? undefined });

  return (
    <article
      className={`k-qcard${hold.phase !== "idle" ? ` k-qcard--hold-${hold.phase}` : ""}`}
      {...(hold.enabled ? hold.handlers : {})}
    >
      <div className="k-qcard__cover">
        <AnimeCover src={cover} alt={title} decorative radius="var(--radius-lg)" />

        {/* Hold feedback. The sweep is a progress meter, so it fills linearly:
            easing it would misreport how much longer you have to hold. */}
        {hold.enabled && hold.phase !== "idle" && (
          <div className="k-qhold" aria-hidden>
            <div className="k-qhold__fill" />
            <span className="k-qhold__label">
              {hold.phase === "holding"
                ? "Adding to My Order"
                : hold.phase === "done"
                  ? "Added to My Order"
                  : "My Order is full"}
            </span>
          </div>
        )}
        {onMove && (
          <div className="k-qcard__move">
            <button
              type="button"
              disabled={!canMoveEarlier}
              onClick={() => onMove(rootId, -1)}
              aria-label={`Move ${title} earlier in the queue`}
            >
              <Icon icon={ChevronLeft} size={16} />
            </button>
            <button
              type="button"
              disabled={!canMoveLater}
              onClick={() => onMove(rootId, 1)}
              aria-label={`Move ${title} later in the queue`}
            >
              <Icon icon={ChevronRight} size={16} />
            </button>
          </div>
        )}
        {/* Only numbered cards carry a stamp. An affordance on all 1200 cards
            was noise: the order is built from the My Order dashboard, where you
            can search for a title instead of hunting for its card. */}
        {planNumber != null && (
          <button
            type="button"
            className="k-qcard__num"
            onClick={() => onNumber?.(rootId)}
            aria-label={`${title} is number ${planNumber} in your watch order. Change it`}
          >
            {planNumber}
          </button>
        )}
        {/* Two ways out of the plan, weighted the same: people either start a
            title or find they have already seen it, and promoting one of those
            over the other just makes the other a menu trip. Split across the
            footprint the single Start button used to have, so the grid's row
            maths is untouched — and each half carries its own keyline, so a
            wide thumb can't land on both. Both are undoable. */}
        <div className="k-qcard__acts">
          <button
            type="button"
            className="k-qcard__act"
            onClick={() =>
              void updateStatusUndoable(displayEntry.anilist_id, "watching", title)
            }
            aria-label={`Start watching ${title}`}
          >
            <Icon icon={Play} size={12} weight="fill" />
            Start
          </button>
          <button
            type="button"
            className="k-qcard__act"
            onClick={() =>
              void updateStatusUndoable(displayEntry.anilist_id, "completed", title)
            }
            aria-label={`Mark ${title} complete`}
          >
            <Icon icon={Check} size={12} />
            Done
          </button>
        </div>
      </div>
      {/* The title is the card's real door: a button stretched over the whole
          poster (see .k-qcard__open); Start and the move controls float above
          it, so the card opens by keyboard and screen reader too. */}
      <button
        type="button"
        className="k-qcard__title k-qcard__open"
        onClick={() => onOpen(rootId)}
      >
        {title}
      </button>
    </article>
  );
}

/**
 * Memoized. The virtualizer re-renders its parent on every scroll frame, so an
 * unmemoized card re-reconciles its whole tree (cover, pin, two move buttons
 * and Start, each carrying an SVG) on every one of those frames, for every
 * visible card. This is the single biggest reason the plan room scrolled worse
 * than Completed despite holding fewer entries.
 *
 * Only holds while the props stay referentially stable — see the note on
 * FranchiseCard, and the useCallback wrappers in StatusRoom.
 */
export const QueueCard = memo(QueueCardImpl);