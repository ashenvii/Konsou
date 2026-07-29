import { useCallback, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowUpDown, ListOrdered, SlidersHorizontal } from "lucide-react";
import { FranchiseCollection } from "@/components/list/FranchiseCollection";
import { LetterRail } from "@/components/list/LetterRail";
import type { RailSection } from "@/components/list/LetterRail";
import { RoomFilters } from "@/components/list/RoomFilters";
import { RoomHeader } from "@/components/list/RoomHeader";
import { NumberPicker } from "@/components/anime/NumberPicker";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/EmptyState";
import { useFrozenOrder } from "@/hooks/useFrozenOrder";
import { preferredTitle } from "@/lib/format";
import { collectHashtags, hasHashtag } from "@/lib/hashtags";
import { groupEntries } from "@/lib/franchise/grouping";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import { useListStore, UP_NEXT_CAP } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { TitleLanguage } from "@/types/list";

/**
 * The watch plan.
 *
 * The room's spine is the order you chose. The numbered titles lead the list in
 * their own order, and everything else follows behind them — one list, not a
 * shelf sitting on top of a list. That distinction is load-bearing: the shelf
 * version of this room spent 299px of an 844px phone restating what the top of
 * the list already said.
 *
 * Numbering is capped (UP_NEXT_CAP) on purpose. A hand-made order over a
 * thousand planned titles is not a thing anyone can maintain; a shortlist you
 * can actually rank is. Beyond the shortlist the room is a library, sorted by
 * whatever is useful — how recently you added something, or how short it is
 * when you want to finish something tonight.
 *
 * Every card carries both ways out: Start and Done, the same size, each
 * undoable. See QueueSlider's card.
 */

/** Stable identity for a card across re-sorts. Module level so the frozen-order
 *  memo is not invalidated on every render. */
const groupKey = (g: FranchiseGroup) => g.rootId;

type PlanSort = "order" | "added" | "length" | "alpha";

const SORT_LABELS: Record<PlanSort, string> = {
  order: "My order",
  added: "Recently added",
  length: "Shortest",
  alpha: "A-Z",
};

const SORTS: PlanSort[] = ["order", "added", "length", "alpha"];

/** A franchise's place in the order: its earliest-numbered member. Unnumbered
 *  cards sort after every numbered one. */
function planRankOf(g: FranchiseGroup): number {
  let min = Number.POSITIVE_INFINITY;
  for (const e of g.entries) {
    if (e.plan_rank != null && e.plan_rank < min) min = e.plan_rank;
  }
  return min;
}

/** The card's own name, resolved the way the card resolves it, so A-Z order
 *  agrees with what is on screen. */
function titleOf(g: FranchiseGroup, lang: TitleLanguage): string {
  const root = g.entries.find((e) => e.anilist_id === g.rootId) ?? g.entries[0];
  return preferredTitle(
    { romaji: root.title_romaji, english: root.title_english, native: root.title_native },
    lang,
  );
}

/** Index letter for a title. Anything outside A-Z collects under "#". */
function letterOf(title: string): string {
  const c = title.trim().charAt(0).toUpperCase();
  return c >= "A" && c <= "Z" ? c : "#";
}

/** Total runtime of everything under this card. AniList's duration is
 *  per-episode; 24 is the same fallback Stats uses when it's unknown. */
function totalMinutes(g: FranchiseGroup): number {
  return g.entries.reduce(
    (sum, e) => sum + (e.total_episodes ?? 0) * (e.episode_duration ?? 24),
    0,
  );
}

