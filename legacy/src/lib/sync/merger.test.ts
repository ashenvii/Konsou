import { describe, it, expect } from "vitest";
import {
  CLOCK_SKEW_TOLERANCE_MS as SKEW,
  higherPriorityStatus,
  mergeAnimeEntry,
  mergeCompletions,
  mergeLists,
  mergeTombstones,
} from "./merger";
import { makeEntry } from "@/test/factories";
import type { CompletionEvent } from "@/types/list";

/**
 * The merge decides what survives when two devices disagree, so every rule here
 * is a rule about not losing someone's watch history. A "wrong" merge is silent:
 * nothing errors, progress just quietly goes backwards on one device.
 */

const T = 1_700_000_000_000;

describe("higherPriorityStatus", () => {
  it("ranks further-along progress above earlier stages", () => {
    expect(higherPriorityStatus("completed", "watching")).toBe("completed");
    expect(higherPriorityStatus("watching", "plan_to_watch")).toBe("watching");
    expect(higherPriorityStatus("on_hold", "dropped")).toBe("on_hold");
  });

  it("keeps a real status over the not-interested mute flag", () => {
    expect(higherPriorityStatus("not_interested", "dropped")).toBe("dropped");
    expect(higherPriorityStatus("not_interested", "plan_to_watch")).toBe(
      "not_interested",
    );
  });

  it("is order independent", () => {
    expect(higherPriorityStatus("watching", "completed")).toBe(
      higherPriorityStatus("completed", "watching"),
    );
  });
});

describe("mergeAnimeEntry — progress", () => {
  it("never lets episodes go backwards, whichever side is newer", () => {
    const local = makeEntry({ anilist_id: 1, episodes_watched: 12, updated_at: T });
    const remote = makeEntry({
      anilist_id: 1,
      episodes_watched: 3,
      updated_at: T + 10 * SKEW,
    });
    expect(mergeAnimeEntry(local, remote).episodes_watched).toBe(12);
    expect(mergeAnimeEntry(remote, local).episodes_watched).toBe(12);
  });

  it("only ever grows the rewatch count", () => {
    const local = makeEntry({ anilist_id: 1, rewatch_count: 2, updated_at: T });
    const remote = makeEntry({ anilist_id: 1, rewatch_count: 0, updated_at: T + SKEW * 2 });
    expect(mergeAnimeEntry(local, remote).rewatch_count).toBe(2);
  });

  it("treats a missing rewatch count from an older app version as zero", () => {
    const local = makeEntry({ anilist_id: 1 });
    const remote = makeEntry({ anilist_id: 1 });
    // Payload written before the field existed.
    delete (remote as Partial<typeof remote>).rewatch_count;
    expect(mergeAnimeEntry(local, remote).rewatch_count).toBe(0);
  });
});

describe("mergeAnimeEntry — status", () => {
  it("takes the further-along status when the clocks are too close to trust", () => {
    const local = makeEntry({ anilist_id: 1, status: "watching", updated_at: T });
    const remote = makeEntry({
      anilist_id: 1,
      status: "completed",
      updated_at: T + SKEW - 1,
    });
    expect(mergeAnimeEntry(local, remote).status).toBe("completed");
    // Even with the more-advanced status on the older side.
    expect(mergeAnimeEntry(remote, local).status).toBe("completed");
  });

  it("takes the newer status once the gap clears the skew window", () => {
    const local = makeEntry({ anilist_id: 1, status: "completed", updated_at: T });
    const remote = makeEntry({
      anilist_id: 1,
      status: "dropped",
      updated_at: T + SKEW,
    });
    // A deliberate later change to a "lower" status must not be undone.
    expect(mergeAnimeEntry(local, remote).status).toBe("dropped");
  });
});

describe("mergeAnimeEntry — recency-sensitive fields", () => {
  it("keeps the local score when local is not meaningfully older", () => {
    const local = makeEntry({ anilist_id: 1, score: 9, notes: "mine", updated_at: T });
    const remote = makeEntry({
      anilist_id: 1,
      score: 4,
      notes: "theirs",
      updated_at: T + SKEW,
    });
    const merged = mergeAnimeEntry(local, remote);
    expect(merged.score).toBe(9);
    expect(merged.notes).toBe("mine");
  });

  it("takes the remote score once local is older than the whole skew window", () => {
    const local = makeEntry({ anilist_id: 1, score: 9, notes: "mine", updated_at: T });
    const remote = makeEntry({
      anilist_id: 1,
      score: 4,
      notes: "theirs",
      updated_at: T + SKEW + 1,
    });
    const merged = mergeAnimeEntry(local, remote);
    expect(merged.score).toBe(4);
    expect(merged.notes).toBe("theirs");
  });
});

