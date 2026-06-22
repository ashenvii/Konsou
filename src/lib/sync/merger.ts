import type { AnimeListEntry, ListStatus } from "@/types/list";

/**
 * Field-level, clock-skew-tolerant merge for Drive sync. Pure logic, no I/O —
 * tested in isolation before any sync code touches the network (Trap 6).
 *
 * Android devices with aggressive battery optimization can suppress NTP and
 * drift 30–60s, so a 30s tolerance window guards recency-based fields.
 */
export const CLOCK_SKEW_TOLERANCE_MS = 30_000;

const STATUS_PRIORITY: Record<ListStatus, number> = {
  completed: 6,
  rewatching: 5,
  watching: 4,
  on_hold: 3,
  dropped: 2,
  plan_to_watch: 1,
};

export function higherPriorityStatus(a: ListStatus, b: ListStatus): ListStatus {
  return STATUS_PRIORITY[a] >= STATUS_PRIORITY[b] ? a : b;
}

export function mergeAnimeEntry(
  local: AnimeListEntry,
  remote: AnimeListEntry,
): AnimeListEntry {
  const timeDiff = Math.abs(local.updated_at - remote.updated_at);
  const ambiguous = timeDiff < CLOCK_SKEW_TOLERANCE_MS;

  // Progress never goes backward — clock skew irrelevant.
  const episodes_watched = Math.max(
    local.episodes_watched,
    remote.episodes_watched,
  );

  // Status: priority order when timestamps are ambiguous, else latest wins.
  const status = ambiguous
    ? higherPriorityStatus(local.status, remote.status)
    : local.updated_at > remote.updated_at
      ? local.status
      : remote.status;

  // Recency-sensitive fields, with skew tolerance favouring local on ties.
  const useLocal = local.updated_at >= remote.updated_at - CLOCK_SKEW_TOLERANCE_MS;
  const score = useLocal ? local.score : remote.score;
  const notes = useLocal ? local.notes : remote.notes;

  return {
    ...local,
    episodes_watched,
    status,
    score,
    notes,
    // Keep the earliest "added" time.
    added_at: Math.min(local.added_at, remote.added_at),
    started_at: minDefined(local.started_at, remote.started_at),
    completed_at: maxDefined(local.completed_at, remote.completed_at),
    updated_at: Math.max(local.updated_at, remote.updated_at),
  };
}

/** Merge two full lists keyed by anilist_id. */
export function mergeLists(
  local: AnimeListEntry[],
  remote: AnimeListEntry[],
): AnimeListEntry[] {
  const byId = new Map<number, AnimeListEntry>();
  for (const e of local) byId.set(e.anilist_id, e);
  for (const r of remote) {
    const l = byId.get(r.anilist_id);
    byId.set(r.anilist_id, l ? mergeAnimeEntry(l, r) : r);
  }
  return [...byId.values()];
}

function minDefined(a: number | null, b: number | null): number | null {
  if (a == null) return b;
  if (b == null) return a;
  return Math.min(a, b);
}
function maxDefined(a: number | null, b: number | null): number | null {
  if (a == null) return b;
  if (b == null) return a;
  return Math.max(a, b);
}
