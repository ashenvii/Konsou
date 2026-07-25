import { memo } from "react";
import { Star, X } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { Icon } from "@/components/ui/Icon";
import { useDragScroll } from "@/hooks/useDragScroll";
import { bestScore } from "@/lib/franchise/grouping";
import { formatScore, getCoverUrl, preferredTitle } from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { FranchiseGroup } from "@/lib/franchise/grouping";

/**
 * Completed as a collector's shelf. Covers stand on a ledge; the score rides
 * the corner (always visible, so touch never needs a hover) and lifts on hover
 * for the desktop flourish. Tapping a cover opens the quick menu. A recent
 * slice only; the full record lives in the Completed room.
 * Desktop pans by mouse drag (no scrollbar); the wheel stays with the page.
 */
export function DigitalShelf({
  groups,
  onOpen,
}: {
  groups: FranchiseGroup[];
  onOpen: (rootId: number) => void;
}) {
  const rowRef = useDragScroll<HTMLDivElement>();
  if (groups.length === 0) return null;
  return (
    <div className="k-shelf">
      <div className="k-shelf__row" ref={rowRef}>
        {groups.map((g) => (
          <ShelfItem key={g.rootId} group={g} onOpen={onOpen} />
        ))}
      </div>
      <div className="k-shelf__ledge" aria-hidden />
    </div>
  );
}

/** One cover on the ledge. Exported so the Completed room renders the same card
 *  in its virtualized grid. */
function ShelfItemImpl({
  group,
  onOpen,
}: {
  group: FranchiseGroup;
  onOpen: (rootId: number) => void;
}) {
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

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
  // The best score across the franchise's members represents the set (the
  // shared rule: see bestScore in grouping).
  const score = bestScore(entries);
  // Dropped rides the shelf when you ask for it: desaturated, marked with a
  // cross instead of a score. It's part of the record ("I dealt with this"),
  // just never a title you finished.
  const dropped = displayEntry.status === "dropped";

  return (
    <button
      type="button"
      className={`k-shelfitem${dropped ? " k-shelfitem--dropped" : ""}`}
      onClick={() => onOpen(rootId)}
      title={title}
      // Content order would put the corner badge before the title ("9 Cowboy
      // Bebop"); name the button explicitly so the score reads as a score.
      aria-label={
        dropped
          ? `${title}, dropped`
          : score != null
            ? `${title}, scored ${formatScore(score)}`
            : title
      }
    >
      <div className="k-shelfitem__cover">
        <AnimeCover src={cover} alt={title} decorative radius="var(--radius-md)" />
        {dropped ? (
          <span className="k-shelfitem__score k-shelfitem__score--dropped">
            <Icon icon={X} size={11} />
            Dropped
          </span>
        ) : (
          score != null && (
            <span className="k-shelfitem__score">
              <Icon icon={Star} size={11} weight="fill" />
              {formatScore(score)}
            </span>
          )
        )}
      </div>
      <span className="k-shelfitem__title">{title}</span>
    </button>
  );
}

/** Memoized for the same reason as QueueCard: the virtualizer re-renders the
 *  parent every scroll frame. Cheaper tree than the queue poster, which is why
 *  Completed already felt smoother, but it still pays per frame without this. */
export const ShelfItem = memo(ShelfItemImpl);
