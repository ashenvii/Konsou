import { anilist } from "@/lib/api/anilist/client";
import type { KonsouDb } from "@/lib/db/contract";
import type { AnimeListEntry } from "@/types/list";
import type { KonsouNotification } from "@/types/notification";

export interface AiringScanResult {
  notifications: KonsouNotification[];
  /** ids whose airing_status changed and need to be reloaded into memory */
  updatedIds: number[];
}

/**
 * Check every plan_to_watch entry that was previously NOT_YET_RELEASED to see
 * if it has flipped to RELEASING. For each transition:
 *   - Updates airing_status in the DB
 *   - Creates a "started_airing" notification so Alerts surfaces it
 *
 * Called from runScheduledScan on each background cycle. Uses the shared
 * low-priority rate limiter via getAiringStatusBatch.
 */
export async function scanPlanToWatchAirings(
  entries: AnimeListEntry[],
  db: KonsouDb,
): Promise<AiringScanResult> {
  const targets = entries.filter(
    (e) =>
      e.status === "plan_to_watch" && e.airing_status === "NOT_YET_RELEASED",
  );
  if (targets.length === 0) return { notifications: [], updatedIds: [] };

  const ids = targets.map((e) => e.anilist_id);
  const fresh = await anilist.getAiringStatusBatch(ids, "low");

  const now = Math.floor(Date.now() / 1000);
  const notifications: KonsouNotification[] = [];
  const updatedIds: number[] = [];

  for (const entry of targets) {
    const info = fresh.get(entry.anilist_id);
    if (!info) continue;

    if (info.status !== entry.airing_status) {
      await db.listUpdate(entry.anilist_id, { airing_status: info.status });
      updatedIds.push(entry.anilist_id);
    }

    if (info.status !== "RELEASING") continue;

    // Estimate finish: if we know nextAiringEpisode and total episodes,
    // project forward by the remaining episode count at ~7 days/ep.
    let estimatedFinish: number | null = null;
    if (info.nextAiringAt != null && info.episodes != null) {
      const nextEp = (info as any).nextAiringEpisode?.episode ?? 1;
      const remaining = info.episodes - nextEp + 1;
      const nextAiringMs = info.nextAiringAt * 1000;
      estimatedFinish = Math.floor(
        (nextAiringMs + remaining * 7 * 24 * 60 * 60 * 1000) / 1000,
      );
    }

    notifications.push({
      source_id: entry.anilist_id,
      related_id: entry.anilist_id,
      type: "started_airing",
      related_title: entry.title_romaji,
      related_cover: entry.cover_url,
      related_status: "RELEASING",
      airing_at: estimatedFinish,
      seen: 0,
      dismissed: 0,
      created_at: now,
    });
  }

  return { notifications, updatedIds };
}
