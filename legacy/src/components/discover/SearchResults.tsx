import { useMemo } from "react";
import { AnimeCollection } from "@/components/list/AnimeCollection";
import { EmptyState } from "@/components/ui/EmptyState";
import { Skeleton } from "@/components/ui/Skeleton";
import { Text } from "@/components/ui/Text";
import { useAniListSearch } from "@/hooks/useAniList";
import { entryToSummary } from "@/lib/format";
import { localFuzzySearch } from "@/lib/search/localTitleIndex";
import { useListStore } from "@/lib/store/listStore";

import type { ViewMode } from "@/types/list";

interface SearchResultsProps {
  /** Debounced query. The caller only mounts this once it is >= 2 chars. */
  query: string;
  /** Density inherited from the Discover view toggle. */
  view?: ViewMode;
}

/**
 * The results half of search: live AniList results, a loading grid, and the
 * offline fuzzy "did you mean" fallback. Lives under Discover's shared search
 * bar (search and browse are the same page).
 */
export function SearchResults({ query, view = "grid" }: SearchResultsProps) {
  const { results, isLoading, isError, hasNextPage, fetchNextPage } =
    useAniListSearch(query);

  const noResults = !isLoading && !isError && results.length === 0;
  // No live results to show: either the search came back empty, or it failed
  // (offline / network error). Both are cases where a local fallback helps.
  const noLiveResults = !isLoading && (isError || noResults);

  const suggestions = useMemo(() => {
    if (!noLiveResults) return [];
    const listSummaries = useListStore.getState().entries.map(entryToSummary);
    return localFuzzySearch(query, listSummaries);
  }, [noLiveResults, query]);

  if (isLoading) {
    return (
      <div className="k-skelgrid">
        {Array.from({ length: 9 }).map((_, i) => (
          <Skeleton key={i} height="auto" style={{ aspectRatio: "2 / 3" }} />
        ))}
      </div>
    );
  }

  if (noLiveResults) {
    if (suggestions.length > 0) {
      return (
        <div className="k-search__didyoumean">
          <div className="k-search__didyoumean-head">
            <Text size="sm" color="secondary">
              {isError
                ? "Can't reach search. From your library:"
                : `No exact match for "${query.trim()}". Did you mean:`}
            </Text>
          </div>
          <AnimeCollection
            items={suggestions}
            view={view}
            restoreKey="discover.suggest.scroll"
          />
        </div>
      );
    }
    return isError ? (
      <EmptyState
        title="Couldn't search right now"
        subtitle="Check your connection and try again."
      />
    ) : (
      <EmptyState title={`No results for "${query.trim()}"`} />
    );
  }

  return (
    <AnimeCollection
      items={results}
      view={view}
      onEndReached={hasNextPage ? () => fetchNextPage() : undefined}
      restoreKey="discover.search.scroll"
    />
  );
}
