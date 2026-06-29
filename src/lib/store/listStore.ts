import { create } from "zustand";
import { getDb } from "@/lib/db";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { resolveFranchiseChain } from "@/lib/franchise/cascade";
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
  removeMany: (anilistIds: number[]) => void;
  clearAll: (opts?: { propagateToDrive?: boolean }) => Promise<void>;
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

  /**
   * Walk the PREQUEL chain for `primaryId`, add missing ancestors as completed,
   * and stamp franchise_root_id on the primary entry and any existing ancestors.
   * Runs entirely in the background — errors are swallowed so they never block
   * the original add.
   */
  const runFranchiseCascade = async (primaryId: number): Promise<void> => {
    try {
      const inList = new Set(get().entries.map((e) => e.anilist_id));
      const { rootId, toAdd, toUpdate } = await resolveFranchiseChain(primaryId, inList);

      // Give the newly added entry its franchise root.
      await patchEntry(primaryId, { franchise_root_id: rootId });

      // Stamp already-tracked ancestors that were added before this feature.
      for (const id of toUpdate) {
        await patchEntry(id, { franchise_root_id: rootId });
      }

      if (toAdd.length === 0) return;

      const db = await getDb();
      const now = Date.now();

      for (const rel of toAdd) {
        const total = rel.episodes ?? null;
        const entry: AnimeListEntry = {
          anilist_id: rel.id,
          mal_id: rel.idMal ?? null,
          title_romaji: rel.title.romaji,
          title_english: rel.title.english ?? null,
          title_native: rel.title.native ?? null,
          cover_url: getCoverUrl(rel.coverImage) || null,
          total_episodes: total,
          status: "completed",
          episodes_watched: total ?? 0,
          score: null,
          notes: null,
          has_dub: null,
          franchise_root_id: rootId,
          airing_status: rel.status ?? null,
          added_at: now,
          updated_at: now,
          started_at: null,
          completed_at: now,
        };
        applyEntry(entry);
        try {
          await db.listUpsert(entry);
          await db.tombstoneRemove(rel.id);
        } catch {
          removeFromState(rel.id);
        }
      }

      queueSync();

      const msg =
        toAdd.length === 1
          ? `Also added "${preferredTitle(toAdd[0].title)}" as completed`
          : `Also added ${toAdd.length} prior entries as completed`;
      toast.success(msg);
    } catch (err) {
      console.warn("[cascade] franchise chain resolve failed:", err);
      // Non-fatal: the primary entry is already in the list, just ungrouped until
      // the user visits its detail page and the root is resolved there.
    }
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

  /**
   * Background pass that stamps franchise_root_id on entries that were added
   * before this feature shipped. Runs at "low" priority so it never competes
   * with foreground API calls. Already-resolved entries are skipped, and when
   * one chain walk resolves multiple chain members those are also skipped in
   * subsequent iterations.
   */
  const resolveOrphanRoots = async (): Promise<void> => {
    const unresolved = get().entries.filter((e) => e.franchise_root_id == null);
    if (unresolved.length === 0) return;

    for (const entry of unresolved) {
      // Another iteration may have already resolved this via toUpdate.
      if (get().map[entry.anilist_id]?.franchise_root_id != null) continue;

      try {
        const inList = new Set(get().entries.map((e) => e.anilist_id));
        const { rootId, toUpdate } = await resolveFranchiseChain(
          entry.anilist_id,
          inList,
          "low",
        );

        await patchEntry(entry.anilist_id, { franchise_root_id: rootId });

        // Stamp the rest of the chain that's already in the list so the loop
        // can skip them — avoids redundant chain walks for sibling seasons.
        for (const id of toUpdate) {
          if (get().map[id]?.franchise_root_id == null) {
            await patchEntry(id, { franchise_root_id: rootId });
          }
        }
      } catch {
        // Non-fatal. The entry stays ungrouped until the next app launch.
      }
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
      void resolveOrphanRoots();
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
        franchise_root_id: null,
        airing_status: s.status ?? null,
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
        // Immediately scan this one new seed for sequels when added as
        // completed/dropped (foreground priority — the user is right here).
        if (status === "completed" || status === "dropped") {
          const { useNotificationStore } = await import("./notificationStore");
          void useNotificationStore.getState().scanSeed(get().entries, s.id);
        }
        // Walk the PREQUEL chain, add missing ancestors as completed, and tag
        // all franchise members with franchise_root_id. Skipped if dropped —
        // a dropped series doesn't imply the user watched everything before it.
        if (status !== "dropped") {
          void runFranchiseCascade(s.id);
        }
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
      // Scan just this seed immediately when marked completed/dropped.
      if (status === "completed" || status === "dropped") {
        const { useNotificationStore } = await import("./notificationStore");
        void useNotificationStore.getState().scanSeed(get().entries, anilistId);
      }
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
      // Episode tracking only makes sense while actively watching.
      if (prev.status !== "watching" && prev.status !== "rewatching") return;
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

    removeMany: (anilistIds) => {
      const removed = anilistIds
        .map((id) => get().map[id])
        .filter((e): e is AnimeListEntry => !!e);
      if (removed.length === 0) return;
      for (const e of removed) removeFromState(e.anilist_id);

      let undone = false;
      toast.action({
        message:
          removed.length === 1
            ? `Removed ${preferredTitle({
                romaji: removed[0].title_romaji,
                english: removed[0].title_english,
              })}`
            : `Removed ${removed.length} seasons`,
        actionLabel: "Undo",
        duration: 4000,
        onAction: () => {
          undone = true;
          for (const e of removed) applyEntry(e);
        },
      });
      setTimeout(async () => {
        if (undone) return;
        try {
          const db = await getDb();
          const now = Date.now();
          for (const e of removed) {
            await db.listRemove(e.anilist_id);
            await db.tombstoneUpsert({ anilist_id: e.anilist_id, deleted_at: now });
          }
          queueSync();
        } catch {
          for (const e of removed) applyEntry(e);
          toast.error("Couldn't remove those entries");
        }
      }, 4000);
    },

    clearAll: async ({ propagateToDrive = false } = {}) => {
      const previous = get().entries;
      if (previous.length === 0) return;
      // Optimistic wipe: the UI empties immediately.
      set({ entries: [], map: {} });
      try {
        const db = await getDb();
        await db.listReplaceAll([]);
        if (propagateToDrive) {
          // Tombstone every cleared id so the empty state wins the next merge
          // on other devices instead of being resurrected.
          const now = Date.now();
          const tombstones = previous.map((e) => ({
            anilist_id: e.anilist_id,
            deleted_at: now,
          }));
          await db.tombstonesReplaceAll(tombstones);
          await syncManager.pushNow();
        } else {
          // Local-only clear: drop tombstones too so a future sign-in pulls
          // cleanly from Drive without local deletions overriding it.
          await db.tombstonesReplaceAll([]);
        }
      } catch {
        set({ entries: previous, map: indexBy(previous) });
        toast.error("Couldn't clear your list");
      }
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
