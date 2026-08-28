import { useMemo, useRef, useState } from "react";
import { Check, Search, SlidersHorizontal, X } from "lucide-react";
import { Icon } from "./Icon";
import { ItemSurface } from "./ItemSurface";

/**
 * Every way of narrowing a page, in one component, on every page.
 *
 * This replaces per-page filter sheets. There were two of them (RoomFilters for
 * the list rooms, DiscoverFilterSheet for Discover) with their own markup, their
 * own idea of what a sort control looks like and their own idea of where the
 * thing opens — so the same job looked different depending on which page you
 * were standing on. A page now declares WHAT it can be narrowed by, as data, and
 * this owns how that looks and where it appears.
 *
 * Where it appears is the anchored popover, through `ItemSurface`: the same
 * decision the quick menu makes, so the app has one positioning system rather
 * than one per feature. On a phone that is a sheet, for the same reason it is
 * there — a popover anchored to a 40px icon on a 390px screen is a sheet with
 * extra steps.
 */

export interface FilterOption {
  key: string;
  label: string;
  count?: number;
}

export type FilterSection =
  /** Pick exactly one. Sorting is always this. */
  | {
      kind: "choice";
      id: string;
      label: string;
      options: FilterOption[];
      value: string;
      onPick: (key: string) => void;
    }
  /** Pick any number. Tags are this, and there can be hundreds of them. */
  | {
      kind: "toggles";
      id: string;
      label: string;
      options: FilterOption[];
      active: string[];
      onToggle: (key: string) => void;
      onClear?: () => void;
      /** Placeholder for the built-in find field; omit to never show one. */
      searchPlaceholder?: string;
    }
  /** One thing that is either on or off. */
  | {
      kind: "switch";
      id: string;
      /** The heading above it ("Also show"). */
      group: string;
      /** The row itself ("Dropped"). */
      label: string;
      on: boolean;
      count?: number;
      onToggle: () => void;
    };

/** Above this many options a toggle list gets its own find field, because
 *  scanning stops being realistic and tag vocabularies only grow. */
const FIND_THRESHOLD = 8;

function ToggleSection({ section }: { section: Extract<FilterSection, { kind: "toggles" }> }) {
  const [query, setQuery] = useState("");
  const shown = useMemo(() => {
    const q = query.trim().replace(/^#+/, "").toLowerCase();
    if (!q) return section.options;
    return section.options.filter((o) => o.key.toLowerCase().includes(q));
  }, [section.options, query]);

  return (
    <section className="k-fm__section">
      <div className="k-fm__head">
        <h3 className="k-fm__label">{section.label}</h3>
        {section.active.length > 0 && section.onClear && (
          <button type="button" className="k-fm__clear" onClick={section.onClear}>
            Clear {section.active.length}
          </button>
        )}
      </div>

      {section.searchPlaceholder && section.options.length > FIND_THRESHOLD && (
        <div className="k-fm__find">
          <Icon icon={Search} size={14} color="var(--ink-label)" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={section.searchPlaceholder}
            aria-label={section.searchPlaceholder}
          />
          {query && (
            <button type="button" onClick={() => setQuery("")} aria-label="Clear">
              <Icon icon={X} size={13} />
            </button>
          )}
        </div>
      )}

      <div className="k-fm__rows">
        {shown.map((o) => {
          const on = section.active.includes(o.key);
          return (
            <button
              key={o.key}
              type="button"
              className={`k-fm__row${on ? " k-fm__row--on" : ""}`}
              aria-pressed={on}
              onClick={() => section.onToggle(o.key)}
            >
              <span className="k-fm__rowname">{o.label}</span>
              {o.count != null && <span className="k-fm__count">{o.count}</span>}
              {on && <Icon icon={Check} size={15} />}
            </button>
          );
        })}
        {shown.length === 0 && (
          <p className="k-fm__none">Nothing matches “{query.trim()}”.</p>
        )}
      </div>
    </section>
  );
}

/**
 * The toolbar control and the panel it opens, together.
 *
 * Together on purpose: the button owns the element the popover points at, so a
 * page never has to hold a ref and a piece of open state to place a filter
 * panel. Dropping this into a header is the whole integration.
 */
export function FilterMenu({
  sections,
  activeCount,
  onClearAll,
  label = "Filter and sort",
}: {
  sections: FilterSection[];
  /** Drives the badge. The page decides what counts as narrowed — a non-default
   *  sort may or may not, and only the page knows its own default. */
  activeCount: number;
  onClearAll?: () => void;
  label?: string;
}) {
  const [open, setOpen] = useState(false);
  const btnRef = useRef<HTMLButtonElement>(null);

  return (
    <>
      <button
        ref={btnRef}
        type="button"
        className={`k-roomhead__filter${activeCount > 0 ? " k-roomhead__filter--on" : ""}`}
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        aria-label={activeCount > 0 ? `${label}, ${activeCount} active` : label}
      >
        <Icon icon={SlidersHorizontal} size={17} />
        {/* Revealed only where there is room for it (see .k-roomhead__btnlabel). */}
        <span className="k-roomhead__btnlabel">{label === "Filter and sort" ? "Filter" : label}</span>
        {activeCount > 0 && <span className="k-roomhead__badge">{activeCount}</span>}
      </button>

      <ItemSurface
        anchor={btnRef.current}
        open={open}
        onClose={() => setOpen(false)}
        ariaLabel={label}
        size={{ width: 320, maxHeight: 560 }}
      >
        <div className="k-fm">
          {sections.map((s) => {
            if (s.kind === "choice") {
              return (
                <section key={s.id} className="k-fm__section">
                  <h3 className="k-fm__label">{s.label}</h3>
                  <div className="k-fm__rows">
                    {s.options.map((o) => (
                      <button
                        key={o.key}
                        type="button"
                        className={`k-fm__row${s.value === o.key ? " k-fm__row--on" : ""}`}
                        aria-pressed={s.value === o.key}
                        onClick={() => s.onPick(o.key)}
                      >
                        <span className="k-fm__rowname">{o.label}</span>
                        {o.count != null && <span className="k-fm__count">{o.count}</span>}
                        {s.value === o.key && <Icon icon={Check} size={15} />}
                      </button>
                    ))}
                  </div>
                </section>
              );
            }
            if (s.kind === "switch") {
              return (
                <section key={s.id} className="k-fm__section">
                  <h3 className="k-fm__label">{s.group}</h3>
                  <button
                    type="button"
                    className={`k-fm__row${s.on ? " k-fm__row--on" : ""}`}
                    aria-pressed={s.on}
                    onClick={s.onToggle}
                  >
                    <span className="k-fm__rowname">{s.label}</span>
                    {s.count != null && <span className="k-fm__count">{s.count}</span>}
                    {s.on && <Icon icon={Check} size={15} />}
                  </button>
                </section>
              );
            }
            return <ToggleSection key={s.id} section={s} />;
          })}

          {onClearAll && activeCount > 0 && (
            <button type="button" className="k-fm__clearall" onClick={onClearAll}>
              Clear all
            </button>
          )}
        </div>
      </ItemSurface>
    </>
  );
}