describe("mergeAnimeEntry — timestamps", () => {
  it("keeps the earliest added, earliest start, latest finish, latest update", () => {
    const local = makeEntry({
      anilist_id: 1,
      added_at: 500,
      started_at: 900,
      completed_at: 2_000,
      updated_at: T,
    });
    const remote = makeEntry({
      anilist_id: 1,
      added_at: 100,
      started_at: 300,
      completed_at: 1_000,
      updated_at: T + 5_000,
    });
    const merged = mergeAnimeEntry(local, remote);
    expect(merged.added_at).toBe(100);
    expect(merged.started_at).toBe(300);
    expect(merged.completed_at).toBe(2_000);
    expect(merged.updated_at).toBe(T + 5_000);
  });

  it("fills a null date from whichever side has one", () => {
    const local = makeEntry({ anilist_id: 1, started_at: null, completed_at: 2_000 });
    const remote = makeEntry({ anilist_id: 1, started_at: 300, completed_at: null });
    const merged = mergeAnimeEntry(local, remote);
    expect(merged.started_at).toBe(300);
    expect(merged.completed_at).toBe(2_000);
  });
});

describe("mergeAnimeEntry — airing status", () => {
  it("advances but never regresses", () => {
    const cases: [string, string, string][] = [
      ["NOT_YET_RELEASED", "RELEASING", "RELEASING"],
      ["RELEASING", "FINISHED", "FINISHED"],
      ["FINISHED", "RELEASING", "FINISHED"],
      ["HIATUS", "NOT_YET_RELEASED", "HIATUS"],
    ];
    for (const [a, b, want] of cases) {
      const merged = mergeAnimeEntry(
        makeEntry({ anilist_id: 1, airing_status: a }),
        makeEntry({ anilist_id: 1, airing_status: b }),
      );
      expect(merged.airing_status, `${a} + ${b}`).toBe(want);
    }
  });

  it("takes whichever side knows one at all", () => {
    expect(
      mergeAnimeEntry(
        makeEntry({ anilist_id: 1, airing_status: null }),
        makeEntry({ anilist_id: 1, airing_status: "RELEASING" }),
      ).airing_status,
    ).toBe("RELEASING");
    expect(
      mergeAnimeEntry(
        makeEntry({ anilist_id: 1, airing_status: "RELEASING" }),
        makeEntry({ anilist_id: 1, airing_status: null }),
      ).airing_status,
    ).toBe("RELEASING");
  });
});

describe("mergeAnimeEntry — franchise and plan rank", () => {
  it("keeps a resolved franchise root over an unresolved one", () => {
    expect(
      mergeAnimeEntry(
        makeEntry({ anilist_id: 2, franchise_root_id: null }),
        makeEntry({ anilist_id: 2, franchise_root_id: 1 }),
      ).franchise_root_id,
    ).toBe(1);
  });

  it("gives the plan rank to the side that wrote most recently", () => {
    const local = makeEntry({ anilist_id: 1, plan_rank: 3, updated_at: T });
    const remote = makeEntry({ anilist_id: 1, plan_rank: 7, updated_at: T + 1 });
    expect(mergeAnimeEntry(local, remote).plan_rank).toBe(7);
    expect(mergeAnimeEntry(remote, local).plan_rank).toBe(7);
  });

  it("falls back to the other side's rank rather than dropping to unranked", () => {
    const newerUnranked = makeEntry({ anilist_id: 1, plan_rank: null, updated_at: T + 1 });
    const olderRanked = makeEntry({ anilist_id: 1, plan_rank: 4, updated_at: T });
    expect(mergeAnimeEntry(newerUnranked, olderRanked).plan_rank).toBe(4);
  });

  it("stays null when neither side ever ranked the entry", () => {
    expect(
      mergeAnimeEntry(
        makeEntry({ anilist_id: 1 }),
        makeEntry({ anilist_id: 1 }),
      ).plan_rank,
    ).toBeNull();
  });
});

describe("mergeTombstones", () => {
  it("unions both sides and keeps the latest deletion per id", () => {
    const merged = mergeTombstones(
      [
        { anilist_id: 1, deleted_at: 100 },
        { anilist_id: 2, deleted_at: 500 },
      ],
      [
        { anilist_id: 1, deleted_at: 900 },
        { anilist_id: 3, deleted_at: 50 },
      ],
    );
    expect(merged).toHaveLength(3);
    expect(merged.find((t) => t.anilist_id === 1)?.deleted_at).toBe(900);
    expect(merged.find((t) => t.anilist_id === 2)?.deleted_at).toBe(500);
  });
});

