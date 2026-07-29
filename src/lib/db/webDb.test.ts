import { describe, it, expect, beforeEach } from "vitest";
import { WebKonsouDb } from "./webDb";
import { makeEntry } from "@/test/factories";

/**
 * The browser shim is what every dev session and every manual check runs
 * against, so when its behaviour drifts from the SQLite backend, testing on the
 * dev build starts lying about what the app does on a device. These tests pin
 * the shim to the contract both backends are supposed to honour.
 */

let db: WebKonsouDb;

beforeEach(async () => {
  localStorage.clear();
  db = new WebKonsouDb();
  await db.init();
});

describe("the list", () => {
  it("round-trips an entry with every field intact", async () => {
    const entry = makeEntry({
      anilist_id: 1535,
      status: "completed",
      score: 9,
      notes: "still good",
      plan_rank: 2,
      rewatch_count: 3,
      airing_status: "FINISHED",
    });
    await db.listUpsert(entry);
    expect(await db.listGet(1535)).toMatchObject(entry);
  });

  it("returns null for an entry that was never added", async () => {
    expect(await db.listGet(999)).toBeNull();
  });

  it("updates in place instead of adding a second row", async () => {
    await db.listUpsert(makeEntry({ anilist_id: 1, episodes_watched: 1 }));
    await db.listUpsert(makeEntry({ anilist_id: 1, episodes_watched: 5 }));
    const all = await db.listAll();
    expect(all).toHaveLength(1);
    expect(all[0].episodes_watched).toBe(5);
  });

  it("applies a patch without disturbing the fields it does not mention", async () => {
    await db.listUpsert(
      makeEntry({ anilist_id: 1, score: 8, notes: "keep me", episodes_watched: 3 }),
    );
    await db.listUpdate(1, { episodes_watched: 4, updated_at: 9_999 });
    const entry = await db.listGet(1);
    expect(entry).toMatchObject({ episodes_watched: 4, score: 8, notes: "keep me" });
    expect(entry?.updated_at).toBe(9_999);
  });

  it("ignores a patch for an entry that is not there", async () => {
    await db.listUpdate(404, { episodes_watched: 1, updated_at: 1 });
    expect(await db.listAll()).toHaveLength(0);
  });

  it("accepts every status the app can write", async () => {
    // The status vocabulary grew after v1; the SQLite side needed a migration to
    // catch up. The shim must not be the only place a new status works.
    const statuses = [
      "watching",
      "completed",
      "plan_to_watch",
      "on_hold",
      "dropped",
      "rewatching",
      "not_interested",
    ] as const;
    for (const [i, status] of statuses.entries()) {
      await db.listUpsert(makeEntry({ anilist_id: i + 1, status }));
    }
    expect(await db.listAll()).toHaveLength(statuses.length);
  });

  it("survives a restart — a new instance reads what the last one wrote", async () => {
    await db.listUpsert(makeEntry({ anilist_id: 1, episodes_watched: 7 }));
    const reopened = new WebKonsouDb();
    await reopened.init();
    expect((await reopened.listGet(1))?.episodes_watched).toBe(7);
  });

  it("wipes and re-seeds on a replace-all, as a restore does", async () => {
    await db.listUpsert(makeEntry({ anilist_id: 1 }));
    await db.listReplaceAll([makeEntry({ anilist_id: 2 }), makeEntry({ anilist_id: 3 })]);
    expect((await db.listAll()).map((e) => e.anilist_id).sort()).toEqual([2, 3]);
  });

  it("starts empty rather than throwing when storage holds garbage", async () => {
    localStorage.setItem("konsou.web.list", "{ not json");
    const recovered = new WebKonsouDb();
    await recovered.init();
    expect(await recovered.listAll()).toEqual([]);
  });
});

describe("deletion tombstones", () => {
  it("keeps the later deletion time when the same id is deleted twice", async () => {
    await db.tombstoneUpsert({ anilist_id: 1, deleted_at: 500 });
    await db.tombstoneUpsert({ anilist_id: 1, deleted_at: 100 });
    expect(await db.tombstonesAll()).toEqual([{ anilist_id: 1, deleted_at: 500 }]);
  });

  it("clears a tombstone when the entry comes back", async () => {
    await db.tombstoneUpsert({ anilist_id: 1, deleted_at: 500 });
    await db.tombstoneRemove(1);
    expect(await db.tombstonesAll()).toEqual([]);
  });
});

