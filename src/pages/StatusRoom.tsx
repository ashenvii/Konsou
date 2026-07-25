import { useCallback, useMemo, useRef, useState } from "react";
import { Navigate, useNavigate, useParams } from "react-router-dom";
import { ArrowUpDown, ChevronLeft, ListOrdered, SlidersHorizontal } from "lucide-react";
import { FranchiseCollection } from "@/components/list/FranchiseCollection";
import type { RoomVariant } from "@/components/list/FranchiseCollection";
import { LetterRail } from "@/components/list/LetterRail";
import type { RailSection } from "@/components/list/LetterRail";
import { RoomFilters } from "@/components/list/RoomFilters";
import { NumberPicker } from "@/components/anime/NumberPicker";
import { OrderSheet } from "@/components/list/OrderSheet";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/EmptyState";
import { goBack } from "@/hooks/useAppBack";
import { useFrozenOrder } from "@/hooks/useFrozenOrder";
import { preferredTitle } from "@/lib/format";
import { collectHashtags, hasHashtag } from "@/lib/hashtags";
import { groupEntries } from "@/lib/franchise/grouping";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import { useListStore, UP_NEXT_CAP } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { ListStatus, TitleLanguage } from "@/types/list";

/**
 * A dedicated status page ("room"). Reached from the overview by tapping a
 * section; pushed onto the My List tab's own back stack, so back returns to the
 * overview. Each room shows the franchise members whose status matches it and
 * renders its section's card language, so drilling in reads as more of the same
 * surface.
 *
 * The minor statuses live here rather than getting rooms of their own: Watching
 * carries Paused (on-hold) at the bottom, Completed offers Dropped as a filter.
 */

/** Stable identity for a card across re-sorts. Module level so the frozen-order
 *  memo is not invalidated on every render. */
const groupKey = (g: FranchiseGroup) => g.rootId;


interface RoomDef {
  title: string;
  /** The empty state's headline ("Nothing want to watch yet" doesn't parse). */
  emptyTitle: string;
  /** Statuses this room collects. Watching folds rewatching and on-hold in. */
  statuses: ListStatus[];
  variant: RoomVariant;
}

const ROOMS: Record<string, RoomDef> = {
  watching: {
    title: "Watching",
    emptyTitle: "Nothing watching yet",
    statuses: ["watching", "rewatching", "on_hold"],
    variant: "hero",
  },
  plan: {
    title: "Want to watch",
    emptyTitle: "Nothing queued yet",
    statuses: ["plan_to_watch"],
    variant: "poster",
  },
  completed: {
    title: "Completed",
    emptyTitle: "Nothing completed yet",
    statuses: ["completed"],
    variant: "shelf",
  },
};

/** How a room is arranged. Not every room offers every option. */
type RoomSort = "recent" | "alpha" | "score" | "manual" | "length" | "added";

const SORT_LABELS: Record<RoomSort, string> = {
  recent: "Recent",
  alpha: "A-Z",
  score: "Score",
  manual: "My order",
  length: "Shortest",
  added: "Recently added",
};

/** Sort options per room; the first is that room's default. Watching and
 *  Completed previously had no sort control at all, which left a several
 *  hundred card room with exactly one way to look at it. */
const ROOM_SORTS: Record<string, RoomSort[]> = {
  watching: ["recent", "alpha"],
  // No "My order" here any more: a hand-made order over ~1600 titles is not a
  // thing anyone can maintain. That order now belongs to Up Next alone.
  plan: ["added", "length", "alpha"],
  completed: ["recent", "alpha", "score"],
};

/** The card's own name, resolved the way the card resolves it (root entry,
 *  the user's title language), so A-Z order agrees with what is on screen. */
function titleOf(g: FranchiseGroup, lang: TitleLanguage): string {
  const root = g.entries.find((e) => e.anilist_id === g.rootId) ?? g.entries[0];
  return preferredTitle(
    {
      romaji: root.title_romaji,
      english: root.title_english,
      native: root.title_native,
    },
    lang,
  );
}

/** Index letter for a title. Anything outside A-Z (digits, symbols, kana,
 *  kanji) collects under "#" rather than inventing buckets we cannot order. */
function letterOf(title: string): string {
  const c = title.trim().charAt(0).toUpperCase();
  return c >= "A" && c <= "Z" ? c : "#";
}

/** Best score across the franchise, matching how the shelf badges one. */
function scoreOf(g: FranchiseGroup): number {
  let best = -1;
  for (const e of g.entries) {
    if (e.score != null && e.score > best) best = e.score;
  }
  return best;
}

