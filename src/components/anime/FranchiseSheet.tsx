import { useMemo, useState } from "react";
import {
  Calendar,
  ChevronDown,
  ChevronRight,
  Plus,
  Trash2,
  Zap,
} from "lucide-react";
import { EpisodeCounter } from "./EpisodeCounter";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { HoldButton } from "@/components/ui/HoldButton";
import { Skeleton } from "@/components/ui/Skeleton";
import { AnimeCover } from "./AnimeCover";
import { formatChipMeta, relationChipMeta } from "./relationMeta";
import { StatusSheet } from "./StatusSheet";
import { statusMeta } from "./statusMeta";
import { seasonSegment } from "./SeasonBar";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { useFranchiseWalk } from "@/hooks/useAniList";
import { computeFranchiseLedger, ledgerEpisodeLabel } from "@/lib/franchise/ledger";
import { mainStoryIds, placementLabel } from "@/lib/franchise/storySplit";
import { orderForWatching } from "@/lib/franchise/watchOrder";
import {
  formatFuzzyDate,
  formatLabel,
  formatScore,
  getCoverUrl,
  isMangaNode,
  preferredTitle,
} from "@/lib/format";
import { getDisabledStatuses } from "@/lib/statusValidation";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { CSSProperties } from "react";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { AnimeSummary, RelationNode } from "@/types/anime";
import type { AnimeListEntry, ListStatus } from "@/types/list";

// Relation types that mark side content (OVAs, movies, spin-offs).
const SIDE_REL_TYPES = new Set(["SIDE_STORY", "SPIN_OFF", "PARENT", "SUMMARY"]);

