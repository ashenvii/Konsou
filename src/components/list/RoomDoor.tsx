import { AnimeCover } from "@/components/anime/AnimeCover";
import { getCoverUrl } from "@/lib/format";
import type { FranchiseGroup } from "@/lib/franchise/grouping";

/**
 * A door into one of the two rooms people actually live in: Planned and
 * Completed. Not a summary card — the whole plate is one control, and what it
 * shows is the room itself: how much is in there, the covers currently at the
 * front of it, and the one line that answers "what's the state of this room"
 * (what's next / what you finished last).
 *
 * The pair are the same size on purpose. Neither room is the promoted one:
 * planning and finishing are the two halves of the same habit.
 *
 * The room's name is a button stretched across the plate (same contract as the
 * queue card), so the whole door is clickable by pointer while staying one
 * plain control to a keyboard or a screen reader.
 */
export function RoomDoor({
  label,
  count,
  groups,
  footLabel,
  footValue,
  emptyLine,
  onOpen,
}: {
  /** The room's name, set as a mono catalogue label. */
  label: string;
  count: number;
  /** Whose covers are mounted on the door — the front of the room. */
  groups: FranchiseGroup[];
  /** Mono caption for the bottom line ("next", "last"). */
  footLabel: string;
  /** The title that caption points at. */
  footValue: string | null;
  /** Shown instead of the foot line while the room is empty. */
  emptyLine: string;
  onOpen: () => void;
}) {
  const covers = groups
    .slice(0, 3)
    .map((g) => ({
      id: g.rootId,
      src: getCoverUrl({ medium: g.displayEntry.cover_url ?? undefined }),
    }))
    .filter((c) => !!c.src);

  return (
    <article className={`k-door${count === 0 ? " k-door--empty" : ""}`}>
      {/* Photo-corners: the plate is mounted on the table, not floating. */}
      <span className="k-door__corners" aria-hidden>
        <i /><i /><i /><i />
      </span>

      <div className="k-door__head">
        <button type="button" className="k-door__open" onClick={onOpen}>
          {label}
        </button>
        <span className="k-door__count" aria-hidden>
          {count}
        </span>
        {/* The count is decorative next to the button's own label, which already
            reads it out in words. */}
        <span className="sr-only">
          {count === 0
            ? "empty"
            : `${count} ${count === 1 ? "title" : "titles"}`}
        </span>
      </div>

      <div className="k-door__stack" aria-hidden>
        {covers.map((c, i) => (
          <div className="k-door__mount" key={c.id} style={{ zIndex: 3 - i }}>
            <AnimeCover src={c.src} alt="" decorative radius="var(--radius-plate)" />
          </div>
        ))}
      </div>

      <p className="k-door__foot">
        {count === 0 ? (
          <span className="k-door__emptyline">{emptyLine}</span>
        ) : (
          <>
            <span className="k-door__footlabel">{footLabel}</span>
            <span className="k-door__foottitle">{footValue}</span>
          </>
        )}
      </p>
    </article>
  );
}
