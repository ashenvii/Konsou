import { anilist } from "@/lib/api/anilist/client";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import type { AniListMediaStatus, FuzzyDate, RelationNode } from "@/types/anime";
import type { AnimeListEntry } from "@/types/list";
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

export interface DetectOptions {
  /** Skip the whole run if the last full check was within this window (ms). */
  cooldownMs?: number;
  lastCheckAt?: number | null;
}

/**
 * Returns the notifications to be inserted (caller dedupes via the DB's
 * UNIQUE(source_id, related_id)). Pure of side effects beyond AniList's own
 * relation-snapshot cache.
 */
export async function detectSequels(
  entries: AnimeListEntry[],
  options: DetectOptions = {},
): Promise<Omit<KonsouNotification, "id">[]> {
  if (options.cooldownMs && options.lastCheckAt) {
    if (Date.now() - options.lastCheckAt < options.cooldownMs) return [];
  }

  const inList = new Set(entries.map((e) => e.anilist_id));
  const seeds = entries
    .filter((e) => e.status === "completed" || e.status === "dropped")
    .map((e) => e.anilist_id);

  if (seeds.length === 0) return [];

  const visited = new Set<number>();
  const originOf = new Map<number, number>(); // node id → originating seed id
  seeds.forEach((id) => originOf.set(id, id));

  const found = new Map<number, Omit<KonsouNotification, "id">>(); // keyed by related_id
  let level = [...new Set(seeds)];
  let depth = 0;

  while (level.length > 0 && depth < MAX_DEPTH) {
    const relationMap = await anilist.getRelationsBatch(level);
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

  return [...found.values()];
}

/** Bucket an alert for the Alerts page grouping. */
export function alertBucket(
  n: Pick<KonsouNotification, "related_status">,
): "airing_now" | "announced" | "already_aired" {
  if (n.related_status === "RELEASING") return "airing_now";
  if (n.related_status === "NOT_YET_RELEASED") return "announced";
  return "already_aired"; // FINISHED → missed release
}
