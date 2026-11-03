import { memo, useState } from "react";
import type { CSSProperties, MouseEvent } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, Star } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { SeasonBar } from "./SeasonBar";
import { StatusSheet } from "./StatusSheet";
import { statusMeta } from "./statusMeta";
import { StatusStamp } from "./StatusStamp";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { useEpisodeIncrement } from "@/hooks/useEpisodeIncrement";
import { getDisabledStatuses } from "@/lib/statusValidation";
import { useListStore } from "@/lib/store/listStore";
import {
  formatLabel,
  formatScore,
  getCoverUrl,
  preferredTitle,
} from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AnimeSummary } from "@/types/anime";
import type { ListStatus, ViewMode } from "@/types/list";

interface AnimeCardProps {
  media: AnimeSummary;
  view: ViewMode;
  showStatus?: boolean;
}

function AnimeCardImpl({ media, view, showStatus = false }: AnimeCardProps) {
  const navigate = useNavigate();
  const entry = useListStore((s) => s.map[media.id]);
  const addFromSummary = useListStore((s) => s.addFromSummary);
  const updateStatus = useListStore((s) => s.updateStatus);
  const remove = useListStore((s) => s.remove);

  const [sheetOpen, setSheetOpen] = useState(false);

  const inList = !!entry;
  // Prefer list-entry dub status (set after visiting detail); fall back to
  // summary-level detection from externalLinks so untracked cards show the tag too.
  const hasDub = entry ? entry.has_dub : (media.hasDub ?? null);
  const dubLabel: "DUB+SUB" | "SUB" | null =
    hasDub === true ? "DUB+SUB" :
    hasDub === false ? "SUB" :
    null;
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  // One name per card. The other-language handles live behind the info
  // toggle on the detail page, where there's room to read them.
  const title = preferredTitle(media.title, titleLanguage);
  const cover = getCoverUrl(media.coverImage);
  const total = entry?.total_episodes ?? media.episodes ?? null;
  const watched = entry?.episodes_watched ?? 0;
  const status = entry ? statusMeta(entry.status) : null;
  // Watching + rewatching share the progressive "color-in" treatment: the cover
  // starts greyscale and the watched episodes reveal it in colour, left → right.
  const progressive =
    entry?.status === "watching" || entry?.status === "rewatching";

  // undoToast: a card +1 is a quick, easy-to-mis-tap action, so give every
  // commit a one-tap Undo (the deliberate detail stepper opts out).
  const { increment, pending } = useEpisodeIncrement(media.id, watched, total, {
    undoToast: true,
  });

  const open = () => navigate(`/anime/${media.id}`, { replace: true });
  const stop = (e: MouseEvent) => e.stopPropagation();

  const quickAction = (e: MouseEvent) => {
    stop(e);
    if (inList) increment();
    else setSheetOpen(true);
  };

  const onPick = (status: ListStatus) => {
    if (inList) void updateStatus(media.id, status);
    else void addFromSummary(media, status);
  };

  const sheet = (
    <StatusSheet
      open={sheetOpen}
      onClose={() => setSheetOpen(false)}
      title={inList ? "Change status" : `Add "${title}"`}
      current={entry?.status}
      onPick={onPick}
      onRemove={inList ? () => remove(media.id) : undefined}
      disabledStatuses={getDisabledStatuses(
        entry?.airing_status ?? media.status ?? null,
      )}
    />
  );

  const progressPct =
    inList && total ? Math.min(100, (watched / total) * 100) : 0;

  // The +1 quick action only does anything while watching/rewatching
  // (incrementEpisodes no-ops otherwise); untracked cards use it to add.
  // Showing a dead button on completed/planned/dropped cards just invites
  // taps that go nowhere.
  const showQuick = !inList || progressive;

  // A completed entry with no known episode count would caption "0 / ?"
  // beside a full bar; the completed marker already says everything.
  const hideEpCaption =
    entry?.status === "completed" && total == null && watched === 0;

  // ── Grid ─────────────────────────────────────────────────
  if (view === "grid") {
    return (
      <>
        <article
          className={`k-card k-card--grid${inList && entry ? ` k-card--inlist k-card--status-${entry.status}` : ""}`}
          style={
            inList && status
              ? ({
                  "--card-status": status.color,
                  ...(progressive && total != null
                    ? { "--progress": `${progressPct}%` }
                    : {}),
                } as CSSProperties)
              : undefined
          }
          onClick={open}
        >
          <div className="k-card__cover">
            <AnimeCover src={cover} alt={title} radius="0" />
            {progressive && total != null && cover && (
              <>
                <div
                  className="k-card__reveal"
                  aria-hidden
                  style={{ backgroundImage: `url("${cover}")` }}
                />
                <div className="k-card__front" aria-hidden>
                  <span className="k-card__epnow">EP {watched}</span>
                </div>
              </>
            )}
            {entry?.status === "dropped" && cover && (
              <div
                className="k-card__mono"
                aria-hidden
                style={{ backgroundImage: `url("${cover}")` }}
              />
            )}
            <div className="k-card__scrim" />

            {/* One field-note stamp for every state, always the same corner. */}
            {entry && <StatusStamp status={entry.status} />}

            <div className="k-card__footer">
              <Text size="sm" weight={600} clamp={2} color="onCover" className="k-card__title">
                {title}
              </Text>
              <div className="k-card__footermeta">
                {/* The EP marker only renders over an actual cover, so a broken
                    cover keeps the caption as the progress fallback. */}
                {inList && !(progressive && total != null && cover) && !hideEpCaption && (
                  <span className="k-card__epcaption">
                    {watched}/{total ?? "?"}
                  </span>
                )}
                {entry?.score != null && (
                  <span className="k-card__scorechip">
                    <Icon icon={Star} size={10} fill />
                    {formatScore(entry.score)}
                  </span>
                )}
                {dubLabel && (
                  <span className={`k-card__dubtag${dubLabel === "DUB+SUB" ? " k-card__dubtag--dub" : " k-card__dubtag--sub"}`}>
                    {dubLabel}
                  </span>
                )}
              </div>
              {inList && entry && (
                <SeasonBar entries={[entry]} size="grid" className="k-card__seasonbar" />
              )}
            </div>
            {showQuick && (
              <button
                type="button"
                className="k-card__quick"
                onClick={quickAction}
                aria-label={inList ? "Add one episode" : "Add to list"}
              >
                {inList ? (
                  pending > 0 ? (
                    <span className="k-card__quick-pending">+{pending}</span>
                  ) : (
                    "+1"
                  )
                ) : (
                  <Icon icon={Plus} size={18} />
                )}
              </button>
            )}
          </div>
        </article>
        {sheet}
      </>
    );
  }

  // ── List ─────────────────────────────────────────────────
  if (view === "list") {
    const meta = [media.studio, formatLabel(media.format)]
      .filter(Boolean)
      .join(" · ");
    return (
      <>
        <article
          className={`k-card k-row${inList ? " k-card--inlist" : ""}`}
          style={inList && status ? { "--card-status": status.color } as CSSProperties : undefined}
          onClick={open}
        >
          <div className="k-row__poster">
            <AnimeCover src={cover} alt={title} decorative radius="var(--radius-sm)" />
          </div>
          <div className="k-row__main">
            <Text size="base" weight={600} clamp={1} className="k-row__title">
              {title}
            </Text>
            <div className="k-row__sub">
              {status ? (
                <span className="k-pill">
                  <span className="k-pill__icon" style={{ color: status.color }}>
                    <Icon icon={status.icon} size={12} weight="fill" />
                  </span>
                  {status.label}
                </span>
              ) : (
                meta && <span className="k-row__dim">{meta}</span>
              )}
              {dubLabel && <span className="k-chip-mini">{dubLabel}</span>}
            </div>
            {inList && entry && (
              <SeasonBar entries={[entry]} size="row" className="k-row__seasonbar" />
            )}
          </div>
          <div className="k-row__metacol">
            <span className="k-row__ep">
              {inList && !hideEpCaption ? `${watched} / ${total ?? "?"}` : ""}
            </span>
            {entry?.score != null && (
              <span className="k-row__scoreval">★ {formatScore(entry.score)}</span>
            )}
          </div>
          {showQuick && (
            <button
              type="button"
              className="k-row__action"
              onClick={quickAction}
              aria-label={inList ? "Add one episode" : "Add to list"}
            >
              {inList ? (pending > 0 ? `+${pending}` : "+1") : <Icon icon={Plus} size={18} />}
            </button>
          )}
        </article>
        {sheet}
      </>
    );
  }

  // ── Compact ──────────────────────────────────────────────
  return (
    <>
      <article
        className={`k-card k-compact${inList ? " k-card--inlist" : ""}`}
        style={inList && status ? { "--card-status": status.color } as CSSProperties : undefined}
        onClick={open}
      >
        <AnimeCover src={cover} alt={title} decorative className="k-compact__thumb" radius="var(--radius-sm)" />
        <div className="k-compact__body">
          <Text size="base" weight={500} clamp={1} className="k-compact__title">
            {title}
          </Text>
          {showStatus && status && (
            <span className="k-compact__statuslabel" style={{ color: status.color }}>
              {status.label}
            </span>
          )}
        </div>
        {inList && !hideEpCaption && (
          <span className="k-compact__ep">
            {watched}/{total ?? "?"}
          </span>
        )}
        {status && (
          <span className="k-compact__statusicon" aria-label={status.label} title={status.label} style={{ color: status.color }}>
            <Icon icon={status.icon} size={14} weight="fill" />
          </span>
        )}
        <span className="k-compact__score">
          {entry?.score != null ? formatScore(entry.score) : ""}
        </span>
        {inList && entry && (
          <SeasonBar entries={[entry]} size="row" className="k-compact__seasonbar" />
        )}
      </article>
      {sheet}
    </>
  );
}

// Memoized: the collection re-renders on every scroll frame as the virtual
// window shifts. Without this, every visible card re-runs its store selectors
// and hooks each frame, which is the main source of scroll jank on long lists.
export const AnimeCard = memo(AnimeCardImpl);
