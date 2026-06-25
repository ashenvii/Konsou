import { useEffect, useState } from "react";
import { Minus, Plus } from "lucide-react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Icon } from "@/components/ui/Icon";
import { useListStore } from "@/lib/store/listStore";
import { LIST_STATUSES } from "@/types/list";
import type { ListEntryPatch, ListStatus } from "@/types/list";
import { statusMeta } from "./statusMeta";

interface EditSheetProps {
  open: boolean;
  onClose: () => void;
  anilistId: number;
}

function msToDateInput(ms: number | null): string {
  if (!ms) return "";
  return new Date(ms).toISOString().slice(0, 10);
}
function dateInputToMs(v: string): number | null {
  if (!v) return null;
  const t = new Date(v + "T00:00:00").getTime();
  return Number.isNaN(t) ? null : t;
}

/** Full entry editor. Draft-based: changes only persist on Save. */
export function EditSheet({ open, onClose, anilistId }: EditSheetProps) {
  const entry = useListStore((s) => s.map[anilistId]);
  const patch = useListStore((s) => s.patch);
  const updateStatus = useListStore((s) => s.updateStatus);
  const remove = useListStore((s) => s.remove);

  const [status, setStatus] = useState<ListStatus>("watching");
  const [episodes, setEpisodes] = useState(0);
  const [score, setScore] = useState<number | null>(null);
  const [notes, setNotes] = useState("");
  const [startedAt, setStartedAt] = useState("");
  const [completedAt, setCompletedAt] = useState("");
  const [keyboardOpen, setKeyboardOpen] = useState(false);

  useEffect(() => {
    if (open && entry) {
      setStatus(entry.status);
      setEpisodes(entry.episodes_watched);
      setScore(entry.score);
      setNotes(entry.notes ?? "");
      setStartedAt(msToDateInput(entry.started_at));
      setCompletedAt(msToDateInput(entry.completed_at));
    }
  }, [open, entry]);

  if (!entry) return null;
  const total = entry.total_episodes;

  const save = async () => {
    const p: ListEntryPatch = {
      episodes_watched: episodes,
      score,
      notes: notes.trim() || null,
      started_at: dateInputToMs(startedAt),
      completed_at: dateInputToMs(completedAt),
    };
    await patch(anilistId, p);
    if (status !== entry.status) await updateStatus(anilistId, status);
    onClose();
  };

  const adjust = (d: number) =>
    setEpisodes((e) =>
      Math.max(0, total != null ? Math.min(total, e + d) : e + d),
    );

  return (
    <BottomSheet open={open} onClose={onClose} dismissable={!keyboardOpen}>
      <div className="k-edit__header">
        <button type="button" className="k-edit__cancel" onClick={onClose}>
          Cancel
        </button>
        <span className="k-edit__heading">Edit entry</span>
        <button type="button" className="k-edit__save" onClick={save}>
          Save
        </button>
      </div>

      <div className="k-status-grid">
        {LIST_STATUSES.map((s) => {
          const meta = statusMeta(s);
          const active = s === status;
          return (
            <button
              key={s}
              type="button"
              className={`k-status-option${active ? " k-status-option--active" : ""}`}
              style={active ? { borderColor: meta.color } : undefined}
              onClick={() => setStatus(s)}
            >
              <Icon
                icon={meta.icon}
                size={22}
                weight={active ? "fill" : "regular"}
                color={meta.color}
              />
              <span>{meta.label}</span>
            </button>
          );
        })}
      </div>

      <div className="k-edit__row">
        <label className="k-edit__label">Episodes</label>
        <div className="k-edit__stepper">
          <button
            type="button"
            onClick={() => adjust(-1)}
            disabled={episodes <= 0}
            aria-label="Remove one episode"
          >
            <Icon icon={Minus} size={18} />
          </button>
          <span className="k-edit__epval">
            {episodes} <span className="k-epcounter__total">/ {total ?? "?"}</span>
          </span>
          <button
            type="button"
            onClick={() => adjust(1)}
            disabled={total != null && episodes >= total}
            aria-label="Add one episode"
          >
            <Icon icon={Plus} size={18} />
          </button>
        </div>
      </div>

      <div className="k-edit__row">
        <label className="k-edit__label" htmlFor="k-edit-score">
          Score {score != null ? score : "—"}
        </label>
        <div className="k-edit__score">
          <input
            id="k-edit-score"
            type="range"
            min={1}
            max={10}
            step={0.5}
            value={score ?? 1}
            onChange={(e) => setScore(Number(e.target.value))}
          />
          {score != null && (
            <button
              type="button"
              className="k-edit__clear"
              onClick={() => setScore(null)}
            >
              Clear
            </button>
          )}
        </div>
      </div>

      <div className="k-edit__dates">
        <div className="k-edit__row k-edit__row--col">
          <label className="k-edit__label" htmlFor="k-edit-start">
            Started
          </label>
          <input
            id="k-edit-start"
            type="date"
            className="k-edit__date"
            value={startedAt}
            onChange={(e) => setStartedAt(e.target.value)}
          />
        </div>
        <div className="k-edit__row k-edit__row--col">
          <label className="k-edit__label" htmlFor="k-edit-end">
            Finished
          </label>
          <input
            id="k-edit-end"
            type="date"
            className="k-edit__date"
            value={completedAt}
            onChange={(e) => setCompletedAt(e.target.value)}
          />
        </div>
      </div>

      <div className="k-edit__row k-edit__row--col">
        <label className="k-edit__label" htmlFor="k-edit-notes">
          Notes
        </label>
        <textarea
          id="k-edit-notes"
          className="k-edit__notes"
          rows={3}
          value={notes}
          placeholder="Private notes…"
          onChange={(e) => setNotes(e.target.value)}
          onFocus={() => setKeyboardOpen(true)}
          onBlur={() => setKeyboardOpen(false)}
        />
      </div>

      <button
        type="button"
        className="k-status-remove"
        onClick={() => {
          remove(anilistId);
          onClose();
        }}
      >
        Remove from list
      </button>
    </BottomSheet>
  );
}
