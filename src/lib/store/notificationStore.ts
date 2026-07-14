import { create } from "zustand";
import { getDb } from "@/lib/db";
import { isEnabled } from "@/lib/features";
import { alertBucket, detectSequels } from "@/lib/sequel/detector";
import { computeNextCheck, selectDueSeeds } from "@/lib/sequel/schedule";
import { scanPlanToWatchAirings } from "@/lib/sequel/airingScan";
import { toast } from "./toastStore";
import { useSettingsStore } from "./settingsStore";
import type { ScanScheduleEntry } from "@/lib/db/contract";
import type { AnimeTitle } from "@/types/anime";
import type { AnimeListEntry } from "@/types/list";
import type { Priority } from "@/lib/api/rateLimiter";
import type { KonsouNotification } from "@/types/notification";

const LAST_CHECK_KEY = "last_sequel_check";
/** Seeds drained per background tick — keeps each tick gentle on the rate limit. */
const SCAN_BUDGET = 20;
/** Seeds per detection pass — bounds progress granularity and franchise overlap. */
const GROUP_SIZE = 4;
/** "Already Aired" alerts the user never acted on stop shouting after this long.
 *  They can always be brought back from Settings → restore dismissed. */
const ALREADY_AIRED_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/** One alert per suggested anime for display: the same title can exist as
 *  several rows when different seeds discovered it (rows are unique per
 *  source, not per suggestion). Keeps the newest row of each. */
function dedupeByRelated(items: KonsouNotification[]): KonsouNotification[] {
  const seen = new Set<number>();
  const out: KonsouNotification[] = [];
  for (const n of items) {
    if (seen.has(n.related_id)) continue;
    seen.add(n.related_id);
    out.push(n);
  }
  return out;
}

interface ScanProgress {
  done: number;
  total: number;
}

interface NotificationState {
  loaded: boolean;
  checking: boolean;
  /** Set during a scan so the UI can show "Scanning N/M…". */
  progress: ScanProgress | null;
  /** When the radar last finished a sweep (ms), so Alerts can say "checked 2h ago". */
  lastCheckedAt: number | null;
  items: KonsouNotification[];
  unread: number;

  load: () => Promise<void>;
  /** Background, self-pacing: scans only seeds whose schedule is due (low prio). */
  runScheduledScan: (entries: AnimeListEntry[]) => Promise<void>;
  /** User-initiated full sweep of every seed at foreground priority. */
  refreshAll: (entries: AnimeListEntry[]) => Promise<void>;
  /** Immediately check one freshly completed/dropped seed. */
  scanSeed: (entries: AnimeListEntry[], seedId: number) => Promise<void>;
  markAllSeen: () => Promise<void>;
  /** Dismiss every alert suggesting these anime (all duplicate rows at once). */
  dismissRelated: (relatedIds: number[]) => Promise<void>;
  /** Forget alerts and scan schedule tied to entries that left the list. */
  entriesRemoved: (anilistIds: number[]) => Promise<void>;
  restoreDismissed: () => Promise<void>;
}

function seedIdsOf(entries: AnimeListEntry[]): number[] {
  return entries
    .filter((e) => e.status === "completed" || e.status === "dropped")
    .map((e) => e.anilist_id);
}

/** Tracked titles by id — the detector uses these to judge OTHER relation
 *  edges (followed only when the names claim the same franchise). */
function titleMapOf(entries: AnimeListEntry[]): Map<number, AnimeTitle> {
  return new Map(
    entries.map((e) => [
      e.anilist_id,
      {
        romaji: e.title_romaji,
        english: e.title_english,
        native: e.title_native,
      },
    ]),
  );
}

