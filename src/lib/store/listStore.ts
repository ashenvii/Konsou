import { create } from "zustand";
import { getDb } from "@/lib/db";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { syncQueue } from "@/lib/sync/queue";
import { syncManager } from "@/lib/sync/syncManager";
import { toast } from "./toastStore";
import type { AnimeSummary } from "@/types/anime";
import type {
  AnimeListEntry,
  ListEntryPatch,
  ListStatus,
} from "@/types/list";

interface ListState {
  loaded: boolean;
  entries: AnimeListEntry[];
  map: Record<number, AnimeListEntry>;

  load: () => Promise<void>;
  isInList: (anilistId: number) => boolean;
  getEntry: (anilistId: number) => AnimeListEntry | undefined;

  addFromSummary: (summary: AnimeSummary, status: ListStatus) => Promise<void>;
  importEntries: (toImport: AnimeListEntry[]) => Promise<number>;
  setDubStatus: (anilistId: number, hasDub: boolean) => Promise<void>;
  updateStatus: (anilistId: number, status: ListStatus) => Promise<void>;
  setEpisodes: (anilistId: number, episodes: number) => Promise<void>;
  incrementEpisodes: (anilistId: number, delta: number) => Promise<void>;
  setScore: (anilistId: number, score: number | null) => Promise<void>;
  patch: (anilistId: number, patch: ListEntryPatch) => Promise<void>;
  remove: (anilistId: number) => void;
  restore: (entry: AnimeListEntry) => Promise<void>;
}

function indexBy(entries: AnimeListEntry[]): Record<number, AnimeListEntry> {
  const m: Record<number, AnimeListEntry> = {};
  for (const e of entries) m[e.anilist_id] = e;
  return m;
}

function queueSync(): void {
  syncQueue.scheduleWrite(() => syncManager.pushNow());
}

