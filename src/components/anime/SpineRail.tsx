import type { ListStatus } from "@/types/list";

/**
 * The left spine of a franchise / related row. It does two jobs in one gutter:
 *
 *  - Order: a continuous vertical line threads every row, so the list reads as
 *    one path top to bottom instead of rows that happen to be numbered. Main
 *    entries sit ON the line; extras (OVAs, movies, side stories) branch off it.
 *  - Progress: the node's fill encodes where you are without reading a word.
 *    Filled = watched, ringed = watching now, hollow = planned, dashed = not on
 *    your list. A glance down the spine answers "how far am I", which a static
 *    guide site can never show.
 *
 * The release year rides the same gutter, turned a quarter-turn so it rests
 * against the cover. `first` / `last` cap the line at the end rows so it starts
 * and stops at a node instead of running off into the padding.
 */
export type SpineState = "done" | "active" | "planned" | "untracked";

export function spineStateForStatus(
  status: ListStatus | null | undefined,
): SpineState {
  if (!status || status === "not_interested") return "untracked";
  if (status === "completed") return "done";
  if (status === "watching" || status === "rewatching") return "active";
  return "planned"; // plan_to_watch, on_hold, dropped
}

export function SpineRail({
  year,
  state,
  variant = "main",
  first = false,
  last = false,
}: {
  year: number | null;
  state: SpineState;
  /** Main-story entries sit on the line; extras branch off it. */
  variant?: "main" | "extra";
  first?: boolean;
  last?: boolean;
}) {
  return (
    <span className="k-spine">
      <span
        className={`k-spine__line${first ? " k-spine__line--first" : ""}${last ? " k-spine__line--last" : ""}`}
        aria-hidden
      />
      {variant === "extra" && <span className="k-spine__branch" aria-hidden />}
      <span
        className={`k-spine__node k-spine__node--${state}${variant === "extra" ? " k-spine__node--branch" : ""}`}
        aria-hidden
      />
      {/* Year stays readable to assistive tech; only the glyphs are rotated. */}
      <span className={`k-spine__year${year == null ? " k-spine__year--none" : ""}`}>
        {year ?? ""}
      </span>
    </span>
  );
}
