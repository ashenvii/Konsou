import { useRef, useState } from "react";
import { CalendarRange, Check } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { ItemSurface } from "@/components/ui/ItemSurface";

export interface YearCount {
  year: number;
  count: number;
}

/**
 * Choose a year, or stop slicing by year altogether.
 *
 * This replaces a rail of every year laid end to end. That worked at five years
 * and broke at twenty: the far end simply ran out of the window, and on a
 * narrow screen the horizontal strip it collapsed into hid its own scrollbar,
 * so the older years were unreachable by any input the app offered. A rail's
 * length is the record's length, which is exactly the thing that grows.
 *
 * A picker doesn't grow. The years lay out as a calendar's year page — a grid,
 * newest first, four to a row, each carrying its count — so twenty years is one
 * glance and forty is one short scroll inside a bounded panel.
 *
 * "All years" sits above the grid as a real choice rather than an escape hatch.
 * The year slices exist so no view is ever unbounded; someone searching the
 * whole record wants the opposite, and had no way to ask for it.
 */
export function YearPicker({
  years,
  active,
  showingAll,
  total,
  onPick,
}: {
  years: YearCount[];
  /** The year being shown, or null while showing all of them. */
  active: number | null;
  showingAll: boolean;
  /** How many watches there are in total, for the "All years" row. */
  total: number;
  onPick: (year: number | "all") => void;
}) {
  const [open, setOpen] = useState(false);
  const btnRef = useRef<HTMLButtonElement>(null);

  const label = showingAll ? "All years" : (active?.toString() ?? "—");

  const choose = (y: number | "all") => {
    onPick(y);
    setOpen(false);
  };

  return (
    <>
      <button
        ref={btnRef}
        type="button"
        className="k-yearbtn"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        aria-label={`Showing ${label}. Choose a year`}
      >
        <Icon icon={CalendarRange} size={15} />
        <span className="k-yearbtn__value">{label}</span>
      </button>

      <ItemSurface
        anchor={btnRef.current}
        open={open}
        onClose={() => setOpen(false)}
        ariaLabel="Choose a year"
        size={{ width: 320, maxHeight: 460 }}
      >
        <div className="k-yearpick">
          <button
            type="button"
            className={`k-yearpick__all${showingAll ? " k-yearpick__all--on" : ""}`}
            aria-pressed={showingAll}
            onClick={() => choose("all")}
          >
            <span className="k-yearpick__allname">All years</span>
            <span className="k-yearpick__count">{total.toLocaleString()}</span>
            {showingAll && <Icon icon={Check} size={15} />}
          </button>

          <h3 className="k-yearpick__label">By year</h3>
          <div className="k-yearpick__grid" role="group" aria-label="Years">
            {years.map((y) => {
              const on = !showingAll && y.year === active;
              return (
                <button
                  key={y.year}
                  type="button"
                  className={`k-yearpick__year${on ? " k-yearpick__year--on" : ""}`}
                  aria-pressed={on}
                  aria-label={`${y.year}, ${y.count} ${y.count === 1 ? "watch" : "watches"}`}
                  onClick={() => choose(y.year)}
                >
                  <span className="k-yearpick__num">{y.year}</span>
                  <span className="k-yearpick__count">{y.count}</span>
                </button>
              );
            })}
          </div>
        </div>
      </ItemSurface>
    </>
  );
}
