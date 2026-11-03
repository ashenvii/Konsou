// Stage 1: pull the top ~6500 anime by popularity into media-pool-real.json.
// AniList refuses offset pagination past 5000 entries (page depth cap), so
// after each 100-page segment we continue with popularity_lesser as a cursor.
// Resumable: pool + cursor persist in media-pool-partial.json; the legacy
// media-pages.json (first segment) is folded in if present.
import fs from "node:fs";
import { gql, getRequestCount } from "./net.mjs";

const TARGET = parseInt(process.argv[2] ?? "6500", 10);
const PER_PAGE = 50;
const MAX_PAGE = 100; // 100 * 50 = the 5000-entry depth cap
const dir = new URL(".", import.meta.url);
const partialPath = new URL("media-pool-partial.json", dir);
const legacyPagesPath = new URL("media-pages.json", dir);
const poolPath = new URL("media-pool-real.json", dir);

const QUERY = `
query ($page: Int!, $perPage: Int!, $popLess: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { hasNextPage }
    media(type: ANIME, sort: POPULARITY_DESC, isAdult: false, popularity_lesser: $popLess) {
      id
      idMal
      title { romaji english native }
      coverImage { large medium }
      episodes
      duration
      status
      format
      averageScore
      popularity
      season
      seasonYear
      startDate { year month day }
      nextAiringEpisode { episode }
    }
  }
}`;

let state = { pool: [], cursor: null, page: 1 };
if (fs.existsSync(partialPath)) {
  state = JSON.parse(fs.readFileSync(partialPath, "utf8"));
} else if (fs.existsSync(legacyPagesPath)) {
  // Fold in the segment fetched before the depth cap was hit.
  const pages = JSON.parse(fs.readFileSync(legacyPagesPath, "utf8"));
  const seen = new Set();
  for (const key of Object.keys(pages).sort((a, b) => Number(a) - Number(b))) {
    for (const m of pages[key] ?? []) {
      if (m?.id && !seen.has(m.id)) {
        seen.add(m.id);
        state.pool.push(m);
      }
    }
  }
  state.cursor = Math.min(...state.pool.map((m) => m.popularity ?? Infinity)) + 1;
  state.page = 1;
  console.log(`folded legacy pages: ${state.pool.length} media, cursor ${state.cursor}`);
}

const ids = new Set(state.pool.map((m) => m.id));

while (state.pool.length < TARGET) {
  const before = state.pool.length;
  const { json } = await gql(QUERY, {
    page: state.page,
    perPage: PER_PAGE,
    popLess: state.cursor,
  });
  const data = json?.data?.Page;
  if (!data) throw new Error(`page ${state.page} (cursor ${state.cursor}): ${JSON.stringify(json?.errors?.[0] ?? null)}`);

  for (const m of data.media) {
    if (m?.id && !ids.has(m.id)) {
      ids.add(m.id);
      state.pool.push(m);
    }
  }

  const segmentDone = !data.pageInfo.hasNextPage || state.page >= MAX_PAGE;
  if (segmentDone) {
    const minPop = Math.min(...state.pool.map((m) => m.popularity ?? Infinity));
    const nextCursor = minPop + 1; // +1 keeps boundary ties; dedupe drops repeats
    if (!data.pageInfo.hasNextPage && state.pool.length === before) {
      console.log("no more media available; stopping early");
      break;
    }
    if (state.cursor === nextCursor && state.pool.length === before) {
      throw new Error(`stuck at cursor ${state.cursor} with no progress`);
    }
    state.cursor = nextCursor;
    state.page = 1;
  } else {
    state.page++;
  }

  fs.writeFileSync(partialPath, JSON.stringify(state));
  console.log(`pool ${state.pool.length}/${TARGET} (cursor ${state.cursor ?? "top"}, page ${state.page}, ${getRequestCount()} requests)`);
}

fs.writeFileSync(poolPath, JSON.stringify(state.pool.slice(0, TARGET)));
console.log(`DONE media pool: ${Math.min(state.pool.length, TARGET)} unique anime -> devdata/media-pool-real.json`);
