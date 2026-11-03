import { ChevronRight } from "lucide-react";
import { AnimeCard } from "@/components/anime/AnimeCard";
import { Icon } from "@/components/ui/Icon";
import { useDiscover } from "@/hooks/useAniList";
import { useDragScroll } from "@/hooks/useDragScroll";
import type { Lane } from "./lanes";

interface DiscoverRowProps {
  lane: Lane;
  /** Skip this id — it's already featured in the spotlight above. */
  excludeId?: number;
  onSeeAll: (lane: Lane) => void;
}

// One row shows the head of a lane; the grid is where you go deep.
const ROW_LIMIT = 14;
const SKELETON_COUNT = 8;

/**
 * A single editorial lane: a horizontal strip of covers under a quiet header.
 * Owns its own query so one lane failing (or being empty) never takes the rest
 * of the landing down with it:
 *   - loading  → shimmer strip
 *   - error    → a compact inline "Retry" (a visible recovery beats a vanished
 *                row for a transient blip)
 *   - empty    → render nothing (a genre with no current results just drops)
 */
export function DiscoverRow({ lane, excludeId, onSeeAll }: DiscoverRowProps) {
  const { results, isLoading, isError, refetch, isRefetching } = useDiscover(lane.params);
  // Desktop needs help reaching off-screen covers: wheel scrolls the rail
  // sideways, drag pans it, and a real drag swallows the card tap it lands on.
  const scrollerRef = useDragScroll<HTMLDivElement>();

  const items = results
    .filter((m) => m.id !== excludeId)
    .slice(0, ROW_LIMIT);

  // Loaded clean but nothing to show: drop the lane rather than show an empty shelf.
  if (!isLoading && !isError && items.length === 0) return null;

  return (
    <section className="k-lane" aria-label={lane.title}>
      <header className="k-lane__head">
        <h2 className="k-lane__title">{lane.title}</h2>
        {!isError && (
          <button
            type="button"
            className="k-lane__seeall"
            onClick={() => onSeeAll(lane)}
          >
            See all
            <Icon icon={ChevronRight} size={15} />
          </button>
        )}
      </header>

      {isError ? (
        <div className="k-lane__error">
          <span>Couldn't load this row.</span>
          <button
            type="button"
            className="k-lane__retry"
            onClick={() => void refetch()}
            disabled={isRefetching}
          >
            {isRefetching ? "Retrying…" : "Retry"}
          </button>
        </div>
      ) : (
        <div ref={scrollerRef} className="k-lane__scroller">
          {isLoading
            ? Array.from({ length: SKELETON_COUNT }).map((_, i) => (
                <div key={i} className="k-lane__item k-lane__skel" aria-hidden />
              ))
            : items.map((media) => (
                <div key={media.id} className="k-lane__item">
                  <AnimeCard media={media} view="grid" />
                </div>
              ))}
        </div>
      )}
    </section>
  );
}
