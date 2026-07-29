import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import type { AnimeSummary } from "@/types/anime";
import type { AnimeListEntry } from "@/types/list";
import { makeEntry } from "@/test/factories";

/**
 * listStore is the biggest single risk surface in the app: every add, status
 * change, episode log and plan-queue edit funnels through it, and a slip is
 * silent — no crash, just the wrong number saved. The plan queue especially has
 * a history of shipping broken (a rank leaking past its status, a legacy total
 * order flooding the shelf), so it gets the most coverage here.
 *
 * The store's network and side-effecting collaborators are mocked; the store
 * runs against the real browser shim (jsdom → WebKonsouDb), so the DB writes are
 * real and the optimistic-then-persist paths are actually exercised.
 */

// The franchise cascade and split-root healing reach the network. Neutralize
// them: a resolve that finds nothing new keeps the add flow intact without a
// real chain walk.
vi.mock("@/lib/franchise/cascade", () => ({
  resolveFranchiseChain: vi.fn(async (startId: number) => ({
    rootId: startId,
    toAdd: [],
    toUpdate: [],
  })),
}));
vi.mock("@/lib/api/anilist/client", () => ({
  anilist: { getRelationsBatch: vi.fn(async () => ({})) },
}));
vi.mock("@/lib/haptics", () => ({ haptic: vi.fn() }));
vi.mock("@/lib/sync/queue", () => ({
  syncQueue: { scheduleWrite: vi.fn() },
}));
vi.mock("@/lib/sync/syncManager", () => ({
  syncManager: { pushNow: vi.fn(async () => {}) },
}));
// Dynamically imported inside the store; the mock has to expose the same shape.
vi.mock("@/lib/store/notificationStore", () => ({
  useNotificationStore: {
    getState: () => ({
      loaded: false,
      scanSeed: vi.fn(async () => {}),
      entriesRemoved: vi.fn(async () => {}),
      load: vi.fn(async () => {}),
    }),
  },
}));
// Assert against the undo batching without pulling in its real timers.
vi.mock("@/lib/store/episodeUndo", () => ({ recordEpisodeLog: vi.fn() }));

import { useListStore, UP_NEXT_CAP } from "./listStore";
import { useCompletionStore } from "./completionStore";
import { recordEpisodeLog } from "./episodeUndo";
import { toast } from "./toastStore";
import { getDb } from "@/lib/db";

/** Let the store's fire-and-forget writes (void normalize/patch chains) settle. */
const flush = () => new Promise((r) => setTimeout(r, 0));

function makeSummary(over: Partial<AnimeSummary> & { id: number }): AnimeSummary {
  return {
    title: { romaji: `Title ${over.id}`, english: null, native: null },
    episodes: 12,
    ...over,
  };
}

/** Put entries straight into the DB and load them, as a real launch would. */
async function seed(entries: AnimeListEntry[]) {
  const db = await getDb();
  await db.listReplaceAll(entries);
  await useListStore.getState().load();
  await flush();
}

/** A planned entry carrying a manual queue number. */
function planned(id: number, rank: number | null, over: Partial<AnimeListEntry> = {}) {
  return makeEntry({
    anilist_id: id,
    status: "plan_to_watch",
    plan_rank: rank,
    franchise_root_id: id, // pre-resolved, so grooming finds nothing to walk
    ...over,
  });
}

const store = () => useListStore.getState();
const rankOf = (id: number) => store().map[id]?.plan_rank ?? null;

beforeEach(() => {
  localStorage.clear();
  useListStore.setState({ entries: [], map: {}, loaded: false });
});

afterEach(() => {
  vi.clearAllMocks();
});

describe("addFromSummary", () => {
  it("adds a plan entry unranked, so it falls in by date until dragged", async () => {
    await seed([]);
    await store().addFromSummary(makeSummary({ id: 1 }), "plan_to_watch");
    const e = store().map[1];
    expect(e.status).toBe("plan_to_watch");
    expect(e.plan_rank).toBeNull();
    expect(e.episodes_watched).toBe(0);
  });

  it("marks a completed add as fully watched and stamps completed_at", async () => {
    await seed([]);
    await store().addFromSummary(makeSummary({ id: 1, episodes: 24 }), "completed");
    const e = store().map[1];
    expect(e.episodes_watched).toBe(24);
    expect(e.completed_at).not.toBeNull();
    expect(e.started_at).toBeNull();
  });

  it("stamps started_at when added straight to watching", async () => {
    await seed([]);
    await store().addFromSummary(makeSummary({ id: 1 }), "watching");
    expect(store().map[1].started_at).not.toBeNull();
  });

  it("refuses to complete a show that is still airing", async () => {
    const err = vi.spyOn(toast, "error").mockReturnValue(0);
    await seed([]);
    await store().addFromSummary(
      makeSummary({ id: 1, status: "RELEASING" }),
      "completed",
    );
    expect(store().map[1]).toBeUndefined();
    expect(err).toHaveBeenCalled();
  });
});

