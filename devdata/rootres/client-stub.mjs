// Node stand-in for @/lib/api/anilist/client, exposing only what cascade.ts
// uses: anilist.getRelationsBatch. Replicates the app's behavior points:
// aliased Media batches of <=12 (query-complexity 500 cap), the same
// RELATION_NODE field set, mapRelations flattening, binary-split recovery for
// the one-404-nulls-the-batch quirk, and never caching a missing id.
import fs from "node:fs";
import { gql, getRequestCount } from "../net.mjs";

// Runs only inside the esbuild bundle, whose import.meta.url is
// devdata/resolve-roots.mjs — so "./" is devdata/.
const cachePath = new URL("./relations-cache.json", import.meta.url);
const cache = fs.existsSync(cachePath)
  ? JSON.parse(fs.readFileSync(cachePath, "utf8"))
  : {};
const missing = new Set(); // per-run only, mirroring "never cache null"
let dirty = 0;

export { getRequestCount };

function saveCache(force = false) {
  dirty++;
  if (force || dirty >= 10) {
    fs.writeFileSync(cachePath, JSON.stringify(cache));
    dirty = 0;
  }
}
process.on("exit", () => saveCache(true));

const RELATION_NODE = `
  relationType
  node {
    id
    idMal
    type
    title { romaji english native }
    format
    status
    coverImage { extraLarge large medium color }
    startDate { year month day }
    nextAiringEpisode { airingAt episode timeUntilAiring }
    episodes
    season
    seasonYear
  }`;

function buildQuery(ids) {
  const aliases = ids
    .map(
      (id) => `  m${id}: Media(id: ${id}, type: ANIME) {
    id
    relations { edges { ${RELATION_NODE} } }
  }`,
    )
    .join("\n");
  return `query RelationsBatch {\n${aliases}\n}`;
}

// Mirror of mappers.mapRelations.
function mapEdges(raw) {
  const edges = raw?.relations?.edges ?? [];
  return edges
    .filter((e) => e?.node)
    .map((e) => ({
      relationType: e.relationType,
      id: e.node.id,
      idMal: e.node.idMal ?? null,
      type: e.node.type ?? null,
      title: e.node.title,
      format: e.node.format ?? null,
      status: e.node.status ?? null,
      coverImage: e.node.coverImage ?? null,
      startDate: e.node.startDate ?? null,
      nextAiringEpisode: e.node.nextAiringEpisode ?? null,
      episodes: e.node.episodes ?? null,
      season: e.node.season ?? null,
      seasonYear: e.node.seasonYear ?? null,
    }));
}

async function fetchChunk(ids) {
  if (ids.length === 0) return;
  const { json } = await gql(buildQuery(ids));
  const data = json?.data ?? {};
  const unresolved = [];
  for (const id of ids) {
    const media = data[`m${id}`];
    if (media) {
      cache[id] = mapEdges(media);
      saveCache();
    } else {
      unresolved.push(id);
    }
  }
  // One deleted id can null sibling aliases in the same request; split and
  // retry so the rest of the batch isn't lost. A single id that still comes
  // back empty really is missing.
  if (unresolved.length === ids.length && ids.length === 1) {
    missing.add(ids[0]);
    return;
  }
  if (unresolved.length > 0) {
    if (unresolved.length === ids.length) {
      const mid = Math.ceil(unresolved.length / 2);
      await fetchChunk(unresolved.slice(0, mid));
      await fetchChunk(unresolved.slice(mid));
    } else {
      for (const id of unresolved) await fetchChunk([id]);
    }
  }
}

export const anilist = {
  async getRelationsBatch(ids) {
    const result = {};
    const todo = [];
    for (const id of ids) {
      if (cache[id]) result[id] = cache[id];
      else if (!missing.has(id)) todo.push(id);
    }
    for (let i = 0; i < todo.length; i += 12) {
      await fetchChunk(todo.slice(i, i + 12));
    }
    for (const id of todo) {
      if (cache[id]) result[id] = cache[id];
    }
    return result;
  },
};