/** The chip that says what a non-season member IS (OVA, Movie, Side story…). */
function kindChipFor(rel: RelationNode | undefined) {
  if (!rel) return null;
  if (SIDE_REL_TYPES.has(rel.relationType)) {
    const m = relationChipMeta(rel.relationType);
    if (m) return m;
  }
  return formatChipMeta(rel.format);
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

/**
 * The quick menu for one franchise. One list, in watch order, one truth:
 * every member of the franchise appears exactly once, seasons numbered,
 * side content chip-labeled, and whether each is on YOUR list is the
 * loudest visual signal (solid tracked rows vs hollow add rows).
 */
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
  const allEntries = useListStore((s) => s.entries);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [pendingAdd, setPendingAdd] = useState<AnimeSummary | null>(null);
  const [pendingStatusId, setPendingStatusId] = useState<number | null>(null);

  // The quick menu is the ONE surface where the whole franchise unifies
  // across statuses. Rooms and the Overview group per status, so the group
  // that arrives here may carry just one room's slice (a completed S1
  // without its planned S2). Membership, totals, the root row, and the
  // franchise-wide remove all resolve against the full list instead:
  // every entry sharing the group's root key, whatever its status.
  const franchiseEntries = useMemo(() => {
    if (!group) return [] as AnimeListEntry[];
    const byId = new Map(group.entries.map((e) => [e.anilist_id, e]));
    for (const e of allEntries) {
      if ((e.franchise_root_id ?? e.anilist_id) === group.rootId) {
        byId.set(e.anilist_id, e);
      }
    }
    return [...byId.values()].sort((a, b) => a.added_at - b.added_at);
  }, [group, allEntries]);

  const trackedMap = useMemo(
    () => new Map(franchiseEntries.map((e) => [e.anilist_id, e])),
    [franchiseEntries],
  );

  // THE shared franchise walk — the exact function behind the Related tab,
  // same cache entry and all. The sheet stopped running its own weaker copy;
  // the two surfaces now cannot disagree about what the franchise contains.
  // Negative rootIds are card-identity tokens, not AniList ids.
  const anchorId =
    group == null ? null : group.rootId > 0 ? group.rootId : group.entries[0].anilist_id;
  const anchorEntry =
    franchiseEntries.find((e) => e.anilist_id === anchorId) ??
    franchiseEntries[0] ??
    null;
  const anchorTitle = anchorEntry
    ? {
        romaji: anchorEntry.title_romaji,
        english: anchorEntry.title_english,
        native: anchorEntry.title_native,
      }
    : null;
  const { data: walk, isLoading: relLoading } = useFranchiseWalk(
    anchorId,
    anchorTitle,
    open,
  );

  const allRelNodes = useMemo(() => {
    const m = new Map<number, RelationNode>();
    for (const n of walk?.nodes ?? []) m.set(n.id, n);
    return m;
  }, [walk]);

  /**
   * One ordered member list: everything the walk discovered, the anchor, and
   * any tracked strays the graph missed, interleaved by orderForWatching into
   * the order you'd actually watch (the aniwave #1..#N presentation).
   */
  const orderedIds = useMemo(() => {
    if (!group || anchorId == null) return [] as number[];

    const members = new Set<number>([anchorId]);
    for (const n of walk?.nodes ?? []) {
      if (n.format === "MUSIC" || isMangaNode(n)) continue;
      members.add(n.id);
    }
    for (const id of trackedMap.keys()) members.add(id);

    const orderable = [...members].map((id) => {
      const n = allRelNodes.get(id);
      return { id, startDate: n?.startDate, seasonYear: n?.seasonYear };
    });
    return orderForWatching(orderable, walk?.edges ?? []);
  }, [group, anchorId, walk, trackedMap, allRelNodes]);

  // Main story vs extras: the same structural split the Related tab uses,
  // derived from the same walk, so the two surfaces cannot disagree.
  const storyMembers = useMemo(
    () =>
      orderedIds.map((id) => {
        // The anchor isn't in the walk's node list (a walk never returns its
        // own seed), but a later season's edge back to it carries full node
        // data — without it the anchor has no air date and extras mis-place
        // around "#1".
        const n =
          allRelNodes.get(id) ??
          (id === anchorId ? walk?.seedNode ?? undefined : undefined);
        return { id, format: n?.format ?? null, startDate: n?.startDate ?? null };
      }),
    [orderedIds, allRelNodes, anchorId, walk],
  );
  const mainSet = useMemo(
    () => mainStoryIds(storyMembers, walk?.edges ?? []),
    [storyMembers, walk],
  );
  const mainStory = useMemo(
    () => storyMembers.filter((m) => mainSet.has(m.id)),
    [storyMembers, mainSet],
  );

  // Franchise-wide completion: how much of this series exists (tracked or
  // not) vs how much is watched. Gated on the walk so an offline sheet, which
  // only knows the tracked entries, never wrongly reports a full set.
  const ledger = useMemo(() => {
    if (!walk) return null;
    return computeFranchiseLedger(
      orderedIds.map((id) => ({
        episodes: allRelNodes.get(id)?.episodes,
        // Fall back to the full list: a not-interested member is still ON the
        // list, it just doesn't ride this card's entries.
        entry: trackedMap.get(id) ?? listMap[id],
      })),
    );
  }, [walk, orderedIds, allRelNodes, trackedMap, listMap]);

  if (!group) return null;

  const rootEntry =
    franchiseEntries.find((e) => e.anilist_id === group.rootId) ??
    franchiseEntries[0] ??
    group.entries[0];

  const franchiseTitle = preferredTitle(
    {
      romaji: rootEntry.title_romaji,
      english: rootEntry.title_english,
      native: rootEntry.title_native,
    },
    titleLanguage,
  );

  // Totals span the whole franchise, not the room slice the group carries.
  // Muted (not-interested) members stay out of the math: a mute is a
  // decision, not progress.
  let totalWatched = 0;
  let totalEpisodes: number | null = 0;
  for (const e of franchiseEntries) {
    if (e.status === "not_interested") continue;
    totalWatched += e.episodes_watched;
    if (totalEpisodes !== null) {
      totalEpisodes = e.total_episodes == null ? null : totalEpisodes + e.total_episodes;
    }
  }
  const overallPct =
    totalEpisodes != null && totalEpisodes > 0
      ? Math.round((totalWatched / totalEpisodes) * 100)
      : null;
  const epSummary =
    totalEpisodes != null
      ? `${totalWatched} / ${totalEpisodes} episodes`
      : `${totalWatched} episodes watched`;

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
      if (franchiseEntries.length <= 1) onClose();
    }
  };

  // Franchise-wide means the WHOLE franchise: every tracked member across
  // every status, not just the room slice this group carries.
  const removeFranchise = () => {
    removeMany(franchiseEntries.map((e) => e.anilist_id));
    onClose();
  };

  // The first genuinely untracked member in watch order is the "up next"
  // frontier — a not-interested member is a decision, not a gap. The main
  // story is asked first: the next season beats a side OVA every time, and
  // extras only become "up next" once the story itself is fully accounted for.
  const untrackedHere = (id: number) =>
    !trackedMap.has(id) && !listMap[id] && allRelNodes.has(id);
  const frontierId =
    orderedIds.find((id) => mainSet.has(id) && untrackedHere(id)) ??
    orderedIds.find(untrackedHere);

  // Rows: main-story members carry their watch-order position (#1..#N, same
  // numbering as the Related tab); extras carry a placement chip ("after #2")
  // instead. Format and relation kind stay as chips, year in the meta.
  const rowFor = (id: number, posNo: number | null, where: string | null) => {
    const node = allRelNodes.get(id);
    const kind = kindChipFor(node);
    const year = node?.seasonYear ?? node?.startDate?.year ?? null;
    // On the list in ANY status counts as yours. The listMap fallback also
    // catches tracked members whose root linkage diverged from this card
    // (the walk found them; the grouping key didn't). Muted members render
    // dimmed: present for honesty, visually parked.
    const onList = trackedMap.get(id) ?? listMap[id];
    if (onList) {
      return (
        <SeasonRow
          key={id}
          entry={onList}
          posNo={posNo}
          kind={kind}
          where={where}
          year={year}
          dimmed={onList.status === "not_interested"}
          titleLanguage={titleLanguage}
          onOpen={(entryId) => {
            onClose();
            onNavigate(entryId);
          }}
          onStatusTap={(entryId) => setPendingStatusId(entryId)}
        />
      );
    }
    if (!node) return null;
    return (
      <AddRow
        key={id}
        rel={node}
        posNo={posNo}
        where={where}
        featured={id === frontierId}
        titleLanguage={titleLanguage}
        onAdd={() => setPendingAdd(relationToSummary(node))}
        onOpen={() => {
          onClose();
          onNavigate(id);
        }}
      />
    );
  };

  const onListCount = ledger ? ledger.memberCount - ledger.untrackedCount : null;

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
                <span>{epSummary}</span>
                {overallPct != null && <span className="k-fhead__pct">{overallPct}%</span>}
              </div>
              {/* Ownership is the headline question this sheet answers. */}
              {ledger && (
                <div
                  className={`k-fhead__ledger${ledger.fullSet ? " k-fhead__ledger--full" : ""}`}
                >
                  {ledger.fullSet
                    ? `Full set: all ${ledger.memberCount} entries are on your list`
                    : `${onListCount} of ${ledger.memberCount} on your list · ${ledgerEpisodeLabel(ledger)} in this franchise`}
                </div>
              )}
            </div>
          </div>
        </div>

        {relLoading ? (
          <div className="k-seasonlist">
            {Array.from({ length: Math.max(3, franchiseEntries.length + 1) }).map(
              (_, i) => (
                <Skeleton key={i} height={72} radius="var(--radius-lg)" />
              ),
            )}
          </div>
        ) : (
          (() => {
            // Pre-filter to renderable ids so position numbers stay
            // contiguous even when a member has no usable data.
            const renderable = orderedIds.filter(
              (id) =>
                trackedMap.has(id) || listMap[id] != null || allRelNodes.has(id),
            );
            const mainList = renderable.filter((id) => mainSet.has(id));
            const extraList = renderable.filter((id) => !mainSet.has(id));
            const whereOf = (id: number) => {
              const m = storyMembers.find((s) => s.id === id);
              return m ? placementLabel(m, mainStory) : null;
            };
            return (
              <>
                <p className="k-fsheet-heading">Main story</p>
                <div className="k-seasonlist">
                  {mainList.map((id, i) => rowFor(id, i + 1, null))}
                </div>
                {extraList.length > 0 && (
                  <>
                    <p className="k-fsheet-heading">Extras & side stories</p>
                    <div className="k-seasonlist">
                      {extraList.map((id) => rowFor(id, null, whereOf(id)))}
                    </div>
                  </>
                )}
              </>
            );
          })()
        )}

        {/* Destructive and franchise-wide: deliberate hold, not a stray tap. */}
        <HoldButton
          onConfirm={removeFranchise}
          className="k-holdbtn--danger k-fsheet-removehold"
        >
          <Icon icon={Trash2} size={15} />
          {franchiseEntries.length > 1
            ? "Hold to remove whole franchise"
            : "Hold to remove from list"}
        </HoldButton>
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

      {/* Change status of a tracked entry (Remove lives here too) */}
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

