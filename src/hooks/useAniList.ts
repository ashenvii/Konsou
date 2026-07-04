import { useEffect, useRef } from "react";
import { useInfiniteQuery, useQuery, useQueryClient } from "@tanstack/react-query";
import { anilist } from "@/lib/api/anilist/client";
import { indexSummaries } from "@/lib/search/localTitleIndex";
import type { AiringStatus, BrowseSort, SearchPage } from "@/lib/api/anilist/client";
import type { AnimeSummary, MediaSeason } from "@/types/anime";

const FIVE_MIN = 5 * 60 * 1000;

function flatten(pages: SearchPage[] | undefined): AnimeSummary[] {
  return pages?.flatMap((p) => p.results) ?? [];
}

/** Debounced search (caller passes an already-debounced query). */
export function useAniListSearch(query: string) {
  const queryClient = useQueryClient();
  const enabled = query.trim().length >= 2;
  const normalized = query.trim().toLowerCase();

  // Abort the in-flight search for the previous query string the moment the user
  // types more. Without this, a superseded search (and its Jikan + AniList
  // rehydrate fan-out) keeps draining the shared rate limiter, which is what made
  // typing a long title feel sluggish.
  const prevKey = useRef<string | null>(null);
  useEffect(() => {
    const prev = prevKey.current;
    if (prev !== null && prev !== normalized) {
      void queryClient.cancelQueries({ queryKey: ["search", prev], exact: true });
    }
    prevKey.current = normalized;
  }, [normalized, queryClient]);

  const q = useInfiniteQuery({
    queryKey: ["search", normalized],
    queryFn: ({ pageParam, signal }) => anilist.search(query, pageParam, signal),
    initialPageParam: 1,
    getNextPageParam: (last) => (last.hasNextPage ? last.page + 1 : undefined),
    enabled,
    staleTime: FIVE_MIN,
    networkMode: "offlineFirst",
  });

  // Feed results into the local title index so the offline "did you mean"
  // fallback can re-find them later, even from a typo.
  useEffect(() => {
    const items = flatten(q.data?.pages);
    if (items.length) indexSummaries(items);
  }, [q.data]);

  return {
    results: flatten(q.data?.pages),
    isLoading: enabled && q.isLoading,
    isError: q.isError,
    error: q.error,
    hasNextPage: q.hasNextPage,
    isFetchingNextPage: q.isFetchingNextPage,
    fetchNextPage: q.fetchNextPage,
    enabled,
  };
}

export interface DiscoverParams {
  sort: BrowseSort;
  season?: MediaSeason;
  seasonYear?: number;
  genre?: string;
  /** AniList tag name (themes like "Isekai" are tags, not genres). */
  tag?: string;
}

export function useDiscover(params: DiscoverParams) {
  const q = useInfiniteQuery({
    queryKey: [
      "discover",
      params.sort,
      params.season ?? null,
      params.seasonYear ?? null,
      params.genre ?? null,
      params.tag ?? null,
    ],
    queryFn: ({ pageParam }) => anilist.browse({ ...params, page: pageParam }),
    initialPageParam: 1,
    getNextPageParam: (last) => (last.hasNextPage ? last.page + 1 : undefined),
    staleTime: FIVE_MIN,
    networkMode: "offlineFirst",
  });

  // Browsing also seeds the offline "did you mean" corpus.
  useEffect(() => {
    const items = flatten(q.data?.pages);
    if (items.length) indexSummaries(items);
  }, [q.data]);

  return {
    results: flatten(q.data?.pages),
    isLoading: q.isLoading,
    isError: q.isError,
    hasNextPage: q.hasNextPage,
    isFetchingNextPage: q.isFetchingNextPage,
    fetchNextPage: q.fetchNextPage,
    refetch: q.refetch,
    isRefetching: q.isRefetching,
  };
}

/**
 * Live airing status + next-episode timestamp for the user's tracked ids,
 * powering the Schedule page. Cached 30m; serves stale offline so the calendar
 * still renders without a network round-trip.
 */
export function useAiringSchedule(ids: number[], enabled = true) {
  const key = [...ids].sort((a, b) => a - b).join(",");
  return useQuery({
    queryKey: ["airing-schedule", key],
    queryFn: async () => {
      const map = await anilist.getAiringStatusBatch(ids, "high");
      const out: Record<number, AiringStatus> = {};
      for (const [id, info] of map) out[id] = info;
      return out;
    },
    enabled: enabled && ids.length > 0,
    staleTime: 30 * 60 * 1000,
    networkMode: "offlineFirst",
  });
}

export function useAnimeDetail(id: number | null) {
  return useQuery({
    queryKey: ["detail", id],
    queryFn: () => anilist.getById(id!),
    enabled: id != null,
    staleTime: 24 * 60 * 60 * 1000,
    networkMode: "offlineFirst",
  });
}

/**
 * Fetch relations for a set of tracked entry ids and return the union.
 * Used by FranchiseSheet so untracked sequels/movies that are only direct
 * relations of S2+ (not of S1) still surface in the "Related" section.
 */
export function useFranchiseRelations(ids: number[], enabled: boolean) {
  const key = [...ids].sort().join(",");
  return useQuery({
    queryKey: ["franchise-relations", key],
    queryFn: () => anilist.getRelationsBatch(ids, "high"),
    enabled: enabled && ids.length > 0,
    staleTime: 6 * 60 * 60 * 1000,
    networkMode: "offlineFirst",
  });
}
