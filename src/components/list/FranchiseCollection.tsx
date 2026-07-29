import { useEffect, useMemo, useRef, useState } from "react";
import type { MutableRefObject, PointerEvent as ReactPointerEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useVirtualizer } from "@tanstack/react-virtual";
import { FranchiseCard } from "@/components/anime/FranchiseCard";
import { FranchiseSheet } from "@/components/anime/FranchiseSheet";
import { HeroCard } from "@/components/anime/HeroBinge";
import { QueueCard } from "@/components/anime/QueueSlider";
import { useBreakpoint } from "@/hooks/useMediaQuery";
import { getUiState, setUiState } from "@/lib/uiState";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { ViewMode } from "@/types/list";

/**
 * A room's card language. Each mirrors the matching overview section so
 * drilling in from the overview stays visually continuous, while still riding
 * this component's virtualizer (rooms have to survive 4000+ entries).
 */
export type RoomVariant = "hero" | "poster";

interface FranchiseCollectionProps {
  groups: FranchiseGroup[];
  view: ViewMode;
  /** The room's themed card, used while `view` is "grid"; list/compact win. */
  variant?: RoomVariant;
  /** Up Next only: rerank a card one slot either way. */
  onMove?: (rootId: number, dir: -1 | 1) => void;
  /** Plan room: open the watch-order number picker for a card. */
  onNumber?: (rootId: number) => void;
  /** rootId -> stamped number, for the cards that carry one. */
  planNumbers?: Map<number, number>;
  /** Press-and-hold a card to append it to the watch order. */
  onQuickAdd?: (rootId: number) => boolean;
  dimmedIds?: Set<number> | null;
  showStatus?: boolean;
  /** Save/restore the scroll offset under this key across unmounts. */
  restoreKey?: string;
  /**
   * Filled with a "jump the list to this group index" function while mounted.
   * The virtualizer owns the row maths (and the column count that turns a group
   * index into a row), so the index rail asks it rather than guessing offsets.
   */
  jumpRef?: MutableRefObject<((groupIndex: number) => void) | null>;
}

const MIN_COL_WIDTH = 190;
const ROW_HEIGHT = { list: 84, compact: 54 };

/** Min column width and a sane column cap per room card. */
const VARIANT_COL: Record<RoomVariant, { min: number; max: number }> = {
  hero: { min: 400, max: 2 },
  poster: { min: 150, max: 8 },
};
const HERO_ROW_H = 140;
const POSTER_TITLE_H = 38;

