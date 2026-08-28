import { useMemo, useRef, useState } from "react";
import { Navigate, useNavigate, useParams } from "react-router-dom";
import { ArrowUpDown } from "lucide-react";
import { FranchiseCollection } from "@/components/list/FranchiseCollection";
import type { RoomVariant } from "@/components/list/FranchiseCollection";
import { LetterRail } from "@/components/list/LetterRail";
import type { RailSection } from "@/components/list/LetterRail";
import { RoomHeader } from "@/components/list/RoomHeader";
import { Button } from "@/components/ui/Button";
import { FilterMenu } from "@/components/ui/FilterMenu";
import type { FilterSection } from "@/components/ui/FilterMenu";
import { Icon } from "@/components/ui/Icon";
import { ViewSwitch } from "@/components/ui/ViewSwitch";
import { EmptyState } from "@/components/ui/EmptyState";
import { useDebounce } from "@/hooks/useDebounce";
import { useFrozenOrder } from "@/hooks/useFrozenOrder";
import { normalizeForSearch, preferredTitle } from "@/lib/format";
import { collectHashtags, hasHashtag } from "@/lib/hashtags";
import { groupEntries } from "@/lib/franchise/grouping";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { ListStatus, TitleLanguage } from "@/types/list";

/**
 * The generic status room, reached from the launcher and pushed onto the My
 * List tab's own back stack.
 *
 * Planned and Completed have built rooms of their own (an ordered watch plan
 * and the completion ledger), so what is left here is the in-progress room:
 * Watching, with Paused carried at the bottom rather than exiled to a room
 * nobody would visit. The map still gates the route, so a stray /list/whatever
 * lands back on the launcher instead of rendering an empty page.
 */

/** Stable identity for a card across re-sorts. Module level so the frozen-order
 *  memo is not invalidated on every render. */
const groupKey = (g: FranchiseGroup) => g.rootId;

interface RoomDef {
  title: string;
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
};

type RoomSort = "recent" | "alpha";

const SORT_LABELS: Record<RoomSort, string> = {
  recent: "Recent",
  alpha: "A-Z",
};

const SORTS: RoomSort[] = ["recent", "alpha"];

/** The card's own name, resolved the way the card resolves it (root entry,
 *  the user's title language), so A-Z order agrees with what is on screen. */
function titleOf(g: FranchiseGroup, lang: TitleLanguage): string {
  const root = g.entries.find((e) => e.anilist_id === g.rootId) ?? g.entries[0];
  return preferredTitle(
    { romaji: root.title_romaji, english: root.title_english, native: root.title_native },
    lang,
  );
}

/** Index letter for a title. Anything outside A-Z (digits, symbols, kana,
 *  kanji) collects under "#" rather than inventing buckets we cannot order. */
function letterOf(title: string): string {
  const c = title.trim().charAt(0).toUpperCase();
  return c >= "A" && c <= "Z" ? c : "#";
}

const isPaused = (g: FranchiseGroup) => g.displayEntry.status === "on_hold";

