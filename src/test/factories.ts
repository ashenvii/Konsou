import type { AnimeListEntry } from "@/types/list";

/**
 * A complete list entry with sane defaults, so a test only has to state the
 * fields it actually cares about. Every field is spelled out rather than cast,
 * so adding a column to AnimeListEntry breaks here once instead of failing
 * mysteriously in a merge test later.
 */
export function makeEntry(
  overrides: Partial<AnimeListEntry> & { anilist_id: number },
): AnimeListEntry {
  return {
    mal_id: null,
    title_romaji: `Title ${overrides.anilist_id}`,
    title_english: null,
    title_native: null,
    cover_url: null,
    total_episodes: 12,
    status: "watching",
    episodes_watched: 0,
    score: null,
    notes: null,
    added_at: 1_000,
    updated_at: 1_000,
    started_at: null,
    completed_at: null,
    has_dub: null,
    episode_duration: null,
    rewatch_count: 0,
    aired_episodes: null,
    franchise_root_id: null,
    plan_rank: null,
    airing_status: null,
    ...overrides,
  };
}
