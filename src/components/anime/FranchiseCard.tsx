import type { CSSProperties } from "react";
import {
  Bookmark,
  Check,
  ChevronRight,
  Layers,
  Pause,
  Play,
  RotateCw,
} from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { SeasonBar } from "./SeasonBar";
import { statusMeta } from "./statusMeta";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { formatScore, getCoverUrl, preferredTitle } from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { ViewMode } from "@/types/list";

interface FranchiseCardProps {
  group: FranchiseGroup;
  view: ViewMode;
  /** Called when the user taps the card or its action button — opens the franchise sheet. */
  onOpen: () => void;
}

export function FranchiseCard({ group, view, onOpen }: FranchiseCardProps) {
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const { displayEntry, entries, rootId, totalWatched, totalEpisodes, isGroup } = group;
  const status = statusMeta(displayEntry.status);

  // Use the root entry's title as the franchise name; fall back to the
  // display entry if the root somehow isn't in the tracked list.
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

  // Progressive reveal uses the display entry's individual episode progress —
  // it shows how far you are in the current season, not the franchise total.
  const displayTotal = displayEntry.total_episodes;
  const displayWatched = displayEntry.episodes_watched;
  const progressive =
    displayEntry.status === "watching" || displayEntry.status === "rewatching";
  const progressPct =
    progressive && displayTotal
      ? Math.min(100, (displayWatched / displayTotal) * 100)
      : 0;

  const seasonCount = entries.length;
  const doneSeasons = entries.filter((e) => e.status === "completed").length;
  const epLabel = `${totalWatched} / ${totalEpisodes != null ? totalEpisodes : "?"}`;
  const seasonLabel = `${seasonCount} seasons`;
  const seasonSummary = `${doneSeasons} done`;

  // ── Grid ──────────────────────────────────────────────────
  if (view === "grid") {
    return (
      <article
        className={`k-card k-card--grid k-card--inlist${isGroup ? " k-card--group" : ""} k-card--status-${displayEntry.status}`}
        style={{
          "--card-status": status.color,
          ...(progressive && displayTotal != null
            ? { "--progress": `${progressPct}%` }
            : {}),
        } as CSSProperties}
        onClick={onOpen}
      >
        <div className="k-card__cover">
          <AnimeCover src={cover} alt={title} radius="0" />

          {progressive && displayTotal != null && cover && (
            <>
              <div
                className="k-card__reveal"
                aria-hidden
                style={{ backgroundImage: `url("${cover}")` }}
              />
              <div className="k-card__front" aria-hidden>
                <span className="k-card__epnow">EP {displayWatched}</span>
              </div>
            </>
          )}

          {displayEntry.status === "dropped" && cover && (
            <div
              className="k-card__mono"
              aria-hidden
              style={{ backgroundImage: `url("${cover}")` }}
            />
          )}

          <div className="k-card__scrim" />

          {/* Franchise badge, top-left: the umbrella made obvious at a glance. */}
          {isGroup && (
            <span className="k-franchise-badge" title={`${seasonCount} seasons tracked`}>
              <Icon icon={Layers} size={11} />
              {seasonCount}
            </span>
          )}

          {displayEntry.status === "watching" && (
            <span className={`k-mark ${isGroup ? "k-mark--right" : "k-mark--left"}`}>
              <span className="k-mark__icon">
                <Icon icon={Play} size={13} weight="fill" />
              </span>
              Watching
            </span>
          )}
          {displayEntry.status === "rewatching" && (
            <span className={`k-mark k-mark--spin ${isGroup ? "k-mark--right" : "k-mark--left"}`}>
              <span className="k-mark__icon">
                <Icon icon={RotateCw} size={13} weight="fill" />
              </span>
              Rewatch
            </span>
          )}
          {displayEntry.status === "completed" && (
            <span className="k-seal" aria-label={status.label} title={status.label}>
              <Icon icon={Check} size={17} strokeWidth={3} />
            </span>
          )}
          {displayEntry.status === "plan_to_watch" && (
            <span className="k-bookmark" aria-label={status.label} title={status.label}>
              <Icon icon={Bookmark} size={13} fill />
            </span>
          )}
          {displayEntry.status === "dropped" && (
            <span className="k-ribbon">Dropped</span>
          )}
          {displayEntry.status === "on_hold" && (
            <span className="k-hold" aria-label={status.label}>
              <span className="k-hold__circle">
                <Icon icon={Pause} size={24} weight="fill" />
              </span>
              <span className="k-hold__label">On hold</span>
            </span>
          )}

          <div className="k-card__footer">
            <Text size="sm" weight={600} clamp={2} className="k-card__title">
              {title}
            </Text>
            <div className="k-card__footermeta">
              {/* For groups the footer carries the franchise total (distinct from
                  the per-season "EP" marker). For a single it's hidden only when the
                  EP marker is actually shown (progressive + known total), otherwise
                  the count would simply repeat. */}
              {(isGroup || !(progressive && displayTotal != null)) && (
                <span className="k-card__epcaption">{epLabel}</span>
              )}
              {displayEntry.score != null && (
                <span className="k-card__scorechip">
                  {formatScore(displayEntry.score)}
                </span>
              )}
            </div>
            {/* Segmented season bar: one chunk per tracked season. */}
            <SeasonBar entries={entries} size="grid" className="k-card__seasonbar" />
          </div>

          {/* Opens the franchise sheet */}
          <button
            type="button"
            className="k-card__quick k-card__quick--sheet"
            onClick={(e) => { e.stopPropagation(); onOpen(); }}
            aria-label={isGroup ? "Manage seasons" : "View details"}
          >
            <Icon icon={isGroup ? Layers : ChevronRight} size={16} />
          </button>
        </div>
      </article>
    );
  }

  // ── List ──────────────────────────────────────────────────
  if (view === "list") {
    return (
      <article
        className={`k-card k-row k-card--inlist${isGroup ? " k-card--group" : ""}`}
        style={{ "--card-status": status.color } as CSSProperties}
        onClick={onOpen}
      >
        <div className="k-row__poster">
          <AnimeCover src={cover} alt={title} decorative radius="var(--radius-sm)" />
        </div>
        <div className="k-row__main">
          <Text size="base" weight={600} clamp={1} className="k-row__title">
            {title}
          </Text>
          <div className="k-row__sub">
            <span className="k-pill" style={{ color: status.color }}>
              <Icon icon={status.icon} size={12} weight="fill" />
              {status.label}
            </span>
            {isGroup && (
              <>
                <span className="k-chip-mini">
                  <Icon icon={Layers} size={10} />
                  {seasonLabel}
                </span>
                <span className="k-row__dim">{seasonSummary}</span>
              </>
            )}
          </div>
          <SeasonBar entries={entries} size="row" className="k-row__seasonbar" />
        </div>
        <div className="k-row__metacol">
          <span className="k-row__ep">{epLabel}</span>
          {displayEntry.score != null && (
            <span className="k-row__scoreval">★ {formatScore(displayEntry.score)}</span>
          )}
        </div>
        <button
          type="button"
          className="k-row__action"
          onClick={(e) => { e.stopPropagation(); onOpen(); }}
          aria-label="Manage seasons"
        >
          <Icon icon={ChevronRight} size={18} />
        </button>
      </article>
    );
  }

  // ── Compact ───────────────────────────────────────────────
  return (
    <article
      className={`k-card k-compact k-card--inlist${isGroup ? " k-card--group" : ""}`}
      style={{ "--card-status": status.color } as CSSProperties}
      onClick={onOpen}
    >
      <AnimeCover src={cover} alt={title} decorative className="k-compact__thumb" radius="var(--radius-sm)" />
      <div className="k-compact__body">
        <Text size="base" weight={500} clamp={1} className="k-compact__title">
          {title}
        </Text>
        {isGroup && (
          <span className="k-chip-mini">
            <Icon icon={Layers} size={10} />
            {seasonCount}
          </span>
        )}
      </div>
      <span className="k-compact__ep">{epLabel}</span>
      <span className="k-compact__statusicon" style={{ color: status.color }} title={status.label}>
        <Icon icon={status.icon} size={14} weight="fill" />
      </span>
      <span className="k-compact__score">
        {displayEntry.score != null ? formatScore(displayEntry.score) : ""}
      </span>
      <SeasonBar entries={entries} size="row" className="k-compact__seasonbar" />
    </article>
  );
}
