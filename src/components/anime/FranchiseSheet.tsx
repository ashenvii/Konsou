import { useMemo, useState } from "react";
import { ChevronRight, Plus, Trash2 } from "lucide-react";
import { EpisodeCounter } from "./EpisodeCounter";
import { QuickHead } from "./QuickHead";
import { nextAct } from "./nextAct";
import { ItemSurface } from "@/components/ui/ItemSurface";
import { HoldButton } from "@/components/ui/HoldButton";
import { Skeleton } from "@/components/ui/Skeleton";
import { Verb, VerbRule } from "@/components/ui/Verb";
import { AnimeCover } from "./AnimeCover";
import { formatChipMeta, relationChipMeta } from "./relationMeta";
import { StatusSheet } from "./StatusSheet";
import { statusMeta } from "./statusMeta";
import { STAMP_WORD } from "./StatusStamp";
import { seasonSegment } from "./SeasonBar";
import { Icon } from "@/components/ui/Icon";
import { useFranchiseWalk } from "@/hooks/useAniList";
import { computeFranchiseLedger, ledgerEpisodeLabel } from "@/lib/franchise/ledger";
import { mainStoryIds } from "@/lib/franchise/storySplit";
import { orderByRelease } from "@/lib/franchise/watchOrder";
import {
  formatFuzzyDate,
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
  /** The card this was opened from; the popover points at it. */
  anchor?: HTMLElement | null;
  /** The whole card, when the anchor is only its poster. */
  opener?: HTMLElement | null;
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
  anchor = null,
  opener = null,
  open,
  onClose,
  onNavigate,
}: FranchiseSheetProps) {
  const addFromSummary = useListStore((s) => s.addFromSummary);
  const updateStatus = useListStore((s) => s.updateStatus);
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
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
   * any tracked strays the graph missed, sorted by RELEASE date. Release is the
   * honest default — watch order is a curated community call with no source of
   * truth, so the list shows when things came out and lets the spine + numbering
   * carry the story shape.
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
    return orderByRelease(orderable);
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
  // Rows: main-story members carry their position number (#1..#N); extras sit
  // in release position without one. No thread, no placement chips — the list
  // is already in order, and saying "after #2" on every extra was noise on top
  // of an order you can simply read.
  const rowFor = (id: number, posNo: number | null) => {
    const node = allRelNodes.get(id);
    const kind = kindChipFor(node);
    /** What the lead column shows when this is not a numbered story beat.
     *
     *  Empty when the format is genuinely unknown, which is the common case
     *  offline: the relation walk is what carries `format`, so with no network
     *  every row falls out of the main-story set AND has no tag, and a
     *  placeholder mark in that state paints a column of meaningless bullets
     *  down a list that is simply missing its data. Nothing is the honest
     *  answer to "what kind of thing is this" when we do not know yet. */
    const tag = posNo == null ? (kind?.tag ?? null) : null;
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
          tag={tag}
          kind={kind}
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
        tag={tag}
        year={year}
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
  /**
   * The one line of state under the franchise name.
   *
   * It used to be three stacked lines all answering "how complete is this":
   * "15 / 40 episodes", then "38%", then "3 of 7 on your list · 120 episodes in
   * this franchise". Three statements of one fact, in a head that then repeated
   * the episode fraction on every row beneath it.
   *
   * Ownership wins the slot, because it is the question this surface exists to
   * answer and the only one the rows below cannot answer for themselves. The
   * episode total falls back in while the walk is still loading, so the line is
   * never empty while the network is thinking.
   */
  const headState = ledger
    ? ledger.fullSet
      ? `Full set · all ${ledger.memberCount} on your list`
      : `${onListCount} of ${ledger.memberCount} on your list · ${ledgerEpisodeLabel(ledger)}`
    : epSummary;
  /* The one act, if there is one: whatever in this franchise is actually
     running. A franchise you are part-way through has an episode to log; one
     you have finished or never started has nothing to press, and an inert seal
     is worse than no seal. */
  const runningEntry =
    franchiseEntries.find(
      (e) => e.status === "watching" || e.status === "rewatching",
    ) ?? null;
  const runningTitle = runningEntry
    ? preferredTitle(
        {
          romaji: runningEntry.title_romaji,
          english: runningEntry.title_english,
          native: runningEntry.title_native,
        },
        titleLanguage,
      )
    : "";
  const runningAct = runningEntry ? nextAct(runningEntry, runningTitle) : null;
  /* The rail. Franchise-level acts only, because each season carries its own
     status in its own row. What it buys is the removal of the full-width
     "Hold to remove whole franchise" button that used to sit at the bottom of
     the list, getting further away the more seasons a franchise had. */
  const verbs = (
    <>
      <Verb
        icon={ChevronRight}
        label={`Open the full page for ${franchiseTitle}`}
        onClick={() => {
          onClose();
          onNavigate(rootEntry.anilist_id);
        }}
      />
      <VerbRule />
      {/* Destructive and franchise-wide: a deliberate hold, not a stray tap.
          Especially here, where the rail puts it one press from the panel. */}
      <HoldButton
        onConfirm={removeFranchise}
        className="k-verb k-verb--danger k-holdbtn--verb"
        ariaLabel={
          franchiseEntries.length > 1
            ? `Hold to remove all ${franchiseEntries.length} entries in ${franchiseTitle}`
            : `Hold to remove ${franchiseTitle} from your list`
        }
      >
        <Icon icon={Trash2} size={19} />
      </HoldButton>
    </>
  );
  return (
    <>
      <ItemSurface
        anchor={anchor}
        opener={opener}
        open={open}
        onClose={onClose}
        ariaLabel={group ? franchiseTitle : undefined}
        verbs={verbs}
      >
        <QuickHead
          cover={poster ?? art}
          kicker={franchiseEntries.length > 1 ? "Franchise" : "Series"}
          title={franchiseTitle}
          state={headState}
          seal={
            runningAct && runningEntry
              ? {
                  icon: runningAct.icon,
                  label: runningAct.label,
                  fill: runningAct.fill,
                  disabled: runningAct.disabled,
                  onAct: () => {
                    if (runningAct.kind === "log") {
                      void incrementEpisodes(runningEntry.anilist_id, 1);
                    } else if (runningAct.status) {
                      void updateStatus(runningEntry.anilist_id, runningAct.status);
                    }
                  },
                }
              : null
          }
        />
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
            // ONE list, in release order. Not two.
            //
            // Splitting the story from the extras was a mistake and it is worth
            // saying why, because the reasoning sounded fine: each group was
            // still internally ordered, and the split gave the eye a landmark.
            // What it destroyed is the thing the list is actually FOR. A
            // franchise list answers "how did this come out", and that question
            // is answered by one chronology — season, season, the OVA that
            // aired between them, season, the movie that followed. Cutting it
            // into two blocks put the OVA after the last season it has nothing
            // to do with, and no amount of within-group ordering brings the
            // timeline back.
            //
            // What the split was reaching for — being able to tell a season
            // from an OVA at a glance — belongs in the row, not in the
            // arrangement. The lead column carries it now (see rowFor): the
            // story numbers run 1..N down the same column that says OVA, MOV,
            // SP for everything else, so one downward scan gives you both the
            // order and the kind.
            //
            // Filtered to renderable ids so the story numbers stay contiguous.
            const renderable = orderedIds.filter(
              (id) =>
                trackedMap.has(id) || listMap[id] != null || allRelNodes.has(id),
            );
            let storyNo = 0;
            return (
              <div className="k-seasonlist">
                {renderable.map((id) => {
                  if (mainSet.has(id)) {
                    storyNo += 1;
                    return rowFor(id, storyNo);
                  }
                  return rowFor(id, null);
                })}
              </div>
            );
          })()
        )}
      </ItemSurface>
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
/**
 * One tracked member.
 *
 * Two lines and one control, deliberately. The old row carried a spine rail, a
 * sideways year, a number badge, a hover chevron, a status pill with a caret, a
 * kind chip, a placement chip ("after #2"), an episode counter, a score and
 * sometimes a "Start here" label — ten things competing on a 72px row, which is
 * what made a six-season franchise unreadable. What survived is what answers a
 * question: which one is this (number + name), what is it (year, kind, length),
 * and where am I with it (status + progress).
 */
