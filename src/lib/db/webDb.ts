import type { AnimeMedia, AnimeSummary, RelationNode } from "@/types/anime";
import type {
  AnimeListEntry,
  DeletionTombstone,
  ListEntryPatch,
} from "@/types/list";
import type { KonsouNotification } from "@/types/notification";
import type { KonsouDb, ScanScheduleEntry } from "./contract";

/**
 * Browser-only backend used by `npm run dev`. Persists the durable tables to
 * localStorage; keeps the TTL caches in memory. Lets the entire UI be exercised
 * without the Rust runtime. Not used in production builds.
 */
const LS = {
  list: "konsou.web.list",
  tombstones: "konsou.web.tombstones",
  notifications: "konsou.web.notifications",
  settings: "konsou.web.settings",
  notifId: "konsou.web.notif_id",
  schedule: "konsou.web.scan_schedule",
};

function read<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function write(key: string, value: unknown): void {
  localStorage.setItem(key, JSON.stringify(value));
}

export class WebKonsouDb implements KonsouDb {
  readonly backend = "web" as const;

  private animeCache = new Map<number, { data: AnimeMedia; cachedAt: number }>();
  private searchCache = new Map<
    string,
    { results: AnimeSummary[]; cachedAt: number }
  >();
  private relationCache = new Map<
    number,
    { relations: RelationNode[]; checkedAt: number }
  >();

  async init(): Promise<void> {
    /* nothing to migrate — schema is implicit in the JSON shape */
  }

  // ── List ──────────────────────────────────────────────────
  private loadList(): AnimeListEntry[] {
    return read<AnimeListEntry[]>(LS.list, []);
  }
  private saveList(entries: AnimeListEntry[]): void {
    write(LS.list, entries);
  }

  async listAll(): Promise<AnimeListEntry[]> {
    return this.loadList();
  }

  async listGet(anilistId: number): Promise<AnimeListEntry | null> {
    return this.loadList().find((e) => e.anilist_id === anilistId) ?? null;
  }

  async listUpsert(entry: AnimeListEntry): Promise<void> {
    const list = this.loadList();
    const idx = list.findIndex((e) => e.anilist_id === entry.anilist_id);
    if (idx >= 0) list[idx] = { ...list[idx], ...entry };
    else list.push({ ...entry, id: Date.now() + Math.floor(Math.random() * 1000) });
    this.saveList(list);
  }

  async listUpdate(
    anilistId: number,
    patch: ListEntryPatch & { updated_at: number },
  ): Promise<void> {
    const list = this.loadList();
    const idx = list.findIndex((e) => e.anilist_id === anilistId);
    if (idx >= 0) {
      list[idx] = { ...list[idx], ...patch };
      this.saveList(list);
    }
  }

  async listRemove(anilistId: number): Promise<void> {
    this.saveList(this.loadList().filter((e) => e.anilist_id !== anilistId));
  }

  async listReplaceAll(entries: AnimeListEntry[]): Promise<void> {
    this.saveList(entries.map((e) => ({ ...e })));
  }

  // ── Deletion tombstones ───────────────────────────────────
  private loadTombs(): DeletionTombstone[] {
    return read<DeletionTombstone[]>(LS.tombstones, []);
  }
  private saveTombs(t: DeletionTombstone[]): void {
    write(LS.tombstones, t);
  }

  async tombstonesAll(): Promise<DeletionTombstone[]> {
    return this.loadTombs();
  }

  async tombstoneUpsert(t: DeletionTombstone): Promise<void> {
    const all = this.loadTombs();
    const idx = all.findIndex((x) => x.anilist_id === t.anilist_id);
    if (idx >= 0) {
      all[idx] = {
        ...all[idx],
        deleted_at: Math.max(all[idx].deleted_at, t.deleted_at),
      };
    } else {
      all.push(t);
    }
    this.saveTombs(all);
  }

  async tombstoneRemove(anilistId: number): Promise<void> {
    this.saveTombs(this.loadTombs().filter((t) => t.anilist_id !== anilistId));
  }

