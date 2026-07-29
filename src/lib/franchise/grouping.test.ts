import { describe, it, expect } from "vitest";
import { groupEntries } from "./grouping";
import { makeEntry } from "@/test/factories";

/**
 * Grouping decides what My List actually shows. The rules that matter most are
 * the ones that make cards appear or disappear: the not-interested mute, and
 * which member's cover speaks for a whole franchise.
 */

describe("groupEntries — bucketing", () => {
  it("wraps an unrelated entry as a group of one", () => {
    const groups = groupEntries([makeEntry({ anilist_id: 5 })]);
    expect(groups).toHaveLength(1);
    expect(groups[0].rootId).toBe(5);
    expect(groups[0].isGroup).toBe(false);
  });

  it("collects everything sharing a franchise root into one card", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 1, franchise_root_id: 1, added_at: 10 }),
      makeEntry({ anilist_id: 2, franchise_root_id: 1, added_at: 20 }),
      makeEntry({ anilist_id: 3, franchise_root_id: 1, added_at: 30 }),
      makeEntry({ anilist_id: 9 }),
    ]);
    expect(groups).toHaveLength(2);
    const franchise = groups.find((g) => g.rootId === 1)!;
    expect(franchise.isGroup).toBe(true);
    expect(franchise.entries.map((e) => e.anilist_id)).toEqual([1, 2, 3]);
  });

  it("orders members by when they were added, not by id", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 3, franchise_root_id: 1, added_at: 10 }),
      makeEntry({ anilist_id: 1, franchise_root_id: 1, added_at: 90 }),
    ]);
    expect(groups[0].entries.map((e) => e.anilist_id)).toEqual([3, 1]);
  });
});

describe("groupEntries — the not-interested mute", () => {
  it("gives a muted entry no card of its own", () => {
    expect(groupEntries([makeEntry({ anilist_id: 5, status: "not_interested" })])).toEqual(
      [],
    );
  });

  it("keeps a muted member out of its franchise's card entirely", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 1, franchise_root_id: 1, added_at: 10, status: "completed" }),
      makeEntry({
        anilist_id: 2,
        franchise_root_id: 1,
        added_at: 20,
        status: "not_interested",
        episodes_watched: 4,
      }),
    ]);
    expect(groups[0].entries.map((e) => e.anilist_id)).toEqual([1]);
    // A one-member card is no longer a group, and the muted progress is not counted.
    expect(groups[0].isGroup).toBe(false);
    expect(groups[0].totalWatched).toBe(0);
  });

  it("keeps the franchise root id even when the root itself is muted", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 1, franchise_root_id: 1, status: "not_interested" }),
      makeEntry({ anilist_id: 2, franchise_root_id: 1, status: "watching" }),
    ]);
    expect(groups[0].rootId).toBe(1);
    expect(groups[0].displayEntry.anilist_id).toBe(2);
  });
});

describe("groupEntries — which member represents the card", () => {
  const franchise = (statuses: Record<number, Parameters<typeof makeEntry>[0]["status"]>) =>
    groupEntries(
      Object.entries(statuses).map(([id, status], i) =>
        makeEntry({
          anilist_id: Number(id),
          franchise_root_id: 1,
          added_at: i * 10,
          status,
        }),
      ),
    )[0].displayEntry.anilist_id;

  it("follows an active watch above everything else", () => {
    expect(franchise({ 1: "completed", 2: "watching", 3: "plan_to_watch" })).toBe(2);
    expect(franchise({ 1: "completed", 2: "rewatching" })).toBe(2);
  });

  it("shows what is up next when nothing is being watched", () => {
    expect(franchise({ 1: "completed", 2: "plan_to_watch", 3: "plan_to_watch" })).toBe(2);
  });

  it("surfaces a stall over a finished season", () => {
    expect(franchise({ 1: "completed", 2: "on_hold" })).toBe(2);
  });

  it("reverts to the root's artwork once the whole franchise is done", () => {
    expect(franchise({ 2: "completed", 1: "completed", 3: "dropped" })).toBe(1);
  });

  it("falls back to the earliest member when the root is not tracked", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 2, franchise_root_id: 1, added_at: 50, status: "completed" }),
      makeEntry({ anilist_id: 3, franchise_root_id: 1, added_at: 10, status: "completed" }),
    ]);
    expect(groups[0].displayEntry.anilist_id).toBe(3);
  });

  // The reported bug: adding season 2 first made season 2 the card's current
  // entry, so Start and the loupe acted on it while season 1 sat unwatched.
  it("picks the first season even when a later one was added first", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 200, franchise_root_id: 100, added_at: 10, status: "plan_to_watch" }),
      makeEntry({ anilist_id: 100, franchise_root_id: 100, added_at: 90, status: "plan_to_watch" }),
    ]);
    expect(groups[0].displayEntry.anilist_id).toBe(100);
  });

  it("orders tied members by story position, not by when they were added", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 300, franchise_root_id: 100, added_at: 10, status: "watching" }),
      makeEntry({ anilist_id: 200, franchise_root_id: 100, added_at: 90, status: "watching" }),
      makeEntry({ anilist_id: 100, franchise_root_id: 100, added_at: 50, status: "completed" }),
    ]);
    expect(groups[0].displayEntry.anilist_id).toBe(200);
  });
});

describe("groupEntries — totals and sort keys", () => {
  it("sums watched episodes across the franchise", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 1, franchise_root_id: 1, episodes_watched: 12 }),
      makeEntry({ anilist_id: 2, franchise_root_id: 1, episodes_watched: 5 }),
    ]);
    expect(groups[0].totalWatched).toBe(17);
    expect(groups[0].totalEpisodes).toBe(24);
  });

  it("reports an unknown total when any member's count is unknown", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 1, franchise_root_id: 1, total_episodes: 12 }),
      makeEntry({ anilist_id: 2, franchise_root_id: 1, total_episodes: null }),
    ]);
    expect(groups[0].totalEpisodes).toBeNull();
  });

  it("sorts by the franchise's newest edit and oldest add", () => {
    const groups = groupEntries([
      makeEntry({ anilist_id: 1, franchise_root_id: 1, added_at: 10, updated_at: 100 }),
      makeEntry({ anilist_id: 2, franchise_root_id: 1, added_at: 40, updated_at: 900 }),
    ]);
    expect(groups[0].sortUpdated).toBe(900);
    expect(groups[0].sortAdded).toBe(10);
  });
});