export const useNotificationStore = create<NotificationState>((set, get) => {
  /**
   * Shared scan core. Walks the given seeds in small groups (so progress and
   * per-seed rescheduling stay granular), inserts any new notifications, and
   * re-dates each scanned seed via the adaptive scheduler. Returns how many
   * notifications were newly inserted.
   */
  const scanSeeds = async (
    seedIds: number[],
    inList: Set<number>,
    priority: Priority,
    schedule: Record<number, ScanScheduleEntry>,
    knownTitles: Map<number, AnimeTitle>,
  ): Promise<number> => {
    const db = await getDb();
    let inserted = 0;
    set({ progress: { done: 0, total: seedIds.length } });

    for (let i = 0; i < seedIds.length; i += GROUP_SIZE) {
      const group = seedIds.slice(i, i + GROUP_SIZE);
      const { notifications, volatileSeeds } = await detectSequels(
        group,
        inList,
        priority,
        knownTitles,
      );
      for (const n of notifications) {
        if (await db.notificationInsertIfNew(n)) inserted++;
      }
      const now = Date.now();
      for (const seed of group) {
        await db.scheduleSet(
          computeNextCheck(
            seed,
            schedule[seed]?.quiet_streak ?? 0,
            volatileSeeds.has(seed),
            now,
          ),
        );
      }
      set({ progress: { done: Math.min(i + GROUP_SIZE, seedIds.length), total: seedIds.length } });
    }
    return inserted;
  };

  const enabled = () =>
    isEnabled("SEQUEL_RADAR") && useSettingsStore.getState().sequelNotifications;

  return {
    loaded: false,
    checking: false,
    progress: null,
    lastCheckedAt: null,
    items: [],
    unread: 0,

    load: async () => {
      const db = await getDb();
      let items = await db.notificationsActive();

      // Decay: an "Already Aired" alert the user ignored for a month has had
      // its chance — quietly retire it instead of letting the bucket grow
      // forever. Airing/announced alerts stay; they still have a date coming.
      const cutoff = Date.now() - ALREADY_AIRED_TTL_MS;
      const expired = items.filter(
        (n) => alertBucket(n) === "already_aired" && n.created_at < cutoff,
      );
      if (expired.length > 0) {
        await db.notificationDismissByRelated(expired.map((n) => n.related_id));
        const gone = new Set(expired.map((n) => n.related_id));
        items = items.filter((n) => !gone.has(n.related_id));
      }

      // "Started airing" alerts are retired: the Airing → Episodes calendar
      // already shows a plan-to-watch title the moment it starts airing, so a
      // separate notification for it was pure duplication. Drop any that the
      // background airing scan may still have inserted so they never surface.
      items = dedupeByRelated(items).filter((n) => n.type !== "started_airing");
      const unread = await db.unreadCount();
      const settings = await db.settingsGetAll();
      const lastRaw = Number(settings[LAST_CHECK_KEY]);
      set({
        items,
        unread,
        loaded: true,
        lastCheckedAt: Number.isFinite(lastRaw) && lastRaw > 0 ? lastRaw : null,
      });
    },

    runScheduledScan: async (entries) => {
      if (!enabled() || get().checking) return;
      const db = await getDb();

      // Airing scan runs first — low-cost since it only hits plan_to_watch entries
      // with NOT_YET_RELEASED status, and those shrink as anime start airing.
      try {
        const { notifications: airingAlerts, updatedIds } =
          await scanPlanToWatchAirings(entries, db);
        for (const n of airingAlerts) {
          await db.notificationInsertIfNew(n);
        }
        if (updatedIds.length > 0) {
          // Reload the full list so in-memory entries reflect the new airing_status.
          const { useListStore } = await import("./listStore");
          await useListStore.getState().load();
        }
        if (airingAlerts.length > 0) await get().load();
      } catch (err) {
        console.error("[alerts] airing scan failed:", err);
      }

      const schedule = await db.scheduleGetAll();
      const due = selectDueSeeds(seedIdsOf(entries), schedule, SCAN_BUDGET);
      if (due.length === 0) return;

      set({ checking: true });
      try {
        const inList = new Set(entries.map((e) => e.anilist_id));
        const inserted = await scanSeeds(due, inList, "low", schedule, titleMapOf(entries));
        const finishedAt = Date.now();
        await db.settingsSet(LAST_CHECK_KEY, String(finishedAt));
        set({ lastCheckedAt: finishedAt });
        if (inserted > 0) await get().load();
      } catch (err) {
        console.error("[alerts] scheduled scan failed:", err);
      } finally {
        set({ checking: false, progress: null });
      }
    },

    refreshAll: async (entries) => {
      if (!enabled() || get().checking) return;
      const db = await getDb();
      const seeds = seedIdsOf(entries);
      if (seeds.length === 0) {
        toast.show("No completed anime to scan yet");
        return;
      }

      set({ checking: true });
      try {
        const schedule = await db.scheduleGetAll();
        const inList = new Set(entries.map((e) => e.anilist_id));
        const inserted = await scanSeeds(seeds, inList, "high", schedule, titleMapOf(entries));
        const finishedAt = Date.now();
        await db.settingsSet(LAST_CHECK_KEY, String(finishedAt));
        set({ lastCheckedAt: finishedAt });
        await get().load();
        toast.show(
          inserted > 0
            ? `Found ${inserted} new alert${inserted === 1 ? "" : "s"}`
            : "No new sequels found",
        );
      } catch (err) {
        console.error("[alerts] full refresh failed:", err);
        toast.show("Sequel scan couldn't complete — check your connection");
      } finally {
        set({ checking: false, progress: null });
      }
    },

    scanSeed: async (entries, seedId) => {
      if (!enabled()) return;
      const db = await getDb();
      // A scan is already running — just mark this seed due so the running tick
      // (or the next one) picks it up, rather than colliding with it.
      if (get().checking) {
        await db.scheduleSet({
          anilist_id: seedId,
          last_check_at: 0,
          next_check_at: 0,
          quiet_streak: 0,
        });
        return;
      }

      set({ checking: true });
      try {
        const schedule = await db.scheduleGetAll();
        const inList = new Set(entries.map((e) => e.anilist_id));
        const inserted = await scanSeeds([seedId], inList, "high", schedule, titleMapOf(entries));
        if (inserted > 0) await get().load();
      } catch (err) {
        console.error("[alerts] single-seed scan failed:", err);
      } finally {
        set({ checking: false, progress: null });
      }
    },

    markAllSeen: async () => {
      const db = await getDb();
      await db.notificationMarkAllSeen();
      set((s) => ({
        unread: 0,
        items: s.items.map((n) => ({ ...n, seen: 1 })),
      }));
    },

    dismissRelated: async (relatedIds) => {
      if (relatedIds.length === 0) return;
      const db = await getDb();
      await db.notificationDismissByRelated(relatedIds);
      const gone = new Set(relatedIds);
      set((s) => ({ items: s.items.filter((n) => !gone.has(n.related_id)) }));
    },

    entriesRemoved: async (anilistIds) => {
      if (anilistIds.length === 0) return;
      const db = await getDb();
      for (const id of anilistIds) {
        await db.notificationsPurgeForEntry(id);
        await db.scheduleRemove(id);
      }
      if (get().loaded) await get().load();
    },

    restoreDismissed: async () => {
      const db = await getDb();
      await db.notificationRestoreDismissed();
      await get().load();
    },
  };
});
