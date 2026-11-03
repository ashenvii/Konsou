import { useEffect, useMemo, useRef } from "react";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { useDiscover } from "@/hooks/useAniList";
import { getUiState, setUiState } from "@/lib/uiState";
import { DiscoverRow } from "./DiscoverRow";
import { DiscoverSpotlight, SpotlightSkeleton } from "./DiscoverSpotlight";
import { buildLanes } from "./lanes";
import type { Lane } from "./lanes";

interface DiscoverLandingProps {
  /** Drill into the Browse-all grid pre-loaded with a lane's sort + filters. */
  onSeeAll: (lane: Lane) => void;
}

const SCROLL_KEY = "discover.landing.scroll";

/**
 * The default Discover view: a spotlight over a stack of editorial lanes. Built
 * to graze — several axes visible at once — instead of forcing a single tab
 * choice that dead-ends in one wall of covers.
 *
 * The spotlight source (this season's lead, falling back to trending) is fetched
 * here and shared by cache with the matching rows below, so featuring a title
 * costs no extra request. Each row owns its own query, so one lane failing never
 * blanks the page; only a total wipe (both primary queries down, no cache) shows
 * the offline state.
 */
export function DiscoverLanding({ onSeeAll }: DiscoverLandingProps) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const lanes = useMemo(() => buildLanes(), []);

  const season = useDiscover(lanes[0].params);
  const trending = useDiscover(lanes[1].params);

  const spotlight = season.results[0] ?? trending.results[0] ?? null;
  const spotlightLoading = !spotlight && (season.isLoading || trending.isLoading);
  const totalFailure = !spotlight && season.isError && trending.isError;

  // Restore the vertical scroll offset so returning from a detail page lands
  // where the user left off.
  useEffect(() => {
    const el = scrollRef.current;
    if (!el) return;
    el.scrollTop = getUiState(SCROLL_KEY, 0);
    const onScroll = () => setUiState(SCROLL_KEY, el.scrollTop);
    el.addEventListener("scroll", onScroll, { passive: true });
    return () => el.removeEventListener("scroll", onScroll);
  }, []);

  if (totalFailure) {
    return (
      <EmptyState
        title="Couldn't load Discover"
        subtitle="Konsou can't reach AniList right now. Your list still works offline."
        action={
          <Button
            size="sm"
            variant="primary"
            onClick={() => {
              void season.refetch();
              void trending.refetch();
            }}
          >
            Try again
          </Button>
        }
      />
    );
  }

  return (
    <div ref={scrollRef} className="k-dl konsou-scroll">
      <div className="k-dl__inner">
        {spotlightLoading ? (
          <SpotlightSkeleton />
        ) : spotlight ? (
          <DiscoverSpotlight media={spotlight} />
        ) : null}

        {lanes.map((lane) => (
          <DiscoverRow
            key={lane.key}
            lane={lane}
            excludeId={spotlight?.id}
            onSeeAll={onSeeAll}
          />
        ))}
      </div>
    </div>
  );
}
