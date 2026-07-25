import { useEffect, useRef, useState } from "react";
import { useLocation } from "react-router-dom";
import { Search as SearchIcon, SlidersHorizontal, X } from "lucide-react";
import { SearchResults } from "@/components/discover/SearchResults";
import { DiscoverLanding } from "@/components/discover/DiscoverLanding";
import { DiscoverBrowse } from "@/components/discover/DiscoverBrowse";
import { EMPTY_BROWSE, browseActive } from "@/components/discover/lanes";
import type { BrowseState, Lane } from "@/components/discover/lanes";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { useDebounce } from "@/hooks/useDebounce";
import { useSearchStore } from "@/lib/store/searchStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { getUiState, setUiState } from "@/lib/uiState";
import { registerSheet } from "@/lib/sheetStack";

const EXAMPLE_CHIPS = ["Attack on Titan", "Frieren", "One Piece", "Bocchi"];

/**
 * Discover is one surface with three modes:
 *   - landing  (default): a spotlight over editorial lanes — the graze view
 *   - browse   (filters):  the all-anime inline-filter browse, opened from the
 *              search bar's Filter button or a lane's "See all"; the keyword
 *              composes with the filters
 *   - search   (keyword):  quick title lookup while just typing
 *
 * Browse and search are internal state, not routes. Each is registered on the
 * shared sheet stack while active, so hardware/edge/mouse back pops it before
 * leaving the Discover tab.
 */
export function Discover() {
  const location = useLocation();
  const inputRef = useRef<HTMLInputElement>(null);

  // ── Search (field on the page, state shared through the store) ──
  const value = useSearchStore((s) => s.query);
  const setValue = useSearchStore((s) => s.setQuery);
  const searching = useSearchStore((s) => s.searching);
  const setSearching = useSearchStore((s) => s.setSearching);
  const debouncedQuery = useDebounce(value, 400);

  const defaultView = useSettingsStore((s) => s.defaultView);
  const recent = useSettingsStore((s) => s.recentSearches);
  const addRecent = useSettingsStore((s) => s.addRecentSearch);
  const removeRecent = useSettingsStore((s) => s.removeRecentSearch);

  // ── Browse (inline filters over all anime) ──────────────────
  const [browsing, setBrowsingState] = useState(() => getUiState("discover.browsing", false));
  const [browse, setBrowseState] = useState<BrowseState>(() =>
    getUiState<BrowseState>("discover.browse", EMPTY_BROWSE),
  );

  const setBrowsing = (b: boolean) => {
    setBrowsingState(b);
    setUiState("discover.browsing", b);
  };
  const setBrowse = (s: BrowseState) => {
    setBrowseState(s);
    setUiState("discover.browse", s);
  };

  // While browsing, the keyword refines the filtered results (not a separate
  // quick-search view). Otherwise a typed keyword opens quick search.
  const searchMode = !browsing && debouncedQuery.trim().length >= 2;
  const showRecents = !browsing && searching && !searchMode;

  // Arriving from a "Search for anime" CTA opens search and focuses the field.
  // The door may carry the words the user already typed (My List's no-match
  // handoff), so the title they just searched for never needs retyping.
  useEffect(() => {
    const intent = location.state as
      | { fromSearchIntent?: boolean; query?: string }
      | null;
    if (intent?.fromSearchIntent) {
      if (intent.query) setValue(intent.query);
      setSearching(true);
      inputRef.current?.focus();
    }
  }, [location.state, setSearching, setValue]);

  const runChip = (q: string) => {
    setValue(q);
    addRecent(q);
    setSearching(true);
  };

  // "See all" on a lane opens the browse pre-narrowed to that lane.
  const enterBrowse = (lane: Lane) => {
    setBrowse(lane.seeAll);
    setBrowsing(true);
  };

  // Back-stack: register the right closer for whichever mode is on top.
  useEffect(() => {
    if (browsing) {
      return registerSheet(() => setBrowsing(false));
    }
    if (searching) {
      return registerSheet(() => {
        setValue("");
        setSearching(false);
        inputRef.current?.blur();
      });
    }
  }, [browsing, searching, setValue, setSearching]);

  const filterOn = browsing || browseActive(browse);

  return (
    <div className="k-page k-discover">
      <div className="k-search__bar">
        <div className="k-hsearch">
          <Icon icon={SearchIcon} size={18} color="var(--color-text-tertiary)" />
          <input
            ref={inputRef}
            className="k-hsearch__input"
            type="search"
            inputMode="search"
            enterKeyHint="search"
            placeholder={browsing ? "Add a keyword…" : "Search any anime…"}
            value={value}
            onChange={(e) => {
              setValue(e.target.value);
              if (!browsing) setSearching(true);
            }}
            onFocus={() => {
              if (!browsing) setSearching(true);
            }}
            onBlur={() => {
              if (value.trim().length === 0) setSearching(false);
            }}
            onKeyDown={(e) => {
              if (e.key === "Enter" && value.trim().length >= 2) {
                addRecent(value);
                inputRef.current?.blur();
              }
            }}
            aria-label="Search anime"
          />
          {value && (
            <button
              type="button"
              className="k-hsearch__clear"
              onClick={() => setValue("")}
              aria-label="Clear search"
            >
              <Icon icon={X} size={16} />
            </button>
          )}
        </div>

        {searching && !browsing ? (
          <button
            type="button"
            className="k-search__cancel"
            onClick={() => {
              setValue("");
              setSearching(false);
              inputRef.current?.blur();
            }}
          >
            Cancel
          </button>
        ) : (
          <button
            type="button"
            className={`k-icon-btn k-discover__filterbtn-ico${filterOn ? " k-discover__filterbtn-ico--on" : ""}`}
            onClick={() => setBrowsing(!browsing)}
            aria-label={browsing ? "Close filters" : "Filter all anime"}
            aria-pressed={browsing}
            title="Filters"
          >
            <Icon icon={SlidersHorizontal} size={18} />
          </button>
        )}
      </div>

      {browsing ? (
        <DiscoverBrowse
          state={browse}
          onChange={setBrowse}
          keyword={debouncedQuery}
          onBack={() => setBrowsing(false)}
        />
      ) : searchMode ? (
        <SearchResults query={debouncedQuery} view={defaultView} />
      ) : showRecents ? (
        // preventDefault on mousedown keeps the input focused while tapping a
        // chip; without it the blur empties `searching`, the panel unmounts
        // between mousedown and click, and the tap lands on nothing.
        <div
          className="k-search__suggest konsou-scroll"
          onMouseDown={(e) => e.preventDefault()}
        >
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
            </>
          )}
        </div>
      ) : (
        <DiscoverLanding onSeeAll={enterBrowse} />
      )}
    </div>
  );
}
