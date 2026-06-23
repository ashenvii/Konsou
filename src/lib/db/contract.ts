import type { AnimeMedia, AnimeSummary, RelationNode } from "@/types/anime";
import type {
  AnimeListEntry,
  DeletionTombstone,
  ListEntryPatch,
} from "@/types/list";
import type { KonsouNotification } from "@/types/notification";

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

  // ── Notifications (sequel radar) ───────────────────────────
  notificationsActive(): Promise<KonsouNotification[]>;
  /** Returns true if it was newly inserted (false if the pair already existed). */
  notificationInsertIfNew(n: Omit<KonsouNotification, "id">): Promise<boolean>;
  notificationMarkAllSeen(): Promise<void>;
  notificationDismiss(id: number): Promise<void>;
  notificationRestoreDismissed(): Promise<void>;
  unreadCount(): Promise<number>;

  // ── Settings (key/value) ───────────────────────────────────
  settingsGetAll(): Promise<Record<string, string>>;
  settingsSet(key: string, value: string): Promise<void>;
}