export function StatusRoom() {
  const { status = "" } = useParams();
  const navigate = useNavigate();
  const room = ROOMS[status];

  const entries = useListStore((s) => s.entries);
  const defaultView = useSettingsStore((s) => s.defaultView);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const [sort, setSort] = useState<RoomSort>("recent");
  const [activeTags, setActiveTags] = useState<string[]>([]);
  const [search, setSearch] = useState("");
  const [searchOpen, setSearchOpen] = useState(false);
  const jumpRef = useRef<((groupIndex: number) => void) | null>(null);
  const query = normalizeForSearch(useDebounce(search, 200));

  const goDiscoverSearch = () =>
    navigate("/discover", { replace: true, state: { fromSearchIntent: true } });

  // The room's entries, before tag filtering. Shared so the facet vocabulary is
  // the room's own and does not shrink as you narrow it.
  const scopedEntries = useMemo(() => {
    if (!room) return [];
    const wanted = new Set<ListStatus>(room.statuses);
    return entries.filter((e) => wanted.has(e.status));
  }, [entries, room]);

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

  // Grouping is the expensive step and none of the narrowing below changes it,
  // so it gets its own memo rather than being redone per keystroke.
  const built = useMemo(() => groupEntries(scopedEntries), [scopedEntries]);

  /** Search text per card, precomputed once instead of per keystroke. */
  const haystacks = useMemo(() => {
    const m = new Map<FranchiseGroup, string>();
    for (const g of built) {
      let s = "";
      for (const e of g.entries) {
        s += `${e.title_romaji} ${e.title_english ?? ""} ${e.title_native ?? ""} `;
      }
      m.set(g, normalizeForSearch(s));
    }
    return m;
  }, [built]);

  const groups = useMemo(() => {
    if (!room) return [];
    // A card matches a tag when any of its entries carries it, so filtering
    // never shows a franchise with seasons mysteriously missing.
    let filtered =
      effectiveTags.length === 0
        ? built
        : built.filter((g) =>
            effectiveTags.every((t) => g.entries.some((e) => hasHashtag(e.notes, t))),
          );
    if (query) {
      filtered = filtered.filter((g) => (haystacks.get(g) ?? "").includes(query));
    }

    if (sort === "alpha") {
      return [...filtered].sort((a, b) =>
        titleOf(a, titleLanguage).localeCompare(titleOf(b, titleLanguage)),
      );
    }
    return [...filtered].sort((a, b) => {
      // Paused sinks below everything you're actually watching.
      const paused = Number(isPaused(a)) - Number(isPaused(b));
      if (paused !== 0) return paused;
      return b.sortUpdated - a.sortUpdated;
    });
  }, [built, haystacks, effectiveTags, query, room, sort, titleLanguage]);

  const frozen = useFrozenOrder(
    groups,
    groupKey,
    `${status}|${sort}|${effectiveTags.join(",")}|${query}`,
  );
  const displayGroups = frozen.items;

  // Rail sections follow the arrangement, so they only mean something while the
  // list is actually alphabetical.
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

  // What the badge counts: anything narrowing or reordering away from the
  // room's default, so the button alone tells you the list is not "everything".
  const filterCount = effectiveTags.length + (sort !== SORTS[0] ? 1 : 0);

  const filterSections: FilterSection[] = [
    {
      kind: "choice",
      id: "sort",
      label: "Sort",
      value: sort,
      options: SORTS.map((key) => ({ key, label: SORT_LABELS[key] })),
      onPick: (key) => setSort(key as RoomSort),
    },
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

  if (!room) return <Navigate to="/" replace />;

  return (
    <div className="k-page k-page--room">
      <RoomHeader
        title={room.title}
        search={{
          value: search,
          onChange: setSearch,
          open: searchOpen,
          onOpen: () => setSearchOpen(true),
          onClose: () => {
            setSearch("");
            setSearchOpen(false);
          },
          placeholder: `Search ${scopedEntries.length.toLocaleString()} in ${room.title.toLowerCase()}`,
        }}
        actions={
          <>
            {/* The order is held still while you log; this is the way back to a
                fresh sort, and it says how many entries are waiting to move. */}
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

            <ViewSwitch />

            <FilterMenu
              sections={filterSections}
              activeCount={filterCount}
              onClearAll={() => {
                setActiveTags([]);
                setSort(SORTS[0]);
              }}
            />
          </>
        }
      />

      {displayGroups.length === 0 ? (
        query ? (
          <EmptyState
            title={`Nothing in ${room.title.toLowerCase()} matches “${search.trim()}”`}
            subtitle="This only looks inside this room. My List's own search looks across every status."
          />
        ) : effectiveTags.length > 0 ? (
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
            subtitle="Start something from your plan and it lands here."
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
            restoreKey={`room.${status}.scroll`}
            jumpRef={jumpRef}
          />
          <LetterRail sections={sections} onJump={(i) => jumpRef.current?.(i)} />
        </div>
      )}
    </div>
  );
}
