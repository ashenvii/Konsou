import type { CSSProperties } from "react";
import { Icon } from "@/components/ui/Icon";
import { statusMeta } from "./statusMeta";
import type { ListStatus } from "@/types/list";

/**
 * The field-note stamp: what a card says about where you are with a title.
 *
 * One shape in one corner for every state. Before this there were six markers —
 * a pill, a spinning pill, a circular seal, a hanging bookmark, a diagonal
 * ribbon bleeding off the corner, and a breathing circle parked over the middle
 * of the cover — each a different shape in a different place. That was a
 * deliberate old choice ("the grid never looks like one template recoloured"),
 * and it is the wrong one for this world: the shapes it used are the ones the
 * design contract retired, and the reader had to learn six marks instead of
 * reading one.
 *
 * Colorblind-safe by construction: hue AND glyph AND word, never hue alone.
 * The word is real text, so a screen reader gets the state for free.
 */

/** Short enough for the corner of a 150px poster. Exported so every surface
 *  that shows a status inline says the same word: a card reading "PLAN" beside
 *  a row reading "PLAN TO WATCH" is two vocabularies for one thing. */
export const STAMP_WORD: Record<ListStatus, string> = {
  watching: "Watching",
  rewatching: "Rewatch",
  completed: "Done",
  plan_to_watch: "Plan",
  on_hold: "Paused",
  dropped: "Dropped",
  not_interested: "Muted",
};

export function StatusStamp({ status }: { status: ListStatus }) {
  const meta = statusMeta(status);
  return (
    <span
      className={`k-stamp k-stamp--${status}`}
      style={{ "--stamp": meta.color } as CSSProperties}
    >
      <Icon icon={meta.icon} size={11} className="k-stamp__glyph" />
      {STAMP_WORD[status]}
    </span>
  );
}
