import { useEffect, useState } from "react";
import { ChevronRight, Trash2 } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { EpisodeCounter } from "./EpisodeCounter";
import { statusMeta } from "./statusMeta";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Icon } from "@/components/ui/Icon";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { statusBlockReason } from "@/lib/statusValidation";
import { LIST_STATUSES } from "@/types/list";

interface QuickMenuProps {
  open: boolean;
  onClose: () => void;
  anilistId: number;
  /** Jump to the full detail page (notes, dates, relations live there). */
  onOpenDetails?: () => void;
}

/**
 * The single-entry action surface. Tapping any standalone card opens this;
 * every change persists immediately (no Save step). Episode stepping, status,
 * and an optional score all live here; the deeper edit (notes, dates) stays on
 * the detail page. The franchise form is a separate variant that lists members
 * in watch order — this one is the leaf.
 */
export function QuickMenu({ open, onClose, anilistId, onOpenDetails }: QuickMenuProps) {
  const entry = useListStore((s) => s.map[anilistId]);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const updateStatus = useListStore((s) => s.updateStatus);
  const setScore = useListStore((s) => s.setScore);
  const remove = useListStore((s) => s.remove);

  // Score is the one control that drags, so it's held locally and committed on
  // release instead of writing to the DB on every tick.
  const [scoreDraft, setScoreDraft] = useState<number | null>(null);
  useEffect(() => {
    if (open && entry) setScoreDraft(entry.score);
  }, [open, entry?.anilist_id, entry?.score]);

  if (!entry) return null;

  const title = preferredTitle(
    {
      romaji: entry.title_romaji,
      english: entry.title_english,
      native: entry.title_native,
    },
    titleLanguage,
  );
  const cover = getCoverUrl({ medium: entry.cover_url ?? undefined });
  const total = entry.total_episodes;
  const watched = entry.episodes_watched;
  const pct = total ? Math.min(100, (watched / total) * 100) : 0;

  const commitScore = () => {
    if (scoreDraft !== entry.score) setScore(anilistId, scoreDraft);
  };

  return (
    <BottomSheet open={open} onClose={onClose}>
      <div className="k-qm__head">
        <div className="k-qm__cover">
          <AnimeCover src={cover} alt={title} decorative radius="var(--radius-sm)" />
        </div>
        <div className="k-qm__headmain">
          <p className="k-qm__title">{title}</p>
          <p className="k-qm__sub">{total != null ? `${total} episodes` : "Episode count unknown"}</p>
          {onOpenDetails && (
            <button type="button" className="k-qm__details" onClick={onOpenDetails}>
              Open full details
              <Icon icon={ChevronRight} size={14} />
            </button>
          )}
        </div>
      </div>

      <div className="k-qm__progress">
        <div className="k-qm__progresstop">
          <span className="k-qm__label">Episodes watched</span>
          <EpisodeCounter anilistId={anilistId} watched={watched} total={total} />
        </div>
        <div className="k-qm__bar">
          <span style={{ width: `${pct}%` }} />
        </div>
      </div>

      <p className="k-qm__label k-qm__label--section">Status</p>
      <div className="k-status-grid">
        {LIST_STATUSES.map((s) => {
          const meta = statusMeta(s);
          const active = s === entry.status;
          const disabled = !active && !!statusBlockReason(entry.airing_status, s);
          return (
            <button
              key={s}
              type="button"
              className={`k-status-option${active ? " k-status-option--active" : ""}${disabled ? " k-status-option--disabled" : ""}`}
              style={active ? { borderColor: meta.color } : undefined}
              disabled={disabled}
              aria-disabled={disabled}
              title={disabled ? "Not available — hasn't aired yet" : undefined}
              onClick={() => updateStatus(anilistId, s)}
            >
              <Icon icon={meta.icon} size={22} weight={active ? "fill" : "regular"} color={meta.color} />
              <span>{meta.label}</span>
            </button>
          );
        })}
      </div>

      <div className="k-qm__scorerow">
        <span className="k-qm__label">Score {scoreDraft != null ? scoreDraft : "—"}</span>
        <div className="k-qm__score">
          <input
            type="range"
            min={1}
            max={10}
            step={0.5}
            value={scoreDraft ?? 1}
            onChange={(e) => setScoreDraft(Number(e.target.value))}
            onPointerUp={commitScore}
            onKeyUp={commitScore}
            onBlur={commitScore}
            aria-label="Score"
          />
          {scoreDraft != null && (
            <button
              type="button"
              className="k-qm__scoreclear"
              onClick={() => {
                setScoreDraft(null);
                setScore(anilistId, null);
              }}
            >
              Clear
            </button>
          )}
        </div>
      </div>

      <button
        type="button"
        className="k-status-remove"
        onClick={() => {
          remove(anilistId);
          onClose();
        }}
      >
        <Icon icon={Trash2} size={18} color="var(--color-error)" />
        Remove from list
      </button>
    </BottomSheet>
  );
}
