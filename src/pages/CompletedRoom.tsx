import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useVirtualizer } from "@tanstack/react-virtual";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { RoomHeader } from "@/components/list/RoomHeader";
import { YearPicker } from "@/components/list/YearPicker";
import { Button } from "@/components/ui/Button";
import { FilterMenu } from "@/components/ui/FilterMenu";
import type { FilterSection } from "@/components/ui/FilterMenu";
import { EmptyState } from "@/components/ui/EmptyState";
import { ViewSwitch } from "@/components/ui/ViewSwitch";
import { useDebounce } from "@/hooks/useDebounce";
import { useBreakpoint } from "@/hooks/useMediaQuery";
import { getCoverUrl, normalizeForSearch, preferredTitle } from "@/lib/format";
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
/** Row heights for the two ledger renditions (see the view switch). */
const LEDGER_ROW_H = 72;
const INDEX_ROW_H = 44;

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

/** Carries the year too, for the all-years views where a bare day is ambiguous. */
function fullDayLabel(ms: number): string {
  const d = new Date(ms);
  return `${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
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
  // The ledger honours the app's rendition setting like every other room, so
  // the view switch in the header works here too.
  const view = useSettingsStore((s) => s.defaultView);
  const { isDesktop } = useBreakpoint();

  const [showDropped, setShowDropped] = useState(false);
  const [activeTags, setActiveTags] = useState<string[]>([]);
  // `null` = nothing chosen yet, which resolves to the newest year; "all" is
  // the deliberate choice to stop slicing by year at all.
  const [year, setYear] = useState<number | "all" | null>(null);
  const [search, setSearch] = useState("");
  const [searchOpen, setSearchOpen] = useState(false);
  const parentRef = useRef<HTMLDivElement>(null);
  const [paneWidth, setPaneWidth] = useState(600);
  const query = normalizeForSearch(useDebounce(search, 200));

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
    let filtered =
      effectiveTags.length === 0
        ? out
        : out.filter((w) => {
            const live = map[w.anilistId];
            return live ? effectiveTags.every((t) => hasHashtag(live.notes, t)) : false;
          });
    // Searching the ledger searches the record, not the collection: a ghost row
    // for a title you removed is still findable, which is the whole point of
    // keeping it.
    if (query) {
      filtered = filtered.filter((w) => normalizeForSearch(w.title).includes(query));
    }
    return filtered.sort((a, b) => b.at - a.at);
  }, [events, map, dropped, showDropped, effectiveTags, query, titleLanguage]);

  /** The index: every year that has anything in it, newest first. */
  const years = useMemo(() => {
    const counts = new Map<number, number>();
    for (const w of watches) counts.set(w.year, (counts.get(w.year) ?? 0) + 1);
    return [...counts.entries()]
      .map(([y, count]) => ({ year: y, count }))
      .sort((a, b) => b.year - a.year);
  }, [watches]);

  // Open on the most recent year, and never sit on a year the filters emptied.
  const showingAll = year === "all";
  const activeYear = showingAll
    ? null
    : typeof year === "number" && years.some((y) => y.year === year)
      ? year
      : (years[0]?.year ?? null);

  /** Every watch when showing all years, otherwise just the chosen year's. */
  const shown = useMemo(
    () => (showingAll ? watches : watches.filter((w) => w.year === activeYear)),
    [watches, activeYear, showingAll],
  );

  useEffect(() => {
    const el = parentRef.current;
    if (!el) return;
    const ro = new ResizeObserver((e) => setPaneWidth(e[0].contentRect.width));
    ro.observe(el);
    setPaneWidth(el.clientWidth);
    return () => ro.disconnect();
  }, []);

  // The wall is a grid of plates; the two ledger renditions are single-column
  // rows, so the same virtualizer serves all three by varying these two.
  const isWall = view === "grid";
  const columns = isWall
    ? Math.max(2, Math.floor((paneWidth + GAP) / (MIN_TILE + GAP)))
    : 1;
  const tileWidth = (paneWidth - GAP * (columns - 1)) / columns;
  const rowHeight = isWall
    ? tileWidth * 1.5 + TILE_LABEL_H + GAP
    : view === "list"
      ? LEDGER_ROW_H
      : INDEX_ROW_H;
  const rowCount = Math.ceil(shown.length / columns);

  const virtualizer = useVirtualizer({
    count: rowCount,
    getScrollElement: () => parentRef.current,
    estimateSize: () => rowHeight,
    overscan: isDesktop ? 4 : 2,
  });
  useEffect(() => {
    virtualizer.measure();
  }, [rowHeight, columns, view, virtualizer]);

  // Changing year starts that year at the top: you asked for a different view,
  // not for the same scroll position in a different year.
  useEffect(() => {
    if (parentRef.current) parentRef.current.scrollTop = 0;
  }, [activeYear]);

  // Coming back from a detail page lands where the reading left off.
  useEffect(() => {
    setYear(getUiState<number | "all" | null>("room.completed.year", null));
  }, []);
  const pickYear = (y: number | "all") => {
    setYear(y);
    setUiState("room.completed.year", y);
  };

  const filterCount = effectiveTags.length + (showDropped ? 1 : 0);

  const filterSections: FilterSection[] = [
    ...(dropped.length > 0
      ? [
          {
            kind: "switch" as const,
            id: "dropped",
            group: "Also show",
            label: "Dropped",
            on: showDropped,
            count: dropped.length,
            onToggle: () => setShowDropped((v) => !v),
          },
        ]
      : []),
    ...(tagFacets.length > 0
      ? [
          {
            kind: "toggles" as const,
            id: "tags",
            label: "Tags",
            options: tagFacets.map((t) => ({ key: t.key, label: t.label, count: t.count })),
            active: effectiveTags,
            onToggle: (key: string) =>
              setActiveTags((prev) =>
                prev.includes(key) ? prev.filter((t) => t !== key) : [...prev, key],
              ),
            onClear: () => setActiveTags([]),
            searchPlaceholder: `Find one of ${tagFacets.length} tags…`,
          },
        ]
      : []),
  ];

  return (
    <div className="k-page k-page--room k-page--years">
      <RoomHeader
        title="Completed"
        search={{
          value: search,
          onChange: setSearch,
          open: searchOpen,
          onOpen: () => setSearchOpen(true),
          onClose: () => {
            setSearch("");
            setSearchOpen(false);
          },
          placeholder: "Search everything you have finished",
        }}
        actions={
          <>
            {years.length > 0 && (
              <YearPicker
                years={years}
                active={activeYear}
                showingAll={showingAll}
                total={watches.length}
                onPick={pickYear}
              />
            )}
            <ViewSwitch />
            {filterSections.length > 0 && (
              <FilterMenu
                sections={filterSections}
                activeCount={filterCount}
                label="Filter"
                onClearAll={() => {
                  setActiveTags([]);
                  setShowDropped(false);
                }}
              />
            )}
          </>
        }
      />

      {watches.length === 0 ? (
        query ? (
          <EmptyState
            title={`Nothing finished matches “${search.trim()}”`}
            subtitle="This searches the whole record, including watches of titles you have since removed."
          />
        ) : effectiveTags.length > 0 ? (
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
          <div className="k-years__pane">
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
                      className={`k-years__row${isWall ? "" : " k-years__row--flat"}`}
                      style={{
                        transform: `translateY(${v.start}px)`,
                        gridTemplateColumns: isWall
                          ? `repeat(${columns}, minmax(0, 1fr))`
                          : "1fr",
                        gap: isWall ? GAP : 0,
                        paddingBottom: isWall ? GAP : 0,
                        // A ledger row has to BE the height the virtualizer
                        // placed it at. Left to size itself it collapses to its
                        // content and drifts out of step with the offsets, so
                        // the rows creep apart down a long year.
                        height: isWall ? undefined : rowHeight,
                      }}
                    >
                      {row.map((w) => {
                        const open = () =>
                          navigate(`/anime/${w.anilistId}`, { replace: true });

                        /* Plates: the covers ARE the record, so the wall stays
                           the default, and the two ledger renditions below are
                           for the times you are looking something UP. */
                        if (isWall) {
                          return (
                            <button
                              key={w.key}
                              type="button"
                              className={`k-tile${w.ghost ? " k-tile--ghost" : ""}`}
                              onClick={open}
                            >
                              <span className="k-tile__art">
                                <AnimeCover
                                  src={w.cover}
                                  alt=""
                                  decorative
                                  radius="var(--plate-radius)"
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
                          );
                        }

                        /* Index: one ruled line each — the densest way to scan
                           a few thousand finished watches for a single name. */
                        if (view === "compact") {
                          return (
                            <button
                              key={w.key}
                              type="button"
                              className={`k-ledge k-ledge--index${w.ghost ? " k-ledge--ghost" : ""}`}
                              onClick={open}
                            >
                              <span className="k-ledge__date">
                                {w.estimated && <span aria-hidden>~</span>}
                                {showingAll ? fullDayLabel(w.at) : dayLabel(w.at)}
                              </span>
                              <span className="k-ledge__title">{w.title}</span>
                              {w.rewatchIndex > 0 && (
                                <span className="k-ledge__tag">×{w.rewatchIndex + 1}</span>
                              )}
                              {w.kind === "dropped" && (
                                <span className="k-ledge__tag k-ledge__tag--dropped">
                                  Dropped
                                </span>
                              )}
                            </button>
                          );
                        }

                        /* Ledger: the accession row — plate, name, date. */
                        return (
                          <button
                            key={w.key}
                            type="button"
                            className={`k-ledge${w.ghost ? " k-ledge--ghost" : ""}`}
                            onClick={open}
                          >
                            <span className="k-ledge__cover">
                              <AnimeCover
                                src={w.cover}
                                alt=""
                                decorative
                                radius="var(--plate-radius)"
                              />
                            </span>
                            <span className="k-ledge__main">
                              <span className="k-ledge__title">{w.title}</span>
                              <span className="k-ledge__meta">
                                {w.estimated && <span aria-hidden>~</span>}
                                {showingAll ? fullDayLabel(w.at) : dayLabel(w.at)}
                                {w.ghost && <span className="k-ledge__gone">removed</span>}
                              </span>
                            </span>
                            {w.rewatchIndex > 0 && (
                              <span className="k-ledge__tag">×{w.rewatchIndex + 1}</span>
                            )}
                            {w.kind === "dropped" && (
                              <span className="k-ledge__tag k-ledge__tag--dropped">
                                Dropped
                              </span>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
