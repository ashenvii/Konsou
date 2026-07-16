import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ChevronRight, Search, X } from "lucide-react";
import { FranchiseCard } from "@/components/anime/FranchiseCard";
import { FranchiseSheet } from "@/components/anime/FranchiseSheet";
import { HeroBinge } from "@/components/anime/HeroBinge";
import { FranchiseCollection } from "@/components/list/FranchiseCollection";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { ImportSheet } from "@/components/ui/ImportSheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { useDebounce } from "@/hooks/useDebounce";
import { groupEntries } from "@/lib/franchise/grouping";
import { normalizeForSearch } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { getUiState, setUiState } from "@/lib/uiState";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { AnimeListEntry, ListStatus } from "@/types/list";

/**
 * My List landing. A responsive dashboard, not a phone layout stretched onto a
 * desktop: on wide screens the three statuses sit side by side as columns that
 * fill the width; on a phone they stack into sections. Same content, laid out
 * for the platform it's on. Each column shows a recent slice and opens its
 * dedicated room for the full, sortable view. A query turns the whole surface
 * into a flat "have you seen it?" search across every status.
 */

type BandKind = "watching" | "plan" | "completed";

// How many rows a column shows before "see all N" points at the room.
const COLUMN_LIMIT: Record<BandKind, number> = {
  watching: 12,
  plan: 12,
  completed: 8,
};

function recencyKey(g: FranchiseGroup, kind: BandKind): number {
  if (kind === "completed") {
    return Math.max(...g.entries.map((e) => e.completed_at ?? e.updated_at));
  }
  if (kind === "plan") return g.sortAdded;
  return g.sortUpdated;
}

function groupsFor(entries: AnimeListEntry[], statuses: ListStatus[]): FranchiseGroup[] {
  const wanted = new Set(statuses);
  return groupEntries(entries.filter((e) => wanted.has(e.status)));
}

function sortBand(groups: FranchiseGroup[], kind: BandKind): FranchiseGroup[] {
  return [...groups].sort((a, b) => recencyKey(b, kind) - recencyKey(a, kind));
}

export function Overview() {
  const navigate = useNavigate();
  const loaded = useListStore((s) => s.loaded);
  const entries = useListStore((s) => s.entries);

  const [search, setSearchState] = useState(() => getUiState("mylist.search", ""));
  const [importOpen, setImportOpen] = useState(false);
  const [activeRootId, setActiveRootId] = useState<number | null>(null);
  const debounced = useDebounce(search, 300);
  const setSearch = (v: string) => {
    setSearchState(v);
    setUiState("mylist.search", v);
  };

  const watching = useMemo(
    () => sortBand(groupsFor(entries, ["watching", "rewatching"]), "watching"),
    [entries],
  );
  // The 1-2 most-active shows are spotlit in the Hero Binge and pulled out of
  // the Watching column so nothing shows twice.
  const heroGroups = useMemo(() => watching.slice(0, 2), [watching]);
  const watchingRest = useMemo(() => watching.slice(heroGroups.length), [watching, heroGroups]);
  const plan = useMemo(() => sortBand(groupsFor(entries, ["plan_to_watch"]), "plan"), [entries]);
  const completed = useMemo(() => sortBand(groupsFor(entries, ["completed"]), "completed"), [entries]);

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
    return [...watching, ...plan, ...completed].find((g) => g.rootId === activeRootId) ?? null;
  }, [activeRootId, watching, plan, completed]);

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
            <Button
              variant="primary"
              onClick={() => navigate("/discover", { replace: true, state: { fromSearchIntent: true } })}
            >
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

  return (
    <div className="k-page k-overview">
      <div className="k-ovsearch">
        <Icon icon={Search} size={18} color="var(--color-text-tertiary)" />
        <input
          className="k-ovsearch__input"
          type="search"
          inputMode="search"
          placeholder="Have you seen it? Search everything…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search your whole list"
        />
        {search && (
          <button
            type="button"
            className="k-ovsearch__clear"
            onClick={() => setSearch("")}
            aria-label="Clear search"
          >
            <Icon icon={X} size={16} />
          </button>
        )}
      </div>

      {searching ? (
        matches.length > 0 ? (
          <>
            <p className="k-list-results">
              {matches.length} {matches.length === 1 ? "match" : "matches"} for “{debounced.trim()}”
            </p>
            <FranchiseCollection groups={matches} view="grid" restoreKey="overview.search" />
          </>
        ) : (
          <EmptyState
            title="No matches"
            subtitle={`Nothing in your list matches “${debounced.trim()}”.`}
          />
        )
      ) : (
        <div className="k-overview__scroll konsou-scroll">
          <HeroBinge groups={heroGroups} onOpen={setActiveRootId} />
          <div className="k-overview__grid">
            <Column
              title="Watching"
              kind="watching"
              groups={watchingRest}
              onOpenRoom={() => openRoom("/list/watching")}
              onCard={setActiveRootId}
            />
            <Column
              title="Want to watch"
              kind="plan"
              groups={plan}
              onOpenRoom={() => openRoom("/list/plan")}
              onCard={setActiveRootId}
            />
            <Column
              title="Completed"
              kind="completed"
              groups={completed}
              onOpenRoom={() => openRoom("/list/completed")}
              onCard={setActiveRootId}
            />
          </div>
        </div>
      )}

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

function Column({
  title,
  kind,
  groups,
  onOpenRoom,
  onCard,
}: {
  title: string;
  kind: BandKind;
  groups: FranchiseGroup[];
  onOpenRoom: () => void;
  onCard: (rootId: number) => void;
}) {
  if (groups.length === 0) return null;
  const limit = COLUMN_LIMIT[kind];
  const shown = groups.slice(0, limit);
  const overflow = groups.length - shown.length;

  return (
    <section className={`k-ovcol k-ovcol--${kind}`}>
      <div className="k-ovcol__head">
        <h2 className="k-ovcol__title">{title}</h2>
        <span className="k-ovcol__count">{groups.length}</span>
      </div>
      <div className="k-ovcol__list">
        {shown.map((g) => (
          <FranchiseCard key={g.rootId} group={g} view="list" onOpen={onCard} />
        ))}
      </div>
      <button type="button" className="k-ovcol__more" onClick={onOpenRoom}>
        {overflow > 0 ? `See all ${groups.length}` : "Open room"}
        <Icon icon={ChevronRight} size={15} />
      </button>
    </section>
  );
}
