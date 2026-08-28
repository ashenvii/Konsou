import { memo } from "react";
import { Check, Play, Plus } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { Icon } from "@/components/ui/Icon";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { statusBlockReason } from "@/lib/statusValidation";
import type { FranchiseGroup } from "@/lib/franchise/grouping";

/**
 * The plan card: a mounted poster with its watch-order slot and the two ways
 * out of the plan on its footer. Rendered by the plan room inside the
 * virtualized grid.
 */

/** One poster with its Start action. Exported so the Plan room renders the same
 *  card in its virtualized grid. */
/** How long a planned title reads as "just added".
 *
 *  The plan room sorts numbered-first by default, so anything you added
 *  recently lands wherever its number puts it — usually nowhere near the
 *  top. Nothing on the surface said which titles were new, so a room with
 *  four hundred cards looked the same the day after you added twenty. Two
 *  weeks is long enough to still count as "I just put this here" and short
 *  enough that the mark stays rare on a list you have not touched. */
const JUST_ADDED_MS = 14 * 24 * 60 * 60 * 1000;

function QueueCardImpl({
  group,
  onOpen,
  onNumber,
  onAdd,
  planNumber,
  orderFull,
}: {
  group: FranchiseGroup;
  onOpen: (rootId: number) => void;
  /** Open the watch-order number picker for a card that already has a number.
   *  Carries the tapped element so the picker can anchor to it like every
   *  other quick menu, instead of the number being the one control left that
   *  always opened a full-width mobile sheet regardless of window size. */
  onNumber?: (rootId: number, anchor: HTMLElement) => void;
  /** Put an unnumbered card into the watch order at the next free number. */
  onAdd?: (rootId: number) => void;
  /** The number currently stamped on this card, if any. */
  planNumber?: number | null;
  /** The order is at its cap; the empty slot says so instead of pretending. */
  orderFull?: boolean;
}) {
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const updateStatusUndoable = useListStore((s) => s.updateStatusUndoable);

  const { displayEntry, rootId, entries } = group;
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

  // Same guard the store enforces either way, checked here so the card can
  // say so before the tap instead of after. QuickMenu's status picker already
  // greys these out for the same reason; the plan card was the one place that
  // still let you find out by bouncing off a toast.
  const justAdded = Date.now() - group.sortAdded < JUST_ADDED_MS;

  const startBlocked = statusBlockReason(displayEntry.airing_status, "watching");
  const doneBlocked = statusBlockReason(displayEntry.airing_status, "completed");

  return (
    <article className="k-qcard">
      <div className="k-qcard__cover">
        <AnimeCover src={cover} alt={title} decorative radius="var(--radius-lg)" />

        {/* The number slot is a control, not a badge. A numbered card shows the
            number and opens the picker; an unnumbered one offers the slot. This
            replaces a press-and-hold that had to fight a flinging list for the
            same gesture, and lost often enough that the owner reported adding
            to the order as broken. */}
        {planNumber != null ? (
          <button
            type="button"
            className="k-qcard__num"
            onClick={(e) => onNumber?.(rootId, e.currentTarget)}
            aria-label={`${title} is number ${planNumber} in your watch order. Change it`}
          >
            {planNumber}
          </button>
        ) : (
          onAdd && (
            <button
              type="button"
              className="k-qcard__num k-qcard__num--add"
              onClick={() => onAdd(rootId)}
              aria-disabled={orderFull || undefined}
              aria-label={`Add ${title} to your watch order`}
            >
              <Icon icon={Plus} size={18} />
            </button>
          )
        )}
        {/* Opposite corner from the number, and deliberately quieter than it:
            the number is what you chose, this is only when it arrived. */}
        {justAdded && <span className="k-qcard__new">new</span>}

        {/* Two ways out of the plan, weighted the same: people either start a
            title or find they have already seen it, and promoting one of those
            over the other just makes the other a menu trip. Split across the
            footprint the single Start button used to have, so the grid's row
            maths is untouched — and each half carries its own keyline, so a
            wide thumb can't land on both. Both are undoable. */}
        <div className="k-qcard__acts">
          {/* Blocked stays clickable rather than natively disabled: a disabled
              button never fires a click at all, so a blocked tap on a touch
              device (no hover to read a title from) got no feedback
              whatsoever. The tap now reaches the store, which already carries
              this exact reason in a toast (see listStore.updateStatus's
              guard) — this only had to stop swallowing the tap before it got
              there. Desktop keeps the hover title as a second, immediate way
              to read the same reason. */}
          <button
            type="button"
            className="k-qcard__act"
            aria-disabled={startBlocked ? true : undefined}
            onClick={() =>
              void updateStatusUndoable(displayEntry.anilist_id, "watching", title)
            }
            aria-label={startBlocked ? `${title}: ${startBlocked}` : `Start watching ${title}`}
            title={startBlocked ?? undefined}
          >
            <Icon icon={Play} size={12} weight="fill" />
            Start
          </button>
          <button
            type="button"
            className="k-qcard__act"
            aria-disabled={doneBlocked ? true : undefined}
            onClick={() =>
              void updateStatusUndoable(displayEntry.anilist_id, "completed", title)
            }
            aria-label={doneBlocked ? `${title}: ${doneBlocked}` : `Mark ${title} complete`}
            title={doneBlocked ?? undefined}
          >
            <Icon icon={Check} size={12} />
            Done
          </button>
        </div>
      </div>
      {/* The title is the card's real door: a button stretched over the whole
          poster (see .k-qcard__open); the slot and the actions float above
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
 * unmemoized card re-reconciles its whole tree (cover, slot, Start and Done,
 * each carrying an SVG) on every one of those frames, for every visible card.
 * This is the single biggest reason the plan room scrolled worse than Completed
 * despite holding fewer entries.
 *
 * Only holds while the props stay referentially stable — see the note on
 * FranchiseCard, and the useCallback wrappers in PlanRoom.
 */
export const QueueCard = memo(QueueCardImpl);