function SeasonRow({
  entry,
  posNo,
  tag,
  kind,
  year,
  titleLanguage,
  onOpen,
  onStatusTap,
  dimmed = false,
}: {
  entry: AnimeListEntry;
  /** Watch-order number for main-story rows; null for extras. */
  posNo: number | null;
  /** What the lead column shows instead of a number: OVA, MOV, SP. */
  tag: string | null;
  kind: KindChip | null;
  year: number | null;
  titleLanguage: string;
  onOpen: (id: number) => void;
  onStatusTap: (id: number) => void;
  dimmed?: boolean;
}) {
  const meta = statusMeta(entry.status);
  const { color } = seasonSegment(entry);
  const title = preferredTitle(
    {
      romaji: entry.title_romaji,
      english: entry.title_english,
      native: entry.title_native,
    },
    titleLanguage as never,
  );
  const isActive = entry.status === "watching" || entry.status === "rewatching";
  /** Progress as a bar rather than a fraction. Unknown length gets no bar
   *  rather than a guessed one. */
  const pct =
    entry.total_episodes != null && entry.total_episodes > 0
      ? Math.min(
          100,
          Math.round((entry.episodes_watched / entry.total_episodes) * 100),
        )
      : null;
  return (
    <div
      className={`k-srow k-srow--mine${dimmed ? " k-srow--dimmed" : ""}`}
      style={{ "--card-status": color } as CSSProperties}
    >
      {/* The lead column. A story beat shows its number; anything else shows
          what kind of thing it is. One column, scanned once, gives both the
          order and the shape of the franchise. */}
      <span
        className={`k-srow__no${posNo == null ? " k-srow__no--tag" : ""}`}
        // "MOV" and "SP" are abbreviations, so the full word has to exist
        // somewhere: on hover here, and in the row's own name below for anyone
        // who is not looking at it.
        title={posNo == null ? (kind?.label ?? undefined) : undefined}
      >
        {posNo ?? tag}
      </span>
      <button
        type="button"
        className="k-srow__open"
        onClick={() => onOpen(entry.anilist_id)}
        aria-label={`Open ${title}${kind ? `, ${kind.label}` : ""}`}
      >
        <span className="k-srow__cover">
          <AnimeCover
            src={entry.cover_url ?? undefined}
            alt={title}
            decorative
            radius="var(--plate-radius)"
          />
        </span>
      </button>
      <div className="k-srow__main">
        <button
          type="button"
          className="k-srow__titlebtn"
          onClick={() => onOpen(entry.anilist_id)}
        >
          {title}
        </button>
        {/* Two facts, where there were four.
            The episode fraction left because the meter below says it faster and
            the counter beside it says it exactly; printing it a third time in
            11px mono was a third of this panel's flat-text problem. The score
            left because a franchise list answers "which one is this and where
            am I", and a rating is neither — it lives on the entry's own page.
            The format chip is already absent for a plain TV season
            (relationMeta's FORMAT_META), so it only appears when it is telling
            you something: a movie, an OVA, a special. */}
        {/* The kind moved to the lead column, so the meta line is down to the
            one fact nothing else on the row carries. */}
        <p className="k-srow__meta">{year != null && <span>{year}</span>}</p>
        {/* Progress you read before you read anything. Same device as the
            Overview's running sheet, deliberately: one meter in the app, not
            two that drift.

            Suppressed on the rows that carry a counter. The counter IS the
            progress on those, exactly and as a control, so a bar above it is
            the third statement of one fact on the row that can least afford
            it — measured, it was the difference between an 89px row and a
            147px one, on the row you look at most. */}
        {pct != null && !isActive && (
          <span className="k-srow__meter" aria-hidden>
            <i style={{ width: `${pct}%` }} />
          </span>
        )}
      </div>
      <div className="k-srow__act">
        <button
          type="button"
          className="k-srow__statusbtn"
          onClick={() => onStatusTap(entry.anilist_id)}
          aria-label={`Change status (currently ${meta.label})`}
          style={{ "--stamp": meta.color } as CSSProperties}
        >
          <Icon icon={meta.icon} size={11} className="k-srow__statusglyph" />
          {/* The word goes below 420px and the glyph carries it alone. It is
              already saying what the colour and the icon say, and it was the
              last thing in a row that overflowed, so on a phone it was pushed
              off the right edge and took the status with it. */}
          <span className="k-srow__statusword">{STAMP_WORD[entry.status]}</span>
        </button>
      </div>
      {/* Its own line, under the title rather than beside it.
          This is the whole of the mobile fix. The action column was `flex:
          none` against a `flex: 1` title, so the counter and the status pill
          took whatever width they wanted and the title absorbed one hundred
          percent of the squeeze: about 38px of a 360px row, with the meta line
          (nowrap, overflow hidden below 520) clipped to nothing behind it. A
          row is for reading which season this is. The counter can have the
          space underneath, where nothing is competing for it. */}
      {isActive && (
        <div className="k-srow__count">
          <EpisodeCounter
            anilistId={entry.anilist_id}
            watched={entry.episodes_watched}
            total={entry.total_episodes}
            airedCeiling={entry.aired_episodes}
          />
        </div>
      )}
    </div>
  );
}
/** A member of the franchise that isn't on your list. Same two-line shape as a
 *  tracked row so the list reads as one thing; the difference is the hollow
 *  treatment and that its one control adds instead of edits. */
