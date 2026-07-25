import { useMemo, useState } from "react";
import { Check, Search, X } from "lucide-react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Icon } from "@/components/ui/Icon";
import type { HashtagFacet } from "@/lib/hashtags";

export interface SortOption {
  key: string;
  label: string;
}

interface RoomFiltersProps {
  open: boolean;
  onClose: () => void;
  sorts: SortOption[];
  activeSort: string;
  onSort: (key: string) => void;
  tags: HashtagFacet[];
  activeTags: string[];
  onToggleTag: (key: string) => void;
  onClearTags: () => void;
  /** Completed room only. */
  droppedCount?: number;
  showDropped?: boolean;
  onToggleDropped?: () => void;
}

/** Above this many tags the list gets its own search box, because scanning is
 *  no longer realistic and hashtags are designed to grow. */
const SEARCH_THRESHOLD = 8;

/**
 * Every way of narrowing a room, in one sheet.
 *
 * These controls used to sit permanently on screen as stacked bands: a sort
 * row, a horizontal tag strip, a dropped toggle. On a phone that was ~150px of
 * chrome before any content, and the tag strip got worse as the tag vocabulary
 * grew, which is precisely backwards for a feature whose whole point is that
 * you invent tags freely. A sheet costs one tap, scales to any number of tags,
 * and gives the list back the screen.
 */
export function RoomFilters({
  open,
  onClose,
  sorts,
  activeSort,
  onSort,
  tags,
  activeTags,
  onToggleTag,
  onClearTags,
  droppedCount = 0,
  showDropped,
  onToggleDropped,
}: RoomFiltersProps) {
  const [query, setQuery] = useState("");

  const shown = useMemo(() => {
    const q = query.trim().replace(/^#+/, "").toLowerCase();
    if (!q) return tags;
    return tags.filter((t) => t.key.includes(q));
  }, [tags, query]);

  return (
    <BottomSheet open={open} onClose={onClose} title="Filter & sort">
      <div className="k-rfilter">
        <section className="k-rfilter__section">
          <h3 className="k-rfilter__label">Sort</h3>
          <div className="k-rfilter__sorts">
            {sorts.map((s) => (
              <button
                key={s.key}
                type="button"
                className={`k-rfilter__sort${activeSort === s.key ? " k-rfilter__sort--on" : ""}`}
                aria-pressed={activeSort === s.key}
                onClick={() => onSort(s.key)}
              >
                {s.label}
                {activeSort === s.key && <Icon icon={Check} size={15} />}
              </button>
            ))}
          </div>
        </section>

        {onToggleDropped && droppedCount > 0 && (
          <section className="k-rfilter__section">
            <h3 className="k-rfilter__label">Also show</h3>
            <button
              type="button"
              className={`k-rfilter__row${showDropped ? " k-rfilter__row--on" : ""}`}
              aria-pressed={!!showDropped}
              onClick={onToggleDropped}
            >
              <span>Dropped</span>
              <span className="k-rfilter__count">{droppedCount}</span>
              {showDropped && <Icon icon={Check} size={15} />}
            </button>
          </section>
        )}

        {tags.length > 0 && (
          <section className="k-rfilter__section">
            <div className="k-rfilter__head">
              <h3 className="k-rfilter__label">Tags</h3>
              {activeTags.length > 0 && (
                <button type="button" className="k-rfilter__clear" onClick={onClearTags}>
                  Clear {activeTags.length}
                </button>
              )}
            </div>

            {tags.length > SEARCH_THRESHOLD && (
              <div className="k-rfilter__search">
                <Icon icon={Search} size={15} color="var(--color-text-tertiary)" />
                <input
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder={`Search ${tags.length} tags…`}
                  aria-label="Search tags"
                />
                {query && (
                  <button type="button" onClick={() => setQuery("")} aria-label="Clear tag search">
                    <Icon icon={X} size={14} />
                  </button>
                )}
              </div>
            )}

            {/* Vertical and scrollable: a sideways strip could never surface the
                twentieth tag, and the vocabulary only grows. */}
            <div className="k-rfilter__tags konsou-scroll">
              {shown.map((t) => {
                const on = activeTags.includes(t.key);
                return (
                  <button
                    key={t.key}
                    type="button"
                    className={`k-rfilter__row${on ? " k-rfilter__row--on" : ""}`}
                    aria-pressed={on}
                    onClick={() => onToggleTag(t.key)}
                  >
                    <span className="k-rfilter__tagname">{t.label}</span>
                    <span className="k-rfilter__count">{t.count}</span>
                    {on && <Icon icon={Check} size={15} />}
                  </button>
                );
              })}
              {shown.length === 0 && (
                <p className="k-rfilter__none">No tag matches “{query.trim()}”.</p>
              )}
            </div>
          </section>
        )}
      </div>
    </BottomSheet>
  );
}
