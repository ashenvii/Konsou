import { useEffect, useRef, useState } from "react";
import {
  ArrowUpDown,
  Filter,
  LayoutGrid,
  List,
  Rows3,
  Search,
  X,
} from "lucide-react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Icon } from "@/components/ui/Icon";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { listStatusLabel } from "@/lib/format";
import { LIST_STATUSES } from "@/types/list";
import { statusMeta } from "@/components/anime/statusMeta";
import type { ListFilter, ListStatus, SortSpec, ViewMode } from "@/types/list";

export const VIEW_ICONS: Record<ViewMode, typeof LayoutGrid> = {
  grid: LayoutGrid,
  list: Rows3,
  compact: List,
};

export const VIEW_LABELS: Record<ViewMode, string> = {
  grid: "Grid",
  list: "List",
  compact: "Compact",
};

const SORT_LABELS: Record<SortSpec["key"], string> = {
  title: "Title",
  updated: "Last Updated",
  score: "Score",
  episodes: "Episodes",
  added: "Date Added",
};

// Narrow screens cycle view modes through one button instead of a 3-wide
// toggle (DIM-style compact header: chrome earns its row or leaves it).
export const VIEW_CYCLE: Record<ViewMode, ViewMode> = {
  grid: "list",
  list: "compact",
  compact: "grid",
};

interface ListToolbarProps {
  search: string;
  onSearch: (v: string) => void;
  /** Multi-select status filter; empty = everything shows. */
  selected: ListStatus[];
  onToggleStatus: (s: ListStatus) => void;
  onClearStatuses: () => void;
  counts: Record<ListFilter, number>;
  view: ViewMode;
  onView: (v: ViewMode) => void;
  sort: SortSpec;
  onOpenSort: () => void;
}

