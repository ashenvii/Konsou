import { useState } from "react";
import type { CSSProperties, MouseEvent } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, Star } from "@phosphor-icons/react";
import { AnimeCover } from "./AnimeCover";
import { StatusSheet } from "./StatusSheet";
import { statusMeta } from "./statusMeta";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { useEpisodeIncrement } from "@/hooks/useEpisodeIncrement";
import { useListStore } from "@/lib/store/listStore";
import {
  formatLabel,
  formatScore,
  getCoverUrl,
  preferredTitle,
  secondaryTitle,
} from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AnimeSummary } from "@/types/anime";
import type { ListStatus, ViewMode } from "@/types/list";

interface AnimeCardProps {
  media: AnimeSummary;
  view: ViewMode;
  showStatus?: boolean;
}

export function AnimeCard({ media, view, showStatus = false }: AnimeCardProps) {
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
  const title = preferredTitle(media.title, titleLanguage);
  const subtitle = secondaryTitle(media.title, titleLanguage);
  const cover = getCoverUrl(media.coverImage);
  const total = entry?.total_episodes ?? media.episodes ?? null;
  const watched = entry?.episodes_watched ?? 0;
  const status = entry ? statusMeta(entry.status) : null;

  const { increment, pending } = useEpisodeIncrement(media.id, watched, total);

  const open = () => navigate(`/anime/${media.id}`);
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
    />
  );

  const progressPct =
    inList && total ? Math.min(100, (watched / total) * 100) : 0;

  // ── Grid ─────────────────────────────────────────────────
  if (view === "grid") {
    return (
      <>
        <article
          className={`k-card k-card--grid${inList ? " k-card--inlist" : ""}`}
          style={inList && status ? { "--card-status": status.color } as CSSProperties : undefined}
          onClick={open}
        >
          <div className="k-card__cover">
            <AnimeCover src={cover} alt={title} radius="0" />
            <div className="k-card__scrim" />
            {status && (
              <span className="k-card__statusicon" aria-label={status.label} title={status.label} style={{ color: status.color }}>
                <Icon icon={status.icon} size={16} weight="fill" />
              </span>
            )}
            {entry?.score != null && (
              <span className="k-card__score">
                <Icon icon={Star} size={11} weight="fill" />
                {formatScore(entry.score)}
              </span>
            )}
            <div className="k-card__footer">
              <Text size="sm" weight={600} clamp={2} className="k-card__title">
                {title}
              </Text>
              {subtitle && (
                <span className="k-card__subtitle" title={subtitle}>
                  {subtitle}
                </span>
              )}
              <div className="k-card__footermeta">
                {inList && (
                  <span className="k-card__epcaption">
                    {watched}/{total ?? "?"}
                  </span>
                )}
                {dubLabel && (
                  <span className={`k-card__dubtag${dubLabel === "DUB+SUB" ? " k-card__dubtag--dub" : " k-card__dubtag--sub"}`}>
                    {dubLabel}
                  </span>
                )}
              </div>
              {showStatus && status && (
                <span className="k-card__statuslabel" style={{ color: status.color }}>
                  {status.label}
                </span>
              )}
            </div>
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
            {inList && total != null && (
              <div className="k-card__progress">
                <div
                  className="k-card__progress-fill"
                  style={{ width: `${progressPct}%` }}
                />
              </div>
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
          <AnimeCover src={cover} alt={title} decorative className="k-row__thumb" />
          <div className="k-row__main">
            <Text size="base" weight={600} clamp={1}>
              {title}
            </Text>
            {subtitle && (
              <Text size="xs" color="tertiary" clamp={1}>
                {subtitle}
              </Text>
            )}
            {meta && (
              <Text size="xs" color="secondary" clamp={1}>
                {meta}
              </Text>
            )}
          </div>
          <div className="k-row__status">
            {status && (
              <span className="k-row__statusinline" style={{ color: status.color }}>
                <Icon icon={status.icon} size={14} weight="fill" />
                <span className="k-row__statuslabel">{status.label}</span>
              </span>
            )}
          </div>
          <div className="k-row__ep">
            {inList ? `${watched} / ${total ?? "?"}` : ""}
          </div>
          <div className="k-row__score">
            {entry?.score != null ? formatScore(entry.score) : ""}
          </div>
          <button
            type="button"
            className="k-row__action"
            onClick={quickAction}
            aria-label={inList ? "Add one episode" : "Add to list"}
          >
            {inList ? (pending > 0 ? `+${pending}` : "+1") : <Icon icon={Plus} size={18} />}
          </button>
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
        <AnimeCover src={cover} alt={title} decorative className="k-compact__thumb" />
        <Text size="base" weight={500} clamp={1} className="k-compact__title">
          {title}
        </Text>
        {inList && (
          <span className="k-compact__ep">
            {watched}/{total ?? "?"}
          </span>
        )}
        {showStatus && status && (
          <span className="k-compact__status" style={{ color: status.color }}>
            {status.label}
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
      </article>
      {sheet}
    </>
  );
}
