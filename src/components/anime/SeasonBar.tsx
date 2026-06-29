import type { CSSProperties } from "react";
import { statusMeta } from "./statusMeta";
import type { AnimeListEntry } from "@/types/list";

/** Per-season fill fraction + the colour that season's status owns. A completed
 *  season reads full; an unstarted one reads empty; everything else fills to its
 *  watched fraction so the bar tells the whole "where am I in the franchise"
 *  story at a glance. */
export function seasonSegment(e: AnimeListEntry): { pct: number; color: string } {
  const color = statusMeta(e.status).color;
  let pct: number;
  if (e.status === "completed") pct = 100;
  else if (e.total_episodes && e.total_episodes > 0)
    pct = Math.min(100, (e.episodes_watched / e.total_episodes) * 100);
  else pct = e.episodes_watched > 0 ? 12 : 0;
  return { pct, color };
}

interface SeasonBarProps {
  entries: AnimeListEntry[];
  /** Visual size: grid sits thicker, rows stay slim. */
  size?: "grid" | "row";
  className?: string;
}

/**
 * One segment per tracked season, filled and tinted by that season's own status.
 * The umbrella made visible: four chunks, three solid green, one half-blue means
 * "four seasons, three finished, mid-way through the fourth."
 */
export function SeasonBar({ entries, size = "row", className }: SeasonBarProps) {
  return (
    <div
      className={`k-seasonbar k-seasonbar--${size}${className ? ` ${className}` : ""}`}
      aria-hidden
    >
      {entries.map((e) => {
        const { pct, color } = seasonSegment(e);
        return (
          <span
            key={e.anilist_id}
            className="k-seasonbar__seg"
            style={{ "--seg": color } as CSSProperties}
          >
            <span className="k-seasonbar__fill" style={{ width: `${pct}%` }} />
          </span>
        );
      })}
    </div>
  );
}
