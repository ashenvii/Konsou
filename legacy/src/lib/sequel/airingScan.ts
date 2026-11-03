import { airedEpisodes } from "@/lib/format";
import { anilist } from "@/lib/api/anilist/client";
import type { KonsouDb } from "@/lib/db/contract";
import type { AnimeListEntry, ListEntryPatch } from "@/types/list";
import type { KonsouNotification } from "@/types/notification";

export interface AiringScanResult {
  notifications: KonsouNotification[];
  /** ids whose airing_status changed and need to be reloaded into memory */
  updatedIds: number[];
}

/**
 * Two jobs share one batched fetch, because both need the same AniList data
 * (current status, episode total, next-airing episode number) for whatever
 * of the user's titles could still be airing:
 *
 *  1. A plan_to_watch entry that was NOT_YET_RELEASED and has now started
 *     airing gets a "started_airing" notification.
 *  2. A watching/rewatching entry that is already RELEASING gets its
 *     `aired_episodes` (and, if it was unknown, `total_episodes`) refreshed.
 *
 * (2) is the reason this scan exists at all beyond the notification: without
 * it, `aired_episodes` — the real ceiling `listStore.setEpisodes` enforces so
 * a still-airing show can't be logged past what exists yet — only ever
 * refreshes when the user happens to visit that title's own detail page or
 * the Airing tab's Episodes panel. Someone who only ever logs from the
 * Watching room's own card, QuickMenu, or Overview's on-now stamp would never
 * trigger either, and the ceiling would freeze at whatever it was when the
 * title was added — eventually blocking episodes that have genuinely aired
 * since. This runs on the same background cycle as the notification scan, at
 * the same low priority, so a title being watched stays caught up without the
 * user having to go lookfor it.
 *
 * Called from runScheduledScan on each background cycle. Uses the shared
 * low-priority rate limiter via getAiringStatusBatch.
 */
export async function scanPlanToWatchAirings(
  entries: AnimeListEntry[],
  db: KonsouDb,
): Promise<AiringScanResult> {
  const planTargets = entries.filter(
    (e) =>
      e.status === "plan_to_watch" && e.airing_status === "NOT_YET_RELEASED",
  );
  const watchingTargets = entries.filter(
    (e) =>
      (e.status === "watching" || e.status === "rewatching") &&
      e.airing_status === "RELEASING",
  );
  const targets = [...planTargets, ...watchingTargets];
  if (targets.length === 0) return { notifications: [], updatedIds: [] };

  const ids = targets.map((e) => e.anilist_id);
  const fresh = await anilist.getAiringStatusBatch(ids, "low");

  const now = Math.floor(Date.now() / 1000);
  const notifications: KonsouNotification[] = [];
  const updatedIds: number[] = [];

  for (const entry of planTargets) {
    const info = fresh.get(entry.anilist_id);
    if (!info) continue;

    if (info.status !== entry.airing_status) {
      await db.listUpdate(entry.anilist_id, { airing_status: info.status, updated_at: now });
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

  // Silent: this half never produces a notification, just keeps the episode
  // ceiling honest. A long-runner with no fixed episode count yet (One
  // Piece and the like) still resolves correctly — `airedEpisodes` returns
  // whatever the next-airing episode number says has already aired, entirely
  // independent of `total_episodes` being known.
  for (const entry of watchingTargets) {
    const info = fresh.get(entry.anilist_id);
    if (!info) continue;

    const patch: ListEntryPatch = {};
    const aired = airedEpisodes({
      status: info.status,
      episodes: info.episodes,
      nextAiringEpisode: info.nextEpisode != null ? { episode: info.nextEpisode } : null,
    });
    if (aired != null && entry.aired_episodes !== aired) patch.aired_episodes = aired;
    if (entry.total_episodes == null && info.episodes != null) {
      patch.total_episodes = info.episodes;
    }
    if (info.status !== entry.airing_status) patch.airing_status = info.status;

    if (Object.keys(patch).length > 0) {
      await db.listUpdate(entry.anilist_id, { ...patch, updated_at: now });
      updatedIds.push(entry.anilist_id);
    }
  }

  return { notifications, updatedIds };
}
