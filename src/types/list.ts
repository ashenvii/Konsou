/** User list + preferences types. Mirrors the `anime_list` SQLite table. */

export type ListStatus =
  | "watching"
  | "completed"
  | "plan_to_watch"
  | "on_hold"
  | "dropped"
  | "rewatching"
  | "not_interested";

export const LIST_STATUSES: ListStatus[] = [
  "watching",
  "completed",
  "plan_to_watch",
  "on_hold",
  "dropped",
  "rewatching",
  "not_interested",
];

/** A row in the user's list. Timestamps are Unix milliseconds. */
export interface AnimeListEntry {
  id?: number;
  anilist_id: number;
  mal_id: number | null;
  title_romaji: string;
  title_english: string | null;
  title_native: string | null;
  cover_url: string | null;
  total_episodes: number | null;
  status: ListStatus;
  episodes_watched: number;
  score: number | null;
  notes: string | null;
  added_at: number;
  updated_at: number;
  started_at: number | null;
  completed_at: number | null;
  /** null = not yet determined (detail not visited), true = dub available, false = sub only */
  has_dub: boolean | null;
  /** Minutes per episode from AniList. null = unknown; stats fall back to 24. */
  episode_duration: number | null;
  /** Completed prior watches. Incremented when a completed entry flips to
   *  rewatching, so the finished watch keeps its time credit while
   *  episodes_watched restarts from zero. */
  rewatch_count: number;
  /** Episodes actually aired, from nextAiringEpisode. null = unknown; for
   *  FINISHED shows the total is the aired count. Keeps "episodes left"
   *  honest for airing shows with a known planned total. */
  aired_episodes: number | null;
  /** anilist_id of the first entry in this franchise's SEQUEL chain. null = unresolved or standalone. */
  franchise_root_id: number | null;
  /**
   * AniList media airing status at the time of last sync. Drives status-picker guards and
   * plan-to-watch airing notifications. null = unknown (entry predates this field).
   * Values: "FINISHED" | "RELEASING" | "NOT_YET_RELEASED" | "CANCELLED" | "HIATUS"
   */
  airing_status: string | null;
}

/**
 * A deletion record. When an entry is removed locally we keep a tombstone so the
 * deletion can propagate during sync — without it, a delete on one device is
 * resurrected by the merge on the next pull. `deleted_at` is Unix milliseconds.
 */
export interface DeletionTombstone {
  anilist_id: number;
  deleted_at: number;
}

/** Patch shape for updating an existing entry. */
export type ListEntryPatch = Partial<
  Pick<
    AnimeListEntry,
    | "status"
    | "episodes_watched"
    | "score"
    | "notes"
    | "started_at"
    | "completed_at"
    | "total_episodes"
    | "has_dub"
    | "franchise_root_id"
    | "airing_status"
    | "episode_duration"
    | "rewatch_count"
    | "aired_episodes"
  >
>;

export type ViewMode = "grid" | "list" | "compact";

export type SortKey = "title" | "updated" | "score" | "episodes" | "added";
export type SortOrder = "asc" | "desc";

export interface SortSpec {
  key: SortKey;
  order: SortOrder;
}

/** "all" is the no-filter pseudo-tab on My List. */
export type ListFilter = ListStatus | "all";

export type AccentName = "coral" | "violet" | "cobalt" | "crimson" | "sakura" | "amber" | "aqua" | "jade";
export type ThemeMode = "dark" | "light" | "system"; // reserved for future brightness toggle
export type ColorTheme = "void" | "ocean" | "ember" | "forest" | "midnight" | "crimson" | "paper" | "ash";

/**
 * Which title a user sees first. Mirrors AniList's title-language setting:
 *  - romaji  → latinized Japanese ("Sousou no Frieren")  [default]
 *  - english → official English ("Frieren: Beyond Journey's End")
 *  - native  → Japanese script ("葬送のフリーレン")
 */
export type TitleLanguage = "romaji" | "english" | "native";

/**
 * Desktop sidebar behaviour:
 *  - rail     → static icon-only rail, never expands
 *  - hover    → collapsed rail that expands over the content while pointed at
 *  - expanded → permanently open; the page reflows to sit beside it
 */
export type SidebarMode = "rail" | "hover" | "expanded";
