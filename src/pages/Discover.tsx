import { useEffect, useMemo, useRef, useState } from "react";
import { useLocation } from "react-router-dom";
import { ChevronLeft, ChevronRight, Search as SearchIcon, X } from "lucide-react";
import { AnimeCollection } from "@/components/list/AnimeCollection";
import { SearchResults } from "@/components/discover/SearchResults";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Skeleton } from "@/components/ui/Skeleton";
import { Text } from "@/components/ui/Text";
import { useDebounce } from "@/hooks/useDebounce";
import { useDiscover } from "@/hooks/useAniList";
import { useDragScroll } from "@/hooks/useDragScroll";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { getUiState, setUiState } from "@/lib/uiState";
import type { BrowseSort } from "@/lib/api/anilist/client";
import type { MediaSeason } from "@/types/anime";

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

const GENRES = [
  "Action", "Adventure", "Comedy", "Drama", "Fantasy", "Romance",
  "Sci-Fi", "Slice of Life", "Sports", "Supernatural", "Mystery", "Thriller",
];

// AniList calls these "tags"; to users they're themes. Exact AniList tag
// names — the browse query matches on them verbatim.
const THEMES = [
  "Isekai", "Reincarnation", "Time Travel", "School", "Magic", "Mecha",
  "Psychological", "Demons", "Vampire", "Historical", "Space",
  "Martial Arts", "Cyberpunk", "Samurai",
];

const EXAMPLE_CHIPS = ["Attack on Titan", "Frieren", "One Piece", "Bocchi"];

const SEASONS: MediaSeason[] = ["WINTER", "SPRING", "SUMMER", "FALL"];

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

const LAST_TAB_KEY = "konsou.discover_tab";

export function Discover() {
  const location = useLocation();
  const inputRef = useRef<HTMLInputElement>(null);

  // ── Search (folded in from the old Search page) ─────────────
  const [value, setValueState] = useState(() => getUiState("discover.query", ""));
  const debouncedQuery = useDebounce(value, 400);
  const [focused, setFocused] = useState(false);
  const setValue = (v: string) => {
    setValueState(v);
    setUiState("discover.query", v);
  };

  const recent = useSettingsStore((s) => s.recentSearches);
  const addRecent = useSettingsStore((s) => s.addRecentSearch);
  const removeRecent = useSettingsStore((s) => s.removeRecentSearch);

  const searchMode = debouncedQuery.trim().length >= 2;
  // Focused with nothing to search yet → offer recent/example queries.
  const showRecents = focused && !searchMode;

  // Arriving from the "Search for anime" CTA focuses the bar straight away.
  useEffect(() => {
    if ((location.state as { fromSearchIntent?: boolean } | null)?.fromSearchIntent) {
      inputRef.current?.focus();
    }
  }, [location.state]);

  const runChip = (q: string) => {
    setValue(q);
    addRecent(q);
    inputRef.current?.focus();
  };

  // ── Browse ──────────────────────────────────────────────────
  const [tab, setTab] = useState<Tab>(
    () => (localStorage.getItem(LAST_TAB_KEY) as Tab) ?? "trending",
  );
  // Genre and theme combine (AND) and apply on every tab, seasonal included —
  // "Isekai airing this season" is exactly the browse people come here for.
  // All three survive navigating into an anime and back (session-scoped).
  const [genre, setGenreState] = useState<string | null>(() =>
    getUiState<string | null>("discover.genre", null),
  );
  const [theme, setThemeState] = useState<string | null>(() =>
    getUiState<string | null>("discover.theme", null),
  );
  const [seasonOffset, setSeasonOffsetState] = useState(() =>
    getUiState("discover.seasonOffset", 0),
  );

  const setGenre = (v: string | null) => {
    setGenreState(v);
    setUiState("discover.genre", v);
  };
  const setTheme = (v: string | null) => {
    setThemeState(v);
    setUiState("discover.theme", v);
  };
  const setSeasonOffset = (fn: (o: number) => number) => {
    setSeasonOffsetState((o) => {
      const next = fn(o);
      setUiState("discover.seasonOffset", next);
      return next;
    });
  };

  const season = useMemo(() => resolveSeason(seasonOffset), [seasonOffset]);
  const genreRowRef = useDragScroll<HTMLDivElement>();
  const themeRowRef = useDragScroll<HTMLDivElement>();

  const { results, isLoading, isError, hasNextPage, fetchNextPage } = useDiscover({
    sort: SORT_BY_TAB[tab],
    season: tab === "seasonal" ? season.season : undefined,
    seasonYear: tab === "seasonal" ? season.year : undefined,
    genre: genre ?? undefined,
    tag: theme ?? undefined,
  });

  const selectTab = (t: Tab) => {
    setTab(t);
    localStorage.setItem(LAST_TAB_KEY, t);
  };

  const activeFilters = [genre, theme].filter(Boolean).join(" + ");

  return (
    <div className="k-page k-discover">
      <div className="k-search__bar">
        <div className="k-searchbar">
          <Icon icon={SearchIcon} size={18} color="var(--color-text-tertiary)" />
          <input
            ref={inputRef}
            className="k-searchbar__input"
            type="search"
            inputMode="search"
            enterKeyHint="search"
            placeholder="Search any anime…"
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
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
              className="k-searchbar__clear"
              onClick={() => setValue("")}
              aria-label="Clear search"
            >
              <Icon icon={X} size={16} />
            </button>
          )}
        </div>
      </div>

      {searchMode ? (
        <SearchResults query={debouncedQuery} />
      ) : showRecents ? (
        // Keep the input focused when a chip is tapped: preventDefault on the
        // panel's mousedown stops the blur that would hide it mid-click.
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

          {tab === "seasonal" && (
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

          <div ref={genreRowRef} className="k-chiprow k-chiprow--scroll" aria-label="Genres">
            {GENRES.map((g) => (
              <Chip
                key={g}
                active={genre === g}
                onClick={() => setGenre(genre === g ? null : g)}
              >
                {g}
              </Chip>
            ))}
          </div>
          <div ref={themeRowRef} className="k-chiprow k-chiprow--scroll" aria-label="Themes">
            {THEMES.map((t) => (
              <Chip
                key={t}
                active={theme === t}
                onClick={() => setTheme(theme === t ? null : t)}
              >
                {t}
              </Chip>
            ))}
          </div>

          {isLoading ? (
            <div className="k-skelgrid">
              {Array.from({ length: 12 }).map((_, i) => (
                <Skeleton key={i} height="auto" style={{ aspectRatio: "2 / 3" }} />
              ))}
            </div>
          ) : isError ? (
            <EmptyState title="Couldn't load this section" subtitle="Check your connection and try again." />
          ) : results.length === 0 ? (
            <EmptyState
              title={activeFilters ? `No ${activeFilters} anime here` : "Nothing to show here yet"}
              subtitle={
                activeFilters
                  ? tab === "seasonal"
                    ? "Try another season, or drop one of the filters."
                    : "Try dropping one of the filters."
                  : undefined
              }
            />
          ) : (
            <AnimeCollection
              items={results}
              view="grid"
              onEndReached={hasNextPage ? () => fetchNextPage() : undefined}
              restoreKey={`discover.scroll.${tab}`}
            />
          )}
        </>
      )}
    </div>
  );
}