describe("alerts", () => {
  const alert = (relatedId: number, type = "sequel") => ({
    source_id: 1,
    related_id: relatedId,
    type,
    related_title: `Related ${relatedId}`,
    related_cover: null,
    related_status: "RELEASING",
    airing_at: null,
    seen: 0,
    dismissed: 0,
    created_at: 100,
  });

  it("raises one alert per suggested title", async () => {
    expect(await db.notificationInsertIfNew(alert(2) as never)).toBe(true);
    expect(await db.notificationInsertIfNew(alert(2) as never)).toBe(false);
    expect(await db.notificationsActive()).toHaveLength(1);
  });

  it("keeps started-airing in its own lane so it is not swallowed by a sequel alert", async () => {
    await db.notificationInsertIfNew(alert(2) as never);
    expect(
      await db.notificationInsertIfNew(alert(2, "started_airing") as never),
    ).toBe(true);
    expect(await db.notificationsActive()).toHaveLength(2);
  });

  it("keeps suppressing a title after its alert was dismissed", async () => {
    await db.notificationInsertIfNew(alert(2) as never);
    await db.notificationDismissByRelated([2]);
    expect(await db.notificationInsertIfNew(alert(2) as never)).toBe(false);
    expect(await db.notificationsActive()).toHaveLength(0);
  });

  it("counts only what is unseen and undismissed", async () => {
    await db.notificationInsertIfNew(alert(2) as never);
    await db.notificationInsertIfNew(alert(3) as never);
    expect(await db.unreadCount()).toBe(2);
    await db.notificationMarkAllSeen();
    expect(await db.unreadCount()).toBe(0);
  });

  it("purges both sides of an alert when its anime leaves the list", async () => {
    await db.notificationInsertIfNew(alert(2) as never);
    await db.notificationsPurgeForEntry(2);
    expect(await db.notificationsActive()).toHaveLength(0);
    // Purged, not dismissed — the alert can legitimately return on a re-add.
    expect(await db.notificationInsertIfNew(alert(2) as never)).toBe(true);
  });

  it("shows newest first", async () => {
    await db.notificationInsertIfNew({ ...alert(2), created_at: 100 } as never);
    await db.notificationInsertIfNew({ ...alert(3), created_at: 900 } as never);
    expect((await db.notificationsActive()).map((n) => n.related_id)).toEqual([3, 2]);
  });
});

describe("the scan schedule", () => {
  const row = (id: number, next: number) => ({
    anilist_id: id,
    last_check_at: 0,
    next_check_at: next,
    quiet_streak: 0,
  });

  it("keys by anime so a re-check replaces rather than duplicates", async () => {
    await db.scheduleSet(row(1, 100));
    await db.scheduleSet(row(1, 900));
    const all = await db.scheduleGetAll();
    expect(Object.keys(all)).toHaveLength(1);
    expect(all[1].next_check_at).toBe(900);
  });

  it("drops a single seed and clears the lot", async () => {
    await db.scheduleSet(row(1, 100));
    await db.scheduleSet(row(2, 200));
    await db.scheduleRemove(1);
    expect(Object.keys(await db.scheduleGetAll())).toEqual(["2"]);
    await db.scheduleClear();
    expect(await db.scheduleGetAll()).toEqual({});
  });
});

describe("settings", () => {
  it("stores and overwrites by key", async () => {
    await db.settingsSet("theme", "ember");
    await db.settingsSet("theme", "ocean");
    await db.settingsSet("accent", "coral");
    expect(await db.settingsGetAll()).toEqual({ theme: "ocean", accent: "coral" });
  });
});

/**
 * The real database reconstructs the completion log the moment migration 12
 * runs. This shim has no migrations, so a list dropped straight into
 * localStorage (how every dev check seeds data) has to be reconstructed the
 * same way, or the Completed room reads as empty on the dev build while the
 * device shows a full ledger.
 */
describe("the completion log", () => {
  it("reconstructs history from a list that arrived without one", async () => {
    await db.listReplaceAll([
      makeEntry({ anilist_id: 1, status: "completed", completed_at: 900 }),
      makeEntry({ anilist_id: 2, status: "completed", completed_at: 800, rewatch_count: 2 }),
      makeEntry({ anilist_id: 3, status: "watching" }),
    ]);
    const events = await db.completionsAll();
    expect(events).toHaveLength(4);
    expect(events.filter((e) => e.anilist_id === 2)).toHaveLength(3);
    expect(events.every((e) => e.estimated)).toBe(true);
    // Newest first, like the SQLite query's ORDER BY.
    expect(events[0].completed_at).toBe(900);
  });

  it("records a new event and refuses the same one twice", async () => {
    await db.listReplaceAll([]);
    const event = {
      anilist_id: 7,
      rewatch_index: 0,
      completed_at: 1_000,
      episodes_at_completion: 12,
      episode_duration: 24,
      total_episodes: 12,
      title_romaji: "Logged",
      title_english: null,
      title_native: null,
      cover_url: null,
      franchise_root_id: null,
      estimated: false,
    };
    await db.completionAppend(event);
    await db.completionAppend({ ...event, completed_at: 5_000 });
    const events = await db.completionsAll();
    expect(events).toHaveLength(1);
    expect(events[0].completed_at).toBe(1_000);
  });

  it("keeps a completion after its entry is deleted", async () => {
    await db.listReplaceAll([
      makeEntry({ anilist_id: 1, status: "completed", completed_at: 900 }),
    ]);
    await db.completionsAll(); // the reconstruction runs once, here
    await db.listRemove(1);
    expect(await db.completionsAll()).toHaveLength(1);
  });
});