export function PlanRoom() {
  const navigate = useNavigate();
  const entries = useListStore((s) => s.entries);
  const addToPlanOrder = useListStore((s) => s.addToPlanOrder);
  const defaultView = useSettingsStore((s) => s.defaultView);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [sort, setSort] = useState<PlanSort>("order");
  const [activeTags, setActiveTags] = useState<string[]>([]);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [numberFor, setNumberFor] = useState<number | null>(null);
  const jumpRef = useRef<((groupIndex: number) => void) | null>(null);

  const goDiscoverSearch = () =>
    navigate("/discover", { replace: true, state: { fromSearchIntent: true } });

  const scopedEntries = useMemo(
    () => entries.filter((e) => e.status === "plan_to_watch"),
    [entries],
  );

  const tagFacets = useMemo(
    () => collectHashtags(scopedEntries.map((e) => e.notes)),
    [scopedEntries],
  );
  // A tag selected in another room may not exist here; drop it rather than
  // filtering this one down to nothing.
  const effectiveTags = useMemo(() => {
    const available = new Set(tagFacets.map((f) => f.key));
    return activeTags.filter((t) => available.has(t));
  }, [activeTags, tagFacets]);

  const groups = useMemo(() => {
    const built = groupEntries(scopedEntries);
    // A card matches a tag when any of its entries carries it, so filtering
    // never shows a franchise with seasons mysteriously missing.
    const filtered =
      effectiveTags.length === 0
        ? built
        : built.filter((g) =>
            effectiveTags.every((t) => g.entries.some((e) => hasHashtag(e.notes, t))),
          );

    if (sort === "alpha") {
      return [...filtered].sort((a, b) =>
        titleOf(a, titleLanguage).localeCompare(titleOf(b, titleLanguage)),
      );
    }
    if (sort === "length") {
      // Shortest first: this room's job is helping you pick something you can
      // actually finish tonight.
      return [...filtered].sort((a, b) => totalMinutes(a) - totalMinutes(b));
    }
    if (sort === "added") {
      return [...filtered].sort((a, b) => b.sortAdded - a.sortAdded);
    }
    // My order: the numbers you assigned lead, newest additions behind them.
    return [...filtered].sort((a, b) => {
      const ra = planRankOf(a);
      const rb = planRankOf(b);
      return ra !== rb ? ra - rb : b.sortAdded - a.sortAdded;
    });
  }, [scopedEntries, effectiveTags, sort, titleLanguage]);

  const frozen = useFrozenOrder(
    groups,
    groupKey,
    `plan|${sort}|${effectiveTags.join(",")}`,
  );
  const displayGroups = frozen.items;

  // The A-Z rail only means something while the list is actually alphabetical.
  const sections = useMemo(() => {
    if (sort !== "alpha") return [];
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
  }, [displayGroups, sort, titleLanguage]);

  const filterCount = effectiveTags.length + (sort !== SORTS[0] ? 1 : 0);

  /**
   * useCallback is load-bearing, not tidiness: these are handed to every card
   * in the list, and a fresh closure each render would break QueueCard's memo
   * and put every visible card back into per-scroll-frame reconciliation. They
   * read `groups` through a ref so the identity survives list changes too.
   */
  const groupsRef = useRef(groups);
  groupsRef.current = groups;

  const onNumber = useCallback((rootId: number) => {
    const group = groupsRef.current.find((g) => g.rootId === rootId);
    if (!group) return;
    // One entry carries the card's number. Stamping the whole franchise would
    // write a row per season for a single tap.
    const rep =
      group.entries.find((e) => e.anilist_id === group.rootId && e.status === "plan_to_watch") ??
      group.entries.find((e) => e.status === "plan_to_watch") ??
      group.entries[0];
    setNumberFor(rep.anilist_id);
  }, []);

  /**
   * Press-and-hold on a card appends it to the order. Returns false when the
   * order is full so the card can say so on itself, rather than the hold
   * appearing to succeed and silently doing nothing.
   */
  const onQuickAdd = useCallback(
    (rootId: number): boolean => {
      const group = groupsRef.current.find((g) => g.rootId === rootId);
      if (!group) return false;
      const rep = group.entries.find((e) => e.status === "plan_to_watch") ?? group.entries[0];
      // The store owns the cap and the slot choice, so this and the order sheet
      // cannot drift apart on either rule.
      return addToPlanOrder(rep.anilist_id);
    },
    [addToPlanOrder],
  );

  /** How many cards carry a number, for the order button's badge. */
  const orderCount = useMemo(
    () => scopedEntries.filter((e) => e.plan_rank != null).length,
    [scopedEntries],
  );

  /** What the plan actually costs, in hours. The count alone says how many
   *  things are waiting; this says how much of your life they are. Unknown
   *  lengths add nothing, so the figure reads as a floor. */
  const backlogHours = useMemo(
    () =>
      Math.round(
        scopedEntries.reduce(
          (m, e) => m + (e.total_episodes ?? 0) * (e.episode_duration ?? 24),
          0,
        ) / 60,
      ),
    [scopedEntries],
  );

  /** rootId -> the number stamped on that card. */
  const planNumbers = useMemo(() => {
    const m = new Map<number, number>();
    for (const g of groups) {
      const n = planRankOf(g);
      if (n !== Number.POSITIVE_INFINITY) m.set(g.rootId, n);
    }
    return m;
  }, [groups]);

  return (
    <div className="k-page k-page--room">
      <RoomHeader
        title="Planned"
        census={[
          `${displayGroups.length} ${displayGroups.length === 1 ? "title" : "titles"}`,
          orderCount > 0 ? `${orderCount} numbered` : null,
          backlogHours > 0 ? `${backlogHours.toLocaleString()} hours waiting` : null,
        ]}
        purpose="Everything you mean to watch, in the order you mean to watch it."
        actions={
          <>
            {/* The order is held still while you work; this is the way back to
                a fresh sort, and it says how many entries are waiting to move. */}
            {frozen.staleCount > 0 && (
              <button
                type="button"
                className="k-roomhead__chip k-roomhead__chip--restack"
                onClick={frozen.reorder}
                aria-label={`Reorder list, ${frozen.staleCount} ${frozen.staleCount === 1 ? "entry has" : "entries have"} moved`}
              >
                <Icon icon={ArrowUpDown} size={13} />
                {frozen.staleCount} updated
              </button>
            )}

            {/* The order gets its own door: it is a thing you manage, not a
                filter, and it must be reachable without first finding a card. */}
            <button
              type="button"
              className={`k-roomhead__filter${orderCount > 0 ? " k-roomhead__filter--on" : ""}`}
              onClick={() => navigate("/list/plan/order", { replace: true })}
              aria-label={
                orderCount > 0 ? `My order, ${orderCount} of ${UP_NEXT_CAP}` : "My order, empty"
              }
            >
              <Icon icon={ListOrdered} size={17} />
              {orderCount > 0 && <span className="k-roomhead__badge">{orderCount}</span>}
            </button>

            <button
              type="button"
              className={`k-roomhead__filter${filterCount > 0 ? " k-roomhead__filter--on" : ""}`}
              onClick={() => setFiltersOpen(true)}
              aria-label={
                filterCount > 0 ? `Filter and sort, ${filterCount} active` : "Filter and sort"
              }
            >
              <Icon icon={SlidersHorizontal} size={17} />
              {filterCount > 0 && <span className="k-roomhead__badge">{filterCount}</span>}
            </button>
          </>
        }
      />

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
            title="Nothing queued yet"
            subtitle="Anything you might watch goes here, in the order you mean to watch it."
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
            variant="poster"
            onNumber={onNumber}
            planNumbers={planNumbers}
            onQuickAdd={onQuickAdd}
            restoreKey="room.plan.scroll"
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

      <RoomFilters
        open={filtersOpen}
        onClose={() => setFiltersOpen(false)}
        sorts={SORTS.map((key) => ({ key, label: SORT_LABELS[key] }))}
        activeSort={sort}
        onSort={(key) => setSort(key as PlanSort)}
        tags={tagFacets}
        activeTags={effectiveTags}
        onToggleTag={(key) =>
          setActiveTags((prev) =>
            prev.includes(key) ? prev.filter((t) => t !== key) : [...prev, key],
          )
        }
        onClearTags={() => setActiveTags([])}
      />
    </div>
  );
}
