import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useVirtualizer } from "@tanstack/react-virtual";
import { SlidersHorizontal } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { RoomFilters } from "@/components/list/RoomFilters";
import { RoomHeader } from "@/components/list/RoomHeader";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/EmptyState";
import { useBreakpoint } from "@/hooks/useMediaQuery";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { collectHashtags, hasHashtag } from "@/lib/hashtags";
import { useCompletionStore } from "@/lib/store/completionStore";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { getUiState, setUiState } from "@/lib/uiState";
import type { AnimeListEntry, TitleLanguage } from "@/types/list";

/**
 * The ledger: everything you have finished, one year at a time.
 *
 * It reads from the completion log, not from the list, and that is the whole
 * point. A completion is an event with its own date, so a title watched three
 * times appears three times, and a title you later removed from your
 * collection still appears — faded, no longer yours, but there. The record
 * does not get quietly rewritten by a later edit or erased by a removal.
 *
 * The shape is a year index beside a wall of covers. Two earlier attempts got
 * this wrong in the same way: a threaded spine and then a sortable table both
 * made a few thousand finished shows into rows of text, when the covers ARE
 * the record and the thing you recognise. And neither solved the real problem
 * with 3000 entries, which is that one endless list has no landmarks. Picking
 * a year is the landmark: every view is bounded, every view has its own count,
 * and nothing is ever an infinite scroll.
 */

/** Cover tile: a min width, and the row height the virtualizer measures once.
 *  The label budget is the date line plus two lines of title at the current
 *  scale — short by a line and the titles clip into the row below. */
const MIN_TILE = 104;
const TILE_LABEL_H = 60;
const GAP = 12;

interface Watch {
  key: string;
  anilistId: number;
  title: string;
  cover: string | null;
  at: number;
  year: number;
  /** 0 = first watch; anything above is that many rewatches in. */
  rewatchIndex: number;
  /** The date was reconstructed on upgrade rather than recorded. */
  estimated: boolean;
  /** No longer in the collection: the event outlived its entry. */
  ghost: boolean;
  kind: "completed" | "dropped";
}

const MONTHS = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

function dayLabel(ms: number): string {
  const d = new Date(ms);
  return `${d.getDate()} ${MONTHS[d.getMonth()]}`;
}

/** The live entry's title wins so the room follows the language setting; the
 *  event's own snapshot is what keeps a ghost readable. */
function watchTitle(
  live: AnimeListEntry | undefined,
  snapshot: { romaji: string; english: string | null; native: string | null },
  lang: TitleLanguage,
): string {
  const src = live
    ? { romaji: live.title_romaji, english: live.title_english, native: live.title_native }
    : snapshot;
  return preferredTitle(src, lang);
}

