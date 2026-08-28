// Stage 3: combine media-pool-real.json + roots.json into a Konsou restore
// file with realistic list state layered on real AniList data. Statuses obey
// the app's statusValidation guards against each show's REAL airing status.
// Usage: node generate-real-list.mjs [count]
import fs from "node:fs";

const dir = new URL(".", import.meta.url);
const TARGET = parseInt(process.argv[2] ?? "6500", 10);
const OUT = new URL("konsou-real-list.json", dir);

const pool = JSON.parse(fs.readFileSync(new URL("media-pool-real.json", dir), "utf8"));
const roots = JSON.parse(fs.readFileSync(new URL("roots.json", dir), "utf8"));

let seed = 0x2b3c4d5e;
function rand() {
  seed |= 0;
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}
const ri = (lo, hi) => lo + Math.floor(rand() * (hi - lo + 1));
const pick = (arr) => arr[Math.floor(rand() * arr.length)];
const chance = (p) => rand() < p;
function weighted(pairs) {
  const total = pairs.reduce((s, [, w]) => s + w, 0);
  let r = rand() * total;
  for (const [v, w] of pairs) {
    r -= w;
    if (r <= 0) return v;
  }
  return pairs[pairs.length - 1][0];
}

const NOTES = [
  "rewatch with N. sometime",
  "dub is better, fight me",
  "stalled at the beach episode",
  "manga readers say it gets good later",
  "OP of the year, easily",
  "dropped once already, second chance",
  "watch before the movie comes out",
  "S2 supposedly covers the good arc",
  'the "bread scene" alone is worth it',
  "friend spoiled the ending :(\nstill worth finishing?",
  "彼の言う通りだった。続きが気になる",
  "banger soundtrack 🔥 but pacing drags mid-season",
];

const DAY = 24 * 3600 * 1000;
const NOW = Date.now();
const FLOOR_2019 = Date.UTC(2019, 0, 1);

function startMs(m) {
  const d = m.startDate;
  if (d?.year) return Date.UTC(d.year, (d.month ?? 1) - 1, d.day ?? 1);
  if (m.seasonYear) return Date.UTC(m.seasonYear, 0, 1);
  return Date.UTC(2010, 0, 1);
}

// Popularity-rank tiers: the deep tail of anyone's list is planning and
// muting, the top is where the watching/completed mass lives.
function statusFor(rank, airing) {
  if (airing === "NOT_YET_RELEASED") {
    return weighted([["plan_to_watch", 80], ["not_interested", 15], ["dropped", 5]]);
  }
  const tier =
    rank < 2000
      ? [["completed", 46], ["plan_to_watch", 15], ["watching", 9], ["on_hold", 6], ["dropped", 10], ["rewatching", 4], ["not_interested", 10]]
      : rank < 4500
        ? [["completed", 40], ["plan_to_watch", 24], ["watching", 6], ["on_hold", 5], ["dropped", 9], ["rewatching", 2], ["not_interested", 14]]
        : [["completed", 25], ["plan_to_watch", 35], ["watching", 4], ["on_hold", 4], ["dropped", 8], ["rewatching", 1], ["not_interested", 23]];
  let status = weighted(tier);
  // Guard parity with statusValidation.ts: RELEASING can't be completed.
  if (airing === "RELEASING" && (status === "completed" || status === "rewatching")) {
    status = chance(0.6) ? "watching" : "plan_to_watch";
  }
  return status;
}

