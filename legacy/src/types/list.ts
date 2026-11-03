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

/**
 * The real watch statuses — everything except the `not_interested` mute flag.
 * not_interested is not a place in your list; it's a per-entry "don't surface
 * this one" marker. It never forms a card, so it never appears in the My List
 * status filter or the Stats status breakdown. Anything that enumerates
 * statuses *for display of the list itself* uses this; the status PICKER still
 * offers not_interested (from LIST_STATUSES) because choosing it is how you
 * mute an entry.
 */
export const WATCH_STATUSES: ListStatus[] = LIST_STATUSES.filter(
  (s) => s !== "not_interested",
);

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
   * Your manual position in the plan-to-watch queue. Lower sorts first.
   * null = never ranked, which falls back to date-added, so an untouched list
   * needs no backfill. Only meaningful while status is plan_to_watch.
   */
  plan_rank: number | null;
  /**
   * AniList media airing status at the time of last sync. Drives status-picker guards and
   * plan-to-watch airing notifications. null = unknown (entry predates this field).
   * Values: "FINISHED" | "RELEASING" | "NOT_YET_RELEASED" | "CANCELLED" | "HIATUS"
   */
  airing_status: string | null;
}

/**
 * One finished watch. Immutable and append-only: finishing a title writes a
 * row, and every later rewatch writes its own, so the record is a list of dated
 * events rather than a single `completed_at` column that the first finish
 * claimed forever.
 *
 * The title, cover and episode count are copied in rather than looked up, which
 * is what lets a completion still render after the entry is removed from the
 * list (the ledger's ghost records). Identity is (anilist_id, rewatch_index):
 * the Nth completion of a title is one event whichever device recorded it, so
 * two devices' logs union cleanly.
 */
export interface CompletionEvent {
  anilist_id: number;
  /** 0 = first watch, 1 = first rewatch, and so on. */
  rewatch_index: number;
  /** When this particular watch was finished (Unix ms). */
  completed_at: number;
  episodes_at_completion: number;
  /** Minutes per episode as known at the time; null falls back to 24 in Stats. */
  episode_duration: number | null;
  total_episodes: number | null;
  title_romaji: string;
  title_english: string | null;
  title_native: string | null;
  cover_url: string | null;
  franchise_root_id: number | null;
  /**
   * True for rows the v12 migration reconstructed from the old single
   * `completed_at` + `rewatch_count`. The watch happened; the date is the best
   * available guess, so the ledger marks it instead of presenting it as fact.
   */
  estimated: boolean;
}

/** Derived, not stored: index 0 is the first watch, anything above is a rewatch. */
export function isRewatchEvent(e: CompletionEvent): boolean {
  return e.rewatch_index > 0;
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
    | "plan_rank"
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

export type ThemeMode = "dark" | "light" | "system"; // reserved for future brightness toggle

/**
 * The worlds. Two, and only two: a theme is a filled-in set of the role
 * tokens in `src/styles/tokens.css` (layer 2), nothing more. The eight
 * Field Guide plates and the per-user accent inks they carried are gone;
 * the world owns its own two hues now, so there is no second axis to pick.
 */
export type ColorTheme = "lantern" | "neon";

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

/** How much motion the app is allowed. "system" resolves from the device;
 *  see lib/motion.ts for why the other two exist. */
export type MotionMode = "full" | "lite" | "system";
