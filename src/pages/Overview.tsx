import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ChevronRight, Search, X } from "lucide-react";
import { FranchiseCard } from "@/components/anime/FranchiseCard";
import { FranchiseSheet } from "@/components/anime/FranchiseSheet";
import { FranchiseCollection } from "@/components/list/FranchiseCollection";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { ImportSheet } from "@/components/ui/ImportSheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { useDebounce } from "@/hooks/useDebounce";
import { groupEntries } from "@/lib/franchise/grouping";
import { getCoverUrl, normalizeForSearch } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { getUiState, setUiState } from "@/lib/uiState";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { AnimeListEntry, ListStatus } from "@/types/list";

/**
 * My List landing. Not a flat list and not tabs: a calm overview whose bands
 * are doors into the dedicated status rooms. Each band shows only a recent
 * slice, so it stays instant no matter how large the library grows. A query
 * turns the whole surface into a flat "have you seen it?" search.
 */

type BandKind = "watching" | "plan" | "completed";

const BAND_PREVIEW = 12;

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
  const defaultView = useSettingsStore((s) => s.defaultView);

  const [search, setSearchState] = useState(() => getUiState("mylist.search", ""));
  const [importOpen, setImportOpen] = useState(false);
  const [activeRootId, setActiveRootId] = useState<number | null>(null);
  const debounced = useDebounce(search, 300);
  const setSearch = (v: string) => {
    setSearchState(v);
    setUiState("mylist.search", v);
  };

  const watching = useMemo(
    () => sortBand(groupsFor(entries, ["watching", "rewatching"]), "watching").slice(0, BAND_PREVIEW),
    [entries],
  );
  const plan = useMemo(
    () => sortBand(groupsFor(entries, ["plan_to_watch"]), "plan").slice(0, BAND_PREVIEW),
    [entries],
  );
  const completedGroups = useMemo(() => groupsFor(entries, ["completed"]), [entries]);
  const completedRecent = useMemo(
    () => sortBand(completedGroups, "completed").slice(0, 6),
    [completedGroups],
  );

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
    return (
      [...watching, ...plan, ...completedRecent].find((g) => g.rootId === activeRootId) ?? null
    );
  }, [activeRootId, watching, plan, completedRecent]);

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
            <FranchiseCollection groups={matches} view={defaultView} restoreKey="overview.search" />
          </>
        ) : (
          <EmptyState
            title="No matches"
            subtitle={`Nothing in your list matches “${debounced.trim()}”.`}
          />
        )
      ) : (
        <div className="k-overview__scroll konsou-scroll">
          <Band
            title="Watching"
            kind="watching"
            groups={watching}
            onOpenRoom={() => openRoom("/list/watching")}
            onCard={setActiveRootId}
          />
          <Band
            title="Want to watch"
            kind="plan"
            groups={plan}
            onOpenRoom={() => openRoom("/list/plan")}
            onCard={setActiveRootId}
          />
          <CompletedDrawer
            count={completedGroups.length}
            recent={completedRecent}
            onOpenRoom={() => openRoom("/list/completed")}
          />
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

function BandHead({
  title,
  count,
  onOpenRoom,
}: {
  title: string;
  count: number;
  onOpenRoom: () => void;
}) {
  return (
    <div className="k-band__head">
      <h2 className="k-band__title">{title}</h2>
      <button type="button" className="k-band__open" onClick={onOpenRoom}>
        Open <span className="k-band__count">{count}</span>
        <Icon icon={ChevronRight} size={15} />
      </button>
    </div>
  );
}

function Band({
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
  return (
    <section className={`k-band k-band--${kind}`}>
      <BandHead title={title} count={groups.length} onOpenRoom={onOpenRoom} />
      <div className="k-rail konsou-scroll">
        {groups.map((g) => (
          <div key={g.rootId} className="k-rail__item">
            <FranchiseCard group={g} view="grid" onOpen={onCard} />
          </div>
        ))}
      </div>
    </section>
  );
}

function CompletedDrawer({
  count,
  recent,
  onOpenRoom,
}: {
  count: number;
  recent: FranchiseGroup[];
  onOpenRoom: () => void;
}) {
  if (count === 0) return null;
  return (
    <section className="k-band k-band--completed">
      <button type="button" className="k-drawer" onClick={onOpenRoom}>
        <div className="k-drawer__top">
          <span className="k-drawer__num">{count}</span>
          <span className="k-drawer__lab">finished</span>
          <span className="k-drawer__sub">your record</span>
          <Icon icon={ChevronRight} size={16} className="k-drawer__go" />
        </div>
        <div className="k-drawer__shelf">
          {recent.map((g) => (
            <div key={g.rootId} className="k-drawer__bk">
              <AnimeCover
                src={getCoverUrl({ medium: g.displayEntry.cover_url ?? undefined })}
                alt={g.displayEntry.title_romaji}
                decorative
                radius="var(--radius-sm)"
              />
            </div>
          ))}
        </div>
      </button>
    </section>
  );
}