const entries = [];
for (let rank = 0; rank < Math.min(TARGET, pool.length); rank++) {
  const m = pool[rank];
  const airing = m.status ?? null;
  const status = statusFor(rank, airing);

  const total = m.episodes ?? null;
  const aired =
    airing === "FINISHED" || airing === "CANCELLED"
      ? total
      : airing === "RELEASING"
        ? (m.nextAiringEpisode?.episode != null ? m.nextAiringEpisode.episode - 1 : null)
        : null;

  const cap = aired ?? total ?? 24;
  let watched = 0;
  switch (status) {
    case "completed": watched = total ?? aired ?? ri(11, 26); break;
    case "rewatching": watched = ri(0, Math.max(0, cap - 1)); break;
    case "watching": watched = ri(1, Math.max(1, cap - 1)); break;
    case "on_hold": watched = ri(1, Math.max(1, cap - 1)); break;
    case "dropped": watched = ri(0, cap); break;
    default: watched = 0;
  }

  const airStart = startMs(m);
  let added;
  if (airing === "NOT_YET_RELEASED") {
    added = NOW - ri(1, 180) * DAY;
  } else if (chance(0.7)) {
    const lo = Math.max(FLOOR_2019, Math.min(airStart, NOW - DAY));
    added = lo + Math.floor(rand() * Math.max(DAY, NOW - DAY - lo));
  } else {
    const lo = Math.min(Math.max(airStart, Date.UTC(2012, 0, 1)), NOW - DAY);
    added = lo + Math.floor(rand() * Math.max(DAY, NOW - DAY - lo));
  }
  const updated = added + Math.floor(rand() * (NOW - added));
  const hasProgress = ["watching", "on_hold", "dropped", "completed", "rewatching"].includes(status);
  const started = hasProgress && chance(0.8) ? Math.min(added + ri(0, 14) * DAY, NOW) : null;
  const completedAt =
    status === "completed" ? Math.min((started ?? added) + ri(1, 120) * DAY, NOW) : null;

  let rewatch = 0;
  if (status === "rewatching") rewatch = ri(1, 3);
  else if (status === "completed" && chance(0.08)) rewatch = ri(1, 4);

  const scoreP =
    status === "completed" || status === "rewatching" ? 0.45
    : status === "dropped" ? 0.25
    : status === "watching" || status === "on_hold" ? 0.15
    : 0;
  let score = null;
  if (chance(scoreP)) {
    const base = m.averageScore != null ? m.averageScore / 10 : 7;
    score = Math.max(1, Math.min(10, Math.round(base + (rand() * 3 - 1.5))));
  }

  entries.push({
    anilist_id: m.id,
    mal_id: m.idMal ?? null,
    title_romaji: m.title?.romaji ?? `AniList #${m.id}`,
    title_english: m.title?.english ?? null,
    title_native: m.title?.native ?? null,
    cover_url: m.coverImage?.large ?? m.coverImage?.medium ?? null,
    total_episodes: total,
    status,
    episodes_watched: watched,
    score,
    notes: chance(0.1) ? pick(NOTES) : null,
    added_at: added,
    updated_at: Math.min(updated, NOW),
    started_at: started,
    completed_at: completedAt,
    has_dub: weighted([[true, 35], [false, 35], [null, 30]]),
    episode_duration: m.duration ?? null,
    rewatch_count: rewatch,
    aired_episodes: aired,
    franchise_root_id: roots[m.id] ?? null,
    plan_rank: null,
    airing_status: airing,
  });
}

// Manual plan-queue ranks on a shuffled subset.
const planners = entries.filter((e) => e.status === "plan_to_watch");
for (let i = planners.length - 1; i > 0; i--) {
  const j = Math.floor(rand() * (i + 1));
  [planners[i], planners[j]] = [planners[j], planners[i]];
}
planners.slice(0, 350).forEach((e, i) => { e.plan_rank = i + 1; });

fs.writeFileSync(OUT, JSON.stringify(entries));

// Self-check.
const byStatus = {};
for (const e of entries) byStatus[e.status] = (byStatus[e.status] ?? 0) + 1;
const legal = new Set(["watching", "completed", "plan_to_watch", "on_hold", "dropped", "rewatching", "not_interested"]);
const problems = [];
for (const e of entries) {
  if (!legal.has(e.status)) problems.push(`illegal status ${e.status}`);
  if (e.score != null && (e.score < 1 || e.score > 10)) problems.push(`score ${e.score} on ${e.anilist_id}`);
  if (e.airing_status === "RELEASING" && e.status === "completed") problems.push(`releasing-completed ${e.anilist_id}`);
  if (e.airing_status === "NOT_YET_RELEASED" && ["watching", "rewatching", "completed"].includes(e.status)) problems.push(`nyr-${e.status} ${e.anilist_id}`);
  if (e.total_episodes != null && e.episodes_watched > e.total_episodes) problems.push(`overwatch ${e.anilist_id}`);
  if (e.updated_at < e.added_at) problems.push(`time ${e.anilist_id}`);
}
const rooted = entries.filter((e) => e.franchise_root_id != null).length;
const groups = new Map();
for (const e of entries) {
  const r = e.franchise_root_id ?? e.anilist_id;
  groups.set(r, (groups.get(r) ?? 0) + 1);
}
const multi = [...groups.values()].filter((n) => n > 1);
console.log(`wrote ${entries.length} entries -> devdata/konsou-real-list.json`);
console.log("status counts:", byStatus);
console.log(`rooted: ${rooted}/${entries.length}; multi-member franchises: ${multi.length} covering ${multi.reduce((a, b) => a + b, 0)} entries`);
console.log(`covers present: ${entries.filter((e) => e.cover_url).length}; real durations: ${entries.filter((e) => e.episode_duration != null).length}`);
console.log(problems.length === 0 ? "self-check: CLEAN" : `PROBLEMS (${problems.length}): ${problems.slice(0, 10).join("; ")}`);
