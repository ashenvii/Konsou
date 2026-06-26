import { useMemo, useState } from "react";
import { Calendar, ChevronRight, Plus, Zap } from "lucide-react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { AnimeCover } from "./AnimeCover";
import { StatusSheet } from "./StatusSheet";
import { statusMeta } from "./statusMeta";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { useFranchiseRelations } from "@/hooks/useAniList";
import { formatLabel, getCoverUrl, preferredTitle } from "@/lib/format";
import { getDisabledStatuses } from "@/lib/statusValidation";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { AnimeSummary, FuzzyDate, RelationNode } from "@/types/anime";
import type { AnimeListEntry, ListStatus } from "@/types/list";

// Relation types that go into the "Also in this franchise" side section.
const SIDE_REL_TYPES = new Set(["SIDE_STORY", "SPIN_OFF", "PARENT", "SUMMARY"]);

function sideLabel(type: string): string {
  const map: Record<string, string> = {
    SIDE_STORY: "side story",
    SPIN_OFF: "spin-off",
    PARENT: "parent",
    SUMMARY: "summary",
  };
  return map[type] ?? type.toLowerCase().replace(/_/g, " ");
}

function relStartMs(r: RelationNode): number {
  const d = r.startDate as FuzzyDate | null | undefined;
  if (d?.year) return Date.UTC(d.year, (d.month ?? 1) - 1, d.day ?? 1);
  if (r.seasonYear) return Date.UTC(r.seasonYear, 0, 1);
  return 0;
}

function relationToSummary(r: RelationNode): AnimeSummary {
  return {
    id: r.id,
    idMal: r.idMal ?? null,
    title: r.title,
    coverImage: r.coverImage ?? null,
    format: r.format ?? null,
    episodes: r.episodes ?? null,
    status: r.status ?? null,
    seasonYear: r.seasonYear ?? null,
    season: r.season ?? null,
    nextAiringEpisode: r.nextAiringEpisode ?? null,
    hasDub: null,
  };
}

interface FranchiseSheetProps {
  group: FranchiseGroup | null;
  open: boolean;
  onClose: () => void;
  onNavigate: (anilistId: number) => void;
}

