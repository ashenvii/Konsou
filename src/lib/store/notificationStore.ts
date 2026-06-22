import { create } from "zustand";
import { getDb } from "@/lib/db";
import { isEnabled } from "@/lib/features";
import { detectSequels } from "@/lib/sequel/detector";
import { useSettingsStore } from "./settingsStore";
import type { AnimeListEntry } from "@/types/list";
import type { KonsouNotification } from "@/types/notification";

const SIX_HOURS = 6 * 60 * 60 * 1000;
const LAST_CHECK_KEY = "last_sequel_check";

interface NotificationState {
  loaded: boolean;
  checking: boolean;
  items: KonsouNotification[];
  unread: number;

  load: () => Promise<void>;
  runDetection: (entries: AnimeListEntry[], force?: boolean) => Promise<void>;
  markAllSeen: () => Promise<void>;
  dismiss: (id: number) => Promise<void>;
  restoreDismissed: () => Promise<void>;
}

export const useNotificationStore = create<NotificationState>((set, get) => ({
  loaded: false,
  checking: false,
  items: [],
  unread: 0,

  load: async () => {
    const db = await getDb();
    const items = await db.notificationsActive();
    const unread = await db.unreadCount();
    set({ items, unread, loaded: true });
  },

  runDetection: async (entries, force = false) => {
    if (!isEnabled("SEQUEL_RADAR")) return;
    if (!useSettingsStore.getState().sequelNotifications) return;
    if (get().checking) return;

    set({ checking: true });
    try {
      const db = await getDb();
      const settings = await db.settingsGetAll();
      const lastCheckAt = settings[LAST_CHECK_KEY]
        ? Number(settings[LAST_CHECK_KEY])
        : null;

      const discovered = await detectSequels(entries, {
        cooldownMs: force ? 0 : SIX_HOURS,
        lastCheckAt,
      });

      let inserted = 0;
      for (const n of discovered) {
        if (await db.notificationInsertIfNew(n)) inserted++;
      }
      await db.settingsSet(LAST_CHECK_KEY, String(Date.now()));

      if (inserted > 0 || force) await get().load();
    } catch {
      /* sequel detection is best-effort — never surface a blocking error */
    } finally {
      set({ checking: false });
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
}));
