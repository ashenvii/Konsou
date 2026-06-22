import { useEffect, useRef, useState } from "react";
import { useLocation } from "react-router-dom";
import { MagnifyingGlass, X } from "@phosphor-icons/react";
import { AnimeCollection } from "@/components/list/AnimeCollection";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Skeleton } from "@/components/ui/Skeleton";
import { Text } from "@/components/ui/Text";
import { useAniListSearch } from "@/hooks/useAniList";
import { useDebounce } from "@/hooks/useDebounce";
import { useSettingsStore } from "@/lib/store/settingsStore";

const EXAMPLE_CHIPS = ["Attack on Titan", "Frieren", "One Piece", "Bocchi"];

export function Search() {
  const location = useLocation();
  const inputRef = useRef<HTMLInputElement>(null);
  const [value, setValue] = useState("");
  const debounced = useDebounce(value, 400);

  const recent = useSettingsStore((s) => s.recentSearches);
  const addRecent = useSettingsStore((s) => s.addRecentSearch);
  const removeRecent = useSettingsStore((s) => s.removeRecentSearch);

  const { results, isLoading, isError, hasNextPage, fetchNextPage, enabled } =
    useAniListSearch(debounced);

  useEffect(() => {
    if ((location.state as { fromSearchIntent?: boolean } | null)?.fromSearchIntent) {
      inputRef.current?.focus();
    }
  }, [location.state]);

  const runChip = (q: string) => {
    setValue(q);
    addRecent(q);
    inputRef.current?.focus();
  };

  const showEmptyState = !enabled;
  const noResults = enabled && !isLoading && !isError && results.length === 0;

  return (
    <div className="k-page k-search">
      <div className="k-search__bar">
        <div className="k-searchbar">
          <Icon icon={MagnifyingGlass} size={18} color="var(--color-text-tertiary)" />
          <input
            ref={inputRef}
            className="k-searchbar__input"
            type="search"
            inputMode="search"
            enterKeyHint="search"
            placeholder="Search any anime…"
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && value.trim().length >= 2) addRecent(value);
            }}
            aria-label="Search anime"
          />
          {value && (
            <button
              type="button"
              className="k-searchbar__clear"
              onClick={() => setValue("")}
              aria-label="Clear search"
            >
              <Icon icon={X} size={16} />
            </button>
          )}
        </div>
      </div>

      {showEmptyState ? (
        <div className="k-search__suggest konsou-scroll">
          {recent.length > 0 ? (
            <>
              <Text size="sm" color="secondary" className="k-search__sectiontitle">
                Recent
              </Text>
              <div className="k-chiprow">
                {recent.map((q) => (
                  <Chip key={q} onClick={() => runChip(q)} onRemove={() => removeRecent(q)}>
                    {q}
                  </Chip>
                ))}
              </div>
            </>
          ) : (
            <>
              <Text size="sm" color="secondary" className="k-search__sectiontitle">
                Try searching
              </Text>
              <div className="k-chiprow">
                {EXAMPLE_CHIPS.map((q) => (
                  <Chip key={q} onClick={() => runChip(q)}>
                    {q}
                  </Chip>
                ))}
              </div>
              <Text size="sm" color="tertiary" style={{ marginTop: "var(--space-6)" }}>
                Add any anime to your list without scoring it.
              </Text>
            </>
          )}
        </div>
      ) : isLoading ? (
        <div className="k-skelgrid">
          {Array.from({ length: 9 }).map((_, i) => (
            <Skeleton key={i} height="auto" style={{ aspectRatio: "2 / 3" }} />
          ))}
        </div>
      ) : isError ? (
        <EmptyState
          title="Couldn't search right now"
          subtitle="Check your connection and try again."
        />
      ) : noResults ? (
        <EmptyState title={`No results for "${debounced.trim()}"`} />
      ) : (
        <AnimeCollection
          items={results}
          view="grid"
          onEndReached={hasNextPage ? () => fetchNextPage() : undefined}
        />
      )}
    </div>
  );
}
