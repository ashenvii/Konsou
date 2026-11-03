// devdata/rootres/entry.ts
import fs2 from "node:fs";

// devdata/rootres/client-stub.mjs
import fs from "node:fs";

// devdata/net.mjs
var MIN_GAP_MS = 2400;
var lastRequestAt = 0;
var requestCount = 0;
var sleep = (ms) => new Promise((r) => setTimeout(r, ms));
function getRequestCount() {
  return requestCount;
}
async function gql(query, variables) {
  for (let attempt = 0; ; attempt++) {
    const wait = lastRequestAt + MIN_GAP_MS - Date.now();
    if (wait > 0) await sleep(wait);
    lastRequestAt = Date.now();
    requestCount++;
    let res;
    try {
      res = await fetch("https://graphql.anilist.co", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(variables ? { query, variables } : { query })
      });
    } catch (e) {
      if (attempt >= 4) throw e;
      await sleep([5e3, 15e3, 45e3, 9e4][attempt]);
      continue;
    }
    if (res.status === 429) {
      const retryAfter = parseInt(res.headers.get("Retry-After") ?? "60", 10);
      await sleep((retryAfter + 2) * 1e3);
      continue;
    }
    let json = null;
    try {
      json = await res.json();
    } catch {
      json = null;
    }
    if (!json?.data && res.status >= 500) {
      if (attempt >= 4) throw new Error(`AniList ${res.status} after retries`);
      await sleep([5e3, 15e3, 45e3, 9e4][attempt]);
      continue;
    }
    const remaining = parseInt(res.headers.get("X-RateLimit-Remaining") ?? "99", 10);
    if (remaining <= 2) await sleep(45e3);
    return { status: res.status, json };
  }
}

