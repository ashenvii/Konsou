import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ChevronRight, Plus, Search, X } from "lucide-react";
import { FranchiseSheet } from "@/components/anime/FranchiseSheet";
import { HeroBinge } from "@/components/anime/HeroBinge";
import { QueueSlider } from "@/components/anime/QueueSlider";
import { DigitalShelf } from "@/components/anime/DigitalShelf";
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
import type { ReactNode } from "react";
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
  // Every add door on this page opens the same engine: Discover's search with
  // the full status choice (the add law: a door may suggest, never lock).
  const goDiscoverSearch = () =>
    navigate("/discover", { replace: true, state: { fromSearchIntent: true } });
  const debounced = useDebounce(search, 300);
  const setSearch = (v: string) => {
    setSearchState(v);
    setUiState("mylist.search", v);
  };

  const watching = useMemo(
    () => sortBand(groupsFor(entries, ["watching", "rewatching"]), "watching"),
    [entries],
  );
  // The 1-2 most-active shows are spotlit in the Hero Binge; the rest of
  // Watching lives one tap away in its room.
  const heroGroups = useMemo(() => watching.slice(0, 2), [watching]);
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
          {/* Sections stay on the page when empty: a missing section reads as
              a broken page on a small library, and the invitations are the
              doors into the habits (queue it, start it, finish it). */}
          <Section
            title="Watching"
            count={watching.length}
            onOpenRoom={() => openRoom("/list/watching")}
          >
            {watching.length > 0 ? (
              <HeroBinge groups={heroGroups} onOpen={setActiveRootId} />
            ) : (
              <SectionEmpty>
                {plan.length > 0
                  ? "Nothing on right now. Start something from your queue."
                  : "Nothing on right now."}
              </SectionEmpty>
            )}
          </Section>
          <Section
            title="Want to watch"
            count={plan.length}
            onOpenRoom={() => openRoom("/list/plan")}
          >
            {plan.length > 0 ? (
              <QueueSlider
                groups={plan.slice(0, 15)}
                onOpen={setActiveRootId}
                onAdd={goDiscoverSearch}
              />
            ) : (
              <SectionEmpty
                action={{ label: "Add something to watch", onClick: goDiscoverSearch }}
              >
                The scratchpad for what to watch next, so a title never slips
                away again.
              </SectionEmpty>
            )}
          </Section>
          <Section
            title="Completed"
            count={completed.length}
            onOpenRoom={() => openRoom("/list/completed")}
          >
            {completed.length > 0 ? (
              <DigitalShelf groups={completed.slice(0, 15)} onOpen={setActiveRootId} />
            ) : (
              <SectionEmpty>Shows you finish take their place here.</SectionEmpty>
            )}
          </Section>
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

function Section({
  title,
  count,
  onOpenRoom,
  children,
}: {
  title: string;
  count: number;
  onOpenRoom: () => void;
  children: ReactNode;
}) {
  return (
    <section className="k-ovsection">
      <div className="k-ovsection__head">
        <h2 className="k-ovsection__title">{title}</h2>
        {/* An empty room is a dead end, so its door and count stand down. */}
        {count > 0 && <span className="k-ovsection__count">{count}</span>}
        {count > 0 && (
          <button type="button" className="k-ovsection__more" onClick={onOpenRoom}>
            See all
            <Icon icon={ChevronRight} size={15} />
          </button>
        )}
      </div>
      {children}
    </section>
  );
}

/** The in-section invitation: one quiet line about what belongs here, plus at
 *  most one door. Small on purpose; the page's real content stays the star. */
function SectionEmpty({
  action,
  children,
}: {
  action?: { label: string; onClick: () => void };
  children: ReactNode;
}) {
  return (
    <div className="k-ovempty">
      <p className="k-ovempty__text">{children}</p>
      {action && (
        <button type="button" className="k-ovempty__action" onClick={action.onClick}>
          <Icon icon={Plus} size={16} />
          {action.label}
        </button>
      )}
    </div>
  );
}
