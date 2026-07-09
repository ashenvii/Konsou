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
import { formatChipMeta, relationChipMeta } from "./relationMeta";
import { StatusSheet } from "./StatusSheet";
import { statusMeta } from "./statusMeta";
import { seasonSegment } from "./SeasonBar";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { useFranchiseRelations } from "@/hooks/useAniList";
import { computeFranchiseLedger, ledgerEpisodeLabel } from "@/lib/franchise/ledger";
import { isFranchiseOther } from "@/lib/franchise/relatedness";
import { orderForWatching } from "@/lib/franchise/watchOrder";
import type { RelationEdge } from "@/lib/franchise/watchOrder";
import {
  formatFuzzyDate,
  formatLabel,
  formatScore,
  getCoverUrl,
  isMangaNode,
  preferredTitle,
  secondaryTitle,
} from "@/lib/format";
import { getDisabledStatuses } from "@/lib/statusValidation";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { CSSProperties } from "react";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { AnimeSummary, RelationNode } from "@/types/anime";
import type { AnimeListEntry, ListStatus } from "@/types/list";

// Relation types that go into the "Also in this franchise" side section.
const SIDE_REL_TYPES = new Set(["SIDE_STORY", "SPIN_OFF", "PARENT", "SUMMARY"]);

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
  const listMap = useListStore((s) => s.map);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [pendingAdd, setPendingAdd] = useState<AnimeSummary | null>(null);
  const [pendingStatusId, setPendingStatusId] = useState<number | null>(null);

  // Tracked ids plus the franchise root. The root anchors the season walk, so
  // it must be fetched even when its own entry was removed from the list —
  // otherwise deleting S1 makes every remaining season fall out of the main
  // chain. Negative rootIds are card-identity tokens, not AniList ids.
  const relationIdList = useMemo(() => {
    if (!group) return [];
    const ids = group.entries.map((e) => e.anilist_id);
    if (group.rootId > 0 && !ids.includes(group.rootId)) ids.unshift(group.rootId);
    return ids;
  }, [group]);

  const { data: relMap, isLoading: relLoading } = useFranchiseRelations(
    relationIdList,
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

    const anchor =
      group.rootId > 0 ? group.rootId : group.entries[0].anilist_id;
    const mainChainIds: number[] = [anchor];
    const inMain = new Set<number>([anchor]);

    let current = anchor;
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

    for (const [idStr, rels] of Object.entries(relMap ?? {})) {
      const fromId = Number(idStr);
      const fromEntry = trackedMap.get(fromId);
      const fromTitle = fromEntry
        ? {
            romaji: fromEntry.title_romaji,
            english: fromEntry.title_english,
            native: fromEntry.title_native,
          }
        : allRelNodes.get(fromId)?.title;
      for (const r of rels) {
        // Manga/novel source can't be opened or tracked as anime; isMangaNode
        // also catches pre-`type` snapshots via their format. OTHER edges
        // join when the names claim the same franchise (Edgerunners 2).
        if (r.format === "MUSIC" || isMangaNode(r)) continue;
        if (
          SIDE_REL_TYPES.has(r.relationType) ||
          isFranchiseOther(fromTitle, r)
        ) {
          addSide(r.id);
        }
      }
    }

    for (const id of trackedMap.keys()) addSide(id);

    // Side entries follow the graph's watch order (a movie tagged SEQUEL of
    // S1 sorts after S1), falling back to air date where tags are silent.
    const edges: RelationEdge[] = [];
    for (const [idStr, rels] of Object.entries(relMap ?? {})) {
      const fromId = Number(idStr);
      for (const r of rels) {
        if (isMangaNode(r) || r.format === "MUSIC") continue;
        edges.push({ from: fromId, to: r.id, type: r.relationType });
      }
    }
    const orderable = [...new Set([...inMain, ...inSide])].map((id) => {
      const n = allRelNodes.get(id);
      return { id, startDate: n?.startDate, seasonYear: n?.seasonYear };
    });
    const pos = new Map(
      orderForWatching(orderable, edges).map((id, i) => [id, i]),
    );
    sideIds.sort((a, b) => (pos.get(a) ?? 0) - (pos.get(b) ?? 0));

    return { mainChainIds, sideIds };
  }, [group, relMap, trackedMap, allRelNodes]);

  // Franchise-wide completion: how much of this series exists (tracked or
  // not) vs how much is watched. Gated on relMap so an offline sheet, which
  // only knows the tracked entries, never wrongly reports a full set.
  const ledger = useMemo(() => {
    if (!relMap) return null;
    const ids = [...mainChainIds, ...sideIds];
    return computeFranchiseLedger(
      ids.map((id) => ({
        episodes: allRelNodes.get(id)?.episodes,
        // Fall back to the full list: a not-interested member is still ON the
        // list, it just doesn't ride this card's entries.
        entry: trackedMap.get(id) ?? listMap[id],
      })),
    );
  }, [relMap, mainChainIds, sideIds, allRelNodes, trackedMap, listMap]);

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

  // Looked up in the full list, not just the group: a not-interested member
  // renders on this sheet without belonging to the group's entries.
  const pendingStatusEntry =
    pendingStatusId != null ? listMap[pendingStatusId] ?? null : null;

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

  // The first genuinely untracked entry in the main chain is the "up next"
  // frontier — a not-interested member is a decision, not a gap.
  const frontierId = mainChainIds.find(
    (id) => !trackedMap.has(id) && !listMap[id],
  );

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

  // A member the user marked not-interested: it no longer rides the card, but
  // pretending it's untracked (with an Add button) would be worse. Show it
  // muted, status tappable, so changing your mind is one tap away.
  const renderNotInterested = (id: number) => {
    const entry = listMap[id];
    if (!entry) return null;
    return (
      <SeasonRow
        key={id}
        entry={entry}
        seasonNo={null}
        dimmed
        titleLanguage={titleLanguage}
        onOpen={(entryId) => {
          onClose();
          onNavigate(entryId);
        }}
        onStatusTap={(entryId) => setPendingStatusId(entryId)}
        onRemove={(entryId) => remove(entryId)}
      />
    );
  };

  const rowFor = (id: number, seasonNo: number | null, isFrontier: boolean) => {
    if (trackedMap.has(id)) return renderTracked(id, seasonNo);
    if (listMap[id]?.status === "not_interested") return renderNotInterested(id);
    return renderUntracked(id, isFrontier);
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
        onOpen={() => {
          onClose();
          onNavigate(id);
        }}
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
              {ledger && (ledger.untrackedCount > 0 || ledger.fullSet) && (
                <div
                  className={`k-fhead__ledger${ledger.fullSet ? " k-fhead__ledger--full" : ""}`}
                >
                  {ledger.fullSet
                    ? `Full set: all ${ledger.memberCount} entries are on your list`
                    : `${ledgerEpisodeLabel(ledger)} in this franchise · ${ledger.untrackedCount} not on your list`}
                </div>
              )}
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
                rowFor(id, group.isGroup ? i + 1 : null, id === frontierId),
              )}
            </div>

            {sideIds.length > 0 && (
              <>
                <p className="k-fsheet-heading">Also in this franchise</p>
                <div className="k-seasonlist">
                  {sideIds.map((id) => rowFor(id, null, false))}
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
  dimmed = false,
}: {
  entry: AnimeListEntry;
  seasonNo: number | null;
  titleLanguage: string;
  onOpen: (id: number) => void;
  onStatusTap: (id: number) => void;
  onRemove: (id: number) => void;
  dimmed?: boolean;
}) {
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
  const meta = statusMeta(entry.status);
  const { color } = seasonSegment(entry);

  const titleParts = {
    romaji: entry.title_romaji,
    english: entry.title_english,
    native: entry.title_native,
  };
  const title = preferredTitle(titleParts, titleLanguage as never);
  const alt = secondaryTitle(titleParts, titleLanguage as never);

  const isActive = entry.status === "watching" || entry.status === "rewatching";
  const epText = `${entry.episodes_watched} / ${entry.total_episodes ?? "?"}`;
  const canDecrement = isActive && entry.episodes_watched > 0;
  const canIncrement =
    isActive &&
    (entry.total_episodes == null ||
      entry.episodes_watched < entry.total_episodes);

  return (
    <div
      className={`k-srow${dimmed ? " k-srow--dimmed" : ""}`}
      style={{ "--card-status": color } as CSSProperties}
    >
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
          {alt && (
            <Text size="xs" color="tertiary" clamp={1}>
              {alt}
            </Text>
          )}
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
  onOpen,
}: {
  rel: RelationNode;
  featured: boolean;
  titleLanguage: string;
  onAdd: () => void;
  onOpen: () => void;
}) {
  const title = preferredTitle(rel.title, titleLanguage as never);
  const alt = secondaryTitle(rel.title, titleLanguage as never);
  const cover = getCoverUrl(rel.coverImage);

  const isUpcoming = rel.status === "NOT_YET_RELEASED";
  const isAiring = rel.status === "RELEASING";
  const relChip = SIDE_REL_TYPES.has(rel.relationType)
    ? relationChipMeta(rel.relationType)
    : null;
  const fmtChip = formatChipMeta(rel.format);
  const upcomingDate = isUpcoming ? formatFuzzyDate(rel.startDate) : null;

  // The format moves into its colored chip when it has one; the dim meta text
  // keeps whatever's left (plain TV formats, the year).
  const meta = [fmtChip ? null : formatLabel(rel.format), rel.seasonYear?.toString()]
    .filter(Boolean)
    .join(" · ");

  return (
    <div
      className={`k-srow k-srow--add${featured ? " k-srow--next" : ""}${isUpcoming ? " k-srow--unaired" : ""}`}
    >
      <button
        type="button"
        className="k-srow__open"
        onClick={onOpen}
        aria-label={`Open ${title}`}
      >
        <div className="k-srow__cover">
          <AnimeCover src={cover} alt={title} decorative radius="var(--radius-sm)" />
          <span className="k-srow__openhint" aria-hidden>
            <Icon icon={ChevronRight} size={18} />
          </span>
        </div>
      </button>
      <div className="k-srow__main">
        {featured && <span className="k-srow__nextlabel">Up next</span>}
        <button type="button" className="k-srow__titlebtn" onClick={onOpen}>
          <Text size="sm" weight={600} clamp={1}>
            {title}
          </Text>
          {alt && (
            <Text size="xs" color="tertiary" clamp={1}>
              {alt}
            </Text>
          )}
        </button>
        <div className="k-srow__controls">
          {meta && <span className="k-srow__dim">{meta}</span>}
          {relChip && (
            <span
              className="k-chip-kind"
              style={{ "--chip": relChip.color } as CSSProperties}
            >
              {relChip.label}
            </span>
          )}
          {fmtChip && (
            <span
              className="k-chip-kind"
              style={{ "--chip": fmtChip.color } as CSSProperties}
            >
              {fmtChip.label}
            </span>
          )}
          {isAiring && (
            <span className="k-chip-mini k-chip-mini--accent">
              <Icon icon={Zap} size={10} weight="fill" />
              airing
            </span>
          )}
          {isUpcoming && (
            <span className="k-chip-unaired">
              <Icon icon={Calendar} size={10} />
              {upcomingDate ? `Not aired yet · ${upcomingDate}` : "Not aired yet · TBA"}
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
