import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { MagnifyingGlass } from "@phosphor-icons/react";
import { AnimeCollection } from "@/components/list/AnimeCollection";
import { ListToolbar } from "@/components/list/ListToolbar";
import { SortSheet } from "@/components/list/SortSheet";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Skeleton } from "@/components/ui/Skeleton";
import { useDebounce } from "@/hooks/useDebounce";
import { entryToSummary, preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AnimeListEntry, ListFilter, SortSpec } from "@/types/list";

const LAST_FILTER_KEY = "konsou.last_filter";

function compareEntries(a: AnimeListEntry, b: AnimeListEntry, sort: SortSpec): number {
  const dir = sort.order === "asc" ? 1 : -1;
  switch (sort.key) {
    case "title":
      return (
        dir *
        preferredTitle({ romaji: a.title_romaji, english: a.title_english }).localeCompare(
          preferredTitle({ romaji: b.title_romaji, english: b.title_english }),
        )
      );
    case "score":
      return dir * ((a.score ?? -1) - (b.score ?? -1));
    case "episodes":
      return dir * (a.episodes_watched - b.episodes_watched);
    case "added":
      return dir * (a.added_at - b.added_at);
    case "updated":
    default:
      return dir * (a.updated_at - b.updated_at);
  }
}

export function MyList() {
  const navigate = useNavigate();
  const loaded = useListStore((s) => s.loaded);
  const entries = useListStore((s) => s.entries);

  const defaultView = useSettingsStore((s) => s.defaultView);
  const defaultSort = useSettingsStore((s) => s.defaultSort);
  const setDefaultView = useSettingsStore((s) => s.setDefaultView);
  const setDefaultSort = useSettingsStore((s) => s.setDefaultSort);

  const [filter, setFilter] = useState<ListFilter>(
    () => (localStorage.getItem(LAST_FILTER_KEY) as ListFilter) ?? "all",
  );
  const [search, setSearch] = useState("");
  const [sortOpen, setSortOpen] = useState(false);
  const debouncedSearch = useDebounce(search, 400);

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

  const filtered = useMemo(() => {
    const base =
      filter === "all" ? entries : entries.filter((e) => e.status === filter);
    return [...base].sort((a, b) => compareEntries(a, b, defaultSort));
  }, [entries, filter, defaultSort]);

  const items = useMemo(() => filtered.map(entryToSummary), [filtered]);

  const dimmedIds = useMemo(() => {
    const q = debouncedSearch.trim().toLowerCase();
    if (!q) return null;
    const set = new Set<number>();
    for (const e of filtered) {
      const hay = `${e.title_romaji} ${e.title_english ?? ""}`.toLowerCase();
      if (hay.includes(q)) set.add(e.anilist_id);
    }
    return set;
  }, [debouncedSearch, filtered]);

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
        <EmptyState
          icon={MagnifyingGlass}
          title="Your list is empty"
          subtitle="Search for anime to start tracking — no score required."
          action={
            <Button variant="primary" onClick={() => navigate("/search")}>
              Go to Search
            </Button>
          }
        />
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

      {filtered.length === 0 ? (
        <EmptyState
          title="Nothing here yet"
          subtitle={`Add anime to your ${filter === "all" ? "" : filter.replace(/_/g, " ")} list.`}
        />
      ) : (
        <AnimeCollection
          items={items}
          view={defaultView}
          dimmedIds={dimmedIds}
          showStatus={filter === "all"}
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
