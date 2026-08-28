// Generates a Konsou "Restore backup" JSON file full of synthetic entries.
// Usage: node gen-stress-list.mjs [count] [outPath]
// Shape matches AnimeListEntry in src/types/list.ts; ids start at 5,000,000
// so they can never collide with real AniList ids (~max 200k in 2026).

import fs from "node:fs";

const COUNT = parseInt(process.argv[2] ?? "6500", 10);
const OUT = process.argv[3] ?? "konsou-stress-list.json";

// Real AniList CDN cover URLs (fetched separately into cover-pool.json).
// Cycled across entries so image loading is actually exercised; without the
// pool every cover is null and the app shows its letter-tile fallback.
const COVER_POOL_PATH = new URL("cover-pool.json", import.meta.url);
const COVERS = fs.existsSync(COVER_POOL_PATH)
  ? JSON.parse(fs.readFileSync(COVER_POOL_PATH, "utf8"))
  : [];

// Deterministic PRNG so reruns produce the same file.
let seed = 0x1a2b3c4d;
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

// ── Title material ─────────────────────────────────────────
const A = ["Sora no", "Yoru no", "Kurenai no", "Hagane no", "Mahou no", "Owari no", "Hoshi no", "Kaze no", "Shinigami no", "Eien no", "Kiseki no", "Zetsubou no", "Seiken no", "Ryuu no", "Tenkuu no", "Ankoku no", "Hikari no", "Gin no", "Kuro no", "Shiroi"];
const B = ["Frontier", "Kishidan", "Monogatari", "Gakuen", "Requiem", "Overture", "Paradox", "Fanfare", "Chronicle", "Rondo", "Kingdom", "Circuit", "Alchemist", "Vanguard", "Symphonia", "Escapade", "Horizon", "Bouken", "Sensen", "Meikyuu"];
const C = ["Academia", "Zero", "Alternative", "Genesis", "Advent", "Reverie", "Ignition", "Rebellion", "Encore", "Fragment", "Memoria", "Catalyst", "Eclipse", "Mirage", "Ascension"];
const ENG_A = ["The", "A", "Our", "My", "That", "This"];
const ENG_B = ["Silent", "Burning", "Forgotten", "Wandering", "Eternal", "Crimson", "Hollow", "Distant", "Restless", "Gilded"];
const ENG_C = ["Sky", "Blade", "Garden", "Empire", "Requiem", "Frontier", "Melody", "Paradox", "Harvest", "Beacon"];
const KATA = ["ソラ", "ヨル", "カゼ", "ホシ", "リュウ", "テン", "クロ", "シロ", "ギン", "アカ"];
const KANJI = ["物語", "学園", "戦線", "迷宮", "冒険", "王国", "騎士団", "幻想", "黎明", "残響"];
const SUFFIXES = ["", " 2nd Season", " Season 3", ": The Movie", " OVA", ": Final Season", " Specials", " Gaiden", " II", ": After Story"];
const NOTES = [
  "rewatch with N. sometime",
  "dub is better, fight me",
  "stalled at the beach episode",
  "manga readers say it gets good at ep 18",
  "OP of the year, easily",
  "dropped once already, second chance",
  "watch before the movie comes out",
  "S2 supposedly covers the good arc",
  'the "bread scene" alone is worth it',
  "friend spoiled the ending :(\nstill worth finishing?",
  "彼の言う通りだった。続きが気になる",
  "banger soundtrack 🔥 but pacing drags mid-season",
];
const LONG_NOTE =
  "Long-form note for layout stress: started this on a flight, fell asleep twice, restarted from episode one, and somehow the recap episode was the thing that hooked me. Track where the anime-original content splits from the source around episode nineteen because apparently everything after that is filler until the last two.";

function baseTitle() {
  const style = rand();
  if (style < 0.62) return `${pick(A)} ${pick(B)}`;
  if (style < 0.8) return `${pick(A)} ${pick(B)} ${pick(C)}`;
  if (style < 0.92) return `${pick(ENG_B)} ${pick(ENG_C)}`;
  return `${pick(B)}: ${pick(C)}`;
}
function englishOf(romaji) {
  if (!chance(0.55)) return null;
  return `${pick(ENG_A)} ${pick(ENG_B)} ${pick(ENG_C)}`;
}
function nativeOf() {
  if (!chance(0.6)) return null;
  return `${pick(KATA)}${pick(KATA)}の${pick(KANJI)}`;
}

