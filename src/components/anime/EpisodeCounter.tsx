import { useEffect, useRef, useState } from "react";
import { Minus, Plus, X } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { useEpisodeIncrement } from "@/hooks/useEpisodeIncrement";
import { useListStore } from "@/lib/store/listStore";

interface EpisodeCounterProps {
  anilistId: number;
  watched: number;
  total: number | null;
  /** Fires when a commit first brings watched up to the total episode. */
  onReachedTotal?: () => void;
  size?: "md" | "lg";
}

export function EpisodeCounter({
  anilistId,
  watched,
  total,
  onReachedTotal,
  size = "md",
}: EpisodeCounterProps) {
  const setEpisodes = useListStore((s) => s.setEpisodes);
  const { increment, cancel, isPending, displayEp } = useEpisodeIncrement(
    anilistId,
    watched,
    total,
  );

  // Direct entry: tapping the number turns it into a numeric field, because
  // incrementing your way to episode 700 of a long-runner is not a plan.
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState("");
  const editRef = useRef<HTMLInputElement>(null);

  const prevWatched = useRef(watched);
  useEffect(() => {
    if (
      total != null &&
      watched >= total &&
      prevWatched.current < total &&
      onReachedTotal
    ) {
      onReachedTotal();
    }
    prevWatched.current = watched;
  }, [watched, total, onReachedTotal]);

  useEffect(() => {
    if (editing) editRef.current?.select();
  }, [editing]);

  const atMax = total != null && displayEp >= total;
  const atMin = displayEp <= 0;

  const onMinus = () => {
    const target = Math.max(0, displayEp - 1);
    cancel();
    void setEpisodes(anilistId, target);
  };

  const beginEdit = () => {
    setDraft(String(displayEp));
    setEditing(true);
  };

  const commitEdit = () => {
    setEditing(false);
    const n = parseInt(draft, 10);
    if (!Number.isFinite(n)) return;
    // Clamp to what exists; an unknown total only bounds at zero.
    const target = Math.max(0, total != null ? Math.min(n, total) : n);
    if (target === displayEp) return;
    cancel();
    void setEpisodes(anilistId, target);
  };

  return (
    <div className={`k-epcounter k-epcounter--${size}`}>
      <button
        type="button"
        className="k-epcounter__btn"
        onClick={onMinus}
        disabled={atMin}
        aria-label="Remove one episode"
      >
        <Icon icon={Minus} size={size === "lg" ? 20 : 18} />
      </button>

      <span className="k-epcounter__value">
        {editing ? (
          <input
            ref={editRef}
            className="k-epcounter__edit"
            type="text"
            inputMode="numeric"
            pattern="[0-9]*"
            value={draft}
            onChange={(e) => setDraft(e.target.value.replace(/\D/g, ""))}
            onBlur={commitEdit}
            onKeyDown={(e) => {
              if (e.key === "Enter") commitEdit();
              if (e.key === "Escape") setEditing(false);
            }}
            aria-label="Set episode number"
          />
        ) : (
          <button
            // Remounts on each change so the stamp animation replays: logging an
            // episode presses the number in like an ink stamp.
            key={displayEp}
            type="button"
            className="k-epcounter__num k-stamped"
            style={isPending ? { color: "var(--color-accent)" } : undefined}
            onClick={beginEdit}
            aria-label={`Watched ${displayEp} episodes. Tap to type a number`}
          >
            {displayEp}
          </button>
        )}
        <span className="k-epcounter__total"> / {total ?? "?"}</span>
        {isPending && !editing && (
          <button
            type="button"
            className="k-epcounter__cancel"
            onClick={cancel}
            aria-label="Cancel pending episode updates"
          >
            <Icon icon={X} size={14} />
          </button>
        )}
      </span>

      <button
        type="button"
        className="k-epcounter__btn k-epcounter__btn--plus"
        onClick={increment}
        disabled={atMax}
        aria-label="Add one episode"
      >
        <Icon icon={Plus} size={size === "lg" ? 20 : 18} />
      </button>
    </div>
  );
}