interface KindChip {
  label: string;
}

function SeasonRow({
  entry,
  posNo,
  kind,
  where,
  year,
  titleLanguage,
  onOpen,
  onStatusTap,
  dimmed = false,
}: {
  entry: AnimeListEntry;
  /** Watch-order number for main-story rows; null for extras. */
  posNo: number | null;
  kind: KindChip | null;
  /** Where an extra falls in the story ("after #2"); null for main rows. */
  where?: string | null;
  year: number | null;
  titleLanguage: string;
  onOpen: (id: number) => void;
  onStatusTap: (id: number) => void;
  dimmed?: boolean;
}) {
  const meta = statusMeta(entry.status);
  const { color } = seasonSegment(entry);

  const titleParts = {
    romaji: entry.title_romaji,
    english: entry.title_english,
    native: entry.title_native,
  };
  const title = preferredTitle(titleParts, titleLanguage as never);

  const isActive = entry.status === "watching" || entry.status === "rewatching";
  const epText = `${entry.episodes_watched} / ${entry.total_episodes ?? "?"}`;

  return (
    <div
      className={`k-srow k-srow--mine${dimmed ? " k-srow--dimmed" : ""}`}
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
          {posNo != null && <span className="k-srow__num">#{posNo}</span>}
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
            onClick={() => onStatusTap(entry.anilist_id)}
            aria-label={`Change status (currently ${meta.label})`}
          >
            <span className="k-pill__icon" style={{ color: meta.color }}>
              <Icon icon={meta.icon} size={12} weight="fill" />
            </span>
            {meta.label}
            <Icon icon={ChevronDown} size={12} className="k-srow__caret" />
          </button>
          {kind && <span className="k-chip-kind">{kind.label}</span>}
          {where && <span className="k-chip-kind k-chip-kind--where">{where}</span>}
          {year != null && <span className="k-srow__dim">{year}</span>}
          {isActive ? (
            <EpisodeCounter
              anilistId={entry.anilist_id}
              watched={entry.episodes_watched}
              total={entry.total_episodes}
            />
          ) : (
            <span className="k-srow__ep">{epText}</span>
          )}
          {entry.score != null && (
            <span className="k-srow__score">★ {formatScore(entry.score)}</span>
          )}
        </div>
      </div>
    </div>
  );
}

function AddRow({
  rel,
  posNo,
  where,
  featured,
  titleLanguage,
  onAdd,
  onOpen,
}: {
  rel: RelationNode;
  /** Watch-order number for main-story rows; null for extras. */
  posNo: number | null;
  /** Where an extra falls in the story ("after #2"); null for main rows. */
  where?: string | null;
  featured: boolean;
  titleLanguage: string;
  onAdd: () => void;
  onOpen: () => void;
}) {
  const title = preferredTitle(rel.title, titleLanguage as never);
  const cover = getCoverUrl(rel.coverImage);

  const isUpcoming = rel.status === "NOT_YET_RELEASED";
  const isAiring = rel.status === "RELEASING";
  const kind = kindChipFor(rel);
  const upcomingDate = isUpcoming ? formatFuzzyDate(rel.startDate) : null;

  // The format moves into its colored chip when it has one; the dim meta text
  // keeps whatever's left (plain TV formats, the year).
  const meta = [kind ? null : formatLabel(rel.format), rel.seasonYear?.toString()]
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
          {posNo != null && <span className="k-srow__num">#{posNo}</span>}
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
        </button>
        <div className="k-srow__controls">
          <span className="k-srow__notin">Not on your list</span>
          {meta && <span className="k-srow__dim">{meta}</span>}
          {kind && <span className="k-chip-kind">{kind.label}</span>}
          {where && <span className="k-chip-kind k-chip-kind--where">{where}</span>}
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
