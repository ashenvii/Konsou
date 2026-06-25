import Database from "@tauri-apps/plugin-sql";
import type { AnimeMedia, AnimeSummary, RelationNode } from "@/types/anime";
import type {
  AnimeListEntry,
  DeletionTombstone,
  ListEntryPatch,
} from "@/types/list";
import type { KonsouNotification } from "@/types/notification";
import type { KonsouDb, ScanScheduleEntry } from "./contract";

/**
 * Production backend. Real SQLite via tauri-plugin-sql. Schema migrations are
 * registered Rust-side (src-tauri/src/lib.rs) and applied on `Database.load`.
 * WAL mode makes writes crash-safe across Android app suspend (Trap 5).
 */
const UPDATABLE_COLUMNS: (keyof ListEntryPatch | "updated_at")[] = [
  "status",
  "episodes_watched",
  "score",
  "notes",
  "started_at",
  "completed_at",
  "total_episodes",
  "has_dub",
  "updated_at",
];

export class TauriKonsouDb implements KonsouDb {
  readonly backend = "sqlite" as const;
  private db!: Database;

  async init(): Promise<void> {
    this.db = await Database.load("sqlite:konsou.db");
    // Crash safety + concurrent reads. Issued per-connection.
    await this.db.execute("PRAGMA journal_mode=WAL;");
    await this.db.execute("PRAGMA synchronous=NORMAL;");
    await this.db.execute("PRAGMA foreign_keys=ON;");
  }

  // ── List ──────────────────────────────────────────────────

  /** SQLite stores booleans as 0/1 integers; convert to JS boolean on read. */
  private rowToEntry(row: AnimeListEntry & { has_dub: number | null }): AnimeListEntry {
    return { ...row, has_dub: row.has_dub === null ? null : row.has_dub !== 0 };
  }

  async listAll(): Promise<AnimeListEntry[]> {
    const rows = await this.db.select<(AnimeListEntry & { has_dub: number | null })[]>(
      "SELECT * FROM anime_list ORDER BY updated_at DESC",
    );
    return rows.map((r) => this.rowToEntry(r));
  }

  async listGet(anilistId: number): Promise<AnimeListEntry | null> {
    const rows = await this.db.select<(AnimeListEntry & { has_dub: number | null })[]>(
      "SELECT * FROM anime_list WHERE anilist_id = $1",
      [anilistId],
    );
    return rows[0] ? this.rowToEntry(rows[0]) : null;
  }

  async listUpsert(e: AnimeListEntry): Promise<void> {
    const hasDub = e.has_dub === null ? null : e.has_dub ? 1 : 0;
    await this.db.execute(
      `INSERT INTO anime_list (
         anilist_id, mal_id, title_romaji, title_english, title_native, cover_url,
         total_episodes, status, episodes_watched, score, notes,
         added_at, updated_at, started_at, completed_at, has_dub
       ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)
       ON CONFLICT(anilist_id) DO UPDATE SET
         mal_id          = excluded.mal_id,
         title_romaji    = excluded.title_romaji,
         title_english   = excluded.title_english,
         title_native    = excluded.title_native,
         cover_url       = excluded.cover_url,
         total_episodes  = excluded.total_episodes,
         status          = excluded.status,
         episodes_watched= excluded.episodes_watched,
         score           = excluded.score,
         notes           = excluded.notes,
         updated_at      = excluded.updated_at,
         started_at      = excluded.started_at,
         completed_at    = excluded.completed_at`,
      [
        e.anilist_id, e.mal_id, e.title_romaji, e.title_english, e.title_native, e.cover_url,
        e.total_episodes, e.status, e.episodes_watched, e.score, e.notes,
        e.added_at, e.updated_at, e.started_at, e.completed_at, hasDub,
      ],
    );
  }

