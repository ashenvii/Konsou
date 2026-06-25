import { useEffect, useRef } from "react";
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

  const atMax = total != null && displayEp >= total;
  const atMin = displayEp <= 0;

  const onMinus = () => {
    const target = Math.max(0, displayEp - 1);
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
        <span
          className="k-epcounter__num"
          style={isPending ? { color: "var(--color-accent)" } : undefined}
        >
          {displayEp}
        </span>
        <span className="k-epcounter__total"> / {total ?? "?"}</span>
        {isPending && (
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