export function FranchiseCollection({
  groups,
  view,
  variant: roomVariant,
  onMove,
  onNumber,
  planNumbers,
  onQuickAdd,
  dimmedIds,
  restoreKey,
  jumpRef,
}: FranchiseCollectionProps) {
  // The themed room card is that room's GRID language. When the user's view
  // mode says list or compact, the mode wins; before this gate the variant
  // silently overrode the setting everywhere, leaving it dead.
  const variant = view === "grid" ? roomVariant : undefined;
  const navigate = useNavigate();
  const parentRef = useRef<HTMLDivElement>(null);
  const { isDesktop } = useBreakpoint();
  const gap = isDesktop ? 16 : 8;
  const [width, setWidth] = useState(() =>
    typeof window !== "undefined" ? window.innerWidth : 360,
  );
  const [activeRootId, setActiveRootId] = useState<number | null>(null);
  // The popover points at the card you clicked, so the collection has to know
  // WHICH element that was. Recording it on the way down (capture) keeps every
  // card's onOpen signature as it is — they only ever knew their rootId.
  const pressedCard = useRef<HTMLElement | null>(null);
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const notePressedCard = (e: ReactPointerEvent) => {
    const el = e.target as HTMLElement | null;
    pressedCard.current =
      (el?.closest(".k-qcard, .k-card, .k-hero") as HTMLElement | null) ?? null;
  };
  const openCard = (rootId: number) => {
    setAnchorEl(pressedCard.current);
    setActiveRootId(rootId);
  };

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

  // Every room card lays out as a grid; only the plain list/compact views are
  // single-column.
  const isGrid = variant != null || view === "grid";

  const columns = variant
    ? Math.max(
        1,
        Math.min(
          VARIANT_COL[variant].max,
          Math.floor((width + gap) / (VARIANT_COL[variant].min + gap)),
        ),
      )
    : view === "grid"
      ? Math.max(2, Math.min(7, Math.floor((width + gap) / (MIN_COL_WIDTH + gap))))
      : 1;

  const rowCount = isGrid ? Math.ceil(groups.length / columns) : groups.length;

  const rowHeight = useMemo(() => {
    const cardW = (width - gap * (columns - 1)) / columns;
    // Hero is a fixed-height landscape card; the poster/shelf cards are 2:3
    // art plus their title line.
    if (variant === "hero") return HERO_ROW_H + gap;
    if (variant === "poster") return cardW * 1.5 + POSTER_TITLE_H + gap;
    if (view === "grid") return cardW * 1.5 + gap;
    return ROW_HEIGHT[view];
  }, [variant, view, width, columns, gap]);

  const virtualizer = useVirtualizer({
    count: rowCount,
    getScrollElement: () => parentRef.current,
    estimateSize: () => rowHeight,
    // Mobile keeps overscan tight: each extra row is a full column-count of
    // painted cover cards, which phone GPUs pay for on every scroll frame.
    overscan: isDesktop ? 6 : 2,
  });

  useEffect(() => { virtualizer.measure(); }, [rowHeight, columns, virtualizer]);

  // Publish the jump handle. A group index becomes a row index here, where the
  // column count actually lives.
  useEffect(() => {
    if (!jumpRef) return;
    jumpRef.current = (groupIndex: number) => {
      const row = isGrid ? Math.floor(groupIndex / columns) : groupIndex;
      virtualizer.scrollToIndex(Math.max(0, row), { align: "start" });
    };
    return () => {
      jumpRef.current = null;
    };
  }, [jumpRef, virtualizer, columns, isGrid]);

  // Restore the last scroll offset on mount, then track it so coming back
  // from a detail page lands where the user left off.
  useEffect(() => {
    const el = parentRef.current;
    if (!el || !restoreKey) return;
    el.scrollTop = getUiState(restoreKey, 0);
    const onScroll = () => setUiState(restoreKey, el.scrollTop);
    el.addEventListener("scroll", onScroll, { passive: true });
    return () => el.removeEventListener("scroll", onScroll);
  }, [restoreKey]);

  const activeGroup =
    activeRootId != null
      ? (groups.find((g) => g.rootId === activeRootId) ?? null)
      : null;

  const dimOf = (rootId: number) =>
    dimmedIds && !dimmedIds.has(rootId) ? 0.2 : 1;

  const renderGroup = (group: FranchiseGroup, index: number) => {
    if (variant === "hero") return <HeroCard group={group} onOpen={openCard} />;
    if (variant === "poster") {
      return (
        <QueueCard
          group={group}
          onOpen={openCard}
          onMove={onMove}
          canMoveEarlier={index > 0}
          canMoveLater={index < groups.length - 1}
          onNumber={onNumber}
          planNumber={planNumbers?.get(group.rootId) ?? null}
          onQuickAdd={onQuickAdd}
        />
      );
    }
    return <FranchiseCard group={group} view={view} onOpen={openCard} />;
  };

  const virtualRows = virtualizer.getVirtualItems();

  return (
    <>
      <div
        ref={parentRef}
        className="k-collection konsou-scroll"
        onPointerDownCapture={notePressedCard}
      >
        <div
          className="k-collection__inner"
          style={{ height: virtualizer.getTotalSize() }}
        >
          {virtualRows.map((vRow) => {
            const top = vRow.start;
            if (isGrid) {
              const startIdx = vRow.index * columns;
              const rowGroups = groups.slice(startIdx, startIdx + columns);
              return (
                <div
                  key={vRow.key}
                  className="k-collection__row k-collection__grid"
                  style={{
                    transform: `translateY(${top}px)`,
                    // minmax(0): a bare 1fr's auto minimum inherits the card's
                    // min-content, and one nowrap hero title then widens the
                    // track past the phone viewport, pushing Ep/+1 off-screen.
                    gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))`,
                    gap,
                    paddingBottom: gap,
                  }}
                >
                  {rowGroups.map((group, i) => (
                    <div
                      key={group.rootId}
                      style={{
                        opacity: dimOf(group.rootId),
                        transition: "opacity 200ms var(--ease-out)",
                      }}
                    >
                      {renderGroup(group, startIdx + i)}
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
                {renderGroup(group, vRow.index)}
              </div>
            );
          })}
        </div>
      </div>

      <FranchiseSheet
        group={activeGroup}
        anchor={anchorEl}
        open={activeGroup != null}
        onClose={() => setActiveRootId(null)}
        onNavigate={(id) => navigate(`/anime/${id}`, { replace: true })}
      />
    </>
  );
}
