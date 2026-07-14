/**
 * Discover landing configuration: the editorial lanes on the default view, plus
 * the shape of the all-anime filtered browse they drill into.
 *
 * Each lane owns a `useDiscover` param set (page 1, a horizontal row) and a
 * `seeAll` browse state that opens the inline-filter browse pre-narrowed to that
 * lane — so "See all" on Action lands in a genre-filtered browse, not a generic
 * wall.
 */
import type { DiscoverParams } from "@/hooks/useAniList";
import type { BrowseSort } from "@/lib/api/anilist/client";
import type { MediaFormat, MediaSeason } from "@/types/anime";

/**
 * The all-anime browse, driven by inline single-select controls (AniList /
 * Aniwaves style) plus the shared keyword. Sort is its own control, so nothing
 * is welded to a tab that can scroll off-screen.
 */
export interface BrowseState {
  sort: BrowseSort;
  genre: string | null;
  format: MediaFormat | null;
  season: MediaSeason | null;
  year: number | null;
}

export const EMPTY_BROWSE: BrowseState = {
  sort: "TRENDING_DESC",
  genre: null,
  format: null,
  season: null,
  year: null,
};

export function browseActive(b: BrowseState): boolean {
  return Boolean(b.genre || b.format || b.season || b.year);
}

// ── Season maths ────────────────────────────────────────────────────────────
const SEASONS: MediaSeason[] = ["WINTER", "SPRING", "SUMMER", "FALL"];

function baseSeasonIndex(month: number): number {
  if (month === 12 || month <= 2) return 0; // winter
  if (month <= 5) return 1; // spring
  if (month <= 8) return 2; // summer
  return 3; // fall
}

/** The season `offset` steps away from the current one (negative = past). */
export function resolveSeason(offset: number): { season: MediaSeason; year: number } {
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

/** "FALL" → "Fall". */
export function seasonLabel(season: MediaSeason): string {
  return season.charAt(0) + season.slice(1).toLowerCase();
}

// ── Lanes ───────────────────────────────────────────────────────────────────
export interface Lane {
  key: string;
  title: string;
  /** page-1 params for the row's own useDiscover call. */
  params: DiscoverParams;
  /** the browse state "See all" opens. */
  seeAll: BrowseState;
}

/**
 * The lane set. Recomputed per call so "This Season" tracks the calendar; the
 * queries are cheap and cached. Order is deliberate, not a uniform shelf grid:
 * the seasonal pulse first, then the two momentum lanes, then evergreen
 * genre/format entry points.
 */
export function buildLanes(): Lane[] {
  const s = resolveSeason(0);
  return [
    {
      key: "season",
      title: "This Season",
      params: { sort: "POPULARITY_DESC", season: s.season, seasonYear: s.year },
      seeAll: { ...EMPTY_BROWSE, sort: "POPULARITY_DESC", season: s.season, year: s.year },
    },
    {
      key: "trending",
      title: "Trending Now",
      params: { sort: "TRENDING_DESC" },
      seeAll: { ...EMPTY_BROWSE, sort: "TRENDING_DESC" },
    },
    {
      key: "top",
      title: "Top Rated",
      params: { sort: "SCORE_DESC" },
      seeAll: { ...EMPTY_BROWSE, sort: "SCORE_DESC" },
    },
    {
      key: "action",
      title: "Action",
      params: { sort: "POPULARITY_DESC", genres: ["Action"] },
      seeAll: { ...EMPTY_BROWSE, sort: "POPULARITY_DESC", genre: "Action" },
    },
    {
      key: "romance",
      title: "Romance",
      params: { sort: "POPULARITY_DESC", genres: ["Romance"] },
      seeAll: { ...EMPTY_BROWSE, sort: "POPULARITY_DESC", genre: "Romance" },
    },
    {
      key: "movies",
      title: "Movies",
      params: { sort: "POPULARITY_DESC", formats: ["MOVIE"] },
      seeAll: { ...EMPTY_BROWSE, sort: "POPULARITY_DESC", format: "MOVIE" },
    },
  ];
}
