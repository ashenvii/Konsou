import { Star, X } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { ItemSurface } from "@/components/ui/ItemSurface";
import { useListStore } from "@/lib/store/listStore";

/**
 * Pick a score, out of ten.
 *
 * A peer surface opened from the verb rail, the same way the status picker is,
 * rather than a section inside the quick menu. Score was three controls and a
 * label in the panel body — a minus, a value, a plus, a Clear, under a heading
 * that said "Score" — to set a number with ten possible values. Stepping to 9
 * from nothing was five taps.
 *
 * Ten targets, one tap. The whole scale is visible, which is the other thing
 * the stepper could not do: you could see the number you were on but never the
 * range it sat in.
 *
 * Score stays optional everywhere. Adding a title never requires rating it, so
 * Clear is a first-class action rather than an undo.
 */
export function ScorePicker({
  open,
  onClose,
  anilistId,
  title,
  anchor = null,
}: {
  open: boolean;
  onClose: () => void;
  anilistId: number | null;
  title: string;
  anchor?: HTMLElement | null;
}) {
  const setScore = useListStore((s) => s.setScore);
  const entry = useListStore((s) => (anilistId != null ? s.map[anilistId] : null));

  if (anilistId == null || !entry) return null;
  const current = entry.score;

  const pick = (n: number | null) => {
    if (current !== n) void setScore(anilistId, n);
    onClose();
  };

  return (
    <ItemSurface
      anchor={anchor}
      open={open}
      onClose={onClose}
      ariaLabel={`Score for ${title}`}
      size={{ width: 300, maxHeight: 320 }}
    >
      <div className="k-score">
        <h3 className="k-score__label">Score</h3>
        <div className="k-score__grid" role="group" aria-label="Score out of ten">
          {Array.from({ length: 10 }, (_, i) => i + 1).map((n) => {
            const mine = current === n;
            return (
              <button
                key={n}
                type="button"
                className={`k-score__n${mine ? " k-score__n--mine" : ""}`}
                onClick={() => pick(n)}
                aria-pressed={mine}
                aria-label={`${n} out of 10`}
              >
                {n}
              </button>
            );
          })}
        </div>
        {current != null && (
          <button type="button" className="k-score__clear" onClick={() => pick(null)}>
            <Icon icon={X} size={14} />
            Clear the score
          </button>
        )}
        {current == null && (
          <p className="k-score__none">
            <Icon icon={Star} size={13} />
            Not scored. It never has to be.
          </p>
        )}
      </div>
    </ItemSurface>
  );
}
