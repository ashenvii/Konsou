import { useEffect, useMemo, useRef, useState } from "react";
import { useLocation } from "react-router-dom";
import {
  ChevronLeft,
  ChevronRight,
  Search as SearchIcon,
  SlidersHorizontal,
  X,
} from "lucide-react";
import { AnimeCollection } from "@/components/list/AnimeCollection";
import { SearchResults } from "@/components/discover/SearchResults";
import {
  DiscoverFilterSheet,
  EMPTY_FILTERS,
  countActiveFilters,
} from "@/components/discover/DiscoverFilterSheet";
import type { DiscoverFilters } from "@/components/discover/DiscoverFilterSheet";
import { VIEW_CYCLE, VIEW_ICONS, VIEW_LABELS } from "@/components/list/ListToolbar";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Skeleton } from "@/components/ui/Skeleton";
import { Text } from "@/components/ui/Text";
import { useDebounce } from "@/hooks/useDebounce";
import { useDiscover } from "@/hooks/useAniList";
import { useSearchStore } from "@/lib/store/searchStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { formatLabel } from "@/lib/format";
import { getUiState, setUiState } from "@/lib/uiState";
import type { BrowseSort } from "@/lib/api/anilist/client";
import type { MediaSeason } from "@/types/anime";
import type { ViewMode } from "@/types/list";

type Tab = "seasonal" | "trending" | "top";
const TABS: { id: Tab; label: string }[] = [
  { id: "seasonal", label: "Seasonal" },
  { id: "trending", label: "Trending" },
  { id: "top", label: "Top Rated" },
];

const SORT_BY_TAB: Record<Tab, BrowseSort> = {
  seasonal: "POPULARITY_DESC",
  trending: "TRENDING_DESC",
  top: "SCORE_DESC",
};

const EXAMPLE_CHIPS = ["Attack on Titan", "Frieren", "One Piece", "Bocchi"];

const SEASONS: MediaSeason[] = ["WINTER", "SPRING", "SUMMER", "FALL"];

const COUNTRY_LABELS: Record<string, string> = {
  JP: "Japan",
  CN: "China",
  KR: "Korea",
  TW: "Taiwan",
};

// "Not yet aired", not "Announced": Schedule owns that word for tracked
// titles waiting on a date. This is AniList's raw airing status.
const STATUS_LABELS: Record<string, string> = {
  RELEASING: "Airing",
  FINISHED: "Finished",
  NOT_YET_RELEASED: "Not yet aired",
};

function baseSeasonIndex(month: number): number {
  if (month === 12 || month <= 2) return 0;
  if (month <= 5) return 1;
  if (month <= 8) return 2;
  return 3;
}

function resolveSeason(offset: number): { season: MediaSeason; year: number } {
  const now = new Date();
  let idx = baseSeasonIndex(now.getMonth() + 1) + offset;
  let year = now.getFullYear();
  while (idx < 0) {
    idx += 4;
    year--;
  }
  while (idx > 3) {
    idx -= 4;
    year++;
  }
  return { season: SEASONS[idx], year };
}

/** One removable pill per active filter, for the summary row under the tabs. */
interface SummaryChip {
  key: string;
  label: string;
  clear: (f: DiscoverFilters) => DiscoverFilters;
}

function summaryChips(f: DiscoverFilters): SummaryChip[] {
  const chips: SummaryChip[] = [];
  for (const g of f.genres) {
    chips.push({ key: `g:${g}`, label: g, clear: (x) => ({ ...x, genres: x.genres.filter((v) => v !== g) }) });
  }
  for (const t of f.themes) {
    chips.push({ key: `t:${t}`, label: t, clear: (x) => ({ ...x, themes: x.themes.filter((v) => v !== t) }) });
  }
  for (const fmt of f.formats) {
    chips.push({ key: `f:${fmt}`, label: formatLabel(fmt) ?? fmt, clear: (x) => ({ ...x, formats: x.formats.filter((v) => v !== fmt) }) });
  }
  if (f.status) {
    chips.push({ key: "status", label: STATUS_LABELS[f.status] ?? f.status, clear: (x) => ({ ...x, status: null }) });
  }
  if (f.country) {
    chips.push({ key: "country", label: COUNTRY_LABELS[f.country] ?? f.country, clear: (x) => ({ ...x, country: null }) });
  }
  if (f.yearFrom || f.yearTo) {
    const label =
      f.yearFrom && f.yearTo
        ? f.yearFrom === f.yearTo
          ? `${f.yearFrom}`
          : `${f.yearFrom}–${f.yearTo}`
        : f.yearFrom
          ? `from ${f.yearFrom}`
          : `until ${f.yearTo}`;
    chips.push({ key: "year", label, clear: (x) => ({ ...x, yearFrom: null, yearTo: null }) });
  }
  return chips;
}

const LAST_TAB_KEY = "konsou.discover_tab";

