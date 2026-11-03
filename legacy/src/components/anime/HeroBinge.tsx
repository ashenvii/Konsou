import { memo } from "react";
import { Play, Plus } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { statusMeta } from "./statusMeta";
import { Icon } from "@/components/ui/Icon";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { CSSProperties } from "react";
import type { FranchiseGroup } from "@/lib/franchise/grouping";

/** One cinematic card. Exported so the Watching room can render the same card
 *  inside its virtualized grid, keeping the language continuous when you
 *  drill in from the overview. */
function HeroCardImpl({
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
  // The real ceiling right now, not the eventual one — a still-airing show
  // can't be logged past what exists yet (setEpisodes already enforces this;
  // this keeps the button's disabled state agreeing with what a tap would do).
  const ceiling =
    displayEntry.airing_status === "RELEASING" && displayEntry.aired_episodes != null
      ? Math.min(total ?? displayEntry.aired_episodes, displayEntry.aired_episodes)
      : total;
  const atMax = ceiling != null && watched >= ceiling;
  // Airing-limited (nothing new yet) stays clickable so the tap can say why —
  // through setEpisodes' own toast, since incrementEpisodes already routes
  // there. A genuinely finished run (atMax for its own total, not the aired
  // ceiling) has nothing left to explain and stays truly disabled.
  const airingLimited =
    atMax &&
    displayEntry.aired_episodes != null &&
    (total == null || displayEntry.aired_episodes < total);
  // A paused entry sits quieter and offers to resume: +Ep would be a dead
  // button, since episode tracking only applies while actively watching.
  const paused = displayEntry.status === "on_hold";

  return (
    <article
      className={`k-hero${paused ? " k-hero--paused" : ""}`}
      style={{ "--card-status": status.color } as CSSProperties}
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
          {/* Radius 0: the art bleeds to the card edges and the card's own
              overflow clip rounds the outer corners. */}
          <AnimeCover src={cover} alt={title} decorative radius="0" />
        </div>

        <div className="k-hero__info">
          <span className="k-hero__tag">
            <Icon icon={status.icon} size={12} weight="fill" />
            {status.label}
          </span>
          {/* The title is the card's real door: a button stretched over the
              whole hero (see .k-hero__open), so the card opens by keyboard
              and screen reader too. The quick-log floats above it. */}
          <h3 className="k-hero__title">
            <button
              type="button"
              className="k-hero__open"
              onClick={() => onOpen(rootId)}
            >
              {title}
            </button>
          </h3>
          <span className="k-hero__meta">
            {/* The season name gives way; the episode count never leaves view.
                On narrow cards a long subtitle otherwise wraps the meta to
                three lines and pushes the bar out of the fixed room row. */}
            {displaySeason && (
              <span className="k-hero__metaseason">{displaySeason} · </span>
            )}
            <span className="k-hero__metaep">
              Ep {watched} of {total ?? "?"}
            </span>
          </span>
          <div className="k-hero__bar">
            <span style={{ width: `${pct}%` }} />
          </div>
        </div>

        {paused ? (
          <button
            type="button"
            className="k-hero__log"
            onClick={() => void updateStatus(displayEntry.anilist_id, "watching")}
            aria-label={`Resume watching ${title}`}
          >
            <Icon icon={Play} size={20} weight="fill" />
            <span>Resume</span>
          </button>
        ) : (
          <button
            type="button"
            className="k-hero__log"
            disabled={atMax && !airingLimited}
            aria-disabled={airingLimited || undefined}
            onClick={() => void incrementEpisodes(displayEntry.anilist_id, 1)}
            aria-label={airingLimited ? `${title}: no new episode yet` : `Log episode ${watched + 1} of ${title}`}
            title={airingLimited ? "No new episode yet" : undefined}
          >
            <Icon icon={Plus} size={20} />
            <span>Ep</span>
          </button>
        )}
      </div>
    </article>
  );
}

/** Memoized for the same reason as QueueCard: the Watching room renders these
 *  inside the virtualizer, which re-renders its parent on every scroll frame. */
export const HeroCard = memo(HeroCardImpl);