  async listUpdate(
    anilistId: number,
    patch: ListEntryPatch & { updated_at: number },
  ): Promise<void> {
    const keys = Object.keys(patch).filter((k) =>
      UPDATABLE_COLUMNS.includes(k as never),
    ) as (keyof typeof patch)[];
    if (keys.length === 0) return;

    const setClause = keys.map((k, i) => `${k} = $${i + 1}`).join(", ");
    const values = keys.map((k) => {
      const v = patch[k];
      if (k === "has_dub") return v === null ? null : v ? 1 : 0;
      return v;
    });
    await this.db.execute(
      `UPDATE anime_list SET ${setClause} WHERE anilist_id = $${keys.length + 1}`,
      [...values, anilistId],
    );
  }

  async listRemove(anilistId: number): Promise<void> {
    await this.db.execute("DELETE FROM anime_list WHERE anilist_id = $1", [
      anilistId,
    ]);
  }

  async listReplaceAll(entries: AnimeListEntry[]): Promise<void> {
    await this.db.execute("DELETE FROM anime_list");
    for (const e of entries) await this.listUpsert(e);
  }

  // ── Deletion tombstones ───────────────────────────────────
  async tombstonesAll(): Promise<DeletionTombstone[]> {
    return this.db.select<DeletionTombstone[]>(
      "SELECT anilist_id, deleted_at FROM list_tombstones",
    );
  }

  async tombstoneUpsert(t: DeletionTombstone): Promise<void> {
    await this.db.execute(
      `INSERT INTO list_tombstones (anilist_id, deleted_at) VALUES ($1,$2)
       ON CONFLICT(anilist_id) DO UPDATE SET deleted_at = MAX(deleted_at, excluded.deleted_at)`,
      [t.anilist_id, t.deleted_at],
    );
  }

  async tombstoneRemove(anilistId: number): Promise<void> {
    await this.db.execute(
      "DELETE FROM list_tombstones WHERE anilist_id = $1",
      [anilistId],
    );
  }

  async tombstonesReplaceAll(tombstones: DeletionTombstone[]): Promise<void> {
    await this.db.execute("DELETE FROM list_tombstones");
    for (const t of tombstones) {
      await this.db.execute(
        "INSERT INTO list_tombstones (anilist_id, deleted_at) VALUES ($1,$2)",
        [t.anilist_id, t.deleted_at],
      );
    }
  }

  // ── Caches ────────────────────────────────────────────────
  async cacheGetAnime(anilistId: number) {
    const rows = await this.db.select<{ data_json: string; cached_at: number }[]>(
      "SELECT data_json, cached_at FROM anime_cache WHERE anilist_id = $1",
      [anilistId],
    );
    if (!rows[0]) return null;
    return {
      data: JSON.parse(rows[0].data_json) as AnimeMedia,
      cachedAt: rows[0].cached_at,
    };
  }

  async cacheSetAnime(anilistId: number, data: AnimeMedia): Promise<void> {
    await this.db.execute(
      `INSERT INTO anime_cache (anilist_id, data_json, cached_at) VALUES ($1,$2,$3)
       ON CONFLICT(anilist_id) DO UPDATE SET data_json = excluded.data_json, cached_at = excluded.cached_at`,
      [anilistId, JSON.stringify(data), Date.now()],
    );
  }

  async cacheGetSearch(queryHash: string) {
    const rows = await this.db.select<{ results_json: string; cached_at: number }[]>(
      "SELECT results_json, cached_at FROM search_cache WHERE query_hash = $1",
      [queryHash],
    );
    if (!rows[0]) return null;
    return {
      results: JSON.parse(rows[0].results_json) as AnimeSummary[],
      cachedAt: rows[0].cached_at,
    };
  }

  async cacheSetSearch(
    queryHash: string,
    queryText: string,
    results: AnimeSummary[],
  ): Promise<void> {
    await this.db.execute(
      `INSERT INTO search_cache (query_hash, query_text, results_json, cached_at) VALUES ($1,$2,$3,$4)
       ON CONFLICT(query_hash) DO UPDATE SET results_json = excluded.results_json, cached_at = excluded.cached_at`,
      [queryHash, queryText, JSON.stringify(results), Date.now()],
    );
  }

