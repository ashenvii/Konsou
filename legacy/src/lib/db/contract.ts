import type { AnimeMedia, AnimeSummary, RelationNode } from "@/types/anime";
import type {
  AnimeListEntry,
  CompletionEvent,
  DeletionTombstone,
  ListEntryPatch,
} from "@/types/list";
import type { KonsouNotification } from "@/types/notification";

/** A seed's adaptive re-scan schedule (see src/lib/sequel/schedule.ts). */
export interface ScanScheduleEntry {
  anilist_id: number;
  last_check_at: number;
  next_check_at: number;
  /** Consecutive checks that turned up nothing new — drives exponential backoff. */
  quiet_streak: number;
}

/**
 * The data-access contract. Feature code and stores talk ONLY to this interface,
 * never to raw SQL — so the same code runs against real SQLite (Tauri) and the
 * localStorage shim (browser dev). See `getDb()` in ./index.ts.
 */
export interface KonsouDb {
  init(): Promise<void>;

  /** Identifies which backend is active — purely for diagnostics / the dev panel. */
  readonly backend: "sqlite" | "web";

  // ── User list ──────────────────────────────────────────────
  listAll(): Promise<AnimeListEntry[]>;
  listGet(anilistId: number): Promise<AnimeListEntry | null>;
  listUpsert(entry: AnimeListEntry): Promise<void>;
  listUpdate(
    anilistId: number,
    patch: ListEntryPatch & { updated_at: number },
  ): Promise<void>;
  /** Pure row delete — does NOT write a tombstone (callers own that). */
  listRemove(anilistId: number): Promise<void>;
  /** Wipe and re-seed the whole list — used by the "replace" sync strategies. */
  listReplaceAll(entries: AnimeListEntry[]): Promise<void>;

  // ── Completion log (the ledger's source of truth) ──────────
  /** Every recorded completion, newest first. Rows outlive their entry. */
  completionsAll(): Promise<CompletionEvent[]>;
  /** Record one finished watch. A repeat of the same event is ignored, so
   *  replaying a synced log can never double-count a watch. */
  completionAppend(event: CompletionEvent): Promise<void>;
  /** Replace the whole log — used after a sync merge and by "clear list". */
  completionsReplaceAll(events: CompletionEvent[]): Promise<void>;
  /** Take one event back out. Only the undo of a just-made completion uses
   *  this: a mistap is not history, and the ledger must not keep it. */
  completionRemove(anilistId: number, rewatchIndex: number): Promise<void>;

  // ── Deletion tombstones ────────────────────────────────────
  tombstonesAll(): Promise<DeletionTombstone[]>;
  /** Insert or bump a tombstone, keeping the latest `deleted_at`. */
  tombstoneUpsert(t: DeletionTombstone): Promise<void>;
  /** Drop a tombstone (an entry was re-added, superseding its deletion). */
  tombstoneRemove(anilistId: number): Promise<void>;
  /** Replace the whole tombstone set — used after a merge or replace. */
  tombstonesReplaceAll(tombstones: DeletionTombstone[]): Promise<void>;

  // ── Caches ─────────────────────────────────────────────────
  cacheGetAnime(
    anilistId: number,
  ): Promise<{ data: AnimeMedia; cachedAt: number } | null>;
  cacheSetAnime(anilistId: number, data: AnimeMedia): Promise<void>;

  cacheGetSearch(
    queryHash: string,
  ): Promise<{ results: AnimeSummary[]; cachedAt: number } | null>;
  cacheSetSearch(
    queryHash: string,
    queryText: string,
    results: AnimeSummary[],
  ): Promise<void>;

  getRelationSnapshot(
    anilistId: number,
  ): Promise<{ relations: RelationNode[]; checkedAt: number } | null>;
  setRelationSnapshot(anilistId: number, relations: RelationNode[]): Promise<void>;

  // ── Sequel-scan schedule (per completed/dropped seed) ──────
  /** Every scheduled seed, keyed by anilist_id. Seeds with no row are "due now". */
  scheduleGetAll(): Promise<Record<number, ScanScheduleEntry>>;
  scheduleSet(entry: ScanScheduleEntry): Promise<void>;
  /** Forget a seed's schedule when its entry leaves the list. */
  scheduleRemove(anilistId: number): Promise<void>;
  scheduleClear(): Promise<void>;

  // ── Notifications (sequel radar) ───────────────────────────
  notificationsActive(): Promise<KonsouNotification[]>;
  /** Returns true if it was newly inserted (false if the pair already existed). */
  notificationInsertIfNew(n: Omit<KonsouNotification, "id">): Promise<boolean>;
  notificationMarkAllSeen(): Promise<void>;
  /** Dismiss every row suggesting any of these anime, regardless of which seed
   *  produced it — one anime can be discovered via several sources. */
  notificationDismissByRelated(relatedIds: number[]): Promise<void>;
  /** Hard-delete every row that references this entry, as the seed that produced
   *  the alert or as the suggestion itself. Used when the entry leaves the list,
   *  so alerts never point at nothing and re-adding starts clean. */
  notificationsPurgeForEntry(anilistId: number): Promise<void>;
  notificationsClear(): Promise<void>;
  notificationRestoreDismissed(): Promise<void>;
  unreadCount(): Promise<number>;

  // ── Settings (key/value) ───────────────────────────────────
  settingsGetAll(): Promise<Record<string, string>>;
  settingsSet(key: string, value: string): Promise<void>;
}