export function FranchiseSheet({
  group,
  open,
  onClose,
  onNavigate,
}: FranchiseSheetProps) {
  const addFromSummary = useListStore((s) => s.addFromSummary);
  const updateStatus = useListStore((s) => s.updateStatus);
  const remove = useListStore((s) => s.remove);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [pendingAdd, setPendingAdd] = useState<AnimeSummary | null>(null);
  const [pendingStatusId, setPendingStatusId] = useState<number | null>(null);

  // Stable list of tracked ids -- used as the query key for useFranchiseRelations.
  const trackedIdList = useMemo(
    () => group?.entries.map((e) => e.anilist_id) ?? [],
    [group],
  );

  // Fetch relations for every tracked entry so we can extend the chain beyond
  // what's directly adjacent to the root. Cached 6h in react-query + SQLite.
  const { data: relMap, isLoading: relLoading } = useFranchiseRelations(
    trackedIdList,
    open,
  );

  // --- All useMemos before the guard ---

  const trackedMap = useMemo(
    () => new Map(group?.entries.map((e) => [e.anilist_id, e]) ?? []),
    [group],
  );

  // Flat index of every RelationNode discovered from tracked entries' relations.
  // Gives us display data (title, cover, format, airing status) for untracked nodes.
  const allRelNodes = useMemo(() => {
    const m = new Map<number, RelationNode>();
    for (const rels of Object.values(relMap ?? {})) {
      for (const r of rels) m.set(r.id, r);
    }
    return m;
  }, [relMap]);

  // Build the ordered main story chain (SEQUEL walk from root) and the side
  // content list. Runs after relMap is available; falls back to just the root
  // while loading so the skeleton count is sensible.
  const { mainChainIds, sideIds } = useMemo(() => {
    if (!group) return { mainChainIds: [], sideIds: [] };

    // Walk SEQUEL edges from the franchise root. relMap only contains data for
    // tracked entries, so the chain naturally extends to the first untracked
    // entry at the current frontier (the one the user should add next).
    const mainChainIds: number[] = [group.rootId];
    const inMain = new Set<number>([group.rootId]);

    let current = group.rootId;
    for (let i = 0; i < 30; i++) {
      const rels = relMap?.[current] ?? [];
      const sequel = rels.find((r) => r.relationType === "SEQUEL");
      if (!sequel || inMain.has(sequel.id)) break;
      inMain.add(sequel.id);
      mainChainIds.push(sequel.id);
      current = sequel.id;
    }

    // Side content: SIDE_STORY / SPIN_OFF / PARENT / SUMMARY entries from any
    // tracked entry's relations, plus any tracked entry that fell outside the
    // main SEQUEL chain (e.g., a movie tracked independently).
    const sideIds: number[] = [];
    const inSide = new Set<number>();

    const addSide = (id: number) => {
      if (!inMain.has(id) && !inSide.has(id)) {
        sideIds.push(id);
        inSide.add(id);
      }
    };

    for (const rels of Object.values(relMap ?? {})) {
      for (const r of rels) {
        if (SIDE_REL_TYPES.has(r.relationType) && r.format !== "MUSIC") {
          addSide(r.id);
        }
      }
    }

    for (const id of trackedMap.keys()) addSide(id);

    sideIds.sort((a, b) => {
      const ra = allRelNodes.get(a);
      const rb = allRelNodes.get(b);
      if (!ra || !rb) return 0;
      return relStartMs(ra) - relStartMs(rb);
    });

    return { mainChainIds, sideIds };
  }, [group, relMap, trackedMap, allRelNodes]);

  // --- Guard ---
  if (!group) return null;

  const rootEntry =
    group.entries.find((e) => e.anilist_id === group.rootId) ?? group.entries[0];

  const franchiseTitle = preferredTitle(
    {
      romaji: rootEntry.title_romaji,
      english: rootEntry.title_english,
      native: rootEntry.title_native,
    },
    titleLanguage,
  );

  const epSummary =
    group.totalEpisodes != null
      ? `${group.totalWatched} / ${group.totalEpisodes} eps`
      : `${group.totalWatched} eps watched`;

  const summaryLine = group.isGroup
    ? `${group.entries.length} tracked · ${epSummary}`
    : epSummary;

  const pendingStatusEntry =
    pendingStatusId != null
      ? group.entries.find((e) => e.anilist_id === pendingStatusId) ?? null
      : null;

  const onAddPick = (status: ListStatus) => {
    if (pendingAdd) {
      void addFromSummary(pendingAdd, status);
      setPendingAdd(null);
    }
  };

  const onStatusPick = (status: ListStatus) => {
    if (pendingStatusId != null) {
      void updateStatus(pendingStatusId, status);
      setPendingStatusId(null);
    }
  };

  const onRemoveEntry = () => {
    if (pendingStatusId != null) {
      remove(pendingStatusId);
      setPendingStatusId(null);
      if (group.entries.length <= 1) onClose();
    }
  };

  // Render one row -- tracked entries show status controls, untracked show Add.
  const renderEntry = (id: number) => {
    const tracked = trackedMap.get(id);
    if (tracked) {
      return (
        <TrackedRow
          key={id}
          entry={tracked}
          titleLanguage={titleLanguage}
          onNavigate={(entryId) => {
            onClose();
            onNavigate(entryId);
          }}
          onStatusTap={(entryId) => setPendingStatusId(entryId)}
        />
      );
    }
    const relNode = allRelNodes.get(id);
    if (relNode) {
      return (
        <UntrackedRow
          key={id}
          rel={relNode}
          titleLanguage={titleLanguage}
          onAdd={() => setPendingAdd(relationToSummary(relNode))}
        />
      );
    }
    return null;
  };

  return (
    <>
      <BottomSheet open={open} onClose={onClose} title={franchiseTitle}>
        <p className="k-fsheet-summary">{summaryLine}</p>

        {relLoading ? (
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {Array.from({ length: Math.max(3, group.entries.length + 1) }).map(
              (_, i) => (
                <Skeleton key={i} height={64} radius="var(--radius-sm)" />
              ),
            )}
          </div>
        ) : (
          <>
            <div>{mainChainIds.map(renderEntry)}</div>

            {sideIds.length > 0 && (
              <>
                <p className="k-fsheet-heading">Also in this franchise</p>
                <div>{sideIds.map(renderEntry)}</div>
              </>
            )}
          </>
        )}
      </BottomSheet>

      {/* Add an untracked entry */}
      <StatusSheet
        open={pendingAdd != null}
        onClose={() => setPendingAdd(null)}
        title={
          pendingAdd
            ? `Add "${preferredTitle(pendingAdd.title, titleLanguage)}"`
            : ""
        }
        onPick={onAddPick}
        disabledStatuses={
          pendingAdd ? getDisabledStatuses(pendingAdd.status ?? null) : undefined
        }
      />

      {/* Change status of a tracked entry */}
      <StatusSheet
        open={pendingStatusId != null}
        onClose={() => setPendingStatusId(null)}
        title={
          pendingStatusEntry
            ? preferredTitle(
                {
                  romaji: pendingStatusEntry.title_romaji,
                  english: pendingStatusEntry.title_english,
                  native: pendingStatusEntry.title_native,
                },
                titleLanguage,
              )
            : ""
        }
        current={pendingStatusEntry?.status}
        onPick={onStatusPick}
        onRemove={onRemoveEntry}
        disabledStatuses={
          pendingStatusEntry
            ? getDisabledStatuses(pendingStatusEntry.airing_status)
            : undefined
        }
      />
    </>
  );
}

