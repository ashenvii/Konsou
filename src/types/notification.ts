import type { AniListMediaStatus } from "./anime";

export type AlertType = "sequel" | "side_story" | "spin_off" | "movie" | "started_airing";

/** Mirrors the `notifications` SQLite table. */
export interface KonsouNotification {
  id?: number;
  source_id: number; // anilist id of the watched anime
  related_id: number; // anilist id of the discovered continuation
  type: AlertType;
  related_title: string;
  related_cover: string | null;
  related_status: AniListMediaStatus | string;
  airing_at: number | null; // unix seconds, when known
  seen: number; // 0 unread, 1 read
  dismissed: number; // 0 active, 1 dismissed
  created_at: number;
}

/** UI grouping buckets on the Alerts page. */
export type AlertBucket = "airing_now" | "announced" | "already_aired";

export interface AlertGroup {
  bucket: AlertBucket;
  label: string;
  items: KonsouNotification[];
}
