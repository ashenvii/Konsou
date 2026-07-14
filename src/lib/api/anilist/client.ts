import { getDb } from "@/lib/db";
import type {
  AniListMediaStatus,
  AnimeMedia,
  AnimeSummary,
  MediaFormat,
  MediaSeason,
  RelationNode,
} from "@/types/anime";
import { anilistLimiter, delay } from "../rateLimiter";
import type { Priority } from "../rateLimiter";
import { mapDetail, mapRelations, mapSummary } from "./mappers";
import {
  BY_MAL_IDS_QUERY,
  DETAIL_QUERY,
  SEARCH_QUERY,
  USER_LIST_QUERY,
  buildAiringStatusBatchQuery,
  buildBrowseQuery,
  buildRelationsBatchQuery,
} from "./queries";
import { jikanSearchMalIds } from "../jikan/client";
import {
  airedEpisodes,
  getCoverUrl,
  normalizeForSearch,
  preferredTitle,
} from "@/lib/format";
import { isPromoNode } from "@/lib/franchise/storySplit";
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
// Hard cap on any single request. Without it, a fetch that connects but never
// gets a response (seen on mobile for the detail query, which passed no signal)
// awaits forever and the page spins with no way out but killing the app. A
// timeout surfaces as a retryable network error instead.
const REQUEST_TIMEOUT_MS = 15_000;
// AniList caps query complexity at 500 per request, and each aliased
// `Media { relations { … } }` in the sequel-detection batch costs ~30. A
// 50-id batch is ~1500 and is rejected outright (HTTP 400, no data), which
// silently zeroes out detection for anyone with a large list. 12 ids ≈ 360,
// leaving headroom against the cap and any future field additions.
const RELATIONS_BATCH_SIZE = 12;
const PER_PAGE = 24;
// Only when AniList returns nothing do we augment with the Jikan/MAL substring
// fallback. AniList ranks partial prefixes conservatively ("frier" → 0), so a
// zero-result query is the tell that its matcher whiffed. When it returns even
// one hit, the extra Jikan + rehydrate round-trip isn't worth the rate-limiter
// cost it adds on every keystroke.
const MIN_FALLBACK_QUERY_LEN = 3;

export interface SearchPage {
  results: AnimeSummary[];
  hasNextPage: boolean;
  page: number;
}

export type RelationMap = Record<number, RelationNode[]>;

/** Live airing snapshot for one media (Schedule page + plan-to-watch scan). */
export interface AiringStatus {
  status: string;
  episodes: number | null;
  nextAiringAt: number | null;
  nextEpisode: number | null;
}

export type BrowseSort = "TRENDING_DESC" | "SCORE_DESC" | "POPULARITY_DESC";

/** ISO-3166 alpha-2 codes AniList uses for `countryOfOrigin`. */
export type CountryCode = "JP" | "CN" | "KR" | "TW";

/** Everything the Discover browse can filter on. All optional so the three
 *  sort tabs work with nothing set; the filter panel fills in the rest. */
export interface BrowseParams {
  sort: BrowseSort;
  page?: number;
  /** Optional keyword: lets the filtered browse also match a title, so users can
   *  search any anime AND narrow it by genre/year/format in one query. */
  search?: string | null;
  season?: MediaSeason;
  seasonYear?: number;
  /** AniList genre names, e.g. "Action"; combined with AND. */
  genres?: string[];
  /** AniList tag names, e.g. "Isekai"; themes are tags, not genres. */
  themes?: string[];
  /** Anime formats to include; MUSIC is never offered. Empty = all-but-Music. */
  formats?: MediaFormat[];
  status?: AniListMediaStatus | null;
  country?: CountryCode | null;
  yearFrom?: number | null;
  yearTo?: number | null;
}