// devdata/rootres/client-stub.mjs
var cachePath = new URL("./relations-cache.json", import.meta.url);
var cache = fs.existsSync(cachePath) ? JSON.parse(fs.readFileSync(cachePath, "utf8")) : {};
var missing = /* @__PURE__ */ new Set();
var dirty = 0;
function saveCache(force = false) {
  dirty++;
  if (force || dirty >= 10) {
    fs.writeFileSync(cachePath, JSON.stringify(cache));
    dirty = 0;
  }
}
process.on("exit", () => saveCache(true));
var RELATION_NODE = `
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
  const aliases = ids.map(
    (id) => `  m${id}: Media(id: ${id}, type: ANIME) {
    id
    relations { edges { ${RELATION_NODE} } }
  }`
  ).join("\n");
  return `query RelationsBatch {
${aliases}
}`;
}
function mapEdges(raw) {
  const edges = raw?.relations?.edges ?? [];
  return edges.filter((e) => e?.node).map((e) => ({
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
    seasonYear: e.node.seasonYear ?? null
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
var anilist = {
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
  }
};

// src/lib/format.ts
function normalizeForSearch(s) {
  return s.normalize("NFKD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/\s+/g, " ").trim();
}
var MANGA_FORMATS = /* @__PURE__ */ new Set(["MANGA", "NOVEL", "ONE_SHOT"]);
function isMangaNode(node) {
  if (!node) return false;
  if (node.type === "MANGA") return true;
  return node.format != null && MANGA_FORMATS.has(node.format);
}

// src/lib/search/fuzzy.ts
function bigrams(s) {
  const m = /* @__PURE__ */ new Map();
  for (let i = 0; i < s.length - 1; i++) {
    const bg = s.slice(i, i + 2);
    m.set(bg, (m.get(bg) ?? 0) + 1);
  }
  return m;
}
function diceSimilarity(a, b) {
  if (a === b) return a.length ? 1 : 0;
  if (a.length < 2 || b.length < 2) return 0;
  const aB = bigrams(a);
  const bB = bigrams(b);
  let intersection = 0;
  for (const [bg, count] of aB) {
    const other = bB.get(bg);
    if (other) intersection += Math.min(count, other);
  }
  const total = a.length - 1 + (b.length - 1);
  return 2 * intersection / total;
}

// src/lib/franchise/relatedness.ts
var FRANCHISE_SIMILARITY = 0.6;
var MIN_PREFIX = 8;
function variants(t) {
  const out = [];
  for (const v of [t.romaji, t.english, t.native]) {
    if (typeof v === "string" && v.trim()) out.push(normalizeForSearch(v));
  }
  return out;
}
function titlesShareFranchise(a, b) {
  const va = variants(a);
  const vb = variants(b);
  for (const x of va) {
    for (const y of vb) {
      const shorter = x.length <= y.length ? x : y;
      const longer = x.length <= y.length ? y : x;
      if (shorter.length >= MIN_PREFIX && longer.startsWith(shorter)) return true;
      if (diceSimilarity(x, y) >= FRANCHISE_SIMILARITY) return true;
    }
  }
  return false;
}
function isFranchiseOther(fromTitle, rel) {
  if (rel.relationType !== "OTHER") return false;
  if (isMangaNode(rel) || rel.format === "MUSIC") return false;
  if (!fromTitle) return false;
  return titlesShareFranchise(fromTitle, rel.title);
}
function isFranchiseParent(fromTitle, rel) {
  if (rel.relationType !== "PARENT") return false;
  if (isMangaNode(rel) || rel.format === "MUSIC") return false;
  if (!fromTitle) return false;
  return titlesShareFranchise(fromTitle, rel.title);
}

// src/lib/franchise/cascade.ts
var MAX_CHAIN_NODES = 30;
var MAIN_CHAIN = /* @__PURE__ */ new Set(["PREQUEL", "SEQUEL"]);
var SIDE_ENTRY = /* @__PURE__ */ new Set([
  "SIDE_STORY",
  "SPIN_OFF",
  "PARENT",
  "SUMMARY"
]);
async function bfsMainChain(startId, priority, seedTitle) {
  const visited = /* @__PURE__ */ new Map();
  const nodeOf = /* @__PURE__ */ new Map();
  const titleOf = /* @__PURE__ */ new Map();
  if (seedTitle) titleOf.set(startId, seedTitle);
  visited.set(startId, []);
  const queue = [startId];
  while (queue.length > 0 && visited.size < MAX_CHAIN_NODES) {
    const batch = queue.splice(0, 12);
    const relMap = await anilist.getRelationsBatch(batch, priority);
    for (const id of batch) {
      const rels = relMap[id] ?? [];
      visited.set(id, rels);
      for (const rel of rels) {
        if (isMangaNode(rel)) continue;
        if (!nodeOf.has(rel.id)) nodeOf.set(rel.id, rel);
        if (!titleOf.has(rel.id)) titleOf.set(rel.id, rel.title);
        const follow = MAIN_CHAIN.has(rel.relationType) || // Climb from a special/OVA back to its parent series — without this
        // a walk STARTING at a side entry can't reach the backbone and
        // strands as its own one-member root (the Jobless split).
        isFranchiseParent(titleOf.get(id), rel) || isFranchiseOther(titleOf.get(id), rel);
        if (follow && !visited.has(rel.id)) {
          visited.set(rel.id, []);
          queue.push(rel.id);
        }
      }
    }
  }
  return { chainMap: visited, nodeOf };
}
function findRootId(startId, { chainMap, nodeOf }) {
  let heads = [...chainMap.keys()].filter((id) => {
    const rels = chainMap.get(id) ?? [];
    return !rels.some(
      (r) => r.relationType === "PREQUEL" && !isMangaNode(r) && chainMap.has(r.id)
    );
  });
  if (heads.length === 0) return startId;
  const backbone = heads.filter(
    (id) => (chainMap.get(id) ?? []).some(
      (r) => r.relationType === "SEQUEL" && !isMangaNode(r) && chainMap.has(r.id)
    )
  );
  if (backbone.length > 0) heads = backbone;
  if (heads.length === 1) return heads[0];
  const key = (id) => {
    const n = nodeOf.get(id);
    if (!n) return Number.MAX_SAFE_INTEGER;
    const d = n.startDate;
    if (d?.year) return Date.UTC(d.year, (d.month ?? 1) - 1, d.day ?? 1);
    if (n.seasonYear) return Date.UTC(n.seasonYear, 0, 1);
    return Number.MAX_SAFE_INTEGER;
  };
  heads.sort((a, b) => key(a) - key(b) || a - b);
  return heads[0];
}
function buildPrequelChain(startId, chainMap) {
  const chain = [];
  const seen = /* @__PURE__ */ new Set([startId]);
  let current = startId;
  for (let i = 0; i < MAX_CHAIN_NODES; i++) {
    const rels = chainMap.get(current) ?? [];
    const prequel = rels.find(
      (r) => r.relationType === "PREQUEL" && chainMap.has(r.id)
    );
    if (!prequel || seen.has(prequel.id)) break;
    seen.add(prequel.id);
    chain.push(prequel);
    current = prequel.id;
  }
  return chain.reverse();
}
function buildFranchiseIds(chainMap) {
  const ids = new Set(chainMap.keys());
  for (const rels of chainMap.values()) {
    for (const rel of rels) {
      if (SIDE_ENTRY.has(rel.relationType) && !isMangaNode(rel)) {
        ids.add(rel.id);
      }
    }
  }
  return ids;
}
function startMs(r) {
  const d = r.startDate;
  if (d?.year) return Date.UTC(d.year, (d.month ?? 1) - 1, d.day ?? 1);
  if (r.seasonYear) return Date.UTC(r.seasonYear, 0, 1);
  return Number.MAX_SAFE_INTEGER;
}
function priorSideEntries(startId, chain, { chainMap, nodeOf }) {
  if (chain.length === 0) return [];
  const chainIds = new Set(chain.map((r) => r.id));
  const startNode = nodeOf.get(startId);
  const addedMs = startNode ? startMs(startNode) : Number.MAX_SAFE_INTEGER;
  const out = /* @__PURE__ */ new Map();
  for (const id of chainIds) {
    for (const rel of chainMap.get(id) ?? []) {
      if (!SIDE_ENTRY.has(rel.relationType)) continue;
      if (isMangaNode(rel)) continue;
      if (chainMap.has(rel.id) || chainIds.has(rel.id) || rel.id === startId) continue;
      if (rel.status !== "FINISHED") continue;
      if (startMs(rel) >= addedMs) continue;
      if (!out.has(rel.id)) out.set(rel.id, rel);
    }
  }
  return [...out.values()].sort((a, b) => startMs(a) - startMs(b));
}
async function resolveFranchiseChain(startId, inList2, priority = "high", seedTitle) {
  const walk = await bfsMainChain(startId, priority, seedTitle);
  const { chainMap } = walk;
  const rootId = findRootId(startId, walk);
  const chain = buildPrequelChain(startId, chainMap);
  const allIds = buildFranchiseIds(chainMap);
  const sides = priorSideEntries(startId, chain, walk);
  return {
    rootId,
    chain,
    toAdd: [...chain, ...sides].filter((r) => !inList2.has(r.id)),
    toUpdate: [...allIds].filter((id) => id !== startId && inList2.has(id))
  };
}

// devdata/rootres/entry.ts
var dir = new URL("./", import.meta.url);
var pool = JSON.parse(
  fs2.readFileSync(new URL("media-pool-real.json", dir), "utf8")
);
var rootsPath = new URL("roots.json", dir);
var roots = fs2.existsSync(rootsPath) ? JSON.parse(fs2.readFileSync(rootsPath, "utf8")) : {};
var inList = new Set(pool.map((m) => m.id));
var processed = 0;
var sinceSave = 0;
for (const media of pool) {
  processed++;
  if (roots[media.id] != null) continue;
  try {
    const { rootId, toUpdate } = await resolveFranchiseChain(
      media.id,
      inList,
      "low",
      media.title
    );
    roots[media.id] = rootId;
    for (const id of toUpdate) {
      if (roots[id] == null) roots[id] = rootId;
    }
  } catch (e) {
    console.warn(`walk failed for ${media.id} (${media.title?.romaji}): ${e}`);
  }
  if (++sinceSave >= 25) {
    fs2.writeFileSync(rootsPath, JSON.stringify(roots));
    sinceSave = 0;
    console.log(
      `progress ${processed}/${pool.length} pooled, ${Object.keys(roots).length} rooted, ${getRequestCount()} api requests`
    );
  }
}
fs2.writeFileSync(rootsPath, JSON.stringify(roots));
var groups = /* @__PURE__ */ new Map();
for (const id of inList) {
  const r = roots[id] ?? id;
  groups.set(r, (groups.get(r) ?? 0) + 1);
}
var multi = [...groups.values()].filter((n) => n > 1);
console.log(
  `DONE roots: ${Object.keys(roots).length}/${pool.length} resolved, ${multi.length} multi-member franchises covering ${multi.reduce((a, b) => a + b, 0)} entries, ${getRequestCount()} api requests this run`
);
