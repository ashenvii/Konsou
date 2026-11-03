import { useMemo } from "react";
import { Check, ListOrdered, X } from "lucide-react";
import { AnimeCover } from "./AnimeCover";
import { Icon } from "@/components/ui/Icon";
import { ItemSurface } from "@/components/ui/ItemSurface";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { useListStore, UP_NEXT_CAP } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";

interface NumberPickerProps {
  open: boolean;
  onClose: () => void;
  /** The entry that carries the card's number (one per card, never the whole
   *  franchise: stamping a group would write a row per season for one tap). */
  anilistId: number | null;
  /** The number badge that was tapped. This used to go straight to a bare
   *  BottomSheet regardless of window size — the one quick menu left on the
   *  old full-width mobile sheet after every other one (QuickMenu,
   *  FranchiseSheet, FilterMenu) moved to ItemSurface's anchored popover on
   *  anything wider than an upright phone. */
  anchor?: HTMLElement | null;
}

/**
 * Move a planned title to a position in the watch order.
 *
 * The order is a dense 1..N queue, so a number is a POSITION, not a label:
 * picking #3 puts this title third and shifts the rest, and no gaps are ever
 * left. Only real positions are offered (1..N for a title already in the order,
 * 1..N+1 when inserting a new one), because an order of five has no tenth slot.
 *
 * It is laid out as the order itself — one row per position, in order, each
 * naming who sits there now — rather than as a grid of bare numbers. A grid of
 * numbers made you translate "slot 7" into "seventh in my list" in your head;
 * the list IS the list, so picking a row is picking a place in it. It shares
 * the quick menu's shell, head block and section labels with QuickMenu and
 * FranchiseSheet, because it is the same kind of thing opened the same way.
 */
export function NumberPicker({ open, onClose, anilistId, anchor = null }: NumberPickerProps) {
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
  const slots = inOrder ? ordered.length : Math.min(ordered.length + 1, UP_NEXT_CAP);

  const pick = (n: number) => {
    if (current !== n) void setPlanNumber(entry.anilist_id, n);
    onClose();
  };

  return (
    <ItemSurface anchor={anchor} open={open} onClose={onClose} ariaLabel={`Watch order for ${title}`}>
      <div className="k-numpick">
        {/* The same identity block every other quick menu opens with: mounted
            cover, species name, one mono line of state. */}
        <header className="k-numpick__head">
          <div className="k-numpick__cover">
            <AnimeCover
              src={getCoverUrl({ medium: entry.cover_url ?? undefined })}
              alt=""
              decorative
              radius="var(--plate-radius)"
            />
          </div>
          <div className="k-numpick__ident">
            <h2 className="k-numpick__title">{title}</h2>
            <p className="k-numpick__state">
              <Icon icon={ListOrdered} size={13} />
              {inOrder ? `Number ${current} of ${ordered.length}` : "Not in the order yet"}
            </p>
          </div>
        </header>

        <section className="k-numpick__section">
          <h3 className="k-numpick__label">
            {inOrder ? "Move to" : "Insert at"}
          </h3>
          <ol
            className="k-numpick__list"
            aria-label={`${slots} watch order ${slots === 1 ? "position" : "positions"}`}
          >
            {Array.from({ length: slots }, (_, i) => i + 1).map((n) => {
              // Who sits at this position now. When this title is already in
              // the order it occupies a slot, so the occupant of position n is
              // read from the list as the user currently sees it.
              const occupant = ordered[n - 1];
              const mine = current === n;
              const occupantName =
                occupant && occupant.anilist_id !== entry.anilist_id ? nameOf(occupant) : null;
              return (
                <li key={n}>
                  <button
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
                    <span
                      className={`k-numpick__holder${
                        !mine && !occupantName ? " k-numpick__holder--open" : ""
                      }`}
                    >
                      {mine ? title : (occupantName ?? "Open place")}
                    </span>
                    {mine ? (
                      <span className="k-numpick__now">
                        <Icon icon={Check} size={12} />
                        Now
                      </span>
                    ) : occupantName ? (
                      <span className="k-numpick__swap">Swap</span>
                    ) : null}
                  </button>
                </li>
              );
            })}
          </ol>
        </section>

        {current != null && (
          <button
            type="button"
            className="k-numpick__clear"
            onClick={() => {
              void setPlanNumber(entry.anilist_id, null);
              onClose();
            }}
          >
            <Icon icon={X} size={14} />
            Remove from order
          </button>
        )}
      </div>
    </ItemSurface>
  );
}