// ── Row components ────────────────────────────────────────────────────────────

function TrackedRow({
  entry,
  titleLanguage,
  onNavigate,
  onStatusTap,
}: {
  entry: AnimeListEntry;
  titleLanguage: string;
  onNavigate: (id: number) => void;
  onStatusTap: (id: number) => void;
}) {
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
  const meta = statusMeta(entry.status);

  const title = preferredTitle(
    {
      romaji: entry.title_romaji,
      english: entry.title_english,
      native: entry.title_native,
    },
    titleLanguage as never,
  );

  const isActive =
    entry.status === "watching" || entry.status === "rewatching";
  const epText = `${entry.episodes_watched} / ${entry.total_episodes ?? "?"}`;
  const canDecrement = isActive && entry.episodes_watched > 0;
  const canIncrement =
    isActive &&
    (entry.total_episodes == null ||
      entry.episodes_watched < entry.total_episodes);

  return (
    <div className="k-frow">
      <AnimeCover
        src={entry.cover_url ?? undefined}
        alt={title}
        decorative
        className="k-frow__cover"
      />
      <div className="k-frow__main">
        <Text size="sm" weight={600} clamp={1}>
          {title}
        </Text>
        <div className="k-frow__controls">
          <button
            type="button"
            className="k-frow__status-btn"
            style={{ color: meta.color }}
            onClick={() => onStatusTap(entry.anilist_id)}
            aria-label="Change status"
          >
            <Icon icon={meta.icon} size={11} weight="fill" />
            {meta.label}
          </button>

          {isActive ? (
            <div className="k-frow__epc">
              <button
                type="button"
                className="k-frow__epc-btn"
                onClick={() => void incrementEpisodes(entry.anilist_id, -1)}
                disabled={!canDecrement}
                aria-label="Remove episode"
              >
                −
              </button>
              <span className="k-frow__epc-num">{epText}</span>
              <button
                type="button"
                className="k-frow__epc-btn"
                onClick={() => void incrementEpisodes(entry.anilist_id, 1)}
                disabled={!canIncrement}
                aria-label="Add episode"
              >
                +
              </button>
            </div>
          ) : (
            <span className="k-frow__meta" style={{ marginLeft: "auto" }}>
              {epText}
            </span>
          )}
        </div>
      </div>
      <button
        type="button"
        className="k-frow__action"
        onClick={() => onNavigate(entry.anilist_id)}
        aria-label="View details"
      >
        <Icon icon={ChevronRight} size={18} />
      </button>
    </div>
  );
}

function UntrackedRow({
  rel,
  titleLanguage,
  onAdd,
}: {
  rel: RelationNode;
  titleLanguage: string;
  onAdd: () => void;
}) {
  const title = preferredTitle(rel.title, titleLanguage as never);
  const cover = getCoverUrl(rel.coverImage);

  const isUpcoming = rel.status === "NOT_YET_RELEASED";
  const isAiring = rel.status === "RELEASING";
  const isSideContent = SIDE_REL_TYPES.has(rel.relationType);

  const meta = [formatLabel(rel.format), rel.seasonYear?.toString()]
    .filter(Boolean)
    .join(" · ");

  return (
    <div className="k-frow k-frow--untracked">
      <AnimeCover src={cover} alt={title} decorative className="k-frow__cover" />
      <div className="k-frow__main">
        <Text size="sm" weight={600} clamp={1}>
          {title}
        </Text>
        <div className="k-frow__controls">
          {meta && <span className="k-frow__meta">{meta}</span>}
          {isSideContent && (
            <span className="k-frow__reltag">
              {sideLabel(rel.relationType)}
            </span>
          )}
          {isAiring && (
            <span className="k-frow__reltag k-frow__reltag--airing">
              <Icon icon={Zap} size={9} weight="fill" />
              airing
            </span>
          )}
          {isUpcoming && (
            <span className="k-frow__reltag k-frow__reltag--upcoming">
              <Icon icon={Calendar} size={9} />
              upcoming
            </span>
          )}
        </div>
      </div>
      <button
        type="button"
        className="k-frow__action k-frow__action--add"
        onClick={onAdd}
        aria-label={`Add ${title}`}
      >
        <Icon icon={Plus} size={18} />
      </button>
    </div>
  );
}
