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
  /** Pre-computed sort keys used by the Overview and room sorts. */
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
  // A "won't watch" member never speaks for the whole franchise card.
  not_interested: 0,
};

/**
 * Story position of an entry within its franchise, lowest first.
 *
 * The root is the chain's start by construction (resolveFranchiseChain walks
 * PREQUEL edges until nothing precedes it), so it always leads. After that,
 * anilist_id ascends roughly with release, which is the closest thing to watch
 * order available here: this function is pure and runs over the whole library
 * on every group, so it cannot reach for relation edges the way
 * `orderForWatching` does.
 */
function storyRank(e: AnimeListEntry, rootId: number): number {
  return e.anilist_id === rootId ? -1 : e.anilist_id;
}

/**
 * Pick the entry that best represents where the user currently is.
 *
 * Ties between same-status members break on story position, NOT on when the
 * user happened to add them. Adding season 2 before season 1 used to make
 * season 2 the card's current entry — so Start, Complete and the loupe all
 * acted on the middle of a franchise while its first season sat unwatched.
 */
function pickDisplayEntry(
  sortedEntries: AnimeListEntry[],
  rootId: number,
): AnimeListEntry {
  const earliest = (match: (e: AnimeListEntry) => boolean) => {
    let best: AnimeListEntry | undefined;
    for (const e of sortedEntries) {
      if (!match(e)) continue;
      if (!best || storyRank(e, rootId) < storyRank(best, rootId)) best = e;
    }
    return best;
  };

  // Active watch states win immediately.
  const active = earliest(
    (e) => e.status === "watching" || e.status === "rewatching",
  );
  if (active) return active;

  // Next-in-queue: the earliest planned season signals what's coming up.
  const planned = earliest((e) => e.status === "plan_to_watch");
  if (planned) return planned;

  // Something stalled.
  const onHold = earliest((e) => e.status === "on_hold");
  if (onHold) return onHold;

  // All completed or dropped: revert to the franchise root artwork (S1).
  const root = sortedEntries.find((e) => e.anilist_id === rootId);
  if (root) return root;
  // The root itself was never tracked (never added, or muted not_interested,
  // which drops it from this bucket the same way). Falling back to array
  // position 0 would revert to whichever member was added to the list
  // first — the exact added_at-over-story-order bug this function's own
  // tie-break exists to prevent, just reintroduced in this one branch. Use
  // the same story-rank pick `earliest` already applies above.
  return earliest(() => true) ?? sortedEntries[0];
}

/**
 * Collapse a flat entry list into franchise groups. Entries without a
 * franchise_root_id are treated as standalone (group of 1). Pure — no I/O.
 *
 * "Not interested" is a mute flag, not a card. Such entries are dropped here
 * entirely: they never appear on My List, never form a standalone card, and
 * never join a franchise group (so marking one member not-interested can't
 * change how the rest of the franchise's card looks). The row still lives in
 * the store map, so franchise views (quick menu, Related tab) can render it
 * dimmed and the surfacing filters (schedule, alerts, radar, catch-up) can
 * skip it — it just isn't a thing on the main list.
 */
export function groupEntries(entries: AnimeListEntry[]): FranchiseGroup[] {
  const byRoot = new Map<number, AnimeListEntry[]>();

  for (const e of entries) {
    if (e.status === "not_interested") continue;
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
 * The score that represents a whole card: the best any member earned. One rule
 * for every surface (shelf badge, franchise card chip, list row), so the same
 * franchise never shows two different numbers depending on where you look.
 */
export function bestScore(entries: AnimeListEntry[]): number | null {
  return entries.reduce<number | null>(
    (best, e) => (e.score != null && (best == null || e.score > best) ? e.score : best),
    null,
  );
}

/**
 * Re-export the display priority so FranchiseCard can read the active status
 * without re-deriving it.
 */
export { DISPLAY_PRIORITY };
