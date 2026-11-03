import { useEffect, useRef, useState } from "react";
import { Minus, Plus, X } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { useEpisodeIncrement } from "@/hooks/useEpisodeIncrement";
import { useListStore } from "@/lib/store/listStore";
import { toast } from "@/lib/store/toastStore";

interface EpisodeCounterProps {
  anilistId: number;
  watched: number;
  total: number | null;
  /** How many episodes actually exist yet, when it differs from `total` — a
   *  still-airing show. Undefined/null means "no tighter ceiling than total,"
   *  which is also what a finished show's own aired count already equals. */
  airedCeiling?: number | null;
  /** Fires when a commit first brings watched up to the total episode. */
  onReachedTotal?: () => void;
  size?: "md" | "lg";
}

export function EpisodeCounter({
  anilistId,
  watched,
  total,
  airedCeiling,
  onReachedTotal,
  size = "md",
}: EpisodeCounterProps) {
  const setEpisodes = useListStore((s) => s.setEpisodes);
  // The real stopping point right now: whichever of "the show's own length"
  // and "how much of it exists yet" is smaller. For a finished show these
  // already agree (aired_episodes settles at the total), so this only ever
  // tightens the ceiling while something is still airing.
  const ceiling =
    total != null
      ? airedCeiling != null
        ? Math.min(total, airedCeiling)
        : total
      : (airedCeiling ?? null);
  const { increment, cancel, isPending, displayEp } = useEpisodeIncrement(
    anilistId,
    watched,
    total,
    {
      ceiling,
      // The accumulator guards before ever calling the store, which is what
      // keeps a burst of taps safe — but it also means a blocked tap on a
      // still-airing show used to do nothing visible at all. This only ever
      // fires while the button is still clickable (see aria-disabled below),
      // so it can never fire for the OTHER reason a "+" goes inert: a
      // finished run with nothing left to log, which needs no explaining.
      onBlocked: () => toast.error("No new episode yet."),
    },
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

  const atMax = ceiling != null && displayEp >= ceiling;
  const atMin = displayEp <= 0;
  // Distinguishes "the show is over" from "nothing new has aired yet" —
  // the same reasoning the Start/Done guards on the plan card explain
  // themselves with, applied here so a stuck "+" doesn't look inert for no
  // reason.
  const airingLimited =
    atMax && airedCeiling != null && (total == null || airedCeiling < total);

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
    // Clamp to what exists; an unknown ceiling only bounds at zero.
    const target = Math.max(0, ceiling != null ? Math.min(n, ceiling) : n);
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
            style={isPending ? { color: "var(--live-ink)" } : undefined}
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
        // A genuinely finished run (atMax and NOT airing-limited) stays
        // natively disabled — there is nothing left to explain. The airing-
        // limited case stays clickable so the tap can say why, instead of a
        // control that looks broken instead of caught-up.
        disabled={atMax && !airingLimited}
        aria-disabled={airingLimited || undefined}
        aria-label={airingLimited ? "No new episode yet" : "Add one episode"}
        title={airingLimited ? "No new episode yet" : undefined}
      >
        <Icon icon={Plus} size={size === "lg" ? 20 : 18} />
      </button>
    </div>
  );
}
