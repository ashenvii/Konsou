import { Star, X } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { Icon } from "@/components/ui/Icon";
import { formatScore, getCoverUrl, preferredTitle } from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { FranchiseGroup } from "@/lib/franchise/grouping";

/**
 * Completed as a collector's shelf. Covers stand on a ledge; the score rides
 * the corner (always visible, so touch never needs a hover) and lifts on hover
 * for the desktop flourish. Tapping a cover opens the quick menu. A recent
 * slice only; the full record lives in the Completed room.
 */
export function DigitalShelf({
  groups,
  onOpen,
}: {
  groups: FranchiseGroup[];
  onOpen: (rootId: number) => void;
}) {
  if (groups.length === 0) return null;
  return (
    <div className="k-shelf">
      <div className="k-shelf__row konsou-scroll">
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
export function ShelfItem({
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
  // The best score across the franchise's finished members represents the set.
  const score = entries.reduce<number | null>(
    (best, e) => (e.score != null && (best == null || e.score > best) ? e.score : best),
    null,
  );
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
