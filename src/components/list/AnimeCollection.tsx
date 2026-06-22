import { useEffect, useMemo, useRef, useState } from "react";
import { useVirtualizer } from "@tanstack/react-virtual";
import { AnimeCard } from "@/components/anime/AnimeCard";
import { useBreakpoint } from "@/hooks/useMediaQuery";
import type { AnimeSummary } from "@/types/anime";
import type { ViewMode } from "@/types/list";

interface AnimeCollectionProps {
  items: AnimeSummary[];
  view: ViewMode;
  /** DIM-style in-place search: matching ids stay bright, others dim to 0.2. */
  dimmedIds?: Set<number> | null;
  /** Show the user's tracking status on each card, useful for the all view. */
  showStatus?: boolean;
  onEndReached?: () => void;
}

const MIN_COL_WIDTH = 190;
const ROW_HEIGHT = { list: 72, compact: 48 };

export function AnimeCollection({
  items,
  view,
  dimmedIds,
  showStatus = false,
  onEndReached,
}: AnimeCollectionProps) {
  const parentRef = useRef<HTMLDivElement>(null);
  const { isDesktop } = useBreakpoint();
  const gap = isDesktop ? 16 : 8;
  // Seed a sane width so the first paint isn't a zero-height stack; the
  // ResizeObserver refines it once the container has measured.
  const [width, setWidth] = useState(() =>
    typeof window !== "undefined" ? window.innerWidth : 360,
  );

  useEffect(() => {
    const el = parentRef.current;
    if (!el) return;
    const ro = new ResizeObserver((entries) => {
      setWidth(entries[0].contentRect.width);
    });
    ro.observe(el);
    setWidth(el.clientWidth);
    return () => ro.disconnect();
  }, []);

  const columns =
    view === "grid"
      ? Math.max(2, Math.min(7, Math.floor((width + gap) / (MIN_COL_WIDTH + gap))))
      : 1;

  const rowCount =
    view === "grid" ? Math.ceil(items.length / columns) : items.length;

  const rowHeight = useMemo(() => {
    if (view === "grid") {
      const cardW = (width - gap * (columns - 1)) / columns;
      return cardW * 1.5 + gap; // 2:3 cover + row gap
    }
    return ROW_HEIGHT[view];
  }, [view, width, columns, gap]);

  const virtualizer = useVirtualizer({
    count: rowCount,
    getScrollElement: () => parentRef.current,
    estimateSize: () => rowHeight,
    overscan: 6,
  });

  // Re-measure when the row height changes (width/column/view change) so cached
  // row offsets don't keep an early estimate.
  useEffect(() => {
    virtualizer.measure();
  }, [rowHeight, columns, virtualizer]);

  // Pagination trigger.
  const virtualRows = virtualizer.getVirtualItems();
  useEffect(() => {
    if (!onEndReached) return;
    const last = virtualRows[virtualRows.length - 1];
    if (last && last.index >= rowCount - 2 && rowCount > 0) onEndReached();
  }, [virtualRows, rowCount, onEndReached]);

  const dimOf = (id: number) =>
    dimmedIds && !dimmedIds.has(id) ? 0.2 : 1;

  return (
    <div ref={parentRef} className="k-collection konsou-scroll">
      <div
        className="k-collection__inner"
        style={{ height: virtualizer.getTotalSize() }}
      >
        {virtualRows.map((vRow) => {
          const top = vRow.start;
          if (view === "grid") {
            const startIdx = vRow.index * columns;
            const rowItems = items.slice(startIdx, startIdx + columns);
            return (
              <div
                key={vRow.key}
                className="k-collection__row k-collection__grid"
                style={{
                  transform: `translateY(${top}px)`,
                  gridTemplateColumns: `repeat(${columns}, 1fr)`,
                  gap,
                  paddingBottom: gap,
                }}
              >
                {rowItems.map((item) => (
                  <div
                    key={item.id}
                    style={{
                      opacity: dimOf(item.id),
                      transition: "opacity 200ms var(--ease-out)",
                    }}
                  >
                    <AnimeCard media={item} view="grid" showStatus={showStatus} />
                  </div>
                ))}
              </div>
            );
          }
          const item = items[vRow.index];
          return (
            <div
              key={vRow.key}
              className="k-collection__row"
              style={{
                transform: `translateY(${top}px)`,
                height: vRow.size,
                opacity: dimOf(item.id),
                transition: "opacity 200ms var(--ease-out)",
              }}
            >
              <AnimeCard media={item} view={view} showStatus={showStatus} />
            </div>
          );
        })}
      </div>
    </div>
  );
}
