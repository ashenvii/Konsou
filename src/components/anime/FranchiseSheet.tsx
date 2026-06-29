import { useMemo, useState } from "react";
import {
  Calendar,
  ChevronDown,
  ChevronRight,
  Minus,
  Plus,
  Trash2,
  Zap,
} from "lucide-react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { AnimeCover } from "./AnimeCover";
import { StatusSheet } from "./StatusSheet";
import { statusMeta } from "./statusMeta";
import { seasonSegment } from "./SeasonBar";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { useFranchiseRelations } from "@/hooks/useAniList";
import { formatLabel, formatScore, getCoverUrl, preferredTitle } from "@/lib/format";
import { getDisabledStatuses } from "@/lib/statusValidation";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { CSSProperties } from "react";
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
  const removeMany = useListStore((s) => s.removeMany);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [pendingAdd, setPendingAdd] = useState<AnimeSummary | null>(null);
  const [pendingStatusId, setPendingStatusId] = useState<number | null>(null);

  // Stable list of tracked ids -- used as the query key for useFranchiseRelations.
  const trackedIdList = useMemo(
    () => group?.entries.map((e) => e.anilist_id) ?? [],
    [group],
  );

  const { data: relMap, isLoading: relLoading } = useFranchiseRelations(
    trackedIdList,
    open,
  );

  const trackedMap = useMemo(
    () => new Map(group?.entries.map((e) => [e.anilist_id, e]) ?? []),
    [group],
  );

  const allRelNodes = useMemo(() => {
    const m = new Map<number, RelationNode>();
    for (const rels of Object.values(relMap ?? {})) {
      for (const r of rels) m.set(r.id, r);
    }
    return m;
  }, [relMap]);

  const { mainChainIds, sideIds } = useMemo(() => {
    if (!group) return { mainChainIds: [], sideIds: [] };

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

  const seasonCount = group.entries.length;
  const overallPct =
    group.totalEpisodes != null && group.totalEpisodes > 0
      ? Math.round((group.totalWatched / group.totalEpisodes) * 100)
      : null;
  const epSummary =
    group.totalEpisodes != null
      ? `${group.totalWatched} / ${group.totalEpisodes} episodes`
      : `${group.totalWatched} episodes watched`;

  const art = rootEntry.cover_url ?? group.displayEntry.cover_url ?? undefined;
  const poster = group.displayEntry.cover_url ?? rootEntry.cover_url ?? undefined;

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

  const removeFranchise = () => {
    removeMany(group.entries.map((e) => e.anilist_id));
    onClose();
  };

  // The first untracked entry in the main chain is the "up next" frontier.
  const frontierId = mainChainIds.find((id) => !trackedMap.has(id));

  const renderTracked = (id: number, seasonNo: number | null) => {
    const tracked = trackedMap.get(id);
    if (!tracked) return null;
    return (
      <SeasonRow
        key={id}
        entry={tracked}
        seasonNo={seasonNo}
        titleLanguage={titleLanguage}
        onOpen={(entryId) => {
          onClose();
          onNavigate(entryId);
        }}
        onStatusTap={(entryId) => setPendingStatusId(entryId)}
        onRemove={(entryId) => {
          remove(entryId);
          if (group.entries.length <= 1) onClose();
        }}
      />
    );
  };

  const renderUntracked = (id: number, isFrontier: boolean) => {
    const relNode = allRelNodes.get(id);
    if (!relNode) return null;
    return (
      <AddRow
        key={id}
        rel={relNode}
        featured={isFrontier}
        titleLanguage={titleLanguage}
        onAdd={() => setPendingAdd(relationToSummary(relNode))}
      />
    );
  };

  return (
    <>
      <BottomSheet open={open} onClose={onClose}>
        <div className="k-fhead">
          {art && (
            <div
              className="k-fhead__art"
              aria-hidden
              style={{ backgroundImage: `url("${art}")` }}
            />
          )}
          <div className="k-fhead__scrim" aria-hidden />
          <div className="k-fhead__row">
            <div className="k-fhead__cover">
              <AnimeCover src={poster} alt={franchiseTitle} decorative radius="var(--radius-md)" />
            </div>
            <div className="k-fhead__info">
              <Text as="h2" size="xl" weight={700} clamp={2} className="k-fhead__title">
                {franchiseTitle}
              </Text>
              <div className="k-fhead__stats">
                {group.isGroup && <span>{seasonCount} seasons</span>}
                <span>{epSummary}</span>
                {overallPct != null && <span className="k-fhead__pct">{overallPct}%</span>}
              </div>
              <div className="k-fhead__bar">
                {group.entries.map((e) => {
                  const { pct, color } = seasonSegment(e);
                  return (
                    <span
                      key={e.anilist_id}
                      className="k-fhead__seg"
                      style={{ "--seg": color } as CSSProperties}
                    >
                      <span style={{ width: `${pct}%` }} />
                    </span>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {relLoading ? (
          <div className="k-seasonlist">
            {Array.from({ length: Math.max(3, group.entries.length + 1) }).map(
              (_, i) => (
                <Skeleton key={i} height={72} radius="var(--radius-lg)" />
              ),
            )}
          </div>
        ) : (
          <>
            <p className="k-fsheet-heading">
              {group.isGroup ? "Seasons" : "Tracked"}
            </p>
            <div className="k-seasonlist">
              {mainChainIds.map((id, i) =>
                trackedMap.has(id)
                  ? renderTracked(id, group.isGroup ? i + 1 : null)
                  : renderUntracked(id, id === frontierId),
              )}
            </div>

            {sideIds.length > 0 && (
              <>
                <p className="k-fsheet-heading">Also in this franchise</p>
                <div className="k-seasonlist">
                  {sideIds.map((id) =>
                    trackedMap.has(id)
                      ? renderTracked(id, null)
                      : renderUntracked(id, false),
                  )}
                </div>
              </>
            )}
          </>
        )}

        <button type="button" className="k-fsheet-remove" onClick={removeFranchise}>
          <Icon icon={Trash2} size={16} />
          {group.isGroup ? "Remove whole franchise" : "Remove from list"}
        </button>
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

// ── Rows ──────────────────────────────────────────────────────────────────────

function SeasonRow({
  entry,
  seasonNo,
  titleLanguage,
  onOpen,
  onStatusTap,
  onRemove,
}: {
  entry: AnimeListEntry;
  seasonNo: number | null;
  titleLanguage: string;
  onOpen: (id: number) => void;
  onStatusTap: (id: number) => void;
  onRemove: (id: number) => void;
}) {
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
  const meta = statusMeta(entry.status);
  const { pct, color } = seasonSegment(entry);

  const title = preferredTitle(
    {
      romaji: entry.title_romaji,
      english: entry.title_english,
      native: entry.title_native,
    },
    titleLanguage as never,
  );

  const isActive = entry.status === "watching" || entry.status === "rewatching";
  const epText = `${entry.episodes_watched} / ${entry.total_episodes ?? "?"}`;
  const canDecrement = isActive && entry.episodes_watched > 0;
  const canIncrement =
    isActive &&
    (entry.total_episodes == null ||
      entry.episodes_watched < entry.total_episodes);

  return (
    <div className="k-srow" style={{ "--card-status": color } as CSSProperties}>
      <button
        type="button"
        className="k-srow__open"
        onClick={() => onOpen(entry.anilist_id)}
        aria-label={`Open ${title}`}
      >
        <div className="k-srow__cover">
          <AnimeCover src={entry.cover_url ?? undefined} alt={title} decorative radius="var(--radius-sm)" />
          {seasonNo != null && <span className="k-srow__num">S{seasonNo}</span>}
          <span className="k-srow__openhint" aria-hidden>
            <Icon icon={ChevronRight} size={18} />
          </span>
        </div>
      </button>

      <div className="k-srow__main">
        <button type="button" className="k-srow__titlebtn" onClick={() => onOpen(entry.anilist_id)}>
          <Text size="sm" weight={600} clamp={1}>
            {title}
          </Text>
        </button>
        <div className="k-srow__controls">
          <button
            type="button"
            className="k-pill k-srow__statusbtn"
            style={{ color: meta.color }}
            onClick={() => onStatusTap(entry.anilist_id)}
            aria-label={`Change status (currently ${meta.label})`}
          >
            <Icon icon={meta.icon} size={12} weight="fill" />
            {meta.label}
            <Icon icon={ChevronDown} size={12} className="k-srow__caret" />
          </button>
          {isActive ? (
            <div className="k-srow__stepper">
              <button
                type="button"
                onClick={() => void incrementEpisodes(entry.anilist_id, -1)}
                disabled={!canDecrement}
                aria-label="Remove one episode"
              >
                <Icon icon={Minus} size={14} />
              </button>
              <span className="k-srow__epnum">{epText}</span>
              <button
                type="button"
                onClick={() => void incrementEpisodes(entry.anilist_id, 1)}
                disabled={!canIncrement}
                aria-label="Add one episode"
              >
                <Icon icon={Plus} size={14} />
              </button>
            </div>
          ) : (
            <span className="k-srow__ep">{epText}</span>
          )}
          {entry.score != null && (
            <span className="k-srow__score">★ {formatScore(entry.score)}</span>
          )}
        </div>
        <div className="k-srow__bar">
          <span style={{ width: `${pct}%` }} />
        </div>
      </div>

      <button
        type="button"
        className="k-srow__remove"
        onClick={() => onRemove(entry.anilist_id)}
        aria-label={`Remove ${title}`}
      >
        <Icon icon={Trash2} size={16} />
      </button>
    </div>
  );
}

function AddRow({
  rel,
  featured,
  titleLanguage,
  onAdd,
}: {
  rel: RelationNode;
  featured: boolean;
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
    <div className={`k-srow k-srow--add${featured ? " k-srow--next" : ""}`}>
      <div className="k-srow__cover">
        <AnimeCover src={cover} alt={title} decorative radius="var(--radius-sm)" />
      </div>
      <div className="k-srow__main">
        {featured && <span className="k-srow__nextlabel">Up next</span>}
        <Text size="sm" weight={600} clamp={1}>
          {title}
        </Text>
        <div className="k-srow__controls">
          {meta && <span className="k-srow__dim">{meta}</span>}
          {isSideContent && (
            <span className="k-chip-mini">{sideLabel(rel.relationType)}</span>
          )}
          {isAiring && (
            <span className="k-chip-mini k-chip-mini--accent">
              <Icon icon={Zap} size={10} weight="fill" />
              airing
            </span>
          )}
          {isUpcoming && (
            <span className="k-chip-mini">
              <Icon icon={Calendar} size={10} />
              upcoming
            </span>
          )}
        </div>
      </div>
      <button
        type="button"
        className={`k-srow__add${featured ? " k-srow__add--primary" : ""}`}
        onClick={onAdd}
        aria-label={`Add ${title}`}
      >
        <Icon icon={Plus} size={16} />
        {featured && <span>Add</span>}
      </button>
    </div>
  );
}
