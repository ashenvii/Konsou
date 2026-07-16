import { Play } from "lucide-react";
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

function QueueCard({
  group,
  onOpen,
}: {
  group: FranchiseGroup;
  onOpen: (rootId: number) => void;
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
    <article className="k-qcard" onClick={() => onOpen(rootId)}>
      <div className="k-qcard__cover">
        <AnimeCover src={cover} alt={title} decorative radius="var(--radius-lg)" />
        <button
          type="button"
          className="k-qcard__start"
          onClick={(e) => {
            e.stopPropagation();
            void updateStatus(displayEntry.anilist_id, "watching");
          }}
          aria-label={`Start watching ${title}`}
        >
          <Icon icon={Play} size={14} weight="fill" />
          Start
        </button>
      </div>
      <span className="k-qcard__title">{title}</span>
    </article>
  );
}
