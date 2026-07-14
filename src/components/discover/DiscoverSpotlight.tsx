import { useState } from "react";
import type { CSSProperties, MouseEvent } from "react";
import { useNavigate } from "react-router-dom";
import { Check, Plus, Star } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { StatusSheet } from "@/components/anime/StatusSheet";
import { statusMeta } from "@/components/anime/statusMeta";
import { Icon } from "@/components/ui/Icon";
import { getDisabledStatuses } from "@/lib/statusValidation";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { formatLabel, getCoverUrl, preferredTitle } from "@/lib/format";
import type { AnimeSummary } from "@/types/anime";
import type { ListStatus } from "@/types/list";

interface DiscoverSpotlightProps {
  media: AnimeSummary;
}

const AIRING_LABEL: Record<string, string> = {
  RELEASING: "Airing",
  FINISHED: "Finished",
  NOT_YET_RELEASED: "Upcoming",
  CANCELLED: "Cancelled",
  HIATUS: "On hiatus",
};

/**
 * The landing's one committed moment: a single featured title. Cover art stays
 * the hero — the poster floats sharp over a darkened banner, so the art reads
 * even when the banner is busy. Everything below it on the page is quieter.
 * One title, never a rotating carousel (carousels bury the art and test poorly).
 */
export function DiscoverSpotlight({ media }: DiscoverSpotlightProps) {
  const navigate = useNavigate();
  const entry = useListStore((s) => s.map[media.id]);
  const addFromSummary = useListStore((s) => s.addFromSummary);
  const updateStatus = useListStore((s) => s.updateStatus);
  const remove = useListStore((s) => s.remove);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const [sheetOpen, setSheetOpen] = useState(false);

  const inList = !!entry;
  const title = preferredTitle(media.title, titleLanguage);
  const cover = getCoverUrl(media.coverImage);
  const banner = media.bannerImage || null;

  const open = () => navigate(`/anime/${media.id}`, { replace: true });
  const stop = (e: MouseEvent) => e.stopPropagation();

  const onPick = (status: ListStatus) => {
    if (inList) void updateStatus(media.id, status);
    else void addFromSummary(media, status);
  };

  const status = entry ? statusMeta(entry.status) : null;

  const meta = [
    formatLabel(media.format),
    media.status ? AIRING_LABEL[media.status] : null,
    media.seasonYear ? String(media.seasonYear) : null,
  ].filter(Boolean);

  const genres = (media.genres ?? []).slice(0, 3);

  return (
    <>
      <article
        className="k-spotlight"
        onClick={open}
        style={media.coverImage?.color ? ({ "--spot-tint": media.coverImage.color } as CSSProperties) : undefined}
      >
        <div
          className={`k-spotlight__bg${banner ? "" : " k-spotlight__bg--cover"}`}
          style={{ backgroundImage: banner ? `url("${banner}")` : cover ? `url("${cover}")` : undefined }}
          aria-hidden
        />
        <div className="k-spotlight__scrim" aria-hidden />

        <div className="k-spotlight__body">
          <div className="k-spotlight__poster">
            <AnimeCover src={cover} alt={title} decorative radius="var(--radius-md)" />
          </div>

          <div className="k-spotlight__text">
            <h2 className="k-spotlight__title">{title}</h2>

            <div className="k-spotlight__meta">
              {media.averageScore != null && (
                <span className="k-spotlight__score">
                  <Icon icon={Star} size={12} fill />
                  {media.averageScore}%
                </span>
              )}
              {meta.map((m) => (
                <span key={m} className="k-spotlight__dot">
                  {m}
                </span>
              ))}
            </div>

            {genres.length > 0 && (
              <div className="k-spotlight__genres">
                {genres.map((g) => (
                  <span key={g} className="k-spotlight__genre">
                    {g}
                  </span>
                ))}
              </div>
            )}

            <div className="k-spotlight__actions" onClick={stop}>
              <button
                type="button"
                className={`k-spotlight__add${inList ? " k-spotlight__add--in" : ""}`}
                onClick={() => setSheetOpen(true)}
                style={
                  inList && status ? ({ "--card-status": status.color } as CSSProperties) : undefined
                }
              >
                <Icon icon={inList ? Check : Plus} size={16} strokeWidth={inList ? 3 : 2.4} />
                {inList ? (status?.label ?? "In list") : "Add to list"}
              </button>
              <button type="button" className="k-spotlight__details" onClick={open}>
                Details
              </button>
            </div>
          </div>
        </div>
      </article>

      <StatusSheet
        open={sheetOpen}
        onClose={() => setSheetOpen(false)}
        title={inList ? "Change status" : `Add "${title}"`}
        current={entry?.status}
        onPick={onPick}
        onRemove={inList ? () => remove(media.id) : undefined}
        disabledStatuses={getDisabledStatuses(entry?.airing_status ?? media.status ?? null)}
      />
    </>
  );
}

/** Placeholder shown while the spotlight source query is still loading. */
export function SpotlightSkeleton() {
  return (
    <div className="k-spotlight k-spotlight--skel" aria-hidden>
      <div className="k-spotlight__body">
        <div className="k-spotlight__poster k-lane__skel" />
        <div className="k-spotlight__text">
          <div className="k-spotlight__skelline k-spotlight__skelline--title" />
          <div className="k-spotlight__skelline k-spotlight__skelline--meta" />
          <div className="k-spotlight__skelline k-spotlight__skelline--btn" />
        </div>
      </div>
    </div>
  );
}
