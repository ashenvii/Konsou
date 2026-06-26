import { create } from "zustand";
import { getDb } from "@/lib/db";
import { isEnabled } from "@/lib/features";
import { detectSequels } from "@/lib/sequel/detector";
import { computeNextCheck, selectDueSeeds } from "@/lib/sequel/schedule";
import { scanPlanToWatchAirings } from "@/lib/sequel/airingScan";
import { toast } from "./toastStore";
import { useSettingsStore } from "./settingsStore";
import type { ScanScheduleEntry } from "@/lib/db/contract";
import type { AnimeListEntry } from "@/types/list";
import type { Priority } from "@/lib/api/rateLimiter";
import type { KonsouNotification } from "@/types/notification";

const LAST_CHECK_KEY = "last_sequel_check";
/** Seeds drained per background tick — keeps each tick gentle on the rate limit. */
const SCAN_BUDGET = 20;
/** Seeds per detection pass — bounds progress granularity and franchise overlap. */
const GROUP_SIZE = 4;

interface ScanProgress {
  done: number;
  total: number;
}

interface NotificationState {
  loaded: boolean;
  checking: boolean;
  /** Set during a scan so the UI can show "Scanning N/M…". */
  progress: ScanProgress | null;
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
  dismiss: (id: number) => Promise<void>;
  restoreDismissed: () => Promise<void>;
}

function seedIdsOf(entries: AnimeListEntry[]): number[] {
  return entries
    .filter((e) => e.status === "completed" || e.status === "dropped")
    .map((e) => e.anilist_id);
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
    items: [],
    unread: 0,

    load: async () => {
      const db = await getDb();
      const items = await db.notificationsActive();
      const unread = await db.unreadCount();
      set({ items, unread, loaded: true });
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
        const inserted = await scanSeeds(due, inList, "low", schedule);
        await db.settingsSet(LAST_CHECK_KEY, String(Date.now()));
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
        const inserted = await scanSeeds(seeds, inList, "high", schedule);
        await db.settingsSet(LAST_CHECK_KEY, String(Date.now()));
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
        const inserted = await scanSeeds([seedId], inList, "high", schedule);
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

    dismiss: async (id) => {
      const db = await getDb();
      await db.notificationDismiss(id);
      set((s) => ({ items: s.items.filter((n) => n.id !== id) }));
    },

    restoreDismissed: async () => {
      const db = await getDb();
      await db.notificationRestoreDismissed();
      await get().load();
    },
  };
});
