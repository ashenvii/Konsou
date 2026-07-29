import { useEffect, useMemo, useState } from "react";
import { ChevronRight, Minus, Plus, Star, Trash2 } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { EpisodeCounter } from "./EpisodeCounter";
import { TagPicker } from "./TagPicker";
import { statusMeta } from "./statusMeta";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Icon } from "@/components/ui/Icon";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { collectHashtags } from "@/lib/hashtags";
import { getDisabledStatuses } from "@/lib/statusValidation";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { LIST_STATUSES } from "@/types/list";

interface QuickMenuProps {
  open: boolean;
  onClose: () => void;
  anilistId: number;
  /** Opens the full detail page. Omitted when already there. */
  onOpenDetails?: () => void;
}

/**
 * One sheet for everything you do to a tracked entry.
 *
 * Before this, the same job was split across four sheets that looked and
 * behaved differently depending on where you tapped: StatusSheet for status,
 * EditSheet (reachable only through a control labelled "Edit score") for score,
 * dates and notes, FranchiseSheet for franchise members. Same intent, three
 * different answers, which is why the app felt like several iterations stitched
 * together.
 *
 * Everything here commits immediately, so there is no Save button to hunt for
 * and no draft to lose: status, episodes and score are single taps that the
 * store already guards and can undo. The note is the one exception, because
 * writing prose one keystroke at a time would mean a write per character; it
 * commits when the field loses focus or the sheet closes.
 */
export function QuickMenu({ open, onClose, anilistId, onOpenDetails }: QuickMenuProps) {
  const entry = useListStore((s) => s.map[anilistId]);
  const entries = useListStore((s) => s.entries);
  const patch = useListStore((s) => s.patch);
  const updateStatus = useListStore((s) => s.updateStatus);
  const setScore = useListStore((s) => s.setScore);
  const remove = useListStore((s) => s.remove);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [noteDraft, setNoteDraft] = useState("");

  // Re-seed whenever the sheet opens or the stored note changes underneath us
  // (a tag added through the picker commits and flows back through here).
  useEffect(() => {
    if (!open) return;
    setNoteDraft(entry?.notes ?? "");
  }, [open, anilistId, entry?.notes]);

  const tagVocabulary = useMemo(
    () => collectHashtags(entries.map((e) => e.notes)),
    [entries],
  );

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
  const disabled = getDisabledStatuses(entry.airing_status);

  const commitNote = (text: string) => {
    const value = text.trim() || null;
    if ((entry.notes ?? null) !== value) void patch(anilistId, { notes: value });
  };

  const onTagsChange = (next: string) => {
    setNoteDraft(next);
    commitNote(next);
  };

  const close = () => {
    commitNote(noteDraft);
    onClose();
  };

  const score = entry.score;
  const stepScore = (delta: number) => {
    const next = Math.max(1, Math.min(10, (score ?? 5) + delta));
    void setScore(anilistId, next);
  };

  return (
    // The sheet's title feeds the dialog's aria-label; an empty one leaves the
    // modal with no accessible name. The heading inside is the cover + title
    // block, so name it after the entry rather than showing a second header.
    <BottomSheet open={open} onClose={close} title="" ariaLabel={title} dock modeless>
      <div className="k-qm">
        <header className="k-qm__head">
          <div className="k-qm__cover">
            <AnimeCover src={cover} alt={title} decorative radius="var(--radius-md)" />
          </div>
          <div className="k-qm__ident">
            <h2 className="k-qm__title">{title}</h2>
            {onOpenDetails && (
              <button
                type="button"
                className="k-qm__details"
                onClick={() => {
                  commitNote(noteDraft);
                  onOpenDetails();
                }}
              >
                Open details
                <Icon icon={ChevronRight} size={14} />
              </button>
            )}
          </div>
        </header>

        <section className="k-qm__section">
          <h3 className="k-qm__label">Progress</h3>
          <EpisodeCounter
            anilistId={anilistId}
            watched={entry.episodes_watched}
            total={entry.total_episodes}
            size="lg"
          />
        </section>

        <section className="k-qm__section">
          <h3 className="k-qm__label">Status</h3>
          <div className="k-status-grid">
            {LIST_STATUSES.map((s) => {
              const meta = statusMeta(s);
              const active = s === entry.status;
              const off = disabled.has(s);
              return (
                <button
                  key={s}
                  type="button"
                  className={`k-status-option${active ? " k-status-option--active" : ""}${off ? " k-status-option--disabled" : ""}`}
                  style={active ? { borderColor: meta.color } : undefined}
                  disabled={off}
                  aria-disabled={off}
                  aria-pressed={active}
                  title={off ? "Not available — hasn't aired yet" : undefined}
                  onClick={() => {
                    if (off) return;
                    void updateStatus(anilistId, s);
                  }}
                >
                  <Icon
                    icon={meta.icon}
                    size={24}
                    weight={active ? "fill" : "regular"}
                    color={meta.color}
                  />
                  <span>{meta.label}</span>
                </button>
              );
            })}
          </div>
          {entry.status === "not_interested" && (
            <p className="k-status-lockhint">
              Muted, so it won't show on your list or in schedules and alerts.
              Pick a status to bring it back, or tap Not Interested again to
              un-mute.
            </p>
          )}
        </section>

        <section className="k-qm__section">
          {/* Score stays optional: adding a title never requires rating it. */}
          <h3 className="k-qm__label">Score</h3>
          <div className="k-qm__score">
            <button
              type="button"
              className="k-qm__stepbtn"
              onClick={() => stepScore(-1)}
              disabled={score == null || score <= 1}
              aria-label="Lower score"
            >
              <Icon icon={Minus} size={18} />
            </button>
            <span className="k-qm__scoreval">
              <Icon
                icon={Star}
                size={16}
                weight={score != null ? "fill" : "regular"}
                color="var(--color-warning)"
              />
              {score ?? "—"}
            </span>
            <button
              type="button"
              className="k-qm__stepbtn"
              onClick={() => stepScore(1)}
              disabled={score != null && score >= 10}
              aria-label="Raise score"
            >
              <Icon icon={Plus} size={18} />
            </button>
            {score != null && (
              <button
                type="button"
                className="k-qm__clear"
                onClick={() => void setScore(anilistId, null)}
              >
                Clear
              </button>
            )}
          </div>
        </section>

        <section className="k-qm__section">
          <h3 className="k-qm__label">Tags</h3>
          <TagPicker
            note={noteDraft}
            onChange={onTagsChange}
            suggestions={tagVocabulary}
          />
        </section>

        <section className="k-qm__section">
          <h3 className="k-qm__label">Notes</h3>
          <textarea
            className="k-qm__notes"
            rows={3}
            value={noteDraft}
            placeholder="Why you stopped, who recommended it, where to pick up…"
            onChange={(e) => setNoteDraft(e.target.value)}
            onBlur={() => commitNote(noteDraft)}
            aria-label="Notes"
          />
        </section>

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
      </div>
    </BottomSheet>
  );
}