describe("updateStatus", () => {
  it("removes the entry when not-interested is picked a second time (the un-mute)", async () => {
    await seed([planned(1, null, { status: "not_interested" })]);
    await store().updateStatus(1, "not_interested");
    await flush();
    expect(store().map[1]).toBeUndefined();
  });

  it("fills episodes and stamps completed_at when marking completed", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12, episodes_watched: 3 })]);
    await store().updateStatus(1, "completed");
    const e = store().map[1];
    expect(e.episodes_watched).toBe(12);
    expect(e.completed_at).not.toBeNull();
  });

  it("counts a completed→rewatching flip as a prior watch and restarts progress", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "completed", total_episodes: 12, episodes_watched: 12, rewatch_count: 1 })]);
    await store().updateStatus(1, "rewatching");
    const e = store().map[1];
    expect(e.rewatch_count).toBe(2);
    expect(e.episodes_watched).toBe(0);
  });

  it("lets a finished-by-count airing show complete despite the airing guard", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "watching", airing_status: "RELEASING", total_episodes: 12, episodes_watched: 12 })]);
    await store().updateStatus(1, "completed");
    expect(store().map[1].status).toBe("completed");
  });

  it("drops the plan rank and closes the gap when a queued title leaves the plan", async () => {
    await seed([planned(1, 1), planned(2, 2), planned(3, 3)]);
    await store().updateStatus(2, "watching");
    await flush();
    expect(rankOf(2)).toBeNull();
    // 1 and 3 renumber dense, no hole where #2 was.
    expect([rankOf(1), rankOf(3)]).toEqual([1, 2]);
  });
});

describe("setEpisodes", () => {
  it("clamps below zero and above the known total", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12, episodes_watched: 5 })]);
    await store().setEpisodes(1, -3);
    expect(store().map[1].episodes_watched).toBe(0);
    await store().setEpisodes(1, 99);
    expect(store().map[1].episodes_watched).toBe(12);
  });

  it("offers to close the entry out on reaching the final episode", async () => {
    const action = vi.spyOn(toast, "action").mockReturnValue(0);
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12, episodes_watched: 11 })]);
    await store().setEpisodes(1, 12);
    expect(action).toHaveBeenCalledTimes(1);
  });

  it("does not re-offer when the run was already finished", async () => {
    const action = vi.spyOn(toast, "action").mockReturnValue(0);
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12, episodes_watched: 12 })]);
    await store().setEpisodes(1, 12);
    expect(action).not.toHaveBeenCalled();
  });
});

describe("incrementEpisodes", () => {
  it("is ignored unless the entry is actively being watched", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "plan_to_watch", episodes_watched: 0 })]);
    await store().incrementEpisodes(1, 1);
    expect(store().map[1].episodes_watched).toBe(0);
  });

  it("advances progress and records a batchable undo for a plain +1", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12, episodes_watched: 3 })]);
    await store().incrementEpisodes(1, 1);
    expect(store().map[1].episodes_watched).toBe(4);
    expect(recordEpisodeLog).toHaveBeenCalledWith(1, 3, 4);
  });

  it("does not record an undo for the finale increment — the complete toast owns it", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12, episodes_watched: 11 })]);
    await store().incrementEpisodes(1, 1);
    expect(recordEpisodeLog).not.toHaveBeenCalled();
  });
});