export const useListStore = create<ListState>((set, get) => {
  /** Replace one entry in both `entries` and `map` (optimistic update). */
  const applyEntry = (entry: AnimeListEntry) => {
    set((s) => {
      const exists = s.map[entry.anilist_id];
      const entries = exists
        ? s.entries.map((e) => (e.anilist_id === entry.anilist_id ? entry : e))
        : [entry, ...s.entries];
      return { entries, map: { ...s.map, [entry.anilist_id]: entry } };
    });
  };

  const removeFromState = (anilistId: number) => {
    set((s) => {
      const map = { ...s.map };
      delete map[anilistId];
      return {
        entries: s.entries.filter((e) => e.anilist_id !== anilistId),
        map,
      };
    });
  };

  /** Optimistic field patch with DB write + revert-on-failure. */
  const patchEntry = async (anilistId: number, patch: ListEntryPatch) => {
    const prev = get().map[anilistId];
    if (!prev) return;
    const updated_at = Date.now();
    applyEntry({ ...prev, ...patch, updated_at });
    try {
      const db = await getDb();
      await db.listUpdate(anilistId, { ...patch, updated_at });
      queueSync();
    } catch {
      applyEntry(prev); // revert
      toast.error("Couldn't save that change");
    }
  };

  return {
    loaded: false,
    entries: [],
    map: {},

    load: async () => {
      const db = await getDb();
      const entries = await db.listAll();
      set({ entries, map: indexBy(entries), loaded: true });
    },

    isInList: (anilistId) => !!get().map[anilistId],
    getEntry: (anilistId) => get().map[anilistId],

    addFromSummary: async (s, status) => {
      const now = Date.now();
      const total = s.episodes ?? null;
      const entry: AnimeListEntry = {
        anilist_id: s.id,
        mal_id: s.idMal ?? null,
        title_romaji: s.title.romaji,
        title_english: s.title.english ?? null,
        title_native: s.title.native ?? null,
        cover_url: getCoverUrl(s.coverImage) || null,
        total_episodes: total,
        status,
        episodes_watched: status === "completed" ? (total ?? 0) : 0,
        score: null,
        notes: null,
        has_dub: null,
        added_at: now,
        updated_at: now,
        started_at:
          status === "watching" || status === "rewatching" ? now : null,
        completed_at: status === "completed" ? now : null,
      };
      applyEntry(entry);
      try {
        const db = await getDb();
        await db.listUpsert(entry);
        // Re-adding supersedes any prior deletion of this title.
        await db.tombstoneRemove(s.id);
        queueSync();
      } catch {
        removeFromState(s.id);
        toast.error("Couldn't add to your list");
      }
    },

    importEntries: async (toImport) => {
      const db = await getDb();
      let count = 0;
      for (const incoming of toImport) {
        const existing = get().map[incoming.anilist_id];
        const entry: AnimeListEntry = existing
          ? {
              ...incoming,
              // Local notes/score win; take max episodes; keep earliest added_at.
              score: existing.score ?? incoming.score,
              notes: existing.notes ?? incoming.notes,
              episodes_watched: Math.max(existing.episodes_watched, incoming.episodes_watched),
              added_at: Math.min(existing.added_at, incoming.added_at),
              updated_at: Date.now(),
            }
          : incoming;
        applyEntry(entry);
        await db.listUpsert(entry);
        await db.tombstoneRemove(incoming.anilist_id);
        count++;
      }
      queueSync();
      return count;
    },

    setDubStatus: async (anilistId, hasDub) => {
      const entry = get().map[anilistId];
      if (!entry || entry.has_dub === hasDub) return;
      await patchEntry(anilistId, { has_dub: hasDub });
    },

    updateStatus: async (anilistId, status) => {
      const prev = get().map[anilistId];
      if (!prev) return;
      const patch: ListEntryPatch = { status };
      if (status === "completed") {
        patch.completed_at = prev.completed_at ?? Date.now();
        if (prev.total_episodes != null) {
          patch.episodes_watched = prev.total_episodes;
        }
      }
      if (
        (status === "watching" || status === "rewatching") &&
        prev.started_at == null
      ) {
        patch.started_at = Date.now();
      }
      await patchEntry(anilistId, patch);
    },

    setEpisodes: async (anilistId, episodes) => {
      const prev = get().map[anilistId];
      if (!prev) return;
      const max = prev.total_episodes ?? Number.MAX_SAFE_INTEGER;
      const clamped = Math.max(0, Math.min(episodes, max));
      await patchEntry(anilistId, { episodes_watched: clamped });
    },

    incrementEpisodes: async (anilistId, delta) => {
      const prev = get().map[anilistId];
      if (!prev) return;
      await get().setEpisodes(anilistId, prev.episodes_watched + delta);
    },

    setScore: async (anilistId, score) => {
      await patchEntry(anilistId, { score });
    },

    patch: async (anilistId, p) => {
      await patchEntry(anilistId, p);
    },

    remove: (anilistId) => {
      const entry = get().map[anilistId];
      if (!entry) return;
      removeFromState(anilistId); // optimistic
      let undone = false;
      toast.action({
        message: `Removed ${preferredTitle({
          romaji: entry.title_romaji,
          english: entry.title_english,
        })}`,
        actionLabel: "Undo",
        duration: 4000,
        onAction: () => {
          undone = true;
          applyEntry(entry);
        },
      });
      // Commit the DB delete only after the undo window closes.
      setTimeout(async () => {
        if (undone) return;
        try {
          const db = await getDb();
          await db.listRemove(anilistId);
          // Record a tombstone so the deletion propagates through sync instead
          // of being resurrected by the next merge.
          await db.tombstoneUpsert({ anilist_id: anilistId, deleted_at: Date.now() });
          queueSync();
        } catch {
          applyEntry(entry);
          toast.error("Couldn't remove that entry");
        }
      }, 4000);
    },

    restore: async (entry) => {
      applyEntry(entry);
      try {
        const db = await getDb();
        await db.listUpsert(entry);
        await db.tombstoneRemove(entry.anilist_id);
        queueSync();
      } catch {
        removeFromState(entry.anilist_id);
      }
    },
  };
});
