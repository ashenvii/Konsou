import { memo } from "react";
import type { CSSProperties } from "react";
import {
  Bookmark,
  Check,
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
import { bestScore } from "@/lib/franchise/grouping";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { ViewMode } from "@/types/list";

interface FranchiseCardProps {
  group: FranchiseGroup;
  view: ViewMode;
  /**
   * Called with the group's rootId when the user taps the card or its action
   * button — opens the franchise sheet. Takes rootId (rather than being a
   * pre-bound closure) so the parent can pass a stable function reference and
   * memo() actually holds across the parent's per-scroll-frame re-renders.
   */
  onOpen: (rootId: number) => void;
}

function FranchiseCardImpl({ group, view, onOpen }: FranchiseCardProps) {
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

  // The card's art follows where the user is in the franchise, which can be a
  // different season than the (root) title above it. Say so, or the cover
  // looks like it changed on its own.
  const displayTitle =
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
  const epLabel = `${totalWatched} / ${totalEpisodes != null ? totalEpisodes : "?"}`;
  // A completed single with no known episode count would read "0 / ?" beside
  // a full season bar; the completed marker already says everything.
  const hideEpLabel =
    !isGroup &&
    displayEntry.status === "completed" &&
    totalEpisodes == null &&
    totalWatched === 0;
  const seasonLabel = `${seasonCount} seasons`;
  // A fully-completed card's season bar is a solid status-colored line: it
  // says nothing the check and count don't, and a room of them reads as
  // hard rules drawn under every row. The bar earns its place only while
  // some part of the franchise is unfinished.
  const allCompleted = entries.every((e) => e.status === "completed");

  // Same rule as the shelf badge: the group's best score, never the display
  // entry's own (an unscored active season would hide the finished one's).
  const score = bestScore(entries);

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
        onClick={() => onOpen(rootId)}
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
          {/* No not_interested marker: muted entries never form a card
              (groupEntries drops them), so a card never carries that status. */}

          <div className="k-card__footer">
            <Text size="sm" weight={600} clamp={2} color="onCover" className="k-card__title">
              {title}
            </Text>
            {displayTitle && (
              <span className="k-card__nowshowing" title={`Cover: ${displayTitle}`}>
                {displayTitle}
              </span>
            )}
            <div className="k-card__footermeta">
              {/* For groups the footer carries the franchise total (distinct from
                  the per-season "EP" marker). For a single it's hidden only when the
                  EP marker is actually shown (progressive + known total), otherwise
                  the count would simply repeat. */}
              {/* The EP marker only renders over an actual cover, so a broken
                  cover keeps the caption as the progress fallback. */}
              {(isGroup || !(progressive && displayTotal != null && cover)) &&
                !hideEpLabel && (
                  <span className="k-card__epcaption">{epLabel}</span>
                )}
              {score != null && (
                <span className="k-card__scorechip">
                  {formatScore(score)}
                </span>
              )}
            </div>
            {/* Segmented season bar: one chunk per tracked season. */}
            {!allCompleted && (
              <SeasonBar entries={entries} size="grid" className="k-card__seasonbar" />
            )}
          </div>
          {/* No corner action button: tapping the card IS the action, and the
              top-left badge already marks the franchise. A button that repeats
              the card tap is clutter, not affordance. */}
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
        onClick={() => onOpen(rootId)}
      >
        <div className="k-row__poster">
          <AnimeCover src={cover} alt={title} decorative radius="var(--radius-sm)" />
        </div>
        <div className="k-row__main">
          <Text size="base" weight={600} clamp={1} className="k-row__title">
            {title}
          </Text>
          <div className="k-row__sub">
            <span className="k-pill">
              <span className="k-pill__icon" style={{ color: status.color }}>
                <Icon icon={status.icon} size={12} weight="fill" />
              </span>
              {status.label}
            </span>
            {/* Count only — the season bar below already draws how many are
                done, so a "N done" caption would say it twice. */}
            {isGroup && (
              <span className="k-chip-mini">
                <Icon icon={Layers} size={10} />
                {seasonLabel}
              </span>
            )}
          </div>
          {!allCompleted && (
            <SeasonBar entries={entries} size="row" className="k-row__seasonbar" />
          )}
        </div>
        <div className="k-row__metacol">
          <span className="k-row__ep">{hideEpLabel ? "" : epLabel}</span>
          {score != null && (
            <span className="k-row__scoreval">★ {formatScore(score)}</span>
          )}
        </div>
        {/* Tapping the row opens the sheet; a chevron repeating that is noise. */}
      </article>
    );
  }

  // ── Compact ───────────────────────────────────────────────
  return (
    <article
      className={`k-card k-compact k-card--inlist${isGroup ? " k-card--group" : ""}`}
      style={{ "--card-status": status.color } as CSSProperties}
      onClick={() => onOpen(rootId)}
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
      <span className="k-compact__ep">{hideEpLabel ? "" : epLabel}</span>
      <span className="k-compact__statusicon" style={{ color: status.color }} title={status.label}>
        <Icon icon={status.icon} size={14} weight="fill" />
      </span>
      <span className="k-compact__score">
        {score != null ? formatScore(score) : ""}
      </span>
      {!allCompleted && (
        <SeasonBar entries={entries} size="row" className="k-compact__seasonbar" />
      )}
    </article>
  );
}

// Memoized: FranchiseCollection re-renders on every scroll frame as the virtual
// window shifts. Without this, every visible card re-runs its store selectors
// and hooks each frame, which is the main source of scroll jank on long lists.
export const FranchiseCard = memo(FranchiseCardImpl);