// ── Status machinery ───────────────────────────────────────
const STATUS_WEIGHTS = [
  ["completed", 40],
  ["plan_to_watch", 23],
  ["not_interested", 13],
  ["dropped", 9],
  ["watching", 7],
  ["on_hold", 5.5],
  ["rewatching", 2.5],
];
function airingFor(status) {
  switch (status) {
    case "completed":
    case "rewatching":
      return chance(0.92) ? "FINISHED" : null;
    case "watching":
      return weighted([["RELEASING", 40], ["FINISHED", 55], [null, 5]]);
    case "on_hold":
      return weighted([["FINISHED", 80], ["RELEASING", 15], [null, 5]]);
    case "dropped":
      return weighted([["FINISHED", 85], ["CANCELLED", 5], ["RELEASING", 5], [null, 5]]);
    case "plan_to_watch":
      return weighted([["FINISHED", 60], ["RELEASING", 15], ["NOT_YET_RELEASED", 20], ["HIATUS", 5]]);
    default:
      return weighted([["FINISHED", 85], ["RELEASING", 10], [null, 5]]);
  }
}
function totalEpisodesFor(airing) {
  if (airing === "NOT_YET_RELEASED") return null;
  const bucket = weighted([
    [1, 5], [12, 35], [25, 30], [45, 12], [200, 5], [900, 2], [null, 11],
  ]);
  if (bucket === null) return airing === "RELEASING" ? null : ri(11, 26);
  if (bucket === 1) return 1;
  if (bucket === 12) return pick([11, 12, 13]);
  if (bucket === 25) return pick([24, 25, 26]);
  if (bucket === 45) return ri(37, 52);
  if (bucket === 200) return ri(100, 500);
  return ri(500, 1122);
}
function scoreFor(status) {
  if (status === "completed" || status === "rewatching")
    return chance(0.45) ? ri(3, 10) : null;
  if (status === "dropped") return chance(0.25) ? ri(1, 6) : null;
  if (status === "watching" || status === "on_hold")
    return chance(0.15) ? ri(5, 9) : null;
  return null;
}

const NOW = Date.now();
const YEAR = 365 * 24 * 3600 * 1000;

function buildEntry(id, romaji, franchiseRootId, forcedStatus) {
  const status = forcedStatus ?? weighted(STATUS_WEIGHTS);
  const airing = airingFor(status);
  let total = totalEpisodesFor(airing);
  if (status === "completed" && total == null) total = ri(11, 26);

  let aired = null;
  if (airing === "FINISHED" || airing === "CANCELLED") aired = total;
  else if (airing === "RELEASING") aired = total != null ? ri(1, Math.max(1, total - 1)) : ri(1, 24);
  else if (airing === "NOT_YET_RELEASED") aired = null;

  let watched = 0;
  const cap = aired ?? total ?? 24;
  switch (status) {
    case "completed": watched = total; break;
    case "rewatching": watched = ri(0, Math.max(0, (total ?? cap) - 1)); break;
    case "watching": watched = ri(1, Math.max(1, cap - 1)); break;
    case "on_hold": watched = ri(1, Math.max(1, cap - 1)); break;
    case "dropped": watched = ri(0, cap); break;
    default: watched = 0;
  }

  const added = NOW - Math.floor(rand() * 7.5 * YEAR) - 24 * 3600 * 1000;
  const updated = added + Math.floor(rand() * (NOW - added));
  const hasProgress = ["watching", "on_hold", "dropped", "completed", "rewatching"].includes(status);
  const started = hasProgress && chance(0.8) ? added + ri(0, 14) * 24 * 3600 * 1000 : null;
  const completedAt =
    status === "completed"
      ? (started ?? added) + ri(1, 120) * 24 * 3600 * 1000
      : null;

  let rewatch = 0;
  if (status === "rewatching") rewatch = ri(1, 3);
  else if (status === "completed" && chance(0.08)) rewatch = ri(1, 4);

  let note = null;
  if (chance(0.12)) note = chance(0.06) ? LONG_NOTE : pick(NOTES);

  return {
    anilist_id: id,
    mal_id: chance(0.7) ? id - 4_950_000 : null,
    title_romaji: romaji,
    title_english: englishOf(romaji),
    title_native: nativeOf(),
    cover_url: COVERS.length > 0 && chance(0.9) ? pick(COVERS) : null,
    total_episodes: total,
    status,
    episodes_watched: watched,
    score: scoreFor(status),
    notes: note,
    added_at: added,
    updated_at: Math.min(updated, NOW),
    started_at: started,
    completed_at: completedAt ? Math.min(completedAt, NOW) : null,
    has_dub: weighted([[true, 40], [false, 40], [null, 20]]),
    episode_duration: weighted([[24, 60], [12, 10], [23, 5], [25, 5], [48, 3], [6, 3], [null, 14]]),
    rewatch_count: rewatch,
    aired_episodes: aired,
    franchise_root_id: franchiseRootId,
    plan_rank: null,
    airing_status: airing,
  };
}

// ── Assembly ───────────────────────────────────────────────
const entries = [];
let nextId = 5_000_000;