describe("mergeLists", () => {
  it("unions both sides, merging the overlap", () => {
    const { entries } = mergeLists(
      [makeEntry({ anilist_id: 1, episodes_watched: 5 }), makeEntry({ anilist_id: 2 })],
      [makeEntry({ anilist_id: 1, episodes_watched: 9 }), makeEntry({ anilist_id: 3 })],
    );
    expect(entries.map((e) => e.anilist_id).sort()).toEqual([1, 2, 3]);
    expect(entries.find((e) => e.anilist_id === 1)?.episodes_watched).toBe(9);
  });

  it("drops an entry whose deletion is newer than its last edit", () => {
    const { entries, tombstones } = mergeLists(
      [makeEntry({ anilist_id: 1, updated_at: T })],
      [],
      [],
      [{ anilist_id: 1, deleted_at: T + 1 }],
    );
    expect(entries).toHaveLength(0);
    expect(tombstones).toEqual([{ anilist_id: 1, deleted_at: T + 1 }]);
  });

  it("resurrects an entry that was re-added after the deletion", () => {
    const { entries, tombstones } = mergeLists(
      [makeEntry({ anilist_id: 1, updated_at: T + 100 })],
      [],
      [],
      [{ anilist_id: 1, deleted_at: T }],
    );
    expect(entries.map((e) => e.anilist_id)).toEqual([1]);
    // The stale tombstone must not survive, or the next pull deletes it again.
    expect(tombstones).toHaveLength(0);
  });

  it("keeps propagating a tombstone for an entry neither side still holds", () => {
    const { entries, tombstones } = mergeLists(
      [makeEntry({ anilist_id: 1 })],
      [],
      [{ anilist_id: 99, deleted_at: T }],
      [],
    );
    expect(entries.map((e) => e.anilist_id)).toEqual([1]);
    expect(tombstones).toEqual([{ anilist_id: 99, deleted_at: T }]);
  });

  it("is idempotent — merging a result against itself changes nothing", () => {
    const local = [
      makeEntry({ anilist_id: 1, episodes_watched: 5, updated_at: T }),
      makeEntry({ anilist_id: 2, status: "completed", updated_at: T }),
    ];
    const remote = [makeEntry({ anilist_id: 1, episodes_watched: 9, updated_at: T + 1 })];
    const once = mergeLists(local, remote, [], [{ anilist_id: 7, deleted_at: T }]);
    const twice = mergeLists(once.entries, once.entries, once.tombstones, once.tombstones);
    expect(twice.entries).toEqual(once.entries);
    expect(twice.tombstones).toEqual(once.tombstones);
  });

  it("survives an empty remote list without wiping local", () => {
    const { entries } = mergeLists([makeEntry({ anilist_id: 1 })], []);
    expect(entries).toHaveLength(1);
  });
});

/**
 * The completion log merges by union, not by last-write-wins: rows are facts
 * about the past, and two devices that both saw the same finish are describing
 * one event, not competing for it.
 */
describe("mergeCompletions", () => {
  const event = (
    over: { anilist_id: number } & Partial<CompletionEvent>,
  ): CompletionEvent => ({
    rewatch_index: 0,
    completed_at: T,
    episodes_at_completion: 12,
    episode_duration: 24,
    total_episodes: 12,
    title_romaji: "Title",
    title_english: null,
    title_native: null,
    cover_url: null,
    franchise_root_id: null,
    estimated: false,
    ...over,
  });

  it("keeps every event both devices hold, once each", () => {
    const merged = mergeCompletions(
      [event({ anilist_id: 1 }), event({ anilist_id: 2 })],
      [event({ anilist_id: 2 }), event({ anilist_id: 3 })],
    );
    expect(merged).toHaveLength(3);
  });

  it("treats each rewatch of a title as its own event", () => {
    const merged = mergeCompletions(
      [event({ anilist_id: 1, rewatch_index: 0 })],
      [event({ anilist_id: 1, rewatch_index: 1, completed_at: T + 5_000 })],
    );
    expect(merged).toHaveLength(2);
  });

  it("takes the earlier date when both devices recorded the same finish", () => {
    const merged = mergeCompletions(
      [event({ anilist_id: 1, completed_at: T + 9_000 })],
      [event({ anilist_id: 1, completed_at: T })],
    );
    expect(merged[0].completed_at).toBe(T);
  });

  it("lets a recorded date replace one an upgrade had to reconstruct", () => {
    const merged = mergeCompletions(
      [event({ anilist_id: 1, completed_at: T, estimated: true })],
      [event({ anilist_id: 1, completed_at: T + 9_000, estimated: false })],
    );
    expect(merged[0]).toMatchObject({ completed_at: T + 9_000, estimated: false });
  });

  it("takes a whole log from a device that has one, when this one does not", () => {
    expect(mergeCompletions([], [event({ anilist_id: 1 })])).toHaveLength(1);
    expect(mergeCompletions([event({ anilist_id: 1 })], [])).toHaveLength(1);
  });

  it("is idempotent, so a re-pull adds nothing", () => {
    const once = mergeCompletions(
      [event({ anilist_id: 1 })],
      [event({ anilist_id: 2 })],
    );
    expect(mergeCompletions(once, once)).toEqual(once);
  });
});
