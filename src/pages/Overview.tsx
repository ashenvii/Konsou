import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ChevronRight, Play, Plus, Search, X } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { FranchiseSheet } from "@/components/anime/FranchiseSheet";
import { StatusStamp } from "@/components/anime/StatusStamp";
import { RoomDoor } from "@/components/list/RoomDoor";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { ImportSheet } from "@/components/ui/ImportSheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { useDebounce } from "@/hooks/useDebounce";
import { useDragScroll } from "@/hooks/useDragScroll";
import { groupEntries } from "@/lib/franchise/grouping";
import { getCoverUrl, normalizeForSearch, preferredTitle } from "@/lib/format";
import { useCompletionStore } from "@/lib/store/completionStore";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { getUiState, setUiState } from "@/lib/uiState";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { AnimeListEntry, ListStatus, TitleLanguage } from "@/types/list";
import type { KonsouNotification } from "@/types/notification";

/**
 * My List's landing: a launcher, not a list.
 *
 * The library itself lives in the rooms. This page answers four things and
 * stops: how big is the collection, what am I planning, what have I finished,
 * and is anything on right now. Two equal doors carry the two rooms people
 * actually live in; the show in progress gets one ruled line with its episode
 * stamp on it, so tonight's log is still one tap from the landing; the sequel
 * radar keeps its strip because "there's more of something you own" is half the
 * reason this app exists.
 *
 * Typing turns the whole surface into the cross-status "have you seen it?"
 * search — the memory job, and the one thing that must not care which room a
 * title is in.
 */

/** How many matches the overlay renders before it asks you to narrow down.
 *  A query over a few thousand entries can match hundreds; a panel is for
 *  finding one thing, not for browsing. */
const FIND_LIMIT = 40;

const MONTHS = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

