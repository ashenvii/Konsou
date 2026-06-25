import { useMemo, useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { AnimeCollection } from "@/components/list/AnimeCollection";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { PageHeader } from "@/components/layout/PageHeader";
import { Skeleton } from "@/components/ui/Skeleton";
import { useDiscover } from "@/hooks/useAniList";
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
  const [tab, setTab] = useState<Tab>(
    () => (localStorage.getItem(LAST_TAB_KEY) as Tab) ?? "trending",
  );
  const [genre, setGenre] = useState<string | null>(null);
  const [seasonOffset, setSeasonOffset] = useState(0);

  const season = useMemo(() => resolveSeason(seasonOffset), [seasonOffset]);

  const { results, isLoading, isError, hasNextPage, fetchNextPage } = useDiscover({
    sort: SORT_BY_TAB[tab],
    season: tab === "seasonal" ? season.season : undefined,
    seasonYear: tab === "seasonal" ? season.year : undefined,
    genre: tab !== "seasonal" ? genre ?? undefined : undefined,
  });

  const selectTab = (t: Tab) => {
    setTab(t);
    localStorage.setItem(LAST_TAB_KEY, t);
  };

  return (
    <div className="k-page">
      <PageHeader title="Discover" />

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

      {tab === "seasonal" ? (
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
      ) : (
        <div className="k-chiprow k-chiprow--scroll">
          {GENRES.map((g) => (
            <Chip
              key={g}
              active={genre === g}
              onClick={() => setGenre((cur) => (cur === g ? null : g))}
            >
              {g}
            </Chip>
          ))}
        </div>
      )}

      {isLoading ? (
        <div className="k-skelgrid">
          {Array.from({ length: 12 }).map((_, i) => (
            <Skeleton key={i} height="auto" style={{ aspectRatio: "2 / 3" }} />
          ))}
        </div>
      ) : isError ? (
        <EmptyState title="Couldn't load this section" subtitle="Check your connection and try again." />
      ) : results.length === 0 ? (
        <EmptyState title="Nothing to show here yet" />
      ) : (
        <AnimeCollection
          items={results}
          view="grid"
          onEndReached={hasNextPage ? () => fetchNextPage() : undefined}
        />
      )}
    </div>
  );
}
