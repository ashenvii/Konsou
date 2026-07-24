import { describe, it, expect } from "vitest";
import { parseMalExport } from "./parseExport";

/**
 * The MAL export is how someone's whole history arrives. A parser slip here
 * doesn't crash, it just quietly drops rows from an import someone waited on.
 */

function malXml(...animeBlocks: string[]): string {
  return `<?xml version="1.0" encoding="UTF-8" ?>
<myanimelist>
  <myinfo><user_name>tester</user_name></myinfo>
  ${animeBlocks.join("\n")}
</myanimelist>`;
}

function anime(fields: Record<string, string | number>): string {
  const body = Object.entries(fields)
    .map(([k, v]) => `<${k}>${v}</${k}>`)
    .join("");
  return `<anime>${body}</anime>`;
}

const FULL = anime({
  series_animedb_id: 1535,
  series_title: "Death Note",
  series_episodes: 37,
  my_watched_episodes: 37,
  my_start_date: "2023-04-02",
  my_finish_date: "2023-05-11",
  my_score: 9,
  my_status: "Completed",
  my_times_watched: 2,
  my_rewatching: 0,
});

describe("parseMalExport — rejecting bad input", () => {
  it("rejects a file that is not a MAL export", () => {
    expect(() => parseMalExport("<html><body>nope</body></html>")).toThrow(
      /MyAnimeList export/,
    );
  });

  it("rejects malformed XML", () => {
    expect(() => parseMalExport("<myanimelist><anime></myanimelist>")).toThrow();
  });

  it("accepts a valid export with no entries", () => {
    expect(parseMalExport(malXml())).toEqual([]);
  });
});

describe("parseMalExport — reading an entry", () => {
  it("reads every field off a complete entry", () => {
    const [entry] = parseMalExport(malXml(FULL));
    expect(entry).toMatchObject({
      mal_id: 1535,
      title: "Death Note",
      status: "completed",
      score: 9,
      episodes_watched: 37,
      total_episodes: 37,
      times_watched: 2,
    });
    expect(entry.started_at).toBe(Date.parse("2023-04-02"));
    expect(entry.finished_at).toBe(Date.parse("2023-05-11"));
  });

  it("maps MAL's status names onto Konsou's", () => {
    const cases: [string, string][] = [
      ["Watching", "watching"],
      ["Completed", "completed"],
      ["On-Hold", "on_hold"],
      ["On Hold", "on_hold"],
      ["Dropped", "dropped"],
      ["Plan to Watch", "plan_to_watch"],
      ["plantowatch", "plan_to_watch"],
    ];
    for (const [malStatus, want] of cases) {
      const [entry] = parseMalExport(
        malXml(anime({ series_animedb_id: 1, my_status: malStatus })),
      );
      expect(entry?.status, malStatus).toBe(want);
    }
  });

  it("treats a completed entry that is being rewatched as rewatching", () => {
    const [entry] = parseMalExport(
      malXml(
        anime({ series_animedb_id: 1, my_status: "Completed", my_rewatching: 1 }),
      ),
    );
    expect(entry.status).toBe("rewatching");
  });

  it("reads MAL's zero-as-empty conventions as unknown, not as zero", () => {
    const [entry] = parseMalExport(
      malXml(
        anime({
          series_animedb_id: 1,
          my_status: "Watching",
          my_score: 0,
          series_episodes: 0,
          my_start_date: "0000-00-00",
          my_finish_date: "0000-00-00",
        }),
      ),
    );
    expect(entry.score).toBeNull();
    expect(entry.total_episodes).toBeNull();
    expect(entry.started_at).toBeNull();
    expect(entry.finished_at).toBeNull();
  });

  it("defaults missing counters to zero rather than NaN", () => {
    const [entry] = parseMalExport(
      malXml(anime({ series_animedb_id: 1, my_status: "Watching" })),
    );
    expect(entry.episodes_watched).toBe(0);
    expect(entry.times_watched).toBe(0);
  });

  it("falls back to a placeholder title rather than an empty one", () => {
    const [entry] = parseMalExport(
      malXml(anime({ series_animedb_id: 777, my_status: "Watching" })),
    );
    expect(entry.title).toBe("MAL #777");
  });
});

describe("parseMalExport — skipping what it cannot use", () => {
  it("skips entries with no series id", () => {
    const rows = parseMalExport(
      malXml(anime({ series_animedb_id: 0, my_status: "Watching" }), FULL),
    );
    expect(rows.map((r) => r.mal_id)).toEqual([1535]);
  });

  it("skips entries whose status it does not recognise", () => {
    const rows = parseMalExport(
      malXml(anime({ series_animedb_id: 2, my_status: "Some New Bucket" }), FULL),
    );
    expect(rows.map((r) => r.mal_id)).toEqual([1535]);
  });

  it("keeps reading after a bad row", () => {
    const rows = parseMalExport(
      malXml(anime({ series_animedb_id: 0, my_status: "" }), FULL, FULL),
    );
    expect(rows).toHaveLength(2);
  });
});
