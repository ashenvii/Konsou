import { ChevronDown, ChevronLeft } from "lucide-react";
import { AnimeCollection } from "@/components/list/AnimeCollection";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Skeleton } from "@/components/ui/Skeleton";
import { useDiscover } from "@/hooks/useAniList";
import { useDragScroll } from "@/hooks/useDragScroll";
import { formatLabel } from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { GENRES } from "./DiscoverFilterSheet";
import { browseActive, resolveSeason, seasonLabel, EMPTY_BROWSE } from "./lanes";
import type { BrowseState } from "./lanes";
import type { BrowseSort } from "@/lib/api/anilist/client";
import type { MediaFormat, MediaSeason } from "@/types/anime";

const SORTS: { v: BrowseSort; label: string }[] = [
  { v: "TRENDING_DESC", label: "Trending" },
  { v: "POPULARITY_DESC", label: "Popular" },
  { v: "SCORE_DESC", label: "Top Rated" },
];
const FORMATS: MediaFormat[] = ["TV", "TV_SHORT", "MOVIE", "SPECIAL", "OVA", "ONA"];
const SEASONS: MediaSeason[] = ["WINTER", "SPRING", "SUMMER", "FALL"];
const NOW_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: NOW_YEAR + 1 - 1960 + 1 }, (_, i) => NOW_YEAR + 1 - i);

interface DiscoverBrowseProps {
  state: BrowseState;
  onChange: (s: BrowseState) => void;
  /** The shared search keyword: applied alongside the filters so users can find
   *  a title AND narrow it in one query. */
  keyword: string;
  onBack: () => void;
}

interface Opt {
  value: string;
  label: string;
}
interface PillProps {
  /** Facet name shown when nothing is picked, e.g. "Genre". */
  placeholder: string;
  value: string;
  options: Opt[];
  /** Accent the pill as an applied filter. Off for Sort (always has a value but
   *  isn't a "filter"). */
  accent: boolean;
  onChange: (v: string) => void;
}

/** A native <select> dressed as a pill: opens the platform picker (great on
 *  mobile), stays accessible, and never needs a portal to escape clipping. The
 *  visible label reflects the current pick, or the facet name when unset. */
function Pill({ placeholder, value, options, accent, onChange }: PillProps) {
  const current = options.find((o) => o.value === value)?.label;
  const display = value !== "" && current ? current : placeholder;
  return (
    <label className={`k-fpill${accent && value !== "" ? " k-fpill--on" : ""}`}>
      <span className="k-fpill__label">{display}</span>
      <Icon icon={ChevronDown} size={14} className="k-fpill__chev" />
      <select
        className="k-fpill__select"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        aria-label={placeholder}
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>{o.label}</option>
        ))}
      </select>
    </label>
  );
}

/**
 * The all-anime filtered browse: an inline row of single-select controls
 * (Sort / Genre / Format / Season / Year) over a landing-grade cover grid. The
 * controls apply across everything and compose with the keyword, so it's one
 * "find any anime" surface — not filters trapped inside a curated section.
 */
export function DiscoverBrowse({ state, onChange, keyword, onBack }: DiscoverBrowseProps) {
  const pillsRef = useDragScroll<HTMLDivElement>();
  const defaultView = useSettingsStore((s) => s.defaultView);
  const seasonYear = state.season ? (state.year ?? resolveSeason(0).year) : undefined;

  const { results, isLoading, isError, hasNextPage, fetchNextPage, refetch } = useDiscover({
    sort: state.sort,
    search: keyword,
    genres: state.genre ? [state.genre] : undefined,
    formats: state.format ? [state.format] : undefined,
    season: state.season ?? undefined,
    seasonYear,
    yearFrom: !state.season && state.year ? state.year : undefined,
    yearTo: !state.season && state.year ? state.year : undefined,
  });

  const active = browseActive(state);
  const set = (patch: Partial<BrowseState>) => onChange({ ...state, ...patch });

  const kw = keyword.trim();

  return (
    <div className="k-browse">
      <div className="k-browse__bar">
        <button
          type="button"
          className="k-discover__back k-browse__back"
          onClick={onBack}
          aria-label="Back to Discover"
        >
          <Icon icon={ChevronLeft} size={18} />
          <span>Discover</span>
        </button>

        <div ref={pillsRef} className="k-fpills">
          <Pill
            placeholder="Sort"
            value={state.sort}
            accent={false}
            options={SORTS.map((s) => ({ value: s.v, label: s.label }))}
            onChange={(v) => set({ sort: v as BrowseSort })}
          />
          <Pill
            placeholder="Genre"
            value={state.genre ?? ""}
            accent
            options={[{ value: "", label: "Any genre" }, ...GENRES.map((g) => ({ value: g, label: g }))]}
            onChange={(v) => set({ genre: v || null })}
          />
          <Pill
            placeholder="Format"
            value={state.format ?? ""}
            accent
            options={[
              { value: "", label: "Any format" },
              ...FORMATS.map((f) => ({ value: f, label: formatLabel(f) ?? f })),
            ]}
            onChange={(v) => set({ format: (v || null) as MediaFormat | null })}
          />
          <Pill
            placeholder="Season"
            value={state.season ?? ""}
            accent
            options={[
              { value: "", label: "Any season" },
              ...SEASONS.map((s) => ({ value: s, label: seasonLabel(s) })),
            ]}
            onChange={(v) => set({ season: (v || null) as MediaSeason | null })}
          />
          <Pill
            placeholder="Year"
            value={state.year ? String(state.year) : ""}
            accent
            options={[
              { value: "", label: "Any year" },
              ...YEARS.map((y) => ({ value: String(y), label: String(y) })),
            ]}
            onChange={(v) => set({ year: v ? Number(v) : null })}
          />
          {active && (
            <button
              type="button"
              className="k-browse__clear"
              onClick={() => set({ ...EMPTY_BROWSE, sort: state.sort })}
            >
              Clear
            </button>
          )}
        </div>
      </div>

      {isLoading ? (
        <div className="k-skelgrid">
          {Array.from({ length: 12 }).map((_, i) => (
            <Skeleton key={i} height="auto" style={{ aspectRatio: "2 / 3" }} />
          ))}
        </div>
      ) : isError ? (
        <EmptyState
          title="Couldn't load results"
          subtitle="Konsou can't reach AniList right now."
          action={
            <Button size="sm" variant="primary" onClick={() => void refetch()}>
              Try again
            </Button>
          }
        />
      ) : results.length === 0 ? (
        <EmptyState
          title={kw ? `No matches for "${kw}"` : "Nothing matches these filters"}
          subtitle="Try loosening a filter or a different search."
        />
      ) : (
        <AnimeCollection
          items={results}
          view={defaultView}
          onEndReached={hasNextPage ? () => fetchNextPage() : undefined}
          restoreKey="discover.browse.scroll"
        />
      )}
    </div>
  );
}
