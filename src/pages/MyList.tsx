import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FranchiseCollection } from "@/components/list/FranchiseCollection";
import { ListToolbar } from "@/components/list/ListToolbar";
import { SortSheet } from "@/components/list/SortSheet";
import { TonightQueue } from "@/components/list/TonightQueue";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { ImportSheet } from "@/components/ui/ImportSheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { useDebounce } from "@/hooks/useDebounce";
import { groupEntries } from "@/lib/franchise/grouping";
import { normalizeForSearch, preferredTitle } from "@/lib/format";
import { listStatusLabel } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { getUiState, setUiState } from "@/lib/uiState";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type {
  ListFilter,
  ListStatus,
  SortSpec,
  TitleLanguage,
} from "@/types/list";

const LAST_FILTER_KEY = "konsou.last_filter";
const STATUS_FILTER_KEY = "konsou.status_filter";

/** Load the persisted multi-select status filter, migrating the old
 *  single-choice value ("watching" etc.) the first time it's seen. */
function loadStatusFilter(): ListStatus[] {
  const raw = localStorage.getItem(STATUS_FILTER_KEY);
  if (raw) {
    try {
      const arr = JSON.parse(raw);
      if (Array.isArray(arr)) return arr as ListStatus[];
    } catch {
      // fall through to migration
    }
  }
  const legacy = localStorage.getItem(LAST_FILTER_KEY);
  return legacy && legacy !== "all" ? [legacy as ListStatus] : [];
}

function groupTitle(g: FranchiseGroup, pref: TitleLanguage): string {
  const root = g.entries.find((e) => e.anilist_id === g.rootId) ?? g.entries[0];
  return preferredTitle(
    { romaji: root.title_romaji, english: root.title_english, native: root.title_native },
    pref,
  );
}

function compareGroups(
  a: FranchiseGroup,
  b: FranchiseGroup,
  sort: SortSpec,
  pref: TitleLanguage,
): number {
  const dir = sort.order === "asc" ? 1 : -1;
  switch (sort.key) {
    case "title":
      return dir * groupTitle(a, pref).localeCompare(groupTitle(b, pref));
    case "score":
      return dir * ((a.displayEntry.score ?? -1) - (b.displayEntry.score ?? -1));
    case "episodes":
      return dir * (a.totalWatched - b.totalWatched);
    case "added":
      return dir * (a.sortAdded - b.sortAdded);
    case "updated":
    default:
      return dir * (a.sortUpdated - b.sortUpdated);
  }
}

export function MyList() {
  const navigate = useNavigate();
  const loaded = useListStore((s) => s.loaded);
  const entries = useListStore((s) => s.entries);

  const defaultView = useSettingsStore((s) => s.defaultView);
  const defaultSort = useSettingsStore((s) => s.defaultSort);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const setDefaultView = useSettingsStore((s) => s.setDefaultView);
  const setDefaultSort = useSettingsStore((s) => s.setDefaultSort);

  // Multi-select: empty array = no filter (everything shows). Statuses
  // combine as OR — "watching + plan to watch" shows both groups at once.
  const [selected, setSelected] = useState<ListStatus[]>(loadStatusFilter);
  const [search, setSearchState] = useState(() => getUiState("mylist.search", ""));
  const [sortOpen, setSortOpen] = useState(false);
  const [importOpen, setImportOpen] = useState(false);
  const debouncedSearch = useDebounce(search, 400);

  // Survives navigating into an anime and back (session-scoped).
  const setSearch = (v: string) => {
    setSearchState(v);
    setUiState("mylist.search", v);
  };

  // Status counts operate on individual entries so the filter tabs accurately
  // reflect how many anime are tracked at each status.
  const counts = useMemo(() => {
    const c: Record<ListFilter, number> = {
      all: entries.length,
      watching: 0,
      completed: 0,
      plan_to_watch: 0,
      on_hold: 0,
      dropped: 0,
      rewatching: 0,
      not_interested: 0,
    };
    for (const e of entries) c[e.status]++;
    return c;
  }, [entries]);

  // Group all entries into franchise clusters first, then filter at the group
  // level so a franchise with mixed statuses (e.g. S1=watching, S2=plan_to_watch)
  // still appears as a single card under every relevant status selection.
  const groups = useMemo(() => {
    const allGroups = groupEntries(entries);
    const filtered =
      selected.length === 0
        ? allGroups
        : allGroups.filter((g) =>
            g.entries.some((e) => selected.includes(e.status)),
          );
    return filtered.sort((a, b) => compareGroups(a, b, defaultSort, titleLanguage));
  }, [entries, selected, defaultSort, titleLanguage]);

  // Search filters the list DOWN to just what matches, so a 4000-entry library
  // collapses to the handful you typed instead of making you scroll hunting for
  // a dimmed-but-still-present card.
  const query = normalizeForSearch(debouncedSearch);
  const searching = query.length > 0;
  const visibleGroups = useMemo(() => {
    if (!query) return groups;
    return groups.filter((group) =>
      group.entries.some((e) =>
        normalizeForSearch(
          `${e.title_romaji} ${e.title_english ?? ""} ${e.title_native ?? ""}`,
        ).includes(query),
      ),
    );
  }, [query, groups]);

  const persistStatuses = (next: ListStatus[]) => {
    setSelected(next);
    localStorage.setItem(STATUS_FILTER_KEY, JSON.stringify(next));
  };
  const onToggleStatus = (s: ListStatus) =>
    persistStatuses(
      selected.includes(s)
        ? selected.filter((x) => x !== s)
        : [...selected, s],
    );
  const onClearStatuses = () => persistStatuses([]);

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
              Already on AniList?{" "}
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

  return (
    <div className="k-page">
      <ListToolbar
        search={search}
        onSearch={setSearch}
        selected={selected}
        onToggleStatus={onToggleStatus}
        onClearStatuses={onClearStatuses}
        counts={counts}
        view={defaultView}
        onView={setDefaultView}
        sort={defaultSort}
        onOpenSort={() => setSortOpen(true)}
      />

      {/* Tonight's plan, composed locally. Only on the unfiltered view: a
          status filter or search means the user is already hunting for
          something specific. */}
      {!searching && selected.length === 0 && <TonightQueue entries={entries} />}

      {searching && visibleGroups.length > 0 && (
        <p className="k-list-results">
          {visibleGroups.length}{" "}
          {visibleGroups.length === 1 ? "match" : "matches"} for “
          {debouncedSearch.trim()}”
        </p>
      )}

      {visibleGroups.length === 0 ? (
        searching ? (
          <EmptyState
            title="No matches"
            subtitle={`Nothing in your list matches “${debouncedSearch.trim()}”.`}
          />
        ) : (
          <EmptyState
            title="Your list is a blank page"
            subtitle={
              selected.length === 0
                ? "Find something on Discover and it lands here."
                : `Nothing marked ${selected.map((s) => listStatusLabel(s).toLowerCase()).join(" or ")} yet.`
            }
            showTip={selected.length === 0}
          />
        )
      ) : (
        <FranchiseCollection
          groups={visibleGroups}
          view={defaultView}
          showStatus={selected.length !== 1}
          restoreKey="mylist.scroll"
        />
      )}

      <SortSheet
        open={sortOpen}
        onClose={() => setSortOpen(false)}
        sort={defaultSort}
        onChange={setDefaultSort}
      />
    </div>
  );
}
