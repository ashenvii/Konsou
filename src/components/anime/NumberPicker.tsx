import { useMemo } from "react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { preferredTitle } from "@/lib/format";
import { useListStore, UP_NEXT_CAP } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";

interface NumberPickerProps {
  open: boolean;
  onClose: () => void;
  /** The entry that carries the card's number (one per card, never the whole
   *  franchise: stamping a group would write a row per season for one tap). */
  anilistId: number | null;
}

/**
 * Move a planned title to a position in the watch order.
 *
 * The order is a dense 1..N queue, so a number is a POSITION, not a label:
 * picking #3 puts this title third and shifts the rest, and no gaps are ever
 * left. Only real positions are offered (1..N for a title already in the order,
 * 1..N+1 when inserting a new one), because an order of five has no tenth slot.
 */
export function NumberPicker({ open, onClose, anilistId }: NumberPickerProps) {
  const entries = useListStore((s) => s.entries);
  const setPlanNumber = useListStore((s) => s.setPlanNumber);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const entry = anilistId != null ? entries.find((e) => e.anilist_id === anilistId) : null;

  /** The order as it stands, so each position can show who sits there now. */
  const ordered = useMemo(
    () =>
      entries
        .filter((e) => e.status === "plan_to_watch" && e.plan_rank != null)
        .sort((a, b) => (a.plan_rank ?? 0) - (b.plan_rank ?? 0)),
    [entries],
  );

  if (!entry) return null;

  const current = entry.plan_rank; // 1-based position, or null when not in the order
  const title = preferredTitle(
    { romaji: entry.title_romaji, english: entry.title_english, native: entry.title_native },
    titleLanguage,
  );
  const nameOf = (e: (typeof ordered)[number]) =>
    preferredTitle(
      { romaji: e.title_romaji, english: e.title_english, native: e.title_native },
      titleLanguage,
    );

  // Already in the order: N positions to move between. Not yet: one extra slot
  // to append, unless the queue is already full.
  const inOrder = current != null;
  const slots = inOrder
    ? ordered.length
    : Math.min(ordered.length + 1, UP_NEXT_CAP);

  const pick = (n: number) => {
    if (current !== n) void setPlanNumber(entry.anilist_id, n);
    onClose();
  };

  return (
    <BottomSheet open={open} onClose={onClose} title="" ariaLabel={`Watch order for ${title}`}>
      <div className="k-numpick">
        <p className="k-numpick__for">{title}</p>

        <div className="k-numpick__grid">
          {Array.from({ length: slots }, (_, i) => i + 1).map((n) => {
            // Who sits at this position now. When this title is already in the
            // order it occupies a slot, so the occupant of position n is read
            // from the list as the user currently sees it.
            const occupant = ordered[n - 1];
            const mine = current === n;
            const occupantName =
              occupant && occupant.anilist_id !== entry.anilist_id ? nameOf(occupant) : null;
            return (
              <button
                key={n}
                type="button"
                className={`k-numpick__slot${mine ? " k-numpick__slot--mine" : ""}`}
                onClick={() => pick(n)}
                aria-pressed={mine}
                aria-label={
                  mine
                    ? `Position ${n}, where this title is now`
                    : occupantName
                      ? `Move to position ${n}, currently ${occupantName}`
                      : `Move to position ${n}`
                }
              >
                <span className="k-numpick__n">{n}</span>
                {occupantName && <span className="k-numpick__holder">{occupantName}</span>}
              </button>
            );
          })}
        </div>

        {current != null && (
          <button
            type="button"
            className="k-numpick__clear"
            onClick={() => {
              void setPlanNumber(entry.anilist_id, null);
              onClose();
            }}
          >
            Remove from order
          </button>
        )}
      </div>
    </BottomSheet>
  );
}
