import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useVirtualizer } from "@tanstack/react-virtual";
import { FranchiseCard } from "@/components/anime/FranchiseCard";
import { FranchiseSheet } from "@/components/anime/FranchiseSheet";
import { useBreakpoint } from "@/hooks/useMediaQuery";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { ViewMode } from "@/types/list";

interface FranchiseCollectionProps {
  groups: FranchiseGroup[];
  view: ViewMode;
  dimmedIds?: Set<number> | null;
  showStatus?: boolean;
}

const MIN_COL_WIDTH = 190;
const ROW_HEIGHT = { list: 72, compact: 48 };

export function FranchiseCollection({
  groups,
  view,
  dimmedIds,
}: FranchiseCollectionProps) {
  const navigate = useNavigate();
  const parentRef = useRef<HTMLDivElement>(null);
  const { isDesktop } = useBreakpoint();
  const gap = isDesktop ? 16 : 8;
  const [width, setWidth] = useState(() =>
    typeof window !== "undefined" ? window.innerWidth : 360,
  );
  const [activeRootId, setActiveRootId] = useState<number | null>(null);

  useEffect(() => {
    const el = parentRef.current;
    if (!el) return;
    const ro = new ResizeObserver((entries) =>
      setWidth(entries[0].contentRect.width),
    );
    ro.observe(el);
    setWidth(el.clientWidth);
    return () => ro.disconnect();
  }, []);

  const columns =
    view === "grid"
      ? Math.max(2, Math.min(7, Math.floor((width + gap) / (MIN_COL_WIDTH + gap))))
      : 1;

  const rowCount =
    view === "grid" ? Math.ceil(groups.length / columns) : groups.length;

  const rowHeight = useMemo(() => {
    if (view === "grid") {
      const cardW = (width - gap * (columns - 1)) / columns;
      return cardW * 1.5 + gap;
    }
    return ROW_HEIGHT[view];
  }, [view, width, columns, gap]);

  const virtualizer = useVirtualizer({
    count: rowCount,
    getScrollElement: () => parentRef.current,
    estimateSize: () => rowHeight,
    overscan: 6,
  });

  useEffect(() => { virtualizer.measure(); }, [rowHeight, columns, virtualizer]);

  const activeGroup =
    activeRootId != null
      ? (groups.find((g) => g.rootId === activeRootId) ?? null)
      : null;

  const dimOf = (rootId: number) =>
    dimmedIds && !dimmedIds.has(rootId) ? 0.2 : 1;

  const renderGroup = (group: FranchiseGroup) => (
    <FranchiseCard
      group={group}
      view={view}
      onOpen={() => setActiveRootId(group.rootId)}
    />
  );

  const virtualRows = virtualizer.getVirtualItems();

  return (
    <>
      <div ref={parentRef} className="k-collection konsou-scroll">
        <div
          className="k-collection__inner"
          style={{ height: virtualizer.getTotalSize() }}
        >
          {virtualRows.map((vRow) => {
            const top = vRow.start;
            if (view === "grid") {
              const startIdx = vRow.index * columns;
              const rowGroups = groups.slice(startIdx, startIdx + columns);
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
                  {rowGroups.map((group) => (
                    <div
                      key={group.rootId}
                      style={{
                        opacity: dimOf(group.rootId),
                        transition: "opacity 200ms var(--ease-out)",
                      }}
                    >
                      {renderGroup(group)}
                    </div>
                  ))}
                </div>
              );
            }
            const group = groups[vRow.index];
            return (
              <div
                key={vRow.key}
                className="k-collection__row"
                style={{
                  transform: `translateY(${top}px)`,
                  height: vRow.size,
                  opacity: dimOf(group.rootId),
                  transition: "opacity 200ms var(--ease-out)",
                }}
              >
                {renderGroup(group)}
              </div>
            );
          })}
        </div>
      </div>

      <FranchiseSheet
        group={activeGroup}
        open={activeGroup != null}
        onClose={() => setActiveRootId(null)}
        onNavigate={(id) => navigate(`/anime/${id}`)}
      />
    </>
  );
}
