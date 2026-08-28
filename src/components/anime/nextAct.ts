import { Check, Play, Plus } from "lucide-react";
import type { IconComponent } from "@/components/ui/Icon";
import type { AnimeListEntry, ListStatus } from "@/types/list";

/**
 * The one thing to do to this entry next, and what to call it.
 *
 * There are four states here and collapsing any of them loses something real:
 *
 * - **Paused.** The act is to resume, not to log — logging an episode of a show
 *   you said you had stopped watching silently un-pauses it as a side effect.
 * - **Finished.** Every episode is watched. The act is to close it out, and it
 *   has to be offered: `setEpisodes` puts completion in a five-second toast, so
 *   miss the toast and the show sits at max with nothing left to press.
 * - **Caught up.** A currently-airing show whose next episode has not aired.
 *   Nothing to log tonight and nothing to close out either, so this is the one
 *   genuinely inert state.
 * - **Running.** Log the next one.
 *
 * The middle two used to collapse into one "at max" that greyed the control and
 * changed nothing else, which turned the subject of a page into an inert plus
 * with no stated reason.
 *
 * Lives here rather than inside any one surface because the Overview's hero
 * plate, the quick menu's head, and anything else that offers a single act on
 * an entry all have to answer this identically. It was written out by hand in
 * the Overview first; a second copy in the quick menu would be two places to
 * fix the day the rules change.
 */
export interface NextAct {
  /** One or two words naming the state, for a kicker or a label. */
  kicker: string;
  icon: IconComponent;
  /** Solid rather than outlined, for the glyphs that are shapes (Play, Check)
   *  rather than marks (Plus). */
  fill: boolean;
  /** The full sentence a screen reader hears on the control. */
  label: string;
  /** Nothing to do: caught up on an airing show. */
  disabled: boolean;
  /** What pressing it means, resolved by the caller against the store —
   *  "log" takes one episode, the others are a status change. */
  kind: "log" | "resume" | "complete" | "none";
  /** The status to move to, for the two that are a status change. */
  status?: ListStatus;
}

export function nextAct(entry: AnimeListEntry, title: string): NextAct {
  const paused = entry.status === "on_hold";
  const finished =
    entry.total_episodes != null && entry.episodes_watched >= entry.total_episodes;
  // A still-airing show's real ceiling is what has aired, not its eventual
  // total. The store already enforces this; this keeps the control's own
  // disabled state honest with what a press would actually do.
  const ceiling =
    entry.airing_status === "RELEASING" && entry.aired_episodes != null
      ? Math.min(entry.total_episodes ?? entry.aired_episodes, entry.aired_episodes)
      : entry.total_episodes;
  const caughtUp = !finished && ceiling != null && entry.episodes_watched >= ceiling;

  if (paused) {
    return {
      kicker: "Paused",
      icon: Play,
      fill: true,
      label: `Resume watching ${title}`,
      disabled: false,
      kind: "resume",
      status: "watching",
    };
  }
  if (finished) {
    return {
      kicker: "Finished?",
      icon: Check,
      fill: true,
      label: `Mark ${title} complete`,
      disabled: false,
      kind: "complete",
      status: "completed",
    };
  }
  if (caughtUp) {
    return {
      kicker: "Caught up",
      icon: Plus,
      fill: false,
      label: `${title} is caught up, no new episode has aired`,
      disabled: true,
      kind: "none",
    };
  }
  return {
    kicker: "Tonight",
    icon: Plus,
    fill: false,
    label: `Log episode ${entry.episodes_watched + 1} of ${title}`,
    disabled: false,
    kind: "log",
  };
}