/** "Mar 2024" — the month a record starts is precise enough to mean something. */
function monthYear(ms: number): string {
  const d = new Date(ms);
  return `${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

function groupsFor(entries: AnimeListEntry[], statuses: ListStatus[]): FranchiseGroup[] {
  const wanted = new Set(statuses);
  return groupEntries(entries.filter((e) => wanted.has(e.status)));
}

/** A franchise's place in the watch order: its earliest-ranked member. */
function planRankOf(g: FranchiseGroup): number {
  let min = Number.POSITIVE_INFINITY;
  for (const e of g.entries) {
    if (e.plan_rank != null && e.plan_rank < min) min = e.plan_rank;
  }
  return min;
}

function titleOf(g: FranchiseGroup, lang: TitleLanguage): string {
  const root = g.entries.find((e) => e.anilist_id === g.rootId) ?? g.entries[0];
  return preferredTitle(
    { romaji: root.title_romaji, english: root.title_english, native: root.title_native },
    lang,
  );
}

export function Overview() {
  const navigate = useNavigate();
  const loaded = useListStore((s) => s.loaded);
  const entries = useListStore((s) => s.entries);
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
  const updateStatus = useListStore((s) => s.updateStatus);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const alerts = useNotificationStore((s) => s.items);
  // The ledger loads a beat after the list, so until it is there the door
  // counts cards. Showing a real zero on a full collection for one frame reads
  // as data loss, which is the one thing this app must never look like.
  const ledgerLoaded = useCompletionStore((s) => s.loaded);
  const completionCount = useCompletionStore((s) => s.events.length);

  const [search, setSearchState] = useState(() => getUiState("mylist.search", ""));
  // The field is not on the page until asked for. A saved query would reopen
  // it behind your back on the next launch, so an open search starts empty.
  const [searchOpen, setSearchOpen] = useState(false);
  const searchRef = useRef<HTMLInputElement>(null);
  const [importOpen, setImportOpen] = useState(false);
  const [activeRootId, setActiveRootId] = useState<number | null>(null);
  // Every add door on this page opens the same engine: Discover's search with
  // the full status choice (the add law: a door may suggest, never lock).
  const goDiscoverSearch = () =>
    navigate("/discover", { replace: true, state: { fromSearchIntent: true } });
  // The no-match handoff: carry the words along so they type the title once.
  const goDiscoverSearchFor = (query: string) =>
    navigate("/discover", { replace: true, state: { fromSearchIntent: true, query } });
  const debounced = useDebounce(search, 300);
  const setSearch = (v: string) => {
    setSearchState(v);
    setUiState("mylist.search", v);
  };
  const closeSearch = () => {
    setSearch("");
    setSearchOpen(false);
  };

  // Opening the field should put the caret in it; a search you have to click
  // twice to use is a search nobody uses.
  useEffect(() => {
    if (searchOpen) searchRef.current?.focus();
  }, [searchOpen]);

  // On now. Paused folds in, matching the room this line opens: recency keeps
  // the active shows on top, since a paused entry has not been touched lately
  // by definition.
  const watching = useMemo(() => {
    const groups = groupsFor(entries, ["watching", "rewatching", "on_hold"]);
    return groups.sort((a, b) => {
      const paused =
        Number(a.displayEntry.status === "on_hold") -
        Number(b.displayEntry.status === "on_hold");
      return paused !== 0 ? paused : b.sortUpdated - a.sortUpdated;
    });
  }, [entries]);

  // The plan room's own order: what you numbered comes first, then the newest.
  // The door shows the front of that queue, so it agrees with the room.
  const plan = useMemo(() => {
    const groups = groupsFor(entries, ["plan_to_watch"]);
    return groups.sort((a, b) => {
      const ra = planRankOf(a);
      const rb = planRankOf(b);
      return ra !== rb ? ra - rb : b.sortAdded - a.sortAdded;
    });
  }, [entries]);

  // Completed sorts by when it was FINISHED, not by any later edit, so a
  // re-scored title doesn't jump to the front of the door.
  const completed = useMemo(() => {
    const groups = groupsFor(entries, ["completed"]);
    return groups.sort(
      (a, b) =>
        Math.max(...b.entries.map((e) => e.completed_at ?? e.updated_at)) -
        Math.max(...a.entries.map((e) => e.completed_at ?? e.updated_at)),
    );
  }, [entries]);

  // The census counts titles, not cards: a franchise of six seasons is six
  // things you tracked. Muted entries are not part of the collection.
  const census = useMemo(() => {
    let tracked = 0;
    let since = Number.POSITIVE_INFINITY;
    for (const e of entries) {
      if (e.status === "not_interested") continue;
      tracked++;
      if (e.added_at < since) since = e.added_at;
    }
    return { tracked, since: since === Number.POSITIVE_INFINITY ? null : since };
  }, [entries]);

  // Search groups across every status: "have I seen it" doesn't care where.
  const allGroups = useMemo(() => groupEntries(entries), [entries]);
  const searchHays = useMemo(() => {
    const m = new Map<FranchiseGroup, string>();
    for (const g of allGroups) {
      let s = "";
      for (const e of g.entries) {
        s += `${e.title_romaji} ${e.title_english ?? ""} ${e.title_native ?? ""} `;
      }
      m.set(g, normalizeForSearch(s));
    }
    return m;
  }, [allGroups]);
  const query = normalizeForSearch(debounced);
  const searching = query.length > 0;
  const matches = useMemo(
    () => (searching ? allGroups.filter((g) => (searchHays.get(g) ?? "").includes(query)) : []),
    [searching, query, allGroups, searchHays],
  );

  const sheetGroup = useMemo(() => {
    if (activeRootId == null) return null;
    return allGroups.find((g) => g.rootId === activeRootId) ?? null;
  }, [activeRootId, allGroups]);

  if (!loaded) {
    return (
      <div className="k-page">
        <div className="k-skelgrid">
          {Array.from({ length: 12 }).map((_, i) => (
            <Skeleton key={i} height="auto" style={{ aspectRatio: "2 / 3" }} />
          ))}
        </div>
      </div>
    );
  }

  if (entries.length === 0) {
    return (
      <div className="k-page">
        <div className="k-mylist-empty">
          <div className="k-mylist-empty__shelf" aria-hidden>
            <div className="k-mylist-empty__cover" />
            <div className="k-mylist-empty__cover" />
            <div className="k-mylist-empty__cover" />
          </div>
          <p className="k-mylist-empty__title">Your collection starts here</p>
          <p className="k-mylist-empty__sub">
            Track what you're watching, planning, or have finished. No score required.
          </p>
          <div className="k-mylist-empty__actions">
            <Button variant="primary" onClick={goDiscoverSearch}>
              Search for anime
            </Button>
            <p className="k-mylist-empty__import">
              Coming from AniList or MyAnimeList?{" "}
              <button type="button" onClick={() => setImportOpen(true)}>
                Import your list
              </button>
            </p>
          </div>
        </div>
        <ImportSheet open={importOpen} onClose={() => setImportOpen(false)} />
      </div>
    );
  }

  const openRoom = (path: string) => navigate(path, { replace: true });
  const onNow = watching[0] ?? null;

  return (
    <div className="k-page k-overview">
      {/* Always mounted: a live region created together with its content is
          not announced, so the search's outcome would stay silent. */}
      <p className="sr-only" role="status">
        {searching
          ? matches.length > 0
            ? `${matches.length} ${matches.length === 1 ? "match" : "matches"} for ${debounced.trim()}`
            : `No matches for ${debounced.trim()}`
          : ""}
      </p>

      <div className="k-overview__scroll konsou-scroll">
          <div className="k-launch">
            {/* The collection's header, and the one place search lives. The
                field used to hold the top of the page permanently, which put a
                control nobody had asked for above everything they came for.
                Now it opens from the title line and its results hang under it,
                over the page rather than instead of it. */}
            <header className="k-census">
              <div className="k-census__row">
                {searchOpen ? (
                  <div className="k-findfield">
                    <Icon icon={Search} size={16} color="var(--color-text-tertiary)" />
                    <input
                      ref={searchRef}
                      className="k-findfield__input"
                      type="search"
                      inputMode="search"
                      placeholder="Have you seen it?"
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === "Escape") closeSearch();
                      }}
                      aria-label="Search your whole list"
                    />
                    <button
                      type="button"
                      className="k-findfield__clear"
                      onClick={closeSearch}
                      aria-label="Close search"
                    >
                      <Icon icon={X} size={15} />
                    </button>
                  </div>
                ) : (
                  <>
                    <h1 className="k-census__title">My List</h1>
                    <button
                      type="button"
                      className="k-census__find"
                      onClick={() => setSearchOpen(true)}
                      aria-label="Search your whole list"
                    >
                      <Icon icon={Search} size={17} />
                    </button>
                  </>
                )}
              </div>
              <p className="k-census__line">
                <span className="k-census__n">{census.tracked}</span>
                {census.tracked === 1 ? " title" : " titles"}
                {census.since && <> · kept since {monthYear(census.since)}</>}
              </p>

              {/* Results hang off the field: the launcher stays where it was,
                  so closing the search returns you to the page you never left. */}
              {searching && (
                <div className="k-findresults konsou-scroll">
                  {matches.length > 0 ? (
                    <>
                      <p className="k-findresults__count">
                        {matches.length} {matches.length === 1 ? "match" : "matches"}
                        {matches.length > FIND_LIMIT && ` · showing ${FIND_LIMIT}`}
                      </p>
                      {matches.slice(0, FIND_LIMIT).map((g) => (
                        <button
                          type="button"
                          key={g.rootId}
                          className="k-findrow"
                          onClick={() => {
                            setActiveRootId(g.rootId);
                            closeSearch();
                          }}
                        >
                          <span className="k-findrow__cover" aria-hidden>
                            <AnimeCover
                              src={getCoverUrl({
                                medium: g.displayEntry.cover_url ?? undefined,
                              })}
                              alt=""
                              decorative
                              radius="var(--radius-plate)"
                            />
                          </span>
                          <span className="k-findrow__title">
                            {titleOf(g, titleLanguage)}
                          </span>
                          <StatusStamp status={g.displayEntry.status} />
                        </button>
                      ))}
                    </>
                  ) : (
                    /* The likeliest reason it's not in the list: it was never
                       added. Finish the thought instead of dead-ending. */
                    <div className="k-findresults__none">
                      <p>Nothing in your list matches “{debounced.trim()}”.</p>
                      <button
                        type="button"
                        className="k-launch__add"
                        onClick={() => goDiscoverSearchFor(debounced.trim())}
                      >
                        <Icon icon={Search} size={15} />
                        Search all anime
                      </button>
                    </div>
                  )}
                </div>
              )}
            </header>

            {/* The two rooms, equal footing. Everything else on this page is a
                line; only these are plates. */}
            <div className="k-doors">
              <RoomDoor
                label="Planned"
                count={plan.length}
                groups={plan}
                footLabel="Next"
                footValue={plan[0] ? titleOf(plan[0], titleLanguage) : null}
                emptyLine="Nothing queued. Anything you might watch goes here."
                onOpen={() => openRoom("/list/plan")}
              />
              <RoomDoor
                label="Completed"
                // Counts finished WATCHES, not titles, so the door agrees with
                // the room behind it: the ledger lists a rewatch as its own
                // line, and a door that said something different would just be
                // a second number to reconcile.
                count={ledgerLoaded ? completionCount : completed.length}
                groups={completed}
                footLabel="Last"
                footValue={completed[0] ? titleOf(completed[0], titleLanguage) : null}
                emptyLine="Shows you finish take their place here."
                onOpen={() => openRoom("/list/completed")}
              />
            </div>

            {/* Only present while something is actually on. A permanent empty
                "Watching" band was the launcher's biggest piece of nothing. */}
            {onNow && (
              <OnNowLine
                group={onNow}
                total={watching.length}
                titleLanguage={titleLanguage}
                onOpen={() => setActiveRootId(onNow.rootId)}
                onRoom={() => openRoom("/list/watching")}
                onLog={() => void incrementEpisodes(onNow.displayEntry.anilist_id, 1)}
                onResume={() => void updateStatus(onNow.displayEntry.anilist_id, "watching")}
              />
            )}

            {alerts.length > 0 && (
              <SequelStrip
                alerts={alerts}
                onRoom={() => openRoom("/airing")}
                onPick={(id) => navigate(`/anime/${id}`, { replace: true })}
              />
            )}

            <button type="button" className="k-launch__add" onClick={goDiscoverSearch}>
              <Icon icon={Plus} size={16} />
              Add something
            </button>
          </div>
      </div>

      <FranchiseSheet
        group={sheetGroup}
        open={sheetGroup != null}
        onClose={() => setActiveRootId(null)}
        onNavigate={(id) => navigate(`/anime/${id}`, { replace: true })}
      />
      <ImportSheet open={importOpen} onClose={() => setImportOpen(false)} />
    </div>
  );
}

/**
 * What the sequel radar turned up on titles you already own. This is the other
 * half of the app's reason to exist ("there is more of this"), so it keeps a
 * first-class place on the landing rather than living only behind the Airing
 * tab. Absent entirely when the radar has nothing.
 */
function SequelStrip({
  alerts,
  onRoom,
  onPick,
}: {
  alerts: KonsouNotification[];
  onRoom: () => void;
  onPick: (relatedId: number) => void;
}) {
  // Desktop pans by mouse drag with no scrollbar; touch scrolls natively and
  // the wheel always stays with the page (the app-wide rail contract).
  const rowRef = useDragScroll<HTMLDivElement>();

  return (
    <section className="k-strip">
      <button type="button" className="k-strip__door" onClick={onRoom}>
        New sequels
        <span className="k-strip__count">{alerts.length}</span>
        <Icon icon={ChevronRight} size={16} className="k-strip__chev" />
      </button>
      <div className="k-strip__row" ref={rowRef}>
        {alerts.slice(0, 12).map((n) => (
          <button
            type="button"
            key={n.related_id}
            className="k-strip__item"
            onClick={() => onPick(n.related_id)}
          >
            <AnimeCover
              src={getCoverUrl({ medium: n.related_cover ?? undefined })}
              alt=""
              decorative
              radius="var(--radius-plate)"
            />
            <span className="k-strip__title">{n.related_title}</span>
          </button>
        ))}
      </div>
    </section>
  );
}

/**
 * The one show that's on right now, as a single ruled line under the doors.
 *
 * It is a line and not a card because the launcher has exactly two plates and
 * this isn't one of them — but it still carries the episode stamp, because
 * logging tonight's episode is the app's signature act and it has to stay one
 * tap from the landing. A paused show offers Resume instead: episode tracking
 * only means anything while a run is actually going.
 */
function OnNowLine({
  group,
  total,
  titleLanguage,
  onOpen,
  onRoom,
  onLog,
  onResume,
}: {
  group: FranchiseGroup;
  total: number;
  titleLanguage: TitleLanguage;
  onOpen: () => void;
  onRoom: () => void;
  onLog: () => void;
  onResume: () => void;
}) {
  const entry = group.displayEntry;
  const title = titleOf(group, titleLanguage);
  const watched = entry.episodes_watched;
  const totalEps = entry.total_episodes;
  const paused = entry.status === "on_hold";
  const atMax = totalEps != null && watched >= totalEps;

  return (
    <section className="k-onnow">
      <button type="button" className="k-strip__door" onClick={onRoom}>
        Watching
        <span className="k-strip__count">{total}</span>
        <Icon icon={ChevronRight} size={16} className="k-strip__chev" />
      </button>

      <div className={`k-onnow__row${paused ? " k-onnow__row--paused" : ""}`}>
        <div className="k-onnow__cover" aria-hidden>
          <AnimeCover
            src={getCoverUrl({ medium: entry.cover_url ?? undefined })}
            alt=""
            decorative
            radius="var(--radius-plate)"
          />
        </div>
        <button type="button" className="k-onnow__open" onClick={onOpen}>
          {title}
        </button>
        <span className="k-onnow__count">
          {paused ? "Paused" : `Ep ${watched} / ${totalEps ?? "?"}`}
        </span>
        {paused ? (
          <button
            type="button"
            className="k-onnow__stamp"
            onClick={onResume}
            aria-label={`Resume watching ${title}`}
          >
            <Icon icon={Play} size={15} weight="fill" />
          </button>
        ) : (
          <button
            type="button"
            className="k-onnow__stamp"
            disabled={atMax}
            onClick={onLog}
            aria-label={`Log episode ${watched + 1} of ${title}`}
          >
            <Icon icon={Plus} size={17} />
          </button>
        )}
      </div>
    </section>
  );
}
