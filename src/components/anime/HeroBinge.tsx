import { Play, Plus } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { statusMeta } from "./statusMeta";
import { Icon } from "@/components/ui/Icon";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { CSSProperties } from "react";
import type { FranchiseGroup } from "@/lib/franchise/grouping";

/**
 * The active-watch focus. Your 1-2 most-recently-watched shows get a cinematic
 * card: the cover art becomes the material (a blurred backdrop under a scrim,
 * no glass, no color extraction), the ember glow marks it as yours, and a
 * prominent quick-log advances the episode without opening anything. Tapping
 * the card body still opens the quick menu; the +1 is the one inline exception,
 * because this surface is specifically about the show you're mid-binge on.
 */
export function HeroBinge({
  groups,
  onOpen,
}: {
  groups: FranchiseGroup[];
  onOpen: (rootId: number) => void;
}) {
  if (groups.length === 0) return null;
  return (
    <div className="k-herobinge">
      {groups.map((g) => (
        <HeroCard key={g.rootId} group={g} onOpen={onOpen} />
      ))}
    </div>
  );
}

/** One cinematic card. Exported so the Watching room can render the same card
 *  inside its virtualized grid, keeping the language continuous when you
 *  drill in from the overview. */
export function HeroCard({
  group,
  onOpen,
}: {
  group: FranchiseGroup;
  onOpen: (rootId: number) => void;
}) {
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
  const updateStatus = useListStore((s) => s.updateStatus);

  const { displayEntry, rootId, entries } = group;
  const rootEntry = entries.find((e) => e.anilist_id === rootId) ?? entries[0];
  const status = statusMeta(displayEntry.status);

  const title = preferredTitle(
    {
      romaji: rootEntry.title_romaji,
      english: rootEntry.title_english,
      native: rootEntry.title_native,
    },
    titleLanguage,
  );
  // Name the season on the card when the art follows a later season than the
  // franchise root, so the cover never looks like it changed on its own.
  const displaySeason =
    displayEntry.anilist_id !== rootEntry.anilist_id
      ? preferredTitle(
          {
            romaji: displayEntry.title_romaji,
            english: displayEntry.title_english,
            native: displayEntry.title_native,
          },
          titleLanguage,
        )
      : null;

  const cover = getCoverUrl({ medium: displayEntry.cover_url ?? undefined });
  const watched = displayEntry.episodes_watched;
  const total = displayEntry.total_episodes;
  const pct = total ? Math.min(100, (watched / total) * 100) : 0;
  const atMax = total != null && watched >= total;
  // A paused entry sits quieter and offers to resume: +Ep would be a dead
  // button, since episode tracking only applies while actively watching.
  const paused = displayEntry.status === "on_hold";

  return (
    <article
      className={`k-hero${paused ? " k-hero--paused" : ""}`}
      style={{ "--card-status": status.color } as CSSProperties}
      onClick={() => onOpen(rootId)}
    >
      {cover && (
        <div
          className="k-hero__backdrop"
          aria-hidden
          style={{ backgroundImage: `url("${cover}")` }}
        />
      )}
      <div className="k-hero__scrim" aria-hidden />

      <div className="k-hero__body">
        <div className="k-hero__cover">
          <AnimeCover src={cover} alt={title} decorative radius="var(--radius-md)" />
        </div>

        <div className="k-hero__info">
          <span className="k-hero__tag">
            <Icon icon={status.icon} size={12} weight="fill" />
            {status.label}
          </span>
          <h3 className="k-hero__title">{title}</h3>
          <span className="k-hero__meta">
            {displaySeason ? `${displaySeason} · ` : ""}
            Ep {watched} of {total ?? "?"}
          </span>
          <div className="k-hero__bar">
            <span style={{ width: `${pct}%` }} />
          </div>
        </div>

        {paused ? (
          <button
            type="button"
            className="k-hero__log"
            onClick={(e) => {
              e.stopPropagation();
              void updateStatus(displayEntry.anilist_id, "watching");
            }}
            aria-label={`Resume watching ${title}`}
          >
            <Icon icon={Play} size={18} weight="fill" />
            <span>Resume</span>
          </button>
        ) : (
          <button
            type="button"
            className="k-hero__log"
            disabled={atMax}
            onClick={(e) => {
              e.stopPropagation();
              void incrementEpisodes(displayEntry.anilist_id, 1);
            }}
            aria-label={`Log episode ${watched + 1} of ${title}`}
          >
            <Icon icon={Plus} size={20} />
            <span>Ep</span>
          </button>
        )}
      </div>
    </article>
  );
}
