import { describe, expect, it, vi } from "vitest";
import { makeEntry } from "@/test/factories";
import type { KonsouDb } from "@/lib/db/contract";

const getAiringStatusBatch = vi.fn();
vi.mock("@/lib/api/anilist/client", () => ({
  anilist: {
    getAiringStatusBatch: (...args: unknown[]) => getAiringStatusBatch(...args),
  },
}));

const { scanPlanToWatchAirings } = await import("./airingScan");

function fakeDb(): KonsouDb & { listUpdate: ReturnType<typeof vi.fn> } {
  return { listUpdate: vi.fn() } as unknown as KonsouDb & {
    listUpdate: ReturnType<typeof vi.fn>;
  };
}

describe("scanPlanToWatchAirings", () => {
  it("notifies once a plan_to_watch entry starts airing", async () => {
    getAiringStatusBatch.mockResolvedValue(
      new Map([[1, { status: "RELEASING", episodes: 12, nextAiringAt: 2_000, nextEpisode: 2 }]]),
    );
    const db = fakeDb();
    const entry = makeEntry({
      anilist_id: 1,
      status: "plan_to_watch",
      airing_status: "NOT_YET_RELEASED",
    });

    const result = await scanPlanToWatchAirings([entry], db);

    expect(result.notifications).toHaveLength(1);
    expect(result.notifications[0].type).toBe("started_airing");
    expect(result.updatedIds).toEqual([1]);
    expect(db.listUpdate).toHaveBeenCalledWith(
      1,
      expect.objectContaining({ airing_status: "RELEASING" }),
    );
  });

  it("silently refreshes a watching entry's aired_episodes with no notification", async () => {
    // Entry was added when only 3 episodes had aired; 2 more have aired since.
    getAiringStatusBatch.mockResolvedValue(
      new Map([[2, { status: "RELEASING", episodes: 12, nextAiringAt: 9_000, nextEpisode: 6 }]]),
    );
    const db = fakeDb();
    const entry = makeEntry({
      anilist_id: 2,
      status: "watching",
      airing_status: "RELEASING",
      total_episodes: 12,
      aired_episodes: 3,
      episodes_watched: 3,
    });

    const result = await scanPlanToWatchAirings([entry], db);

    expect(result.notifications).toHaveLength(0);
    expect(result.updatedIds).toEqual([2]);
    expect(db.listUpdate).toHaveBeenCalledWith(
      2,
      expect.objectContaining({ aired_episodes: 5 }),
    );
  });

  it("resolves a long-running series with no fixed total (One Piece shape)", async () => {
    // AniList reports `episodes: null` for an ongoing long-runner; the
    // aired count still has to resolve from nextAiringEpisode alone.
    getAiringStatusBatch.mockResolvedValue(
      new Map([[3, { status: "RELEASING", episodes: null, nextAiringAt: 9_000, nextEpisode: 1086 }]]),
    );
    const db = fakeDb();
    const entry = makeEntry({
      anilist_id: 3,
      status: "watching",
      airing_status: "RELEASING",
      total_episodes: null,
      aired_episodes: 1_084,
      episodes_watched: 1_084,
    });

    await scanPlanToWatchAirings([entry], db);

    expect(db.listUpdate).toHaveBeenCalledWith(
      3,
      expect.objectContaining({ aired_episodes: 1_085 }),
    );
    // No total ever existed to backfill; the patch must not invent one.
    const patch = db.listUpdate.mock.calls[0][1];
    expect(patch.total_episodes).toBeUndefined();
  });

  it("writes nothing when the aired count has not moved", async () => {
    getAiringStatusBatch.mockResolvedValue(
      new Map([[4, { status: "RELEASING", episodes: 12, nextAiringAt: 9_000, nextEpisode: 4 }]]),
    );
    const db = fakeDb();
    const entry = makeEntry({
      anilist_id: 4,
      status: "watching",
      airing_status: "RELEASING",
      total_episodes: 12,
      aired_episodes: 3,
      episodes_watched: 3,
    });

    const result = await scanPlanToWatchAirings([entry], db);

    expect(db.listUpdate).not.toHaveBeenCalled();
    expect(result.updatedIds).toEqual([]);
  });

  it("ignores watching entries that are not currently RELEASING", async () => {
    const db = fakeDb();
    const entry = makeEntry({
      anilist_id: 5,
      status: "watching",
      airing_status: "FINISHED",
    });

    const result = await scanPlanToWatchAirings([entry], db);

    expect(getAiringStatusBatch).not.toHaveBeenCalled();
    expect(result.updatedIds).toEqual([]);
  });
});