  async tombstonesReplaceAll(tombstones: DeletionTombstone[]): Promise<void> {
    this.saveTombs(tombstones);
  }

  // ── Caches (in-memory) ────────────────────────────────────
  async cacheGetAnime(anilistId: number) {
    return this.animeCache.get(anilistId) ?? null;
  }
  async cacheSetAnime(anilistId: number, data: AnimeMedia): Promise<void> {
    this.animeCache.set(anilistId, { data, cachedAt: Date.now() });
  }
  async cacheGetSearch(queryHash: string) {
    return this.searchCache.get(queryHash) ?? null;
  }
  async cacheSetSearch(
    queryHash: string,
    _queryText: string,
    results: AnimeSummary[],
  ): Promise<void> {
    this.searchCache.set(queryHash, { results, cachedAt: Date.now() });
  }
  async getRelationSnapshot(anilistId: number) {
    return this.relationCache.get(anilistId) ?? null;
  }
  async setRelationSnapshot(
    anilistId: number,
    relations: RelationNode[],
  ): Promise<void> {
    this.relationCache.set(anilistId, { relations, checkedAt: Date.now() });
  }

  // ── Sequel-scan schedule ──────────────────────────────────
  async scheduleGetAll(): Promise<Record<number, ScanScheduleEntry>> {
    const rows = read<ScanScheduleEntry[]>(LS.schedule, []);
    const out: Record<number, ScanScheduleEntry> = {};
    for (const r of rows) out[r.anilist_id] = r;
    return out;
  }
  async scheduleSet(entry: ScanScheduleEntry): Promise<void> {
    const rows = read<ScanScheduleEntry[]>(LS.schedule, []);
    const idx = rows.findIndex((r) => r.anilist_id === entry.anilist_id);
    if (idx >= 0) rows[idx] = entry;
    else rows.push(entry);
    write(LS.schedule, rows);
  }

  // ── Notifications ─────────────────────────────────────────
  private loadNotifs(): KonsouNotification[] {
    return read<KonsouNotification[]>(LS.notifications, []);
  }
  private saveNotifs(n: KonsouNotification[]): void {
    write(LS.notifications, n);
  }

  async notificationsActive(): Promise<KonsouNotification[]> {
    return this.loadNotifs()
      .filter((n) => n.dismissed === 0)
      .sort((a, b) => b.created_at - a.created_at);
  }

  async notificationInsertIfNew(
    n: Omit<KonsouNotification, "id">,
  ): Promise<boolean> {
    const all = this.loadNotifs();
    if (
      all.some(
        (x) => x.source_id === n.source_id && x.related_id === n.related_id,
      )
    ) {
      return false;
    }
    const nextId = read<number>(LS.notifId, 1);
    all.push({ ...n, id: nextId });
    write(LS.notifId, nextId + 1);
    this.saveNotifs(all);
    return true;
  }

  async notificationMarkAllSeen(): Promise<void> {
    this.saveNotifs(this.loadNotifs().map((n) => ({ ...n, seen: 1 })));
  }

  async notificationDismiss(id: number): Promise<void> {
    this.saveNotifs(
      this.loadNotifs().map((n) => (n.id === id ? { ...n, dismissed: 1 } : n)),
    );
  }

  async notificationRestoreDismissed(): Promise<void> {
    this.saveNotifs(this.loadNotifs().map((n) => ({ ...n, dismissed: 0 })));
  }

  async unreadCount(): Promise<number> {
    return this.loadNotifs().filter((n) => n.seen === 0 && n.dismissed === 0)
      .length;
  }

  // ── Settings ──────────────────────────────────────────────
  async settingsGetAll(): Promise<Record<string, string>> {
    return read<Record<string, string>>(LS.settings, {});
  }
  async settingsSet(key: string, value: string): Promise<void> {
    const s = read<Record<string, string>>(LS.settings, {});
    s[key] = value;
    write(LS.settings, s);
  }
}
