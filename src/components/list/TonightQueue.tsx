import { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { Moon } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { useDragScroll } from "@/hooks/useDragScroll";
import { preferredTitle } from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AnimeListEntry } from "@/types/list";

interface QueueItem {
  entry: AnimeListEntry;
  reason: string;
  /** New-episode items get the accent treatment; they're why you opened the app. */
  accent: boolean;
}

const MAX_ITEMS = 5;

/**
 * Compose tonight's watching plan from local data alone. Priority order:
 * shows with unwatched aired episodes, then shows within two episodes of the
 * finish line, then whatever was picked up most recently.
 */
function buildQueue(entries: AnimeListEntry[]): QueueItem[] {
  const active = entries.filter(
    (e) => e.status === "watching" || e.status === "rewatching",
  );
  const used = new Set<number>();
  const items: QueueItem[] = [];

  // New episodes first: something aired that hasn't been watched yet.
  const fresh = active
    .filter(
      (e) =>
        e.airing_status === "RELEASING" &&
        e.aired_episodes != null &&
        e.aired_episodes > e.episodes_watched,
    )
    .sort((a, b) => b.updated_at - a.updated_at);
  for (const e of fresh) {
    const behind = (e.aired_episodes ?? 0) - e.episodes_watched;
    items.push({
      entry: e,
      reason:
        behind === 1
          ? `EP ${e.episodes_watched + 1} is out`
          : `${behind} new episodes`,
      accent: true,
    });
    used.add(e.anilist_id);
  }

  // Then the almost-finished: two or fewer to the end.
  const almost = active
    .filter((e) => {
      if (used.has(e.anilist_id) || e.total_episodes == null) return false;
      const left = e.total_episodes - e.episodes_watched;
      return left > 0 && left <= 2;
    })
    .sort(
      (a, b) =>
        a.total_episodes! -
        a.episodes_watched -
        (b.total_episodes! - b.episodes_watched),
    );
  for (const e of almost) {
    const left = e.total_episodes! - e.episodes_watched;
    items.push({
      entry: e,
      reason: left === 1 ? "One episode to finish" : "Two episodes to finish",
      accent: false,
    });
    used.add(e.anilist_id);
  }

  // Fill the remaining slots with the freshest of what's left.
  const rest = active
    .filter((e) => !used.has(e.anilist_id))
    .sort((a, b) => b.updated_at - a.updated_at);
  for (const e of rest) {
    if (items.length >= MAX_ITEMS) break;
    items.push({
      entry: e,
      reason: `Continue with EP ${e.episodes_watched + 1}`,
      accent: false,
    });
  }

  return items.slice(0, MAX_ITEMS);
}

/** The "what should I watch right now" strip at the top of My List. */
export function TonightQueue({ entries }: { entries: AnimeListEntry[] }) {
  const navigate = useNavigate();
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const items = useMemo(() => buildQueue(entries), [entries]);
  // The row has no visible scrollbar; on desktop a mouse can't reach the
  // off-screen items without this (wheel scrolls sideways, drag pans it).
  const rowRef = useDragScroll<HTMLDivElement>();

  if (items.length === 0) return null;

  return (
    <section className="k-tonight" aria-label="Tonight's queue">
      <p className="k-tonight__head">
        <Icon icon={Moon} size={13} />
        Tonight
      </p>
      <div className="k-tonight__row" ref={rowRef}>
        {items.map(({ entry, reason, accent }) => (
          <button
            key={entry.anilist_id}
            type="button"
            className="k-tonight__item"
            onClick={() =>
              navigate(`/anime/${entry.anilist_id}`, { replace: true })
            }
          >
            <span className="k-tonight__cover">
              <AnimeCover
                src={entry.cover_url ?? undefined}
                alt=""
                decorative
                radius="var(--radius-sm)"
              />
            </span>
            <span className="k-tonight__body">
              <Text size="sm" weight={600} clamp={1}>
                {preferredTitle(
                  {
                    romaji: entry.title_romaji,
                    english: entry.title_english,
                    native: entry.title_native,
                  },
                  titleLanguage,
                )}
              </Text>
              <span
                className={`k-tonight__reason${accent ? " k-tonight__reason--new" : ""}`}
              >
                {reason}
              </span>
            </span>
          </button>
        ))}
      </div>
    </section>
  );
}
