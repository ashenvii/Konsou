import { create } from "zustand";
import { getDb } from "@/lib/db";
import type { AnimeListEntry, CompletionEvent } from "@/types/list";

/**
 * The completion ledger: every finished watch, in order, kept apart from the
 * list itself.
 *
 * It has to be its own store because its rows outlive the entries they came
 * from. Removing an anime deletes its `anime_list` row; the completions stay,
 * and the Completed room renders them as ghost records ("no longer in your
 * collection"). A log folded into listStore would be wiped along with the entry
 * every time, which is the thing this whole table exists to prevent.
 */
interface CompletionState {
  loaded: boolean;
  events: CompletionEvent[];

  load: () => Promise<void>;
  /** Record that this entry was just finished. No-op if already recorded. */
  record: (entry: AnimeListEntry, at?: number) => Promise<void>;
  /** Record a batch (catch-up "I already watched these"). */
  recordMany: (entries: AnimeListEntry[], at?: number) => Promise<void>;
  /** Rebuild missing history for entries that arrived with a finish already on
   *  them (a restored backup, an AniList import). Dates are reconstructed. */
  backfill: (entries: AnimeListEntry[]) => Promise<void>;
  /** Take back the event a just-undone completion wrote. */
  retract: (anilistId: number, rewatchIndex: number) => Promise<void>;
  /** Replace the whole log after a sync merge. */
  replaceAll: (events: CompletionEvent[]) => Promise<void>;
  clear: () => Promise<void>;
}

/** Newest first, and a stable order for events finished in the same millisecond. */
function byNewest(a: CompletionEvent, b: CompletionEvent): number {
  return b.completed_at - a.completed_at || b.rewatch_index - a.rewatch_index;
}

/**
 * The event a completion of `entry` produces right now.
 *
 * `rewatch_count` is the number of watches already finished (it increments when
 * a completed entry flips to rewatching), so it doubles as this event's index:
 * a first watch writes 0, the run after the first rewatch writes 1.
 */
export function eventFor(entry: AnimeListEntry, at: number): CompletionEvent {
  return {
    anilist_id: entry.anilist_id,
    rewatch_index: entry.rewatch_count ?? 0,
    completed_at: at,
    episodes_at_completion:
      entry.total_episodes ?? entry.episodes_watched ?? 0,
    episode_duration: entry.episode_duration ?? null,
    total_episodes: entry.total_episodes ?? null,
    title_romaji: entry.title_romaji,
    title_english: entry.title_english ?? null,
    title_native: entry.title_native ?? null,
    cover_url: entry.cover_url ?? null,
    franchise_root_id: entry.franchise_root_id ?? null,
    // Recorded as it happened, not reconstructed.
    estimated: false,
  };
}

/**
 * The watches an already-finished entry implies, when no event history came
 * with it. Same reconstruction migration 12 runs on upgrade: one row per
 * finished watch, all carrying the single date the entry knows, every one
 * flagged `estimated` so nothing presents a guess as a record.
 */
export function reconstructEvents(entry: AnimeListEntry): CompletionEvent[] {
  const finished = entry.status === "completed" || entry.completed_at != null;
  if (!finished && entry.status !== "rewatching") return [];
  const priorWatches = entry.rewatch_count ?? 0;
  const count = entry.status === "rewatching" ? priorWatches : priorWatches + 1;
  const at = entry.completed_at ?? entry.updated_at;
  return Array.from({ length: count }, (_, i) => ({
    ...eventFor(entry, at),
    rewatch_index: i,
    estimated: true,
  }));
}

export const useCompletionStore = create<CompletionState>((set, get) => {
  const key = (e: CompletionEvent) => `${e.anilist_id}:${e.rewatch_index}`;

  /**
   * Append events that are actually new, optimistically, and take them back out
   * if the write fails. Dropping already-known events here mirrors the table's
   * own key, so a re-import or a replayed sync log adds nothing twice.
   */
  const write = async (events: CompletionEvent[]): Promise<void> => {
    const seen = new Set(get().events.map(key));
    const fresh = events.filter((e) => !seen.has(key(e)));
    if (fresh.length === 0) return;
    set((s) => ({ events: [...fresh, ...s.events].sort(byNewest) }));
    try {
      const db = await getDb();
      for (const e of fresh) await db.completionAppend(e);
    } catch {
      // Roll the memory back so the room never shows a watch the record does
      // not actually hold.
      const failed = new Set(fresh.map(key));
      set((s) => ({ events: s.events.filter((e) => !failed.has(key(e))) }));
    }
  };

  return {
    loaded: false,
    events: [],

    load: async () => {
      try {
        const db = await getDb();
        const events = await db.completionsAll();
        set({ events: [...events].sort(byNewest), loaded: true });
      } catch {
        // The ledger is history, never a blocker: an unreadable log leaves the
        // room empty rather than stopping the list from loading.
        set({ loaded: true });
      }
    },

    record: async (entry, at = Date.now()) => {
      await get().recordMany([entry], at);
    },

    recordMany: async (entries, at = Date.now()) => {
      await write(entries.map((e) => eventFor(e, at)));
    },

    backfill: async (entries) => {
      await write(entries.flatMap(reconstructEvents));
    },

    retract: async (anilistId, rewatchIndex) => {
      set((s) => ({
        events: s.events.filter(
          (e) => !(e.anilist_id === anilistId && e.rewatch_index === rewatchIndex),
        ),
      }));
      try {
        const db = await getDb();
        await db.completionRemove(anilistId, rewatchIndex);
      } catch {
        // The row stays in the database and comes back on the next load. The
        // ledger over-reporting by one is the safer failure than losing it.
      }
    },

    replaceAll: async (events) => {
      set({ events: [...events].sort(byNewest) });
      const db = await getDb();
      await db.completionsReplaceAll(events);
    },

    clear: async () => {
      set({ events: [] });
      const db = await getDb();
      await db.completionsReplaceAll([]);
    },
  };
});
