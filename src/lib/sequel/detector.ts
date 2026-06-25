import { anilist } from "@/lib/api/anilist/client";
import type { Priority } from "@/lib/api/rateLimiter";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import type { AniListMediaStatus, FuzzyDate, RelationNode } from "@/types/anime";
import type { AlertType, KonsouNotification } from "@/types/notification";

/**
 * Sequel radar — the flagship feature. Walks the AniList relation graph out from
 * every Completed/Dropped entry and surfaces continuations the user hasn't added.
 *
 * BFS (not recursion) keeps the stack flat for large franchise graphs. A visited
 * set prevents re-processing cyclic franchises (Fate/, Monogatari); a depth cap
 * bounds work. SIDE_STORY/SPIN_OFF are followed at depth 0 only — otherwise a
 * single watched anime in a sprawling franchise yields hundreds of alerts.
 */
const MAX_DEPTH = 10;
const ACTIONABLE_STATUSES: AniListMediaStatus[] = [
  "RELEASING",
  "NOT_YET_RELEASED",
  "FINISHED",
];

function fuzzyToUnixSeconds(d?: FuzzyDate | null): number | null {
  if (!d?.year) return null;
  return Math.floor(Date.UTC(d.year, (d.month ?? 1) - 1, d.day ?? 1) / 1000);
}

function alertTypeFor(rel: RelationNode): AlertType {
  if (rel.format === "MOVIE") return "movie";
  if (rel.relationType === "SIDE_STORY") return "side_story";
  if (rel.relationType === "SPIN_OFF") return "spin_off";
  return "sequel";
}

/** Statuses that make a franchise "volatile" — i.e. likely to gain a new entry,
 *  so its seed should be re-checked often rather than backed off. */
const VOLATILE_STATUSES: AniListMediaStatus[] = ["RELEASING", "NOT_YET_RELEASED"];

export interface DetectResult {
  /** Continuations to insert (caller dedupes via UNIQUE(source_id, related_id)). */
  notifications: Omit<KonsouNotification, "id">[];
  /** Seeds whose franchise contains a releasing/announced entry (check often). */
  volatileSeeds: Set<number>;
}

/**
 * Walk the AniList relation graph out from the given seed ids and surface
 * continuations the user hasn't added. `inList` is the full set of tracked ids
 * (used to filter out things already on the list) and is independent of which
 * seeds we're scanning this pass — the scheduler scans seeds in batches, but
 * always filters against the whole list.
 *
 * Pure of side effects beyond AniList's own relation-snapshot cache;
 * persistence and scheduling are the caller's concern.
 */
export async function detectSequels(
  seeds: number[],
  inList: Set<number>,
  priority: Priority = "low",
): Promise<DetectResult> {
  const volatileSeeds = new Set<number>();
  if (seeds.length === 0) return { notifications: [], volatileSeeds };

  const visited = new Set<number>();
  const originOf = new Map<number, number>(); // node id → originating seed id
  seeds.forEach((id) => originOf.set(id, id));

  const found = new Map<number, Omit<KonsouNotification, "id">>(); // keyed by related_id
  let level = [...new Set(seeds)];
  let depth = 0;

  while (level.length > 0 && depth < MAX_DEPTH) {
    const relationMap = await anilist.getRelationsBatch(level, priority);
    const next: number[] = [];

    for (const id of level) {
      if (visited.has(id)) continue;
      visited.add(id);
      const origin = originOf.get(id) ?? id;

      for (const rel of relationMap[id] ?? []) {
        const isDirectChild = depth === 0;
        const shouldWalk =
          rel.relationType === "SEQUEL" ||
          (isDirectChild &&
            (rel.relationType === "SIDE_STORY" ||
              rel.relationType === "SPIN_OFF"));
        if (!shouldWalk) continue;

        if (!originOf.has(rel.id)) originOf.set(rel.id, origin);

        // A releasing/announced entry anywhere in the franchise makes the
        // originating seed volatile, regardless of whether it's already tracked.
        if (rel.status && VOLATILE_STATUSES.includes(rel.status)) {
          volatileSeeds.add(origin);
        }

        // Actionable + not already tracked + not already found.
        if (
          !inList.has(rel.id) &&
          !found.has(rel.id) &&
          rel.status &&
          ACTIONABLE_STATUSES.includes(rel.status)
        ) {
          found.set(rel.id, {
            source_id: origin,
            related_id: rel.id,
            type: alertTypeFor(rel),
            related_title: preferredTitle(rel.title),
            related_cover: getCoverUrl(rel.coverImage) || null,
            related_status: rel.status,
            airing_at:
              rel.nextAiringEpisode?.airingAt ??
              fuzzyToUnixSeconds(rel.startDate),
            seen: 0,
            dismissed: 0,
            created_at: Date.now(),
          });
        }

        if (!visited.has(rel.id)) next.push(rel.id);
      }
    }

    level = [...new Set(next)];
    depth++;
  }

  return { notifications: [...found.values()], volatileSeeds };
}

/** Bucket an alert for the Alerts page grouping. */
export function alertBucket(
  n: Pick<KonsouNotification, "related_status">,
): "airing_now" | "announced" | "already_aired" {
  if (n.related_status === "RELEASING") return "airing_now";
  if (n.related_status === "NOT_YET_RELEASED") return "announced";
  return "already_aired"; // FINISHED → missed release
}