export function ListToolbar({
  search,
  onSearch,
  selected,
  onToggleStatus,
  onClearStatuses,
  counts,
  view,
  onView,
  sort,
  onOpenSort,
}: ListToolbarProps) {
  const [filterSheetOpen, setFilterSheetOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const isNarrow = useMediaQuery("(max-width: 600px)");
  const activeLabel =
    selected.length === 0
      ? "All"
      : selected.length === 1
        ? listStatusLabel(selected[0])
        : `${selected.length} statuses`;
  const activeCount =
    selected.length === 0
      ? counts.all
      : selected.reduce((n, s) => n + (counts[s] ?? 0), 0);

  // Narrow screens collapse the search bar to an icon (DIM's mobile header
  // pattern). It stays expanded while a query is active so the user never
  // loses sight of why the list is filtered.
  const searchExpanded = !isNarrow || searchOpen || search.length > 0;

  useEffect(() => {
    if (isNarrow && searchOpen) inputRef.current?.focus();
  }, [isNarrow, searchOpen]);

  const closeSearch = () => {
    onSearch("");
    setSearchOpen(false);
  };

  return (
    <div className="k-toolbar">
      <div className="k-toolbar__searchrow">
        {!searchExpanded && (
          <button
            type="button"
            className="k-toolbar__searchbtn"
            onClick={() => setSearchOpen(true)}
            aria-label="Search your list"
            aria-expanded={false}
          >
            <Icon icon={Search} size={18} />
          </button>
        )}

        {searchExpanded && (
          <div className="k-searchbar">
            <Icon
              icon={Search}
              size={18}
              color="var(--color-text-tertiary)"
            />
            <input
              ref={inputRef}
              className="k-searchbar__input"
              type="search"
              inputMode="search"
              placeholder="Search your list…"
              value={search}
              onChange={(e) => onSearch(e.target.value)}
              onBlur={() => {
                // Collapse an empty search when focus leaves it on narrow
                // screens; a non-empty query keeps the bar (and the X) around.
                if (isNarrow && search.length === 0) setSearchOpen(false);
              }}
              aria-label="Search your list"
            />
            {(search || (isNarrow && searchOpen)) && (
              <button
                type="button"
                className="k-searchbar__clear"
                // Mousedown so it wins against the input's blur-collapse.
                onMouseDown={(e) => {
                  e.preventDefault();
                  if (search) onSearch("");
                  else closeSearch();
                }}
                aria-label={search ? "Clear search" : "Close search"}
              >
                <Icon icon={X} size={16} />
              </button>
            )}
          </div>
        )}

        {(!isNarrow || !searchExpanded) && (
          <div className="k-toolbar__controls">
            <button
              type="button"
              className="k-toolbar__filter"
              onClick={() => setFilterSheetOpen(true)}
              aria-haspopup="dialog"
              aria-expanded={filterSheetOpen}
              aria-label="Filter by status"
            >
              <Icon icon={Filter} size={18} />
              <span className="k-toolbar__filter-label">{activeLabel}</span>
              {activeCount > 0 && (
                <span className="k-toolbar__filter-count">{activeCount}</span>
              )}
            </button>
            <button
              type="button"
              className="k-toolbar__sort"
              onClick={onOpenSort}
              aria-label={`Sort by ${SORT_LABELS[sort.key]}`}
            >
              <Icon icon={ArrowUpDown} size={18} />
              <span className="k-toolbar__sort-label">{SORT_LABELS[sort.key]}</span>
            </button>
            {isNarrow ? (
              <button
                type="button"
                className="k-toolbar__viewcycle"
                onClick={() => onView(VIEW_CYCLE[view])}
                aria-label={`${view} view. Switch to ${VIEW_CYCLE[view]} view`}
              >
                <Icon icon={VIEW_ICONS[view]} size={18} weight="fill" />
              </button>
            ) : (
              <div className="k-viewtoggle" role="group" aria-label="View mode">
                {(["grid", "list", "compact"] as ViewMode[]).map((v) => (
                  <button
                    key={v}
                    type="button"
                    className={`k-viewtoggle__btn${view === v ? " k-viewtoggle__btn--active" : ""}`}
                    onClick={() => onView(v)}
                    aria-label={`${v} view`}
                    aria-pressed={view === v}
                  >
                    <Icon
                      icon={VIEW_ICONS[v]}
                      size={18}
                      weight={view === v ? "fill" : "regular"}
                    />
                  </button>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      <BottomSheet
        open={filterSheetOpen}
        onClose={() => setFilterSheetOpen(false)}
        title="Filter by status"
      >
        <div className="k-filtersheet">
          <button
            type="button"
            className={`k-filteroption${selected.length === 0 ? " k-filteroption--active" : ""}`}
            onClick={() => {
              onClearStatuses();
              setFilterSheetOpen(false);
            }}
          >
            <Icon icon={Filter} size={20} weight="fill" />
            <span className="k-filteroption__text">
              <span>All entries</span>
              <small>Everything in your list</small>
            </span>
            <span className="k-filteroption__count">{counts.all}</span>
          </button>
          {LIST_STATUSES.map((t) => {
            const active = selected.includes(t);
            return (
              <button
                key={t}
                type="button"
                role="checkbox"
                aria-checked={active}
                className={`k-filteroption${active ? " k-filteroption--active" : ""}`}
                style={{ color: statusMeta(t).color }}
                // Toggling keeps the sheet open so several statuses can be
                // combined in one visit; "All entries" or the handle closes it.
                onClick={() => onToggleStatus(t)}
              >
                <Icon icon={statusMeta(t).icon} size={20} weight="fill" />
                <span className="k-filteroption__text">
                  <span>{listStatusLabel(t)}</span>
                  <small>{active ? "Showing" : "Tap to combine"}</small>
                </span>
                <span className="k-filteroption__count">{counts[t] ?? 0}</span>
              </button>
            );
          })}
        </div>
      </BottomSheet>
    </div>
  );
}

export { SORT_LABELS };
