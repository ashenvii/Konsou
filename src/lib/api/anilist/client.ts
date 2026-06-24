import { getDb } from "@/lib/db";
import type {
  AnimeMedia,
  AnimeSummary,
  MediaSeason,
  RelationNode,
} from "@/types/anime";
import { anilistLimiter, delay } from "../rateLimiter";
import { mapDetail, mapRelations, mapSummary } from "./mappers";
import {
  BROWSE_QUERY,
  BY_MAL_IDS_QUERY,
  DETAIL_QUERY,
  SEARCH_QUERY,
  USER_LIST_QUERY,
  buildRelationsBatchQuery,
} from "./queries";
import { jikanSearchMalIds } from "../jikan/client";
import { getCoverUrl, normalizeForSearch, preferredTitle } from "@/lib/format";
import type { MalRawEntry } from "../mal/parseExport";
import type { AnimeListEntry, ListStatus } from "@/types/list";

/** Outcome of a MAL import: resolved Konsou entries + titles we couldn't map. */
export interface MalResolveResult {
  entries: AnimeListEntry[];
  unmatched: { mal_id: number; title: string }[];
  total: number;
}

const ENDPOINT = "https://graphql.anilist.co";

const SEARCH_TTL = 10 * 60 * 1000; // 10 minutes
const DETAIL_TTL = 24 * 60 * 60 * 1000; // 24 hours
const RELATION_TTL = 6 * 60 * 60 * 1000; // 6 hours
const BATCH_SPACING_MS = 700; // AniList burst limiter guard
const PER_PAGE = 24;
// Below this many AniList hits on a typed-but-incomplete query, augment with the
// Jikan/MAL substring fallback (AniList ranks partial prefixes conservatively).
const SPARSE_RESULT_THRESHOLD = 5;
const MIN_FALLBACK_QUERY_LEN = 3;

export interface SearchPage {
  results: AnimeSummary[];
  hasNextPage: boolean;
  page: number;
}

export type RelationMap = Record<number, RelationNode[]>;

export type BrowseSort = "TRENDING_DESC" | "SCORE_DESC" | "POPULARITY_DESC";

/** Stable, fast key for cache lookups (no crypto needed — collisions are harmless). */
function hashKey(s: string): string {
  let h = 5381;
  for (let i = 0; i < s.length; i++) h = (h * 33) ^ s.charCodeAt(i);
  return (h >>> 0).toString(36);
}

/**
 * Cache access is best-effort: a SQLite failure must never break a live query.
 * Any error (DB not ready, missing table, permission) degrades to network-only.
 */
async function safeCache<T>(fn: () => Promise<T>): Promise<T | null> {
  try {
    return await fn();
  } catch (e) {
    console.warn("[anilist] cache unavailable, using network only:", e);
    return null;
  }
}

class HttpError extends Error {
  constructor(
    public status: number,
    public retryAfter?: number,
  ) {
    super(`HTTP ${status}`);
  }
}

