import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FranchiseCollection } from "@/components/list/FranchiseCollection";
import { ListToolbar } from "@/components/list/ListToolbar";
import { SortSheet } from "@/components/list/SortSheet";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { ImportSheet } from "@/components/ui/ImportSheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { useDebounce } from "@/hooks/useDebounce";
import { groupEntries } from "@/lib/franchise/grouping";
import { normalizeForSearch, preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type {
  ListFilter,
  SortSpec,
  TitleLanguage,
} from "@/types/list";

const LAST_FILTER_KEY = "konsou.last_filter";

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

  const [filter, setFilter] = useState<ListFilter>(
    () => (localStorage.getItem(LAST_FILTER_KEY) as ListFilter) ?? "all",
  );
  const [search, setSearch] = useState("");
  const [sortOpen, setSortOpen] = useState(false);
  const [importOpen, setImportOpen] = useState(false);
  const debouncedSearch = useDebounce(search, 400);

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
    };
    for (const e of entries) c[e.status]++;
    return c;
  }, [entries]);

  // Group all entries into franchise clusters first, then filter at the group
  // level so a franchise with mixed statuses (e.g. S1=watching, S2=plan_to_watch)
  // still appears as a single card under every relevant filter tab.
  const groups = useMemo(() => {
    const allGroups = groupEntries(entries);
    const filtered =
      filter === "all"
        ? allGroups
        : allGroups.filter((g) => g.entries.some((e) => e.status === filter));
    return filtered.sort((a, b) => compareGroups(a, b, defaultSort, titleLanguage));
  }, [entries, filter, defaultSort, titleLanguage]);

  // DIM-style search: a group stays bright if any of its entries match.
  const dimmedIds = useMemo(() => {
    const q = normalizeForSearch(debouncedSearch);
    if (!q) return null;
    const bright = new Set<number>();
    for (const group of groups) {
      const hit = group.entries.some((e) => {
        const hay = normalizeForSearch(
          `${e.title_romaji} ${e.title_english ?? ""} ${e.title_native ?? ""}`,
        );
        return hay.includes(q);
      });
      if (hit) bright.add(group.rootId);
    }
    return bright;
  }, [debouncedSearch, groups]);

  const onFilter = (f: ListFilter) => {
    setFilter(f);
    localStorage.setItem(LAST_FILTER_KEY, f);
  };

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
            Track what you're watching, planning, or have finished — no score required.
          </p>
          <div className="k-mylist-empty__actions">
            <Button variant="primary" onClick={() => navigate("/search")}>
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
        filter={filter}
        onFilter={onFilter}
        counts={counts}
        view={defaultView}
        onView={setDefaultView}
        sort={defaultSort}
        onOpenSort={() => setSortOpen(true)}
      />

      {groups.length === 0 ? (
        <EmptyState
          title="Nothing here yet"
          subtitle={`Add anime to your ${filter === "all" ? "" : filter.replace(/_/g, " ")} list.`}
        />
      ) : (
        <>
          {defaultView === "list" && (
            <div className="k-row-header">
              <div className="k-row-header__thumb" />
              <div className="k-row-header__title">Title</div>
              <div className="k-row-header__status">Status</div>
              <div className="k-row-header__ep">Ep.</div>
              <div className="k-row-header__score">Score</div>
              <div className="k-row-header__action" />
            </div>
          )}
          <FranchiseCollection
            groups={groups}
            view={defaultView}
            dimmedIds={dimmedIds}
            showStatus={filter === "all"}
          />
        </>
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