export function Discover() {
  const location = useLocation();
  const inputRef = useRef<HTMLInputElement>(null);

  // ── Search (pill lives on the page; state is shared via the store) ──
  const value = useSearchStore((s) => s.query);
  const setValue = useSearchStore((s) => s.setQuery);
  const searching = useSearchStore((s) => s.searching);
  const setSearching = useSearchStore((s) => s.setSearching);
  const debouncedQuery = useDebounce(value, 400);

  const recent = useSettingsStore((s) => s.recentSearches);
  const addRecent = useSettingsStore((s) => s.addRecentSearch);
  const removeRecent = useSettingsStore((s) => s.removeRecentSearch);

  const searchMode = debouncedQuery.trim().length >= 2;
  // Header field active with nothing typed yet → offer recent/example queries.
  const showRecents = searching && !searchMode;

  // Arriving from a "Search for anime" CTA opens the search flow and focuses
  // the page search field.
  useEffect(() => {
    if ((location.state as { fromSearchIntent?: boolean } | null)?.fromSearchIntent) {
      setSearching(true);
      inputRef.current?.focus();
    }
  }, [location.state, setSearching]);

  const runChip = (q: string) => {
    setValue(q);
    addRecent(q);
    setSearching(true);
  };

  // ── Browse ──────────────────────────────────────────────────
  const [tab, setTab] = useState<Tab>(
    () => (localStorage.getItem(LAST_TAB_KEY) as Tab) ?? "trending",
  );
  // Filters and view mode survive navigating into an anime and back (session).
  const [filters, setFiltersState] = useState<DiscoverFilters>(() =>
    getUiState<DiscoverFilters>("discover.filters", EMPTY_FILTERS),
  );
  const [view, setViewState] = useState<ViewMode>(() =>
    getUiState<ViewMode>("discover.view", "grid"),
  );
  const [seasonOffset, setSeasonOffsetState] = useState(() =>
    getUiState("discover.seasonOffset", 0),
  );
  const [filtersOpen, setFiltersOpen] = useState(false);

  const setFilters = (f: DiscoverFilters) => {
    setFiltersState(f);
    setUiState("discover.filters", f);
  };
  const setView = (v: ViewMode) => {
    setViewState(v);
    setUiState("discover.view", v);
  };
  const setSeasonOffset = (fn: (o: number) => number) => {
    setSeasonOffsetState((o) => {
      const next = fn(o);
      setUiState("discover.seasonOffset", next);
      return next;
    });
  };

  const season = useMemo(() => resolveSeason(seasonOffset), [seasonOffset]);
  const isSeasonal = tab === "seasonal";

  // The seasonal nav owns the year on that tab, so the year filter is dropped
  // there. Badge and chips derive from the same effective set, so the UI never
  // advertises a filter the query isn't applying; the stored year survives for
  // when the user switches back to Trending/Top Rated.
  const effectiveFilters = useMemo(
    () => (isSeasonal ? { ...filters, yearFrom: null, yearTo: null } : filters),
    [isSeasonal, filters],
  );

  const { results, isLoading, isError, hasNextPage, fetchNextPage, refetch } =
    useDiscover({
      sort: SORT_BY_TAB[tab],
      season: isSeasonal ? season.season : undefined,
      seasonYear: isSeasonal ? season.year : undefined,
      genres: effectiveFilters.genres,
      themes: effectiveFilters.themes,
      formats: effectiveFilters.formats,
      status: effectiveFilters.status,
      country: effectiveFilters.country,
      yearFrom: effectiveFilters.yearFrom,
      yearTo: effectiveFilters.yearTo,
    });

  const selectTab = (t: Tab) => {
    setTab(t);
    localStorage.setItem(LAST_TAB_KEY, t);
  };

  const activeCount = countActiveFilters(effectiveFilters);
  const chips = summaryChips(effectiveFilters);
  const activeLabel = chips.map((c) => c.label).join(" + ");

  return (
    <div className="k-page k-discover">
      <div className="k-search__bar">
        <div className="k-hsearch">
          <Icon icon={SearchIcon} size={18} color="var(--color-text-tertiary)" />
          <input
            ref={inputRef}
            className="k-hsearch__input"
            type="search"
            inputMode="search"
            enterKeyHint="search"
            placeholder="Search any anime…"
            value={value}
            onChange={(e) => {
              setValue(e.target.value);
              setSearching(true);
            }}
            onFocus={() => setSearching(true)}
            onBlur={() => {
              if (value.trim().length === 0) setSearching(false);
            }}
            onKeyDown={(e) => {
              if (e.key === "Enter" && value.trim().length >= 2) {
                addRecent(value);
                inputRef.current?.blur();
              }
            }}
            aria-label="Search anime"
          />
          {value && (
            <button
              type="button"
              className="k-hsearch__clear"
              onClick={() => setValue("")}
              aria-label="Clear search"
            >
              <Icon icon={X} size={16} />
            </button>
          )}
        </div>
        {/* Explicit way out of search back to Discover. The header field can
            stay "in search" with an empty query (recents showing); tapping
            Cancel drops it and returns to the browse tabs. */}
        {searching && (
          <button
            type="button"
            className="k-search__cancel"
            onClick={() => {
              setValue("");
              setSearching(false);
              inputRef.current?.blur();
            }}
          >
            Cancel
          </button>
        )}
      </div>

      {searchMode ? (
        <SearchResults query={debouncedQuery} view={view} />
      ) : showRecents ? (
        // preventDefault on mousedown keeps the input focused while tapping a
        // chip; without it the blur empties `searching`, the panel unmounts
        // between mousedown and click, and the tap lands on nothing.
        <div
          className="k-search__suggest konsou-scroll"
          onMouseDown={(e) => e.preventDefault()}
        >
          {recent.length > 0 ? (
            <>
              <Text size="sm" color="secondary" className="k-search__sectiontitle">
                Recent
              </Text>
              <div className="k-chiprow">
                {recent.map((q) => (
                  <Chip key={q} onClick={() => runChip(q)} onRemove={() => removeRecent(q)}>
                    {q}
                  </Chip>
                ))}
              </div>
            </>
          ) : (
            <>
              <Text size="sm" color="secondary" className="k-search__sectiontitle">
                Try searching
              </Text>
              <div className="k-chiprow">
                {EXAMPLE_CHIPS.map((q) => (
                  <Chip key={q} onClick={() => runChip(q)}>
                    {q}
                  </Chip>
                ))}
              </div>
            </>
          )}
        </div>
      ) : (
        <>
          <div className="k-subtabs" role="tablist">
            {TABS.map((t) => (
              <button
                key={t.id}
                role="tab"
                aria-selected={tab === t.id}
                className={`k-subtab${tab === t.id ? " k-subtab--active" : ""}`}
                onClick={() => selectTab(t.id)}
              >
                {t.label}
              </button>
            ))}
          </div>

          <div className="k-discover__toolbar">
            <button
              type="button"
              className={`k-discover__filterbtn${activeCount > 0 ? " k-discover__filterbtn--on" : ""}`}
              onClick={() => setFiltersOpen(true)}
            >
              <Icon icon={SlidersHorizontal} size={16} />
              <span>Filters</span>
              {activeCount > 0 && <span className="k-discover__filtercount">{activeCount}</span>}
            </button>

            {isSeasonal && (
              <div className="k-season-nav">
                <button
                  type="button"
                  className="k-icon-btn"
                  onClick={() => setSeasonOffset((o) => o - 1)}
                  aria-label="Previous season"
                >
                  <Icon icon={ChevronLeft} size={18} />
                </button>
                <span className="k-season-nav__label">
                  {season.season.charAt(0) + season.season.slice(1).toLowerCase()} {season.year}
                </span>
                <button
                  type="button"
                  className="k-icon-btn"
                  onClick={() => setSeasonOffset((o) => o + 1)}
                  aria-label="Next season"
                >
                  <Icon icon={ChevronRight} size={18} />
                </button>
              </div>
            )}

            <button
              type="button"
              className="k-icon-btn k-discover__viewbtn"
              onClick={() => setView(VIEW_CYCLE[view])}
              aria-label={`View: ${VIEW_LABELS[view]}. Tap to change.`}
              title={`View: ${VIEW_LABELS[view]}`}
            >
              <Icon icon={VIEW_ICONS[view]} size={18} />
            </button>
          </div>

          {chips.length > 0 && (
            <div className="k-chiprow k-chiprow--scroll" aria-label="Active filters">
              {chips.map((c) => (
                <Chip key={c.key} active onRemove={() => setFilters(c.clear(filters))} removeLabel={`Remove ${c.label}`}>
                  {c.label}
                </Chip>
              ))}
              <button
                type="button"
                className="k-discover__clearall"
                onClick={() => setFilters(EMPTY_FILTERS)}
              >
                Clear all
              </button>
            </div>
          )}

          {isLoading ? (
            <div className="k-skelgrid">
              {Array.from({ length: 12 }).map((_, i) => (
                <Skeleton key={i} height="auto" style={{ aspectRatio: "2 / 3" }} />
              ))}
            </div>
          ) : isError ? (
            <EmptyState
              title="Couldn't load this section"
              subtitle="Konsou can't reach AniList right now."
              action={
                <Button size="sm" variant="primary" onClick={() => void refetch()}>
                  Try again
                </Button>
              }
            />
          ) : results.length === 0 ? (
            <EmptyState
              title={activeLabel ? `No ${activeLabel} anime here` : "Nothing to show here yet"}
              subtitle={
                activeLabel
                  ? isSeasonal
                    ? "Try another season, or loosen a filter."
                    : "Try loosening a filter."
                  : undefined
              }
            />
          ) : (
            <AnimeCollection
              items={results}
              view={view}
              onEndReached={hasNextPage ? () => fetchNextPage() : undefined}
              restoreKey={`discover.scroll.${tab}`}
            />
          )}
        </>
      )}

      <DiscoverFilterSheet
        open={filtersOpen}
        onClose={() => setFiltersOpen(false)}
        value={filters}
        onApply={setFilters}
      />
    </div>
  );
}
