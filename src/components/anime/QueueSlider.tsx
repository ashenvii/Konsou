import { ChevronLeft, ChevronRight, Play } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { Icon } from "@/components/ui/Icon";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { FranchiseGroup } from "@/lib/franchise/grouping";

/**
 * Plan-to-watch as an aspirational poster carousel. Tapping a poster opens the
 * quick menu; the Start button promotes it straight into Watching without the
 * detour. Full-width so it uses the desktop, a natural swipe on a phone.
 */
export function QueueSlider({
  groups,
  onOpen,
}: {
  groups: FranchiseGroup[];
  onOpen: (rootId: number) => void;
}) {
  if (groups.length === 0) return null;
  return (
    <div className="k-queue konsou-scroll">
      {groups.map((g) => (
        <QueueCard key={g.rootId} group={g} onOpen={onOpen} />
      ))}
    </div>
  );
}

/** One poster with its Start action. Exported so the Plan room renders the same
 *  card in its virtualized grid. */
export function QueueCard({
  group,
  onOpen,
  onMove,
  canMoveEarlier,
  canMoveLater,
}: {
  group: FranchiseGroup;
  onOpen: (rootId: number) => void;
  /** Only supplied while the Plan room is on your manual order. */
  onMove?: (rootId: number, dir: -1 | 1) => void;
  canMoveEarlier?: boolean;
  canMoveLater?: boolean;
}) {
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const updateStatus = useListStore((s) => s.updateStatus);

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

  return (
    <article className="k-qcard">
      <div className="k-qcard__cover">
        <AnimeCover src={cover} alt={title} decorative radius="var(--radius-lg)" />
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
        <button
          type="button"
          className="k-qcard__start"
          onClick={() => void updateStatus(displayEntry.anilist_id, "watching")}
          aria-label={`Start watching ${title}`}
        >
          <Icon icon={Play} size={14} weight="fill" />
          Start
        </button>
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