/** True for a fetch/request aborted via AbortSignal (superseded search, etc.). */
function isAbortError(err: unknown): boolean {
  return (err as { name?: string } | null)?.name === "AbortError";
}

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
    priority: Priority = "high",
    signal?: AbortSignal,
  ): Promise<T> {
    let networkRetries = 0;
    let serverRetries = 0;
    let rateLimitRetries = 0;

    for (;;) {
      // Bail before spending a token (or a round-trip) if the caller — a
      // superseded search, say — has already been cancelled.
      if (signal?.aborted) throw new DOMException("Aborted", "AbortError");
      await anilistLimiter.acquire(priority);
      if (signal?.aborted) throw new DOMException("Aborted", "AbortError");

      // Own timeout controller so every request is bounded, forwarding the
      // caller's abort (if any). A timeout aborts with a TimeoutError, which is
      // not an AbortError, so the loop below retries it like any network blip.
      const controller = new AbortController();
      const onCallerAbort = () =>
        controller.abort(signal?.reason ?? new DOMException("Aborted", "AbortError"));
      if (signal) signal.addEventListener("abort", onCallerAbort, { once: true });
      const timer = setTimeout(
        () => controller.abort(new DOMException("Request timed out", "TimeoutError")),
        REQUEST_TIMEOUT_MS,
      );
      try {
        let res: Response;
        try {
          res = await fetch(ENDPOINT, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Accept: "application/json",
            },
            body: JSON.stringify({ query, variables }),
            signal: controller.signal,
          });
        } finally {
          clearTimeout(timer);
          if (signal) signal.removeEventListener("abort", onCallerAbort);
        }

        // Trust the server's own budget arithmetic over ours whenever it's
        // visible. Best-effort: if CORS doesn't expose the header, get()
        // returns null and the local bucket stands alone.
        const remaining = Number(res.headers.get("X-RateLimit-Remaining"));
        if (Number.isFinite(remaining)) anilistLimiter.syncRemaining(remaining);

        if (res.status === 429) {
          // AniList's window resets every 60s, so never pause the whole bucket
          // for longer than that even if Retry-After is missing, unparseable, or
          // absurdly large. An over-long pause stalls every query app-wide and
          // looks like a dead app until restart.
          const raw = Number(res.headers.get("Retry-After"));
          const retryAfter = Math.min(Number.isFinite(raw) && raw > 0 ? raw : 60, 60);
          anilistLimiter.backoff(retryAfter);
          throw new HttpError(429, retryAfter);
        }
        if (res.status >= 500) throw new HttpError(res.status);

        // Parse the body even on a 4xx: AniList delivers GraphQL partial
        // success with a non-200 status. A batched query (sequel detection's
        // aliased multi-Media request) that includes a deleted or private
        // related media returns HTTP 404, yet the body still carries every
        // resolvable alias in `data`, with the missing one set to null and
        // reported in `errors`. Throwing on the status — or on any error —
        // would discard the whole batch and silently abort detection, so we
        // only treat the response as fatal when there's no usable data at all.
        const json = await res.json().catch(() => null);
        // Honor any response that carries a `data` object, even on a 4xx and
        // even when every field is null. AniList reports unresolvable ids as
        // per-field 404s (`errors`) while still returning a `data` map with
        // those aliases set to null — including a whole batch of not-found ids
        // (`{ m1: null, m2: null }`). Those nulls are legitimate "no such
        // media" results, not a failed request, so callers handle them (the
        // relation mapper treats a null alias as no relations). Only a missing
        // or null `data` is a real failure.
        if (json?.data != null) return json.data as T;

        if (res.status >= 400) {
          throw new Error(
            `AniList ${res.status}: ${JSON.stringify(json ?? {}).slice(0, 200)}`,
          );
        }
        throw new Error(json?.errors?.[0]?.message ?? "AniList GraphQL error");
      } catch (err) {
        // A cancelled request (a fast typist superseding a search) must surface
        // immediately, never get retried.
        if (isAbortError(err)) throw err;
        if (err instanceof HttpError && err.status === 429) {
          // Limiter already paused for the (capped) Retry-After; wait it out and
          // retry, but give up after a few rounds so a persistent rate-limit
          // surfaces as a retryable error instead of an endless spinner.
          if (rateLimitRetries++ < 4) continue;
          throw err;
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
  async search(query: string, page = 1, signal?: AbortSignal): Promise<SearchPage> {
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
      const data = await this.request<any>(
        SEARCH_QUERY,
        { search: trimmed, page, perPage: PER_PAGE },
        "high",
        signal,
      );
      // PVs/CMs/teasers are advertising, not results anyone searches for;
      // the same conservative gate the franchise walk uses.
      let results: AnimeSummary[] = (data.Page.media ?? [])
        .map(mapSummary)
        .filter((m: AnimeSummary) => !isPromoNode(m));
      let hasNextPage = data.Page.pageInfo?.hasNextPage ?? false;

      // AniList's SEARCH_MATCH whiffs entirely on some partial prefixes
      // ("frier" → 0). Only then augment with MAL/Jikan's substring match,
      // rehydrated through AniList so ids/data stay native. Skipped once AniList
      // returns anything, and skipped if this search was already superseded.
      if (
        page === 1 &&
        trimmed.length >= MIN_FALLBACK_QUERY_LEN &&
        results.length === 0 &&
        !signal?.aborted
      ) {
        const extra = await this.prefixFallback(trimmed, signal);
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

      // Never cache emptiness: a transient upstream miss (Jikan down, rate
      // limit) would otherwise pin "no results" for the TTL even though the
      // title exists. Empty is cheap to re-ask for.
      if (results.length > 0) {
        void safeCache(() =>
          getDb().then((db) => db.cacheSetSearch(key, trimmed, results)),
        );
      }
      return { results, hasNextPage, page };
    } catch (err) {
      // A cancelled search has no result to show and no failure to recover from.
      if (isAbortError(err)) throw err;
      if (cached) return { results: cached.results, hasNextPage: false, page };
      throw err;
    }
  }

  /**
   * Forgiving prefix fallback: ask Jikan (MAL) for matches, then rehydrate its
   * MAL ids through AniList — preserving Jikan's popularity ordering. Returns []
   * on any failure so search degrades to AniList-only, never breaks.
   */
  private async prefixFallback(
    query: string,
    signal?: AbortSignal,
  ): Promise<AnimeSummary[]> {
    try {
      const malIds = await jikanSearchMalIds(query, 12, signal);
      if (malIds.length === 0) return [];

      const data = await this.request<any>(
        BY_MAL_IDS_QUERY,
        { idMal_in: malIds, perPage: malIds.length },
        "high",
        signal,
      );
      const media: AnimeSummary[] = (data.Page.media ?? []).map(mapSummary);

      // AniList returns idMal_in matches in its own order — restore Jikan's.
      const byMal = new Map(media.map((m) => [m.idMal, m]));
      return malIds
        .map((id) => byMal.get(id))
        .filter((m): m is AnimeSummary => !!m);
    } catch (e) {
      // Let a cancellation propagate; only genuine failures degrade to [].
      if (isAbortError(e)) throw e;
      console.warn("[search] Jikan prefix fallback failed:", e);
      return [];
    }
  }

  /** Detail refreshes already running in the background, keyed by media id. */
  private detailRefreshing = new Set<number>();

  /**
   * Stale-while-revalidate detail. ANY cached copy renders immediately -- a
   * title's description, cover, and season list don't change enough to be
   * worth making the user watch a spinner, and repeat opens must cost zero
   * requests or a browsing session eats the whole rate budget. A copy older
   * than DETAIL_TTL additionally kicks off a background (low-priority)
   * refresh, so the cache converges on fresh without the user ever waiting
   * on it. Only a cold id -- never seen before -- goes to the network in the
   * foreground.
   */
  async getById(id: number, signal?: AbortSignal): Promise<AnimeMedia> {
    const cached = await safeCache(() =>
      getDb().then((db) => db.cacheGetAnime(id)),
    );
    if (cached) {
      if (Date.now() - cached.cachedAt >= DETAIL_TTL) {
        void this.refreshDetail(id);
      }
      return cached.data;
    }

    const data = await this.request<any>(DETAIL_QUERY, { id }, "high", signal);
    // A deleted/private id resolves to null even on an otherwise-OK response.
    if (!data?.Media) throw new Error(`AniList media ${id} not found`);
    const media = mapDetail(data.Media);
    void safeCache(() => getDb().then((db) => db.cacheSetAnime(id, media)));
    return media;
  }

  /** Background half of getById's stale-while-revalidate: refetch one detail
   *  at low priority and rewrite the SQLite copy. Deduped so a page being
   *  reopened in a loop can't queue the same refresh N times; failures are
   *  swallowed because the stale copy already rendered. */
  private async refreshDetail(id: number): Promise<void> {
    if (this.detailRefreshing.has(id)) return;
    this.detailRefreshing.add(id);
    try {
      const data = await this.request<any>(DETAIL_QUERY, { id }, "low");
      if (data?.Media) {
        const media = mapDetail(data.Media);
        await safeCache(() => getDb().then((db) => db.cacheSetAnime(id, media)));
      }
    } catch (e) {
      console.warn(`[anilist] background detail refresh failed for ${id}:`, e);
    } finally {
      this.detailRefreshing.delete(id);
    }
  }

  async browse(params: BrowseParams): Promise<SearchPage> {
    const page = params.page ?? 1;
    const genres = params.genres?.length ? params.genres : null;
    const themes = params.themes?.length ? params.themes : null;
    // The user never gets to pick MUSIC (anniversary clips, PVs, music videos)
    // in the panel, so when they haven't narrowed the format at all we still
    // exclude it. An explicit format selection takes over from the exclusion.
    const formats = params.formats?.length ? params.formats : null;
    const withFormatIn = Boolean(formats);
    const withStatus = Boolean(params.status);
    const withCountry = Boolean(params.country);
    const withYear = Boolean(params.yearFrom || params.yearTo);
    const search = params.search?.trim() ? params.search.trim() : null;
    const variables: Record<string, unknown> = {
      page,
      perPage: PER_PAGE,
      sort: [params.sort],
      search,
      season: params.season ?? null,
      seasonYear: params.seasonYear ?? null,
      genre_in: genres,
      tag_in: themes,
      // Always a real value; MUSIC (anniversary clips, PVs) is never wanted.
      format_not_in: ["MUSIC"],
    };
    // These only ride along when set: AniList either errors (format_in, dates)
    // or silently matches "null" and returns nothing (status, country).
    if (withFormatIn) variables.format_in = formats;
    if (withStatus) variables.status = params.status;
    if (withCountry) variables.countryOfOrigin = params.country;
    // FuzzyDateInt is YYYYMMDD; widen to whole calendar years, with a wide
    // sentinel on the open side so a one-sided range stays valid. Both AniList
    // comparators are strict, so nudge each bound past the year edge: -1 keeps
    // year-only dates (YYYY0000) in range, (yearTo+1)*10000 keeps Dec 31
    // premieres in range.
    if (withYear) {
      variables.startDate_greater = params.yearFrom
        ? params.yearFrom * 10000 - 1
        : 10000101;
      variables.startDate_lesser = params.yearTo
        ? (params.yearTo + 1) * 10000
        : 30001231;
    }
    const data = await this.request<any>(
      buildBrowseQuery({ withFormatIn, withStatus, withCountry, withYear }),
      variables,
    );
    return {
      results: (data.Page.media ?? [])
        .map(mapSummary)
        .filter((m: AnimeSummary) => !isPromoNode(m)),
      hasNextPage: data.Page.pageInfo?.hasNextPage ?? false,
      page,
    };
  }

  /** Relation ids already being revalidated in the background. */
  private relationsRevalidating = new Set<number>();

  /**
   * Relations for many anime at once. Reads the snapshot cache first, only
   * fetching the ids whose snapshot is missing/expired, batched ≤12 per request
   * (AniList complexity cap) with 700ms spacing. Defaults to `low` priority --
   * sequel detection is background work that must yield to the user's own
   * searches and page loads.
   *
   * `staleOk` is the presentation mode (franchise walks, quick menu, Related):
   * ANY snapshot serves immediately no matter its age, and expired ones queue
   * a background low-priority revalidation instead of blocking. Franchise
   * graphs change on the timescale of season announcements, so showing a
   * days-old graph instantly beats making the user wait out a re-crawl --
   * that re-crawl was most of what burned the rate budget while browsing.
   * Correctness-sensitive callers (root resolution, the sequel radar) leave
   * it off and keep strict TTL semantics.
   */
  async getRelationsBatch(
    ids: number[],
    priority: Priority = "low",
    opts?: { staleOk?: boolean },
  ): Promise<RelationMap> {
    const result: RelationMap = {};
    const stale: number[] = [];
    const revalidate: number[] = [];

    for (const id of ids) {
      const snap = await safeCache(() =>
        getDb().then((db) => db.getRelationSnapshot(id)),
      );
      if (snap && Date.now() - snap.checkedAt < RELATION_TTL) {
        result[id] = snap.relations;
      } else if (snap && opts?.staleOk) {
        result[id] = snap.relations;
        revalidate.push(id);
      } else {
        stale.push(id);
      }
    }

    if (revalidate.length > 0) void this.revalidateRelations(revalidate);

    let sawNetworkFailure = false;
    for (let i = 0; i < stale.length; i += RELATIONS_BATCH_SIZE) {
      const chunk = stale.slice(i, i + RELATIONS_BATCH_SIZE);
      if (await this.resolveRelationChunk(chunk, priority, result)) {
        sawNetworkFailure = true;
      }
      if (i + RELATIONS_BATCH_SIZE < stale.length) await delay(BATCH_SPACING_MS);
    }

    // Cached snapshots and per-id recoveries count as data; only a total
    // blank caused by network failure becomes an error. Without this, callers
    // read {} as "these anime have no relations": the franchise ledger claims
    // a full set offline, and the cascade stamps wrong standalone roots.
    if (ids.length > 0 && sawNetworkFailure && Object.keys(result).length === 0) {
      throw new Error("AniList relations request failed");
    }

    return result;
  }

  /** Background half of staleOk: re-fetch expired snapshots at low priority.
   *  resolveRelationChunk rewrites the SQLite snapshots as it goes, so the
   *  next walk simply finds them fresh. Deduped per id; failures are dropped
   *  because a stale snapshot already served and the TTL will retry later. */
  private async revalidateRelations(ids: number[]): Promise<void> {
    const todo = ids.filter((id) => !this.relationsRevalidating.has(id));
    if (todo.length === 0) return;
    for (const id of todo) this.relationsRevalidating.add(id);
    try {
      const sink: RelationMap = {};
      for (let i = 0; i < todo.length; i += RELATIONS_BATCH_SIZE) {
        const chunk = todo.slice(i, i + RELATIONS_BATCH_SIZE);
        await this.resolveRelationChunk(chunk, "low", sink);
        if (i + RELATIONS_BATCH_SIZE < todo.length) await delay(BATCH_SPACING_MS);
      }
    } catch (e) {
      console.warn("[anilist] background relation revalidation failed:", e);
    } finally {
      for (const id of todo) this.relationsRevalidating.delete(id);
    }
  }

  /**
   * Resolve one chunk of relation ids into `result`, caching as it goes.
   *
   * AniList nulls out the ENTIRE batch (and returns HTTP 404) if even one id is
   * not-found — and deleted/private nodes are common in real franchise graphs,
   * so a naive batch silently loses every co-batched valid id. We recover them
   * by binary-splitting a chunk that came back with nulls until the not-found
   * id is isolated to a size-1 request. Crucially we never cache a null as `[]`
   * for a multi-id chunk (that poisoned valid ids for the 6h TTL); an id is only
   * recorded as "no relations" once a lone request confirms it's genuinely
   * not-found.
   */
  private async resolveRelationChunk(
    chunk: number[],
    priority: Priority,
    result: RelationMap,
  ): Promise<boolean> {
    if (chunk.length === 0) return false;

    let data: Record<string, unknown>;
    try {
      data = await this.request<Record<string, unknown>>(
        buildRelationsBatchQuery(chunk),
        undefined,
        priority,
      );
    } catch (e) {
      // Network/server failure (not a per-id 404) — leave the whole chunk
      // unresolved and uncached so the next scan retries it. Reported back so
      // the caller can tell "nothing resolved because offline" from "no data".
      console.warn("[anilist] relations chunk request failed, skipping:", e);
      return true;
    }

    const missing: number[] = [];
    for (const id of chunk) {
      const media = data[`m${id}`];
      if (media != null) {
        const relations = mapRelations(media);
        result[id] = relations;
        void safeCache(() =>
          getDb().then((db) => db.setRelationSnapshot(id, relations)),
        );
      } else {
        missing.push(id);
      }
    }

    if (missing.length === 0) return false;

    if (missing.length === 1) {
      // A lone id that resolves to null is genuinely not-found — record empty
      // relations and cache it so we don't keep re-probing a dead node.
      const id = missing[0];
      result[id] = [];
      void safeCache(() =>
        getDb().then((db) => db.setRelationSnapshot(id, [])),
      );
      return false;
    }

    // ≥1 not-found id nulled the batch — split to isolate it and recover the
    // valid ids that came along for the ride.
    const mid = Math.ceil(missing.length / 2);
    await delay(BATCH_SPACING_MS);
    const failedLeft = await this.resolveRelationChunk(
      missing.slice(0, mid),
      priority,
      result,
    );
    await delay(BATCH_SPACING_MS);
    const failedRight = await this.resolveRelationChunk(
      missing.slice(mid),
      priority,
      result,
    );
    return failedLeft || failedRight;
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
          franchise_root_id: null,
          airing_status: (e.media.status as string) ?? null,
          episode_duration: (e.media.duration as number) ?? null,
          // AniList's `repeat` is exactly Konsou's rewatch_count: completed
          // prior watches.
          rewatch_count: (e.repeat as number) ?? 0,
          aired_episodes: airedEpisodes(e.media),
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
        franchise_root_id: null,
        airing_status: m.status ?? null,
        episode_duration: m.duration ?? null,
        rewatch_count: r.times_watched,
        aired_episodes: airedEpisodes(m),
        added_at: now,
        updated_at: now,
        started_at: r.started_at,
        completed_at: isDone ? r.finished_at : null,
      });
    }

    return { entries, unmatched, total: raw.length };
  }

  /**
   * Fetch current airing status + episode count for a batch of ids. Used by
   * the plan-to-watch airing scan to detect NOT_YET_RELEASED → RELEASING
   * transitions without going through the full relations machinery.
   */
  async getAiringStatusBatch(
    ids: number[],
    priority: Priority = "low",
  ): Promise<Map<number, AiringStatus>> {
    const result = new Map<number, AiringStatus>();
    let lastError: unknown = null;

    for (let i = 0; i < ids.length; i += RELATIONS_BATCH_SIZE) {
      const chunk = ids.slice(i, i + RELATIONS_BATCH_SIZE);
      try {
        const data = await this.request<Record<string, any>>(
          buildAiringStatusBatchQuery(chunk),
          undefined,
          priority,
        );
        for (const id of chunk) {
          const m = data[`m${id}`];
          if (!m) continue;
          result.set(id, {
            status: m.status as string,
            episodes: (m.episodes as number) ?? null,
            nextAiringAt: m.nextAiringEpisode?.airingAt ?? null,
            nextEpisode: m.nextAiringEpisode?.episode ?? null,
          });
        }
      } catch (err) {
        /* partial failure — skip the chunk, caller will retry next cycle */
        lastError = err;
      }
      if (i + RELATIONS_BATCH_SIZE < ids.length) await delay(BATCH_SPACING_MS);
    }

    // Partial results are still a success, but when every chunk died and
    // nothing came back the network is down; returning an empty map here
    // would make Schedule say "nothing airing" when the truth is "couldn't
    // check".
    if (result.size === 0 && ids.length > 0 && lastError) throw lastError;

    return result;
  }
}

export const anilist = new AniListClient();