const isPaused = (g: FranchiseGroup) => g.displayEntry.status === "on_hold";

/** Total runtime of everything tracked under this card. AniList's duration is
 *  per-episode; 24 is the same fallback Stats uses when it's unknown. */
function totalMinutes(g: FranchiseGroup): number {
  return g.entries.reduce(
    (sum, e) => sum + (e.total_episodes ?? 0) * (e.episode_duration ?? 24),
    0,
  );
}

/** A franchise's place in the queue is its earliest-ranked member; never-ranked
 *  cards sort after the arranged ones. */
function planRankOf(g: FranchiseGroup): number {
  let min = Number.POSITIVE_INFINITY;
  for (const e of g.entries) {
    if (e.plan_rank != null && e.plan_rank < min) min = e.plan_rank;
  }
  return min;
}

export function StatusRoom() {
  const { status = "" } = useParams();
  const navigate = useNavigate();
  const room = ROOMS[status];
  const isCompleted = status === "completed";
  const isPlan = status === "plan";
  // The same add engine every door opens: Discover's search with the full
  // status choice (the add law: a door may suggest, never lock).
  const goDiscoverSearch = () =>
    navigate("/discover", { replace: true, state: { fromSearchIntent: true } });

  const entries = useListStore((s) => s.entries);
  const addToPlanOrder = useListStore((s) => s.addToPlanOrder);
  const defaultView = useSettingsStore((s) => s.defaultView);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const [showDropped, setShowDropped] = useState(false);
  const sortOptions = ROOM_SORTS[status] ?? ["recent"];
  const [sort, setSort] = useState<RoomSort>(sortOptions[0]);
  // Moving between rooms reuses this component, so a sort the new room does
  // not offer must fall back rather than silently produce an empty arrangement.
  const activeSort = sortOptions.includes(sort) ? sort : sortOptions[0];
  const jumpRef = useRef<((groupIndex: number) => void) | null>(null);
  const [activeTags, setActiveTags] = useState<string[]>([]);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [numberFor, setNumberFor] = useState<number | null>(null);
  const [orderOpen, setOrderOpen] = useState(false);

  // Dropped is part of your record, not a place of its own: it hides behind a
  // filter in Completed, where the "have I dealt with this?" answer lives.
  const droppedCount = useMemo(
    () => (isCompleted ? entries.filter((e) => e.status === "dropped").length : 0),
    [entries, isCompleted],
  );

  // The room's entries, before tag filtering. Shared so the facet vocabulary is
  // the room's own and does not shrink as you narrow it.
  const scopedEntries = useMemo(() => {
    if (!room) return [];
    const wanted = new Set<ListStatus>(room.statuses);
    if (isCompleted && showDropped) wanted.add("dropped");
    return entries.filter((e) => wanted.has(e.status));
  }, [entries, room, isCompleted, showDropped]);

  const tagFacets = useMemo(
    () => collectHashtags(scopedEntries.map((e) => e.notes)),
    [scopedEntries],
  );
  // A tag selected in another room may not exist here; drop it rather than
  // filtering the room down to nothing.
  const effectiveTags = useMemo(() => {
    const available = new Set(tagFacets.map((f) => f.key));
    return activeTags.filter((t) => available.has(t));
  }, [activeTags, tagFacets]);

  const groups = useMemo(() => {
    if (!room) return [];
    const built = groupEntries(scopedEntries);
    // A card matches a tag when any of its entries carries it, so filtering
    // never shows a franchise with seasons mysteriously missing.
    const filtered =
      effectiveTags.length === 0
        ? built
        : built.filter((g) =>
            effectiveTags.every((t) => g.entries.some((e) => hasHashtag(e.notes, t))),
          );

    if (activeSort === "alpha") {
      return [...filtered].sort((a, b) =>
        titleOf(a, titleLanguage).localeCompare(titleOf(b, titleLanguage)),
      );
    }
    if (activeSort === "score") {
      // Unscored cards sink rather than claiming the top of a score sort.
      return [...filtered].sort((a, b) => scoreOf(b) - scoreOf(a));
    }
    if (activeSort === "length") {
      // Shortest first: the queue's job is helping you pick something you can
      // actually finish tonight.
      return [...filtered].sort((a, b) => totalMinutes(a) - totalMinutes(b));
    }
    if (activeSort === "added") {
      return [...filtered].sort((a, b) => b.sortAdded - a.sortAdded);
    }

    // Recency key differs by room: Completed sorts by when you FINISHED it (not
    // any later edit), so a re-scored title doesn't jump the queue. Watching
    // uses last-touched.
    const keyOf = (g: FranchiseGroup) =>
      isCompleted
        ? Math.max(...g.entries.map((e) => e.completed_at ?? e.updated_at))
        : g.sortUpdated;

    return [...filtered].sort((a, b) => {
      // Paused sinks below everything you're actually watching.
      if (status === "watching") {
        const paused = Number(isPaused(a)) - Number(isPaused(b));
        if (paused !== 0) return paused;
      }
      return keyOf(b) - keyOf(a);
    });
  }, [scopedEntries, effectiveTags, room, status, isCompleted, activeSort, titleLanguage]);

  // The room is the whole library. Up Next lives on the Overview, where the
  // queue rail already is: duplicating it here as a 299px band left the actual
  // list 265px of an 844px phone.
  const library = groups;

  // Legacy ranks are settled by the store, at load and at import, so this view
  // no longer migrates anything. A data migration living in a screen was the
  // reason out-of-range numbers appeared to fix themselves "after a few
  // relaunches": nothing repaired them until you happened to open this room.

  const frozen = useFrozenOrder(
    library,
    groupKey,
    `${status}|${showDropped}|${activeSort}|${effectiveTags.join(",")}`,
  );
  const displayGroups = frozen.items;
  const staleCount = frozen.staleCount;

  // Rail sections follow the arrangement, so they only mean something while the
  // list is actually alphabetical.
  const sections = useMemo(() => {
    if (activeSort !== "alpha") return [];
    const out: RailSection[] = [];
    let last = "";
    displayGroups.forEach((g, i) => {
      const key = letterOf(titleOf(g, titleLanguage));
      if (key !== last) {
        out.push({ key, index: i });
        last = key;
      }
    });
    return out;
  }, [displayGroups, activeSort, titleLanguage]);

  // What the badge counts: anything narrowing or reordering away from the
  // room's default, so the button alone tells you the list is not "everything".
  const filterCount =
    effectiveTags.length +
    (activeSort !== sortOptions[0] ? 1 : 0) +
    (isCompleted && showDropped ? 1 : 0);

  /**
   * Join or leave the shelf. The store owns the cap (and says so out loud when
   * it is full), since it is the thing that knows every ranked card.
   *
   * useCallback is load-bearing, not tidiness: this is handed to every card in
   * the list, and a fresh closure each render would break QueueCard's memo and
   * put every visible card back into per-scroll-frame reconciliation. It reads
   * `groups` through a ref so the identity survives list changes too.
   */
  const groupsRef = useRef(groups);
  groupsRef.current = groups;
  const entriesRef = useRef(entries);
  entriesRef.current = entries;
  const onNumber = useCallback((rootId: number) => {
    const group = groupsRef.current.find((g) => g.rootId === rootId);
    if (!group) return;
    // One entry carries the card's number. Stamping the whole franchise would
    // write a row per season for a single tap, which is the write
    // amplification the old mover suffered from.
    const rep =
      group.entries.find((e) => e.anilist_id === group.rootId && e.status === "plan_to_watch") ??
      group.entries.find((e) => e.status === "plan_to_watch") ??
      group.entries[0];
    setNumberFor(rep.anilist_id);
  }, []);

  /**
   * Press-and-hold on a card appends it to the watch order. Returns false when
   * the order is full so the card can say so on itself, rather than the hold
   * appearing to succeed and silently doing nothing.
   */
  const onQuickAdd = useCallback(
    (rootId: number): boolean => {
      const group = groupsRef.current.find((g) => g.rootId === rootId);
      if (!group) return false;
      const rep =
        group.entries.find((e) => e.status === "plan_to_watch") ?? group.entries[0];
      // The store owns the cap and the slot choice, so this and the My Order
      // sheet cannot drift apart on either rule.
      return addToPlanOrder(rep.anilist_id);
    },
    [addToPlanOrder],
  );

  /** How many cards carry a number, for the dashboard button's badge. */
  const orderCount = useMemo(
    () =>
      isPlan
        ? scopedEntries.filter((e) => e.plan_rank != null).length
        : 0,
    [isPlan, scopedEntries],
  );

  /** rootId -> the number stamped on that card. */
  const planNumbers = useMemo(() => {
    const m = new Map<number, number>();
    if (!isPlan) return m;
    for (const g of groups) {
      const n = planRankOf(g);
      if (n !== Number.POSITIVE_INFINITY) m.set(g.rootId, n);
    }
    return m;
  }, [groups, isPlan]);

  if (!room) return <Navigate to="/" replace />;

  return (
    <div className="k-page k-page--room">
      <div className="k-roomhead">
        <button
          type="button"
          className="k-roomhead__back"
          onClick={goBack}
          aria-label="Back to My List"
        >
          <Icon icon={ChevronLeft} size={22} />
        </button>
        <h1 className="k-roomhead__title">{room.title}</h1>
        <span className="k-roomhead__count">{displayGroups.length}</span>

        {/* The order is held still while you work; this is the way back to a
            fresh sort, and it says how many entries are waiting to move. */}
        {staleCount > 0 && (
          <button
            type="button"
            className="k-roomhead__chip k-roomhead__chip--restack"
            onClick={frozen.reorder}
            aria-label={`Reorder list, ${staleCount} ${staleCount === 1 ? "entry has" : "entries have"} moved`}
          >
            <Icon icon={ArrowUpDown} size={13} />
            {staleCount} updated
          </button>
        )}

        {/* The watch order gets its own door: it is a thing you manage, not a
            filter, and it must be reachable without first finding a card. */}
        {isPlan && (
          <button
            type="button"
            className={`k-roomhead__filter${orderCount > 0 ? " k-roomhead__filter--on" : ""}`}
            onClick={() => setOrderOpen(true)}
            aria-label={
              orderCount > 0
                ? `My order, ${orderCount} of ${UP_NEXT_CAP}`
                : "My order, empty"
            }
          >
            <Icon icon={ListOrdered} size={17} />
            {orderCount > 0 && <span className="k-roomhead__badge">{orderCount}</span>}
          </button>
        )}

        {/* One control for every way of narrowing this room, instead of a sort
            row plus a tag strip plus a toggle all holding screen permanently. */}
        <button
          type="button"
          className={`k-roomhead__filter${filterCount > 0 ? " k-roomhead__filter--on" : ""}`}
          onClick={() => setFiltersOpen(true)}
          aria-label={
            filterCount > 0
              ? `Filter and sort, ${filterCount} active`
              : "Filter and sort"
          }
        >
          <Icon icon={SlidersHorizontal} size={17} />
          {filterCount > 0 && <span className="k-roomhead__badge">{filterCount}</span>}
        </button>
      </div>

      {displayGroups.length === 0 ? (
        effectiveTags.length > 0 ? (
          // A filtered-to-nothing room is not an empty room; offer the way back
          // rather than telling someone with 700 cards they have none.
          <EmptyState
            title="Nothing matches those tags"
            subtitle="Try removing one, or clear the filter to see everything again."
            action={
              <Button variant="primary" onClick={() => setActiveTags([])}>
                Clear tags
              </Button>
            }
          />
        ) : (
          <EmptyState
            title={room.emptyTitle}
            subtitle="Add something from Discover and it lands here."
            action={
              <Button variant="primary" onClick={goDiscoverSearch}>
                Search for anime
              </Button>
            }
          />
        )
      ) : (
        /* The rail is positioned against THIS box, not the page, so it lines up
           with the list it scrolls instead of floating over the chrome. */
        <div className="k-roomlist">
          <FranchiseCollection
            groups={displayGroups}
            view={defaultView}
            variant={room.variant}
            // Cards carry the pin so the shortlist is curated from the full
            // list; Up Next itself is shown on the Overview.
            onNumber={isPlan ? onNumber : undefined}
            planNumbers={isPlan ? planNumbers : undefined}
            onQuickAdd={isPlan ? onQuickAdd : undefined}
            restoreKey={`room.${status}.scroll`}
            jumpRef={jumpRef}
          />
          <LetterRail sections={sections} onJump={(i) => jumpRef.current?.(i)} />
        </div>
      )}

      <NumberPicker
        open={numberFor != null}
        onClose={() => setNumberFor(null)}
        anilistId={numberFor}
      />

      <OrderSheet open={orderOpen} onClose={() => setOrderOpen(false)} />

      <RoomFilters
        open={filtersOpen}
        onClose={() => setFiltersOpen(false)}
        sorts={sortOptions.map((key) => ({ key, label: SORT_LABELS[key] }))}
        activeSort={activeSort}
        onSort={(key) => setSort(key as RoomSort)}
        tags={tagFacets}
        activeTags={effectiveTags}
        onToggleTag={(key) =>
          setActiveTags((prev) =>
            prev.includes(key) ? prev.filter((t) => t !== key) : [...prev, key],
          )
        }
        onClearTags={() => setActiveTags([])}
        droppedCount={isCompleted ? droppedCount : 0}
        showDropped={showDropped}
        onToggleDropped={isCompleted ? () => setShowDropped((v) => !v) : undefined}
      />
    </div>
  );
}
