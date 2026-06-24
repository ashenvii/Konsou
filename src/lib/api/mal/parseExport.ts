/**
 * Parser for MyAnimeList export files (myanimelist.net → Settings → Export).
 * MAL serves a gzipped XML (`animelist_….xml.gz`); we accept the raw `.xml` too.
 *
 * MAL has no working public API for fetching a full list anymore, so the export
 * file is the supported import path. Entries are keyed by MAL id here; the
 * AniList resolver (client.resolveMalEntries) maps them onto AniList ids.
 */
import type { ListStatus } from "@/types/list";

export interface MalRawEntry {
  mal_id: number;
  title: string;
  status: ListStatus;
  score: number | null;
  episodes_watched: number;
  total_episodes: number | null;
  started_at: number | null;
  finished_at: number | null;
}

// MAL's `my_status` strings → Konsou tags. Lowercased before lookup.
const STATUS_MAP: Record<string, ListStatus> = {
  watching: "watching",
  completed: "completed",
  "on-hold": "on_hold",
  "on hold": "on_hold",
  dropped: "dropped",
  "plan to watch": "plan_to_watch",
  plantowatch: "plan_to_watch",
};

function malDate(s: string): number | null {
  // MAL uses "0000-00-00" for "no date".
  if (!s || s.startsWith("0000")) return null;
  const t = Date.parse(s);
  return Number.isNaN(t) ? null : t;
}

/**
 * Read a MAL export file to text, transparently un-gzipping if needed.
 * Detects gzip by magic bytes (0x1f 0x8b) rather than the file extension.
 */
export async function readMalFile(file: File): Promise<string> {
  const buf = new Uint8Array(await file.arrayBuffer());
  const isGzip = buf[0] === 0x1f && buf[1] === 0x8b;
  if (!isGzip) return new TextDecoder().decode(buf);

  if (typeof DecompressionStream === "undefined") {
    throw new Error(
      "This export is compressed (.gz) and can't be unzipped here. " +
        "Please decompress it to a .xml file and try again.",
    );
  }
  const stream = new Blob([buf])
    .stream()
    .pipeThrough(new DecompressionStream("gzip"));
  return new Response(stream).text();
}

/** Parse MAL export XML into raw entries. Throws on a non-MAL/invalid file. */
export function parseMalExport(xml: string): MalRawEntry[] {
  const doc = new DOMParser().parseFromString(xml, "text/xml");
  if (doc.querySelector("parsererror") || !doc.querySelector("myanimelist")) {
    throw new Error("That doesn't look like a MyAnimeList export file.");
  }

  const out: MalRawEntry[] = [];
  for (const node of Array.from(doc.getElementsByTagName("anime"))) {
    const get = (tag: string): string =>
      node.getElementsByTagName(tag)[0]?.textContent?.trim() ?? "";

    const mal_id = parseInt(get("series_animedb_id"), 10);
    if (!mal_id) continue;

    let status = STATUS_MAP[get("my_status").toLowerCase()];
    if (!status) continue; // unknown/blank status — skip
    if (status === "completed" && get("my_rewatching") === "1") {
      status = "rewatching";
    }

    const score = parseInt(get("my_score"), 10);
    const totalEp = parseInt(get("series_episodes"), 10);

    out.push({
      mal_id,
      title: get("series_title") || `MAL #${mal_id}`,
      status,
      score: score > 0 ? score : null,
      episodes_watched: parseInt(get("my_watched_episodes"), 10) || 0,
      total_episodes: totalEp > 0 ? totalEp : null,
      started_at: malDate(get("my_start_date")),
      finished_at: malDate(get("my_finish_date")),
    });
  }
  return out;
}
