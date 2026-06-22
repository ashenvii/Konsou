import { useState } from "react";
import {
  Funnel,
  ListBullets,
  MagnifyingGlass,
  Rows,
  SortAscending,
  SquaresFour,
  X,
} from "@phosphor-icons/react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Icon } from "@/components/ui/Icon";
import { listStatusLabel } from "@/lib/format";
import { LIST_STATUSES } from "@/types/list";
import { statusMeta } from "@/components/anime/statusMeta";
import type { ListFilter, SortSpec, ViewMode } from "@/types/list";

const VIEW_ICONS: Record<ViewMode, typeof SquaresFour> = {
  grid: SquaresFour,
  list: Rows,
  compact: ListBullets,
};

const SORT_LABELS: Record<SortSpec["key"], string> = {
  title: "Title",
  updated: "Last Updated",
  score: "Score",
  episodes: "Episodes",
  added: "Date Added",
};

interface ListToolbarProps {
  search: string;
  onSearch: (v: string) => void;
  filter: ListFilter;
  onFilter: (f: ListFilter) => void;
  counts: Record<ListFilter, number>;
  view: ViewMode;
  onView: (v: ViewMode) => void;
  sort: SortSpec;
  onOpenSort: () => void;
}

export function ListToolbar({
  search,
  onSearch,
  filter,
  onFilter,
  counts,
  view,
  onView,
  sort,
  onOpenSort,
}: ListToolbarProps) {
  const [filterSheetOpen, setFilterSheetOpen] = useState(false);
  const tabs: ListFilter[] = ["all", ...LIST_STATUSES];
  const activeLabel = filter === "all" ? "All" : listStatusLabel(filter);
  const activeCount = counts[filter] ?? 0;

  return (
    <div className="k-toolbar">
      <div className="k-toolbar__searchrow">
        <div className="k-searchbar">
          <Icon
            icon={MagnifyingGlass}
            size={18}
            color="var(--color-text-tertiary)"
          />
          <input
            className="k-searchbar__input"
            type="search"
            inputMode="search"
            placeholder="Filter your list…"
            value={search}
            onChange={(e) => onSearch(e.target.value)}
            aria-label="Filter your list"
          />
          {search && (
            <button
              type="button"
              className="k-searchbar__clear"
              onClick={() => onSearch("")}
              aria-label="Clear filter"
            >
              <Icon icon={X} size={16} />
            </button>
          )}
        </div>

        <div className="k-toolbar__controls">
          <button
            type="button"
            className="k-toolbar__filter"
            onClick={() => setFilterSheetOpen(true)}
            aria-haspopup="dialog"
            aria-expanded={filterSheetOpen}
            aria-label="Filter by status"
          >
            <Icon icon={Funnel} size={18} />
            <span className="k-toolbar__filter-label">{activeLabel}</span>
            {activeCount > 0 && (
              <span className="k-toolbar__filter-count">{activeCount}</span>
            )}
          </button>
          <button
            type="button"
            className="k-toolbar__sort"
            onClick={onOpenSort}
            aria-label="Sort"
          >
            <Icon icon={SortAscending} size={18} />
            <span className="k-toolbar__sort-label">{SORT_LABELS[sort.key]}</span>
          </button>
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
        </div>
      </div>

      <BottomSheet
        open={filterSheetOpen}
        onClose={() => setFilterSheetOpen(false)}
        title="Filter by status"
      >
        <div className="k-filtersheet">
          {tabs.map((t) => {
            const label = t === "all" ? "All entries" : listStatusLabel(t);
            const count = counts[t] ?? 0;
            const OptionIcon = t === "all" ? Funnel : statusMeta(t).icon;
            const color = t === "all" ? undefined : statusMeta(t).color;
            return (
              <button
                key={t}
                type="button"
                className={`k-filteroption${filter === t ? " k-filteroption--active" : ""}`}
                style={color ? { color } : undefined}
                onClick={() => {
                  onFilter(t);
                  setFilterSheetOpen(false);
                }}
              >
                <Icon icon={OptionIcon} size={20} weight="fill" />
                <span className="k-filteroption__text">
                  <span>{label}</span>
                  <small>{t === "all" ? "Everything in your list" : "Status group"}</small>
                </span>
                <span className="k-filteroption__count">{count}</span>
              </button>
            );
          })}
        </div>
      </BottomSheet>
    </div>
  );
}

export { SORT_LABELS };
