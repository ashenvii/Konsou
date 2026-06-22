import { useInfiniteQuery, useQuery } from "@tanstack/react-query";
import { anilist } from "@/lib/api/anilist/client";
import type { BrowseSort, SearchPage } from "@/lib/api/anilist/client";
import type { AnimeSummary, MediaSeason } from "@/types/anime";

const FIVE_MIN = 5 * 60 * 1000;

function flatten(pages: SearchPage[] | undefined): AnimeSummary[] {
  return pages?.flatMap((p) => p.results) ?? [];
}

/** Debounced search (caller passes an already-debounced query). */
export function useAniListSearch(query: string) {
  const enabled = query.trim().length >= 2;
  const q = useInfiniteQuery({
    queryKey: ["search", query.trim().toLowerCase()],
    queryFn: ({ pageParam }) => anilist.search(query, pageParam),
    initialPageParam: 1,
    getNextPageParam: (last) => (last.hasNextPage ? last.page + 1 : undefined),
    enabled,
    staleTime: FIVE_MIN,
    networkMode: "offlineFirst",
  });
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
}

export function useDiscover(params: DiscoverParams) {
  const q = useInfiniteQuery({
    queryKey: [
      "discover",
      params.sort,
      params.season ?? null,
      params.seasonYear ?? null,
      params.genre ?? null,
    ],
    queryFn: ({ pageParam }) => anilist.browse({ ...params, page: pageParam }),
    initialPageParam: 1,
    getNextPageParam: (last) => (last.hasNextPage ? last.page + 1 : undefined),
    staleTime: FIVE_MIN,
    networkMode: "offlineFirst",
  });
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

export function useAnimeDetail(id: number | null) {
  return useQuery({
    queryKey: ["detail", id],
    queryFn: () => anilist.getById(id!),
    enabled: id != null,
    staleTime: 24 * 60 * 60 * 1000,
    networkMode: "offlineFirst",
  });
}