// Hand-built torture rows first: the deliberate extremes.
const torture = [];
{
  // One franchise carrying every status at once (cross-status stress).
  const rootId = nextId;
  const base = "Zetsubou no Circuit";
  const all = ["watching", "completed", "plan_to_watch", "on_hold", "dropped", "rewatching", "not_interested"];
  all.forEach((st, i) => {
    const e = buildEntry(nextId, `${base}${SUFFIXES[i] || ""}`, rootId, st);
    torture.push(e);
    nextId++;
  });
  // 1122-episode monster, fully watched (EP badge clamp).
  const big = buildEntry(nextId++, "Hateshinai Bouken Retsuden", null, "completed");
  big.total_episodes = 1122; big.episodes_watched = 1122; big.aired_episodes = 1122;
  big.airing_status = "FINISHED"; big.score = 10;
  torture.push(big);
  // Absurdly long romaji title, no english, no native.
  const long = buildEntry(nextId++, null, null, "plan_to_watch");
  long.title_romaji =
    "Jitsu wa Ore, Saikyou no Kenja de Aru Koto wo Kakushite Heibon na Boukensha " +
    "to Shite Kurashite Ita kedo, Aru Hi Totsuzen Sekai wo Sukuu Hame ni Natta Ken ni Tsuite";
  long.title_english = null; long.title_native = null;
  torture.push(long);
  // Titles that begin with digits/punctuation (sort edges).
  const t86 = buildEntry(nextId++, "86", null, "completed");
  t86.title_english = "Eighty Six"; torture.push(t86);
  torture.push(buildEntry(nextId++, '"Oshiete!" to Kanojo wa Itta', null, "watching"));
  torture.push(buildEntry(nextId++, "K&R: Hackers no Uta", null, "on_hold"));
  torture.push(buildEntry(nextId++, "☆Twinkle Star Precession☆", null, "dropped"));
  // Duplicate romaji titles, different entries (search dedupe display).
  torture.push(buildEntry(nextId++, "Hagane no Requiem", null, "completed"));
  torture.push(buildEntry(nextId++, "Hagane no Requiem", null, "plan_to_watch"));
  // Score extremes.
  const s1 = buildEntry(nextId++, "Saitei no Isekai Slime Life", null, "dropped");
  s1.score = 1; torture.push(s1);
  const s10 = buildEntry(nextId++, "Kamikyoku: Ongaku no Chouten", null, "completed");
  s10.score = 10; torture.push(s10);
  // Ancient entry (Wrapped/Stats horizon) and a just-now entry.
  const old = buildEntry(nextId++, "Natsukashii Denpa Club", null, "completed");
  old.added_at = Date.UTC(2015, 3, 12); old.updated_at = Date.UTC(2015, 8, 2);
  old.started_at = old.added_at; old.completed_at = old.updated_at; torture.push(old);
  const fresh = buildEntry(nextId++, "Kyou Hajimeta Bakari no Show", null, "watching");
  fresh.added_at = NOW - 3600_000; fresh.updated_at = NOW - 60_000; torture.push(fresh);
}
entries.push(...torture);

// Bulk fill: franchises (~35% of entries in clusters of 2-7) + standalones.
while (entries.length < COUNT) {
  if (chance(0.14) && entries.length + 7 < COUNT) {
    const size = ri(2, 7);
    const rootId = nextId;
    const base = baseTitle();
    for (let i = 0; i < size && entries.length < COUNT; i++) {
      entries.push(buildEntry(nextId++, i === 0 ? base : `${base}${pick(SUFFIXES.slice(1))}`, rootId, null));
    }
  } else {
    // Standalones exercise both root conventions: own id and null.
    const id = nextId++;
    entries.push(buildEntry(id, baseTitle(), chance(0.6) ? id : null, null));
  }
}

// Plan queue: give a shuffled ~350-entry subset manual ranks 1..N.
const planners = entries.filter((e) => e.status === "plan_to_watch");
for (let i = planners.length - 1; i > 0; i--) {
  const j = Math.floor(rand() * (i + 1));
  [planners[i], planners[j]] = [planners[j], planners[i]];
}
planners.slice(0, 350).forEach((e, i) => { e.plan_rank = i + 1; });

fs.writeFileSync(OUT, JSON.stringify(entries), "utf8");

// Summary + self-check.
const byStatus = {};
for (const e of entries) byStatus[e.status] = (byStatus[e.status] ?? 0) + 1;
const ids = new Set(entries.map((e) => e.anilist_id));
const badScore = entries.filter((e) => e.score != null && (e.score < 1 || e.score > 10)).length;
const badCompleted = entries.filter((e) => e.status === "completed" && e.episodes_watched !== e.total_episodes).length;
const franchised = entries.filter((e) => e.franchise_root_id != null && e.franchise_root_id !== e.anilist_id).length;
console.log(`wrote ${entries.length} entries -> ${OUT}`);
console.log("status counts:", byStatus);
console.log(`unique ids: ${ids.size === entries.length}, bad scores: ${badScore}, completed mismatches: ${badCompleted}`);
console.log(`entries inside multi-member franchises (non-root): ${franchised}`);
console.log(`plan_rank assigned: ${entries.filter((e) => e.plan_rank != null).length}`);
