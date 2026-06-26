import type {
  AnimeListEntry,
  DeletionTombstone,
  ListStatus,
} from "@/types/list";

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
    // Prefer whichever device has already resolved the franchise root.
    franchise_root_id: local.franchise_root_id ?? remote.franchise_root_id,
    // Airing status only advances (NOT_YET_RELEASED → RELEASING → FINISHED).
    // Take the further-along value so a device that already scanned the new
    // status doesn't get regressed by a stale remote.
    airing_status: advanceAiringStatus(local.airing_status, remote.airing_status),
  };
}

export interface MergeResult {
  entries: AnimeListEntry[];
  tombstones: DeletionTombstone[];
}

/** Union two tombstone sets, keeping the latest deletion time per id. */
export function mergeTombstones(
  a: DeletionTombstone[],
  b: DeletionTombstone[],
): DeletionTombstone[] {
  const byId = new Map<number, number>();
  for (const t of [...a, ...b]) {
    byId.set(t.anilist_id, Math.max(byId.get(t.anilist_id) ?? 0, t.deleted_at));
  }
  return [...byId].map(([anilist_id, deleted_at]) => ({ anilist_id, deleted_at }));
}

/**
 * Merge two full lists (with their tombstones) keyed by anilist_id.
 *
 * Deletions reconcile against edits by timestamp: a tombstone wins only when its
 * `deleted_at` is at or after the entry's `updated_at`. A later re-add (which
 * bumps `updated_at`) therefore resurrects the entry and drops the tombstone.
 * Tombstones for ids absent from both lists are kept so the deletion keeps
 * propagating to devices that still hold the entry.
 */
export function mergeLists(
  local: AnimeListEntry[],
  remote: AnimeListEntry[],
  localTombstones: DeletionTombstone[] = [],
  remoteTombstones: DeletionTombstone[] = [],
): MergeResult {
  const byId = new Map<number, AnimeListEntry>();
  for (const e of local) byId.set(e.anilist_id, e);
  for (const r of remote) {
    const l = byId.get(r.anilist_id);
    byId.set(r.anilist_id, l ? mergeAnimeEntry(l, r) : r);
  }

  const tombById = new Map<number, number>();
  for (const t of mergeTombstones(localTombstones, remoteTombstones)) {
    tombById.set(t.anilist_id, t.deleted_at);
  }

  const entries: AnimeListEntry[] = [];
  const tombstones: DeletionTombstone[] = [];
  for (const e of byId.values()) {
    const deletedAt = tombById.get(e.anilist_id);
    if (deletedAt != null && deletedAt >= e.updated_at) {
      // Deletion is newer than the last edit — drop the entry, keep the tombstone.
      tombstones.push({ anilist_id: e.anilist_id, deleted_at: deletedAt });
    } else {
      // Entry is live (never deleted, or re-added after the deletion).
      entries.push(e);
    }
    tombById.delete(e.anilist_id);
  }
  // Tombstones whose entry isn't present anywhere — keep propagating them.
  for (const [anilist_id, deleted_at] of tombById) {
    tombstones.push({ anilist_id, deleted_at });
  }

  return { entries, tombstones };
}

const AIRING_RANK: Record<string, number> = {
  NOT_YET_RELEASED: 0,
  HIATUS: 1,
  RELEASING: 2,
  CANCELLED: 3,
  FINISHED: 3,
};

function advanceAiringStatus(a: string | null, b: string | null): string | null {
  if (!a) return b;
  if (!b) return a;
  return (AIRING_RANK[a] ?? 0) >= (AIRING_RANK[b] ?? 0) ? a : b;
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