export function CompletedRoom() {
  const navigate = useNavigate();
  const entries = useListStore((s) => s.entries);
  const map = useListStore((s) => s.map);
  const events = useCompletionStore((s) => s.events);
  const loaded = useCompletionStore((s) => s.loaded);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const { isDesktop } = useBreakpoint();

  const [showDropped, setShowDropped] = useState(false);
  const [activeTags, setActiveTags] = useState<string[]>([]);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [year, setYear] = useState<number | null>(null);
  const parentRef = useRef<HTMLDivElement>(null);
  const [paneWidth, setPaneWidth] = useState(600);

  const goDiscoverSearch = () =>
    navigate("/discover", { replace: true, state: { fromSearchIntent: true } });

  // Dropped is part of your record too, but it is not a completion, so it is a
  // filter rather than a permanent part of the ledger.
  const dropped = useMemo(
    () => entries.filter((e) => e.status === "dropped"),
    [entries],
  );

  const tagFacets = useMemo(() => {
    const notes = entries
      .filter((e) => e.status === "completed" || e.status === "dropped")
      .map((e) => e.notes);
    return collectHashtags(notes);
  }, [entries]);
  const effectiveTags = useMemo(() => {
    const available = new Set(tagFacets.map((f) => f.key));
    return activeTags.filter((t) => available.has(t));
  }, [activeTags, tagFacets]);

  /** Every watch, newest first, before the year is chosen. */
  const watches = useMemo(() => {
    const out: Watch[] = [];
    for (const e of events) {
      const live = map[e.anilist_id];
      out.push({
        key: `c${e.anilist_id}:${e.rewatch_index}`,
        anilistId: e.anilist_id,
        title: watchTitle(
          live,
          { romaji: e.title_romaji, english: e.title_english, native: e.title_native },
          titleLanguage,
        ),
        cover: getCoverUrl({ medium: (live?.cover_url ?? e.cover_url) ?? undefined }) || null,
        at: e.completed_at,
        year: new Date(e.completed_at).getFullYear(),
        rewatchIndex: e.rewatch_index,
        estimated: e.estimated,
        ghost: !live,
        kind: "completed",
      });
    }
    if (showDropped) {
      for (const e of dropped) {
        out.push({
          key: `d${e.anilist_id}`,
          anilistId: e.anilist_id,
          title: watchTitle(
            e,
            { romaji: e.title_romaji, english: e.title_english, native: e.title_native },
            titleLanguage,
          ),
          cover: getCoverUrl({ medium: e.cover_url ?? undefined }) || null,
          at: e.updated_at,
          year: new Date(e.updated_at).getFullYear(),
          rewatchIndex: 0,
          estimated: true,
          ghost: false,
          kind: "dropped",
        });
      }
    }
    const filtered =
      effectiveTags.length === 0
        ? out
        : out.filter((w) => {
            const live = map[w.anilistId];
            return live ? effectiveTags.every((t) => hasHashtag(live.notes, t)) : false;
          });
    return filtered.sort((a, b) => b.at - a.at);
  }, [events, map, dropped, showDropped, effectiveTags, titleLanguage]);

  /** The index: every year that has anything in it, newest first. */
  const years = useMemo(() => {
    const counts = new Map<number, number>();
    for (const w of watches) counts.set(w.year, (counts.get(w.year) ?? 0) + 1);
    return [...counts.entries()]
      .map(([y, count]) => ({ year: y, count }))
      .sort((a, b) => b.year - a.year);
  }, [watches]);

  // Open on the most recent year, and never sit on a year the filters emptied.
  const activeYear =
    year != null && years.some((y) => y.year === year) ? year : (years[0]?.year ?? null);

  const shown = useMemo(
    () => watches.filter((w) => w.year === activeYear),
    [watches, activeYear],
  );

  /** What this year alone amounts to — the reason a bounded view beats a feed. */
  const yearCensus = useMemo(() => {
    let rewatches = 0;
    let titles = new Set<number>();
    for (const w of shown) {
      titles.add(w.anilistId);
      if (w.rewatchIndex > 0) rewatches++;
    }
    return { finished: shown.length, titles: titles.size, rewatches };
  }, [shown]);

  useEffect(() => {
    const el = parentRef.current;
    if (!el) return;
    const ro = new ResizeObserver((e) => setPaneWidth(e[0].contentRect.width));
    ro.observe(el);
    setPaneWidth(el.clientWidth);
    return () => ro.disconnect();
  }, []);

  const columns = Math.max(2, Math.floor((paneWidth + GAP) / (MIN_TILE + GAP)));
  const tileWidth = (paneWidth - GAP * (columns - 1)) / columns;
  const rowHeight = tileWidth * 1.5 + TILE_LABEL_H + GAP;
  const rowCount = Math.ceil(shown.length / columns);

  const virtualizer = useVirtualizer({
    count: rowCount,
    getScrollElement: () => parentRef.current,
    estimateSize: () => rowHeight,
    overscan: isDesktop ? 4 : 2,
  });
  useEffect(() => {
    virtualizer.measure();
  }, [rowHeight, columns, virtualizer]);

  // Changing year starts that year at the top: you asked for a different view,
  // not for the same scroll position in a different year.
  useEffect(() => {
    if (parentRef.current) parentRef.current.scrollTop = 0;
  }, [activeYear]);

  // Coming back from a detail page lands where the reading left off.
  useEffect(() => {
    setYear(getUiState<number | null>("room.completed.year", null));
  }, []);
  const pickYear = (y: number) => {
    setYear(y);
    setUiState("room.completed.year", y);
  };

  const filterCount = effectiveTags.length + (showDropped ? 1 : 0);
  const totalRewatches = useMemo(
    () => watches.reduce((n, w) => n + (w.rewatchIndex > 0 ? 1 : 0), 0),
    [watches],
  );

  return (
    <div className="k-page k-page--room k-page--years">
      <RoomHeader
        title="Completed"
        census={[
          `${watches.length.toLocaleString()} finished`,
          totalRewatches > 0 ? `${totalRewatches.toLocaleString()} rewatches` : null,
          years.length > 0 ? `${years.length} years` : null,
        ]}
        purpose="Every watch you have finished, kept by the year you finished it."
        actions={
          <button
            type="button"
            className={`k-roomhead__filter${filterCount > 0 ? " k-roomhead__filter--on" : ""}`}
            onClick={() => setFiltersOpen(true)}
            aria-label={filterCount > 0 ? `Filter, ${filterCount} active` : "Filter"}
          >
            <Icon icon={SlidersHorizontal} size={17} />
            {filterCount > 0 && <span className="k-roomhead__badge">{filterCount}</span>}
          </button>
        }
      />

      {watches.length === 0 ? (
        effectiveTags.length > 0 ? (
          <EmptyState
            title="Nothing matches those tags"
            subtitle="Try removing one, or clear the filter to see the whole record."
            action={
              <Button variant="primary" onClick={() => setActiveTags([])}>
                Clear tags
              </Button>
            }
          />
        ) : (
          <EmptyState
            title={loaded ? "Nothing finished yet" : "Reading the record…"}
            subtitle="Every show you finish is dated and kept here, including the ones you watch again."
            action={
              <Button variant="primary" onClick={goDiscoverSearch}>
                Search for anime
              </Button>
            }
          />
        )
      ) : (
        <div className="k-years">
          {/* The index. On a phone it lies down as a row of year chips: the
              same list, turned a quarter turn, because a narrow screen has no
              column to spare. */}
          <nav className="k-years__index konsou-scroll" aria-label="Choose a year">
            {years.map((y) => (
              <button
                key={y.year}
                type="button"
                className={`k-years__year${y.year === activeYear ? " k-years__year--on" : ""}`}
                aria-current={y.year === activeYear ? "true" : undefined}
                onClick={() => pickYear(y.year)}
              >
                <span className="k-years__num">{y.year}</span>
                <span className="k-years__count">{y.count}</span>
              </button>
            ))}
          </nav>

          <div className="k-years__pane">
            <p className="k-years__census">
              {yearCensus.finished} finished
              {yearCensus.rewatches > 0 && ` · ${yearCensus.rewatches} rewatched`}
              {yearCensus.titles !== yearCensus.finished &&
                ` · ${yearCensus.titles} titles`}
            </p>

            <div ref={parentRef} className="k-years__wall konsou-scroll">
              <div
                className="k-years__inner"
                style={{ height: virtualizer.getTotalSize() }}
              >
                {virtualizer.getVirtualItems().map((v) => {
                  const start = v.index * columns;
                  const row = shown.slice(start, start + columns);
                  return (
                    <div
                      key={v.key}
                      className="k-years__row"
                      style={{
                        transform: `translateY(${v.start}px)`,
                        gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))`,
                        gap: GAP,
                        paddingBottom: GAP,
                      }}
                    >
                      {row.map((w) => (
                        <button
                          key={w.key}
                          type="button"
                          className={`k-tile${w.ghost ? " k-tile--ghost" : ""}`}
                          onClick={() =>
                            navigate(`/anime/${w.anilistId}`, { replace: true })
                          }
                        >
                          <span className="k-tile__art">
                            <AnimeCover
                              src={w.cover}
                              alt=""
                              decorative
                              radius="var(--radius-plate)"
                            />
                            {w.rewatchIndex > 0 && (
                              <span className="k-tile__rewatch">
                                ×{w.rewatchIndex + 1}
                              </span>
                            )}
                            {w.kind === "dropped" && (
                              <span className="k-tile__dropped">Dropped</span>
                            )}
                          </span>
                          <span className="k-tile__date">
                            {w.estimated && (
                              <span className="k-tile__approx" aria-hidden>
                                ~
                              </span>
                            )}
                            {dayLabel(w.at)}
                            {w.ghost && <span className="k-tile__gone"> · removed</span>}
                          </span>
                          <span className="k-tile__title">{w.title}</span>
                        </button>
                      ))}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      )}

      <RoomFilters
        open={filtersOpen}
        onClose={() => setFiltersOpen(false)}
        // The year index is the sort; there is nothing left for a sort control
        // to say that picking a year does not already say.
        sorts={[]}
        activeSort=""
        onSort={() => {}}
        tags={tagFacets}
        activeTags={effectiveTags}
        onToggleTag={(key) =>
          setActiveTags((prev) =>
            prev.includes(key) ? prev.filter((t) => t !== key) : [...prev, key],
          )
        }
        onClearTags={() => setActiveTags([])}
        droppedCount={dropped.length}
        showDropped={showDropped}
        onToggleDropped={() => setShowDropped((v) => !v)}
      />
    </div>
  );
}
