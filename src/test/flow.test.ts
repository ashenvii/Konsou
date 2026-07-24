import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import type { RelationNode } from "@/types/anime";
import type { AnimeSummary } from "@/types/anime";
import type { AnimeListEntry } from "@/types/list";
import { makeEntry } from "@/test/factories";

/**
 * A full-flow test standing in for the browser E2E that a Tauri app can't run
 * deterministically (real AniList + real Drive OAuth). It drives one lifecycle —
 * add → log progress → sync-merge a second device → detect a sequel — through
 * the REAL modules (listStore, mergeLists, detectSequels, the web shim), mocking
 * only the network edge. If any two of those stop composing, this breaks.
 */

// The one seam we fake: AniList's relation graph. Everything else is real.
const relationGraph: Record<number, RelationNode[]> = {};
vi.mock("@/lib/api/anilist/client", () => ({
  anilist: {
    getRelationsBatch: vi.fn(async (ids: number[]) => {
      const out: Record<number, RelationNode[]> = {};
      for (const id of ids) out[id] = relationGraph[id] ?? [];
      return out;
    }),
  },
}));
vi.mock("@/lib/franchise/cascade", () => ({
  resolveFranchiseChain: vi.fn(async (startId: number) => ({
    rootId: startId,
    toAdd: [],
    toUpdate: [],
  })),
}));
vi.mock("@/lib/haptics", () => ({ haptic: vi.fn() }));
vi.mock("@/lib/sync/queue", () => ({ syncQueue: { scheduleWrite: vi.fn() } }));
vi.mock("@/lib/sync/syncManager", () => ({
  syncManager: { pushNow: vi.fn(async () => {}) },
}));
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
vi.mock("@/lib/store/episodeUndo", () => ({ recordEpisodeLog: vi.fn() }));

import { useListStore } from "@/lib/store/listStore";
import { mergeLists } from "@/lib/sync/merger";
import { detectSequels } from "@/lib/sequel/detector";
import { getDb } from "@/lib/db";

const flush = () => new Promise((r) => setTimeout(r, 0));
const store = () => useListStore.getState();

function summary(id: number, over: Partial<AnimeSummary> = {}): AnimeSummary {
  return {
    id,
    title: { romaji: `Show ${id}`, english: null, native: null },
    episodes: 12,
    ...over,
  };
}

function rel(id: number, over: Partial<RelationNode>): RelationNode {
  return {
    relationType: "SEQUEL",
    id,
    title: { romaji: `Show ${id}`, english: null, native: null },
    ...over,
  } as RelationNode;
}

beforeEach(() => {
  localStorage.clear();
  for (const k of Object.keys(relationGraph)) delete relationGraph[Number(k)];
  useListStore.setState({ entries: [], map: {}, loaded: false });
});

afterEach(() => {
  vi.clearAllMocks();
});

describe("the add → progress → sync → sequel lifecycle", () => {
  it("carries one entry through every stage without losing data", async () => {
    const db = await getDb();
    await store().load();

    // 1. ADD — a show the user is watching, and an older season already finished.
    await store().addFromSummary(summary(100, { episodes: 12 }), "watching");
    await store().addFromSummary(summary(50, { episodes: 12 }), "completed");
    expect(store().isInList(100)).toBe(true);
    expect(store().map[50].episodes_watched).toBe(12);

    // 2. PROGRESS — log three episodes on the active show.
    await store().incrementEpisodes(100, 1);
    await store().incrementEpisodes(100, 1);
    await store().incrementEpisodes(100, 1);
    await flush();
    expect(store().map[100].episodes_watched).toBe(3);

    // 3. SYNC — a second device that watched further, plus a title only it has.
    //    Run the real merger the way syncManager._applyMerge does, then reload.
    const local = await db.listAll();
    const now = Date.now();
    const remote: AnimeListEntry[] = [
      // Device B is ahead on the shared show.
      { ...local.find((e) => e.anilist_id === 100)!, episodes_watched: 7, updated_at: now + 10_000 },
      // And has a title device A never added.
      makeEntry({ anilist_id: 200, status: "watching", episodes_watched: 2, updated_at: now }),
    ];
    const merged = mergeLists(local, remote, [], []);
    await db.listReplaceAll(merged.entries);
    await store().load();
    await flush();

    // Progress advanced to the further device, nothing regressed, both lists unioned.
    expect(store().map[100].episodes_watched).toBe(7);
    expect(store().isInList(200)).toBe(true);
    expect(store().isInList(50)).toBe(true);

    // 4. SEQUEL CHECK — the finished season has an announced sequel not yet added.
    relationGraph[50] = [
      rel(51, { relationType: "SEQUEL", status: "NOT_YET_RELEASED" }),
      rel(49, { relationType: "PREQUEL", status: "FINISHED" }), // earlier, not a continuation
      rel(9000, { relationType: "ADAPTATION", type: "MANGA", status: "RELEASING" }), // source, never surfaced
    ];
    const inList = new Set(store().entries.map((e) => e.anilist_id));
    const { notifications, volatileSeeds } = await detectSequels([50], inList, "low");

    // Exactly the announced sequel surfaces: not the prequel, not the manga source.
    expect(notifications.map((n) => n.related_id)).toEqual([51]);
    expect(notifications[0].type).toBe("sequel");
    expect(notifications[0].source_id).toBe(50);
    // An announced entry makes the seed volatile, so it gets re-checked often.
    expect(volatileSeeds.has(50)).toBe(true);

    // 5. PERSIST the alert through the same shim the app uses, and confirm it
    //    dedupes on a second scan (one alert per suggested title).
    for (const n of notifications) {
      expect(await db.notificationInsertIfNew(n)).toBe(true);
    }
    const rescan = await detectSequels([50], inList, "low");
    for (const n of rescan.notifications) {
      expect(await db.notificationInsertIfNew(n)).toBe(false);
    }
    expect(await db.notificationsActive()).toHaveLength(1);
  });

  it("does not surface a sequel the user has already added", async () => {
    const db = await getDb();
    await store().load();
    await store().addFromSummary(summary(50), "completed");
    await store().addFromSummary(summary(51), "plan_to_watch"); // already tracked
    await flush();

    relationGraph[50] = [rel(51, { relationType: "SEQUEL", status: "NOT_YET_RELEASED" })];
    const inList = new Set(store().entries.map((e) => e.anilist_id));
    const { notifications } = await detectSequels([50], inList, "low");

    expect(notifications).toHaveLength(0);
    expect(await db.notificationsActive()).toHaveLength(0);
  });
});