function AddRow({
  rel,
  posNo,
  tag,
  year,
  featured,
  titleLanguage,
  onAdd,
  onOpen,
}: {
  rel: RelationNode;
  /** Watch-order number for main-story rows; null for extras. */
  posNo: number | null;
  /** What the lead column shows instead of a number: OVA, MOV, SP. */
  tag: string | null;
  year: number | null;
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
  return (
    <div
      className={`k-srow k-srow--add${featured ? " k-srow--next" : ""}${isUpcoming ? " k-srow--unaired" : ""}`}
    >
      <span
        className={`k-srow__no${posNo == null ? " k-srow__no--tag" : ""}`}
        title={posNo == null ? (kind?.label ?? undefined) : undefined}
      >
        {posNo ?? tag}
      </span>
      <button
        type="button"
        className="k-srow__open"
        onClick={onOpen}
        aria-label={`Open ${title}${kind ? `, ${kind.label}` : ""}`}
      >
        <span className="k-srow__cover">
          <AnimeCover src={cover} alt={title} decorative radius="var(--plate-radius)" />
        </span>
      </button>
      <div className="k-srow__main">
        <button type="button" className="k-srow__titlebtn" onClick={onOpen}>
          {title}
        </button>
        {/* "not on your list" is gone: the hollow treatment and the Add
            button beside it already say so, and it was one more 11px mono run
            on every untracked row. What survives is what the row cannot show
            any other way. */}
        <p className="k-srow__meta">
          {year != null && <span>{year}</span>}
          {isAiring && <span className="k-srow__airing">airing</span>}
          {isUpcoming && (
            <span>{upcomingDate ? `not aired · ${upcomingDate}` : "not aired yet"}</span>
          )}
        </p>
      </div>
      <div className="k-srow__act">
        {featured && <span className="k-srow__nextlabel">Up next</span>}
        <button
          type="button"
          className={`k-srow__add${featured ? " k-srow__add--primary" : ""}`}
          onClick={onAdd}
          aria-label={`Add ${title}`}
        >
          <Icon icon={Plus} size={14} />
          Add
        </button>
      </div>
    </div>
  );
}