class AniListClient {
  /** Low-level POST with rate limiting, 429 backoff, and tiered retries. */
  private async request<T>(
    query: string,
    variables?: Record<string, unknown>,
  ): Promise<T> {
    let networkRetries = 0;
    let serverRetries = 0;

    for (;;) {
      await anilistLimiter.acquire();
      try {
        const res = await fetch(ENDPOINT, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },
          body: JSON.stringify({ query, variables }),
        });

        if (res.status === 429) {
          const retryAfter = Number(res.headers.get("Retry-After") ?? "60");
          anilistLimiter.backoff(retryAfter);
          throw new HttpError(429, retryAfter);
        }
        if (res.status >= 500) throw new HttpError(res.status);
        if (res.status >= 400) {
          // 4xx — do not retry.
          const body = await res.text().catch(() => "");
          throw new Error(`AniList ${res.status}: ${body.slice(0, 200)}`);
        }

        const json = await res.json();
        if (json.errors?.length) {
          throw new Error(json.errors[0]?.message ?? "AniList GraphQL error");
        }
        return json.data as T;
      } catch (err) {
        if (err instanceof HttpError && err.status === 429) {
          // Limiter already paused; loop and try again.
          continue;
        }
        if (err instanceof HttpError && err.status >= 500) {
          if (serverRetries++ < 2) {
            await delay(1000 * 2 ** (serverRetries - 1));
            continue;
          }
          throw err;
        }
        // Network-level failure (fetch throws): retry 3× exp backoff.
        if (!(err instanceof Error) || err.message.startsWith("AniList ")) {
          throw err; // explicit 4xx / GraphQL error — give up
        }
        if (networkRetries++ < 3) {
          await delay(1000 * 2 ** (networkRetries - 1));
          continue;
        }
        throw err;
      }
    }
  }

  /** Cache-first search. Falls back to stale cache on network failure. */
  async search(query: string, page = 1): Promise<SearchPage> {
    // Collapse stray/duplicate whitespace so "  attack   on titan " and
    // "attack on titan" share a cache entry and one clean network query.
    const trimmed = query.replace(/\s+/g, " ").trim();
    const key = hashKey(`search:${trimmed.toLowerCase()}:${page}`);

    const cached = await safeCache(() =>
      getDb().then((db) => db.cacheGetSearch(key)),
    );
    if (cached && Date.now() - cached.cachedAt < SEARCH_TTL) {
      return { results: cached.results, hasNextPage: false, page };
    }

    try {
      const data = await this.request<any>(SEARCH_QUERY, {
        search: trimmed,
        page,
        perPage: PER_PAGE,
      });
      let results: AnimeSummary[] = (data.Page.media ?? []).map(mapSummary);
      let hasNextPage = data.Page.pageInfo?.hasNextPage ?? false;

      // AniList's SEARCH_MATCH is conservative on partial prefixes ("frier" → 0,
      // "shangr" → 1). When a typed query is sparse, augment with MAL/Jikan's
      // substring match, rehydrated through AniList so ids/data stay native.
      if (
        page === 1 &&
        trimmed.length >= MIN_FALLBACK_QUERY_LEN &&
        results.length < SPARSE_RESULT_THRESHOLD
      ) {
        const extra = await this.prefixFallback(trimmed);
        const seen = new Set(results.map((r) => r.id));
        for (const m of extra) {
          if (!seen.has(m.id)) {
            seen.add(m.id);
            results.push(m);
          }
        }
        // The merged set isn't a single AniList page, so don't paginate it.
        if (extra.length) hasNextPage = false;
      }

      void safeCache(() =>
        getDb().then((db) => db.cacheSetSearch(key, trimmed, results)),
      );
      return { results, hasNextPage, page };
    } catch (err) {
      if (cached) return { results: cached.results, hasNextPage: false, page };
      throw err;
    }
  }

  /**
   * Forgiving prefix fallback: ask Jikan (MAL) for matches, then rehydrate its
   * MAL ids through AniList — preserving Jikan's popularity ordering. Returns []
   * on any failure so search degrades to AniList-only, never breaks.
   */
  private async prefixFallback(query: string): Promise<AnimeSummary[]> {
    try {
      const malIds = await jikanSearchMalIds(query);
      if (malIds.length === 0) return [];

      const data = await this.request<any>(BY_MAL_IDS_QUERY, {
        idMal_in: malIds,
        perPage: malIds.length,
      });
      const media: AnimeSummary[] = (data.Page.media ?? []).map(mapSummary);

      // AniList returns idMal_in matches in its own order — restore Jikan's.
      const byMal = new Map(media.map((m) => [m.idMal, m]));
      return malIds
        .map((id) => byMal.get(id))
        .filter((m): m is AnimeSummary => !!m);
    } catch (e) {
      console.warn("[search] Jikan prefix fallback failed:", e);
      return [];
    }
  }

  /** Cache-first detail (24h). */
  async getById(id: number): Promise<AnimeMedia> {
    const cached = await safeCache(() =>
      getDb().then((db) => db.cacheGetAnime(id)),
    );
    if (cached && Date.now() - cached.cachedAt < DETAIL_TTL) {
      return cached.data;
    }

    try {
      const data = await this.request<any>(DETAIL_QUERY, { id });
      const media = mapDetail(data.Media);
      void safeCache(() => getDb().then((db) => db.cacheSetAnime(id, media)));
      return media;
    } catch (err) {
      if (cached) return cached.data; // serve stale on failure
      throw err;
    }
  }

  async browse(params: {
    sort: BrowseSort;
    page?: number;
    season?: MediaSeason;
    seasonYear?: number;
    genre?: string;
  }): Promise<SearchPage> {
    const page = params.page ?? 1;
    const data = await this.request<any>(BROWSE_QUERY, {
      page,
      perPage: PER_PAGE,
      sort: [params.sort],
      season: params.season ?? null,
      seasonYear: params.seasonYear ?? null,
      genre: params.genre ?? null,
    });
    return {
      results: (data.Page.media ?? []).map(mapSummary),
      hasNextPage: data.Page.pageInfo?.hasNextPage ?? false,
      page,
    };
  }

  /**
   * Relations for many anime at once. Reads the 6h snapshot cache first, only
   * fetching the ids whose snapshot is missing/expired, batched ≤50 per request
   * with 700ms spacing (sequel-detection burst guard).
   */
  async getRelationsBatch(ids: number[]): Promise<RelationMap> {
    const result: RelationMap = {};
    const stale: number[] = [];

    for (const id of ids) {
      const snap = await safeCache(() =>
        getDb().then((db) => db.getRelationSnapshot(id)),
      );
      if (snap && Date.now() - snap.checkedAt < RELATION_TTL) {
        result[id] = snap.relations;
      } else {
        stale.push(id);
      }
    }

    for (let i = 0; i < stale.length; i += 50) {
      const chunk = stale.slice(i, i + 50);
      const data = await this.request<any>(buildRelationsBatchQuery(chunk));
      for (const id of chunk) {
        const media = data[`m${id}`];
        const relations = media ? mapRelations(media) : [];
        result[id] = relations;
        void safeCache(() =>
          getDb().then((db) => db.setRelationSnapshot(id, relations)),
        );
      }
      if (i + 50 < stale.length) await delay(BATCH_SPACING_MS);
    }

    return result;
  }

  /**
   * Fetch any public AniList user's anime list and return it as Konsou entries.
   * Uses POINT_10 score format so no conversion is needed.
   */
  async importUserList(userName: string): Promise<AnimeListEntry[]> {
    const data = await this.request<any>(USER_LIST_QUERY, { userName });
    const collection = data?.MediaListCollection;
    if (!collection) {
      throw new Error(`No list found for AniList user "${userName}". Check that the username is correct and their list is public.`);
    }

    const STATUS_MAP: Record<string, ListStatus> = {
      CURRENT: "watching",
      COMPLETED: "completed",
      PLANNING: "plan_to_watch",
      PAUSED: "on_hold",
      DROPPED: "dropped",
      REPEATING: "rewatching",
    };

    const toMs = (d: { year?: number; month?: number; day?: number } | null): number | null => {
      if (!d?.year) return null;
      return new Date(
        `${d.year}-${String(d.month ?? 1).padStart(2, "0")}-${String(d.day ?? 1).padStart(2, "0")}`,
      ).getTime();
    };

    const now = Date.now();
    const seen = new Set<number>();
    const entries: AnimeListEntry[] = [];

    for (const list of collection.lists ?? []) {
      for (const e of list.entries ?? []) {
        const status = STATUS_MAP[e.status as string];
        if (!status || !e.media?.id) continue;
        if (seen.has(e.media.id)) continue;
        seen.add(e.media.id);

        entries.push({
          anilist_id: e.media.id,
          mal_id: e.media.idMal ?? null,
          title_romaji: e.media.title?.romaji ?? "Unknown",
          title_english: e.media.title?.english ?? null,
          title_native: e.media.title?.native ?? null,
          cover_url: e.media.coverImage?.medium ?? null,
          total_episodes: e.media.episodes ?? null,
          status,
          episodes_watched: (e.progress as number) ?? 0,
          score: e.score && (e.score as number) > 0 ? (e.score as number) : null,
          notes: (e.notes as string) || null,
          has_dub: null,
          added_at: now,
          updated_at: now,
          started_at: toMs(e.startedAt),
          completed_at: toMs(e.completedAt),
        });
      }
    }

    return entries;
  }

  /**
   * Resolve parsed MAL export entries onto AniList ids so they fit Konsou's
   * AniList-keyed model. Two-stage matching maximizes hits:
   *   1. batch lookup by MAL id (idMal_in, 50/request) — exact, covers most;
   *   2. for stragglers, an AniList title search, accepting only a confident
   *      match (same MAL id, or an exact normalized-title match).
   * Whatever still can't be matched is returned in `unmatched` for the user to
   * add manually, rather than being silently dropped.
   */
  async resolveMalEntries(raw: MalRawEntry[]): Promise<MalResolveResult> {
    const now = Date.now();
    const byMal = new Map(raw.map((r) => [r.mal_id, r]));
    const ids = [...byMal.keys()];
    const media = new Map<number, AnimeSummary>(); // mal_id → AniList media

    // Stage 1 — exact batch resolution by MAL id.
    for (let i = 0; i < ids.length; i += 50) {
      const chunk = ids.slice(i, i + 50);
      const data = await this.request<any>(BY_MAL_IDS_QUERY, {
        idMal_in: chunk,
        perPage: 50,
      });
      for (const m of (data.Page.media ?? []).map(mapSummary) as AnimeSummary[]) {
        if (m.idMal != null) media.set(m.idMal, m);
      }
      if (i + 50 < ids.length) await delay(700);
    }

    // Stage 2 — title-search fallback for the unmatched remainder.
    const unmatched: { mal_id: number; title: string }[] = [];
    for (const id of ids.filter((x) => !media.has(x))) {
      const r = byMal.get(id)!;
      let hit: AnimeSummary | undefined;
      try {
        const target = normalizeForSearch(r.title);
        const page = await this.search(r.title, 1);
        hit =
          page.results.find((x) => x.idMal === id) ??
          page.results.find(
            (x) =>
              normalizeForSearch(preferredTitle(x.title, "romaji")) === target ||
              normalizeForSearch(x.title.english ?? "") === target,
          );
      } catch {
        /* network hiccup — treat as unmatched */
      }
      if (hit) media.set(id, hit);
      else unmatched.push({ mal_id: id, title: r.title });
    }

    // Build Konsou entries from the matches.
    const entries: AnimeListEntry[] = [];
    for (const [malId, m] of media) {
      const r = byMal.get(malId)!;
      const isDone = r.status === "completed" || r.status === "rewatching";
      entries.push({
        anilist_id: m.id,
        mal_id: malId,
        title_romaji: m.title.romaji,
        title_english: m.title.english ?? null,
        title_native: m.title.native ?? null,
        cover_url: getCoverUrl(m.coverImage) || null,
        total_episodes: m.episodes ?? r.total_episodes,
        status: r.status,
        episodes_watched: r.episodes_watched,
        score: r.score,
        notes: null,
        has_dub: null,
        added_at: now,
        updated_at: now,
        started_at: r.started_at,
        completed_at: isDone ? r.finished_at : null,
      });
    }

    return { entries, unmatched, total: raw.length };
  }
}

export const anilist = new AniListClient();