describe("the plan queue", () => {
  describe("addToPlanOrder", () => {
    it("appends the next number and reports success", async () => {
      await seed([planned(1, 1), planned(2, null)]);
      expect(store().addToPlanOrder(2)).toBe(true);
      await flush();
      expect(rankOf(2)).toBe(2);
    });

    it("refuses a title that is already ranked or not planned", async () => {
      await seed([planned(1, 1), makeEntry({ anilist_id: 9, status: "watching" })]);
      expect(store().addToPlanOrder(1)).toBe(false);
      expect(store().addToPlanOrder(9)).toBe(false);
    });

    it("refuses once the queue is full", async () => {
      const full = Array.from({ length: UP_NEXT_CAP }, (_, i) => planned(i + 1, i + 1));
      await seed([...full, planned(99, null)]);
      expect(store().addToPlanOrder(99)).toBe(false);
      await flush();
      expect(rankOf(99)).toBeNull();
    });
  });

  describe("reorderPlan", () => {
    it("writes a dense 1..N in the given order", async () => {
      await seed([planned(1, 1), planned(2, 2), planned(3, 3)]);
      await store().reorderPlan([3, 1, 2]);
      await flush();
      expect([rankOf(3), rankOf(1), rankOf(2)]).toEqual([1, 2, 3]);
    });

    it("caps at UP_NEXT_CAP and releases the overflow to the library", async () => {
      const ids = Array.from({ length: UP_NEXT_CAP + 3 }, (_, i) => i + 1);
      await seed(ids.map((id) => planned(id, null)));
      await store().reorderPlan(ids);
      await flush();
      for (let i = 0; i < UP_NEXT_CAP; i++) expect(rankOf(ids[i])).toBe(i + 1);
      for (let i = UP_NEXT_CAP; i < ids.length; i++) expect(rankOf(ids[i])).toBeNull();
    });
  });

  describe("setPlanNumber", () => {
    it("inserts at a position and renumbers everything densely around it", async () => {
      await seed([planned(1, 1), planned(2, 2), planned(3, 3)]);
      // Make #3 the new #1.
      await store().setPlanNumber(3, 1);
      await flush();
      expect([rankOf(3), rankOf(1), rankOf(2)]).toEqual([1, 2, 3]);
    });

    it("clears a number and closes the gap it leaves", async () => {
      await seed([planned(1, 1), planned(2, 2), planned(3, 3)]);
      await store().setPlanNumber(2, null);
      await flush();
      expect(rankOf(2)).toBeNull();
      expect([rankOf(1), rankOf(3)]).toEqual([1, 2]);
    });

    it("refuses to add a new title once full, but still lets an existing one move", async () => {
      const full = Array.from({ length: UP_NEXT_CAP }, (_, i) => planned(i + 1, i + 1));
      await seed([...full, planned(99, null)]);

      await store().setPlanNumber(99, 1); // new entry, queue full → rejected
      await flush();
      expect(rankOf(99)).toBeNull();

      await store().setPlanNumber(UP_NEXT_CAP, 1); // already inside → allowed to move
      await flush();
      expect(rankOf(UP_NEXT_CAP)).toBe(1);
    });
  });

  describe("legacy repair on load", () => {
    it("collapses a pre-rework total order into a clean 1..N", async () => {
      // The old model ranked every planned entry (0-based, hundreds deep).
      await seed([planned(1, 0), planned(2, 1), planned(3, 2)]);
      expect([rankOf(1), rankOf(2), rankOf(3)]).toEqual([1, 2, 3]);
    });

    it("keeps the lowest-ranked entries and releases everything past the cap", async () => {
      // A restored backup with far more ranked entries than the cap allows.
      const ids = Array.from({ length: UP_NEXT_CAP + 5 }, (_, i) => i + 1);
      await seed(ids.map((id) => planned(id, id))); // ranks 1..N+5
      const survivors = ids.filter((id) => rankOf(id) != null);
      expect(survivors).toHaveLength(UP_NEXT_CAP);
      // The ones deliberately placed first (lowest ranks) are the survivors.
      expect(survivors).toEqual(ids.slice(0, UP_NEXT_CAP));
    });

    it("leaves an already-legal queue untouched (no needless writes)", async () => {
      await seed([planned(1, 1), planned(2, 2)]);
      const before = store().map[1].updated_at;
      await store().load();
      await flush();
      expect(store().map[1].updated_at).toBe(before);
    });
  });
});

/**
 * The completion ledger. Before it, `completed_at` was a single column written
 * once: finish a show in 2021, rewatch and finish it again this week, and the
 * list still said 2021. Every finish now writes its own dated row, and those
 * rows outlive the entry.
 */
