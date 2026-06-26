import type { AnimeListEntry, ListStatus } from "@/types/list";

/**
 * One card's worth of data on My List. A standalone entry (single tracked
 * item with no franchise siblings) is wrapped as a group of 1 so the list
 * renderer always works with a uniform shape.
 */
export interface FranchiseGroup {
  /** franchise_root_id, or the lone entry's own anilist_id for standalones. */
  rootId: number;
  /** Tracked entries for this franchise, sorted by added_at ASC. */
  entries: AnimeListEntry[];
  /**
   * The entry whose cover and status badge represent the whole group.
   * Priority: watching → rewatching → plan_to_watch → on_hold → root (S1) → first entry.
   * The card "follows" where the user is in the franchise; completing everything
   * reverts to the root artwork.
   */
  displayEntry: AnimeListEntry;
  /** True when 2+ entries are grouped — drives FranchiseCard vs plain AnimeCard. */
  isGroup: boolean;
  /** Sum of episodes_watched across all entries. */
  totalWatched: number;
  /** Sum of total_episodes, or null if any entry has an unknown episode count. */
  totalEpisodes: number | null;
  /** Pre-computed sort keys used by MyList's compareGroups. */
  sortUpdated: number;
  sortAdded: number;
}

// Priority order for selecting the display entry. Higher = shown first.
const DISPLAY_PRIORITY: Record<ListStatus, number> = {
  watching: 6,
  rewatching: 5,
  plan_to_watch: 4,
  on_hold: 3,
  completed: 2,
  dropped: 1,
};

/**
 * Pick the entry that best represents where the user currently is.
 * `sortedEntries` is already ordered by added_at ASC so .find() returns
 * the earliest one for tied-priority statuses (e.g. first plan_to_watch
 * in the chain rather than a later one).
 */
function pickDisplayEntry(
  sortedEntries: AnimeListEntry[],
  rootId: number,
): AnimeListEntry {
  // Active watch states win immediately.
  const active = sortedEntries.find(
    (e) => e.status === "watching" || e.status === "rewatching",
  );
  if (active) return active;

  // Next-in-queue: the earliest plan_to_watch signals what's coming up.
  const planned = sortedEntries.find((e) => e.status === "plan_to_watch");
  if (planned) return planned;

  // Something stalled.
  const onHold = sortedEntries.find((e) => e.status === "on_hold");
  if (onHold) return onHold;

  // All completed or dropped: revert to the franchise root artwork (S1).
  const root = sortedEntries.find((e) => e.anilist_id === rootId);
  return root ?? sortedEntries[0];
}

/**
 * Collapse a flat entry list into franchise groups. Entries without a
 * franchise_root_id are treated as standalone (group of 1). Pure — no I/O.
 */
export function groupEntries(entries: AnimeListEntry[]): FranchiseGroup[] {
  const byRoot = new Map<number, AnimeListEntry[]>();

  for (const e of entries) {
    const key = e.franchise_root_id ?? e.anilist_id;
    const bucket = byRoot.get(key);
    if (bucket) bucket.push(e);
    else byRoot.set(key, [e]);
  }

  const groups: FranchiseGroup[] = [];

  for (const [rootId, members] of byRoot) {
    const sorted = [...members].sort((a, b) => a.added_at - b.added_at);
    const displayEntry = pickDisplayEntry(sorted, rootId);

    let totalWatched = 0;
    let totalEpisodes: number | null = 0;
    let sortUpdated = 0;
    let sortAdded = Infinity;

    for (const e of sorted) {
      totalWatched += e.episodes_watched;
      if (totalEpisodes !== null) {
        totalEpisodes = e.total_episodes == null ? null : totalEpisodes + e.total_episodes;
      }
      if (e.updated_at > sortUpdated) sortUpdated = e.updated_at;
      if (e.added_at < sortAdded) sortAdded = e.added_at;
    }

    groups.push({
      rootId,
      entries: sorted,
      displayEntry,
      isGroup: sorted.length > 1,
      totalWatched,
      totalEpisodes,
      sortUpdated,
      sortAdded,
    });
  }

  return groups;
}

/**
 * Re-export the display priority so FranchiseCard can read the active status
 * without re-deriving it.
 */
export { DISPLAY_PRIORITY };
