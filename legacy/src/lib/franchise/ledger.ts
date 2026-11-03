import type { AnimeListEntry } from "@/types/list";

/** One franchise member as the ledger sees it: an episode count from AniList
 *  (when known) and the tracked list entry (when it's on the list). */
export interface LedgerMember {
  episodes: number | null | undefined;
  entry: AnimeListEntry | null | undefined;
}

export interface FranchiseLedger {
  memberCount: number;
  trackedCount: number;
  untrackedCount: number;
  watchedEpisodes: number;
  /** Sum of every known episode count across the franchise. */
  knownEpisodes: number;
  /** True when at least one member's episode count is unknown. */
  hasUnknownEpisodes: boolean;
  /** Every member is on the list, and there are at least two of them. */
  fullSet: boolean;
}

/**
 * The completionist's answer to "how much of this series exists, and how much
 * of it have I actually seen". Tracked entries contribute their watched count;
 * untracked members contribute their episode count to the "exists" side only.
 * Pure: callers decide which members make up the franchise (manga/music are
 * expected to be filtered out before this).
 */
export function computeFranchiseLedger(members: LedgerMember[]): FranchiseLedger {
  let watched = 0;
  let known = 0;
  let tracked = 0;
  let hasUnknown = false;

  for (const m of members) {
    // The tracked entry's total wins over the relation snapshot; it's fresher.
    const total = m.entry?.total_episodes ?? m.episodes ?? null;
    if (total != null) known += total;
    else hasUnknown = true;
    if (m.entry) {
      tracked++;
      watched += m.entry.episodes_watched;
    }
  }

  return {
    memberCount: members.length,
    trackedCount: tracked,
    untrackedCount: members.length - tracked,
    watchedEpisodes: watched,
    knownEpisodes: known,
    hasUnknownEpisodes: hasUnknown,
    fullSet: members.length >= 2 && tracked === members.length,
  };
}

/** "59 of 87 episodes", with a "+" when some counts are unknown. */
export function ledgerEpisodeLabel(l: FranchiseLedger): string {
  const exists = `${l.knownEpisodes.toLocaleString()}${l.hasUnknownEpisodes ? "+" : ""}`;
  return `${l.watchedEpisodes.toLocaleString()} of ${exists} episodes`;
}