describe("the completion ledger", () => {
  const events = () => useCompletionStore.getState().events;

  beforeEach(async () => {
    useCompletionStore.setState({ events: [], loaded: false });
  });

  it("records a row the first time an entry is finished", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12 })]);
    await store().updateStatus(1, "completed");
    await flush();
    expect(events()).toHaveLength(1);
    expect(events()[0]).toMatchObject({
      anilist_id: 1,
      rewatch_index: 0,
      episodes_at_completion: 12,
      estimated: false,
    });
  });

  it("gives every rewatch its own dated row instead of overwriting the first", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12 })]);
    await store().updateStatus(1, "completed");
    await flush();
    const first = store().map[1].completed_at!;

    vi.setSystemTime(new Date(first + 60_000));
    await store().updateStatus(1, "rewatching");
    await store().updateStatus(1, "completed");
    await flush();
    vi.useRealTimers();

    expect(events().map((e) => e.rewatch_index).sort()).toEqual([0, 1]);
    // The bug this table exists for: the entry's own date now moves too.
    expect(store().map[1].completed_at).toBeGreaterThan(first);
  });

  it("does not log a second event for re-picking a status already set", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "completed", completed_at: 500 })]);
    await store().updateStatus(1, "completed");
    await flush();
    expect(events()).toHaveLength(0);
    expect(store().map[1].completed_at).toBe(500);
  });

  it("keeps the record after the entry itself is removed", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12 })]);
    await store().updateStatus(1, "completed");
    await flush();
    store().remove(1);
    await flush();
    expect(store().map[1]).toBeUndefined();
    expect(events()).toHaveLength(1);
    expect(events()[0].title_romaji).toBe("Title 1");
  });

  it("rebuilds history from a restored backup, without duplicating it", async () => {
    await seed([]);
    const backup = [
      makeEntry({ anilist_id: 1, status: "completed", completed_at: 900, rewatch_count: 2 }),
      makeEntry({ anilist_id: 2, status: "watching" }),
    ];
    await store().importEntries(backup);
    await flush();
    // Three finishes for the rewatched title, none for the one still running.
    expect(events()).toHaveLength(3);
    expect(events().every((e) => e.estimated)).toBe(true);

    await store().importEntries(backup);
    await flush();
    expect(events()).toHaveLength(3);
  });

  it("clears the ledger when the whole list is erased", async () => {
    await seed([makeEntry({ anilist_id: 1, status: "watching", total_episodes: 12 })]);
    await store().updateStatus(1, "completed");
    await flush();
    await store().clearAll();
    await flush();
    expect(events()).toHaveLength(0);
  });
});

/**
 * Start and Done sit next to each other under a thumb in the plan room, so a
 * mistap has to be one tap to reverse — including the queue number the change
 * released and the ledger row a completion wrote.
 */
describe("updateStatusUndoable", () => {
  const events = () => useCompletionStore.getState().events;

  beforeEach(() => {
    useCompletionStore.setState({ events: [], loaded: false });
  });

  it("offers an undo that puts the entry back exactly as it was", async () => {
    const action = vi.spyOn(toast, "action").mockReturnValue(0);
    await seed([planned(1, 1), planned(2, 2)]);
    await store().updateStatusUndoable(1, "completed", "Title 1");
    await flush();
    expect(store().map[1].status).toBe("completed");
    expect(store().map[1].episodes_watched).toBe(12);
    expect(rankOf(1)).toBeNull();
    // The queue closed the gap behind it.
    expect(rankOf(2)).toBe(1);
    expect(events()).toHaveLength(1);

    const undo = action.mock.calls.at(-1)?.[0];
    expect(undo?.actionLabel).toBe("Undo");
    undo?.onAction?.();
    await flush();

    expect(store().map[1].status).toBe("plan_to_watch");
    expect(store().map[1].episodes_watched).toBe(0);
    expect(rankOf(1)).toBe(1);
    expect(rankOf(2)).toBe(2);
    // A completion that was taken back leaves no record of having happened.
    expect(events()).toHaveLength(0);
  });

  it("says nothing to undo when a guard refused the change", async () => {
    await seed([
      makeEntry({ anilist_id: 1, status: "plan_to_watch", airing_status: "NOT_YET_RELEASED" }),
    ]);
    const action = vi.spyOn(toast, "action").mockReturnValue(0);
    vi.spyOn(toast, "error").mockReturnValue(0);
    await store().updateStatusUndoable(1, "watching", "Title 1");
    await flush();
    expect(store().map[1].status).toBe("plan_to_watch");
    expect(action).not.toHaveBeenCalled();
  });
});