  async getRelationSnapshot(anilistId: number) {
    const rows = await this.db.select<{ relations_json: string; checked_at: number }[]>(
      "SELECT relations_json, checked_at FROM relation_snapshots WHERE anilist_id = $1",
      [anilistId],
    );
    if (!rows[0]) return null;
    return {
      relations: JSON.parse(rows[0].relations_json) as RelationNode[],
      checkedAt: rows[0].checked_at,
    };
  }

  async setRelationSnapshot(
    anilistId: number,
    relations: RelationNode[],
  ): Promise<void> {
    await this.db.execute(
      `INSERT INTO relation_snapshots (anilist_id, relations_json, checked_at) VALUES ($1,$2,$3)
       ON CONFLICT(anilist_id) DO UPDATE SET relations_json = excluded.relations_json, checked_at = excluded.checked_at`,
      [anilistId, JSON.stringify(relations), Date.now()],
    );
  }

  // ── Sequel-scan schedule ──────────────────────────────────
  async scheduleGetAll(): Promise<Record<number, ScanScheduleEntry>> {
    const rows = await this.db.select<ScanScheduleEntry[]>(
      "SELECT anilist_id, last_check_at, next_check_at, quiet_streak FROM scan_schedule",
    );
    const out: Record<number, ScanScheduleEntry> = {};
    for (const r of rows) out[r.anilist_id] = r;
    return out;
  }

  async scheduleSet(entry: ScanScheduleEntry): Promise<void> {
    await this.db.execute(
      `INSERT INTO scan_schedule (anilist_id, last_check_at, next_check_at, quiet_streak)
       VALUES ($1,$2,$3,$4)
       ON CONFLICT(anilist_id) DO UPDATE SET
         last_check_at = excluded.last_check_at,
         next_check_at = excluded.next_check_at,
         quiet_streak  = excluded.quiet_streak`,
      [entry.anilist_id, entry.last_check_at, entry.next_check_at, entry.quiet_streak],
    );
  }

  // ── Notifications ─────────────────────────────────────────
  async notificationsActive(): Promise<KonsouNotification[]> {
    return this.db.select<KonsouNotification[]>(
      "SELECT * FROM notifications WHERE dismissed = 0 ORDER BY created_at DESC",
    );
  }

  async notificationInsertIfNew(
    n: Omit<KonsouNotification, "id">,
  ): Promise<boolean> {
    const res = await this.db.execute(
      `INSERT OR IGNORE INTO notifications
         (source_id, related_id, type, related_title, related_cover, related_status, airing_at, seen, dismissed, created_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
      [
        n.source_id, n.related_id, n.type, n.related_title, n.related_cover,
        n.related_status, n.airing_at, n.seen, n.dismissed, n.created_at,
      ],
    );
    return res.rowsAffected > 0;
  }

  async notificationMarkAllSeen(): Promise<void> {
    await this.db.execute("UPDATE notifications SET seen = 1 WHERE seen = 0");
  }

  async notificationDismiss(id: number): Promise<void> {
    await this.db.execute("UPDATE notifications SET dismissed = 1 WHERE id = $1", [
      id,
    ]);
  }

  async notificationRestoreDismissed(): Promise<void> {
    await this.db.execute("UPDATE notifications SET dismissed = 0 WHERE dismissed = 1");
  }

  async unreadCount(): Promise<number> {
    const rows = await this.db.select<{ c: number }[]>(
      "SELECT COUNT(*) as c FROM notifications WHERE seen = 0 AND dismissed = 0",
    );
    return rows[0]?.c ?? 0;
  }

  // ── Settings ──────────────────────────────────────────────
  async settingsGetAll(): Promise<Record<string, string>> {
    const rows = await this.db.select<{ key: string; value: string }[]>(
      "SELECT key, value FROM settings",
    );
    return Object.fromEntries(rows.map((r) => [r.key, r.value]));
  }

  async settingsSet(key: string, value: string): Promise<void> {
    await this.db.execute(
      `INSERT INTO settings (key, value) VALUES ($1,$2)
       ON CONFLICT(key) DO UPDATE SET value = excluded.value`,
      [key, value],
    );
  }
}
