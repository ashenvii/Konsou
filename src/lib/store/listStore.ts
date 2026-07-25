import { create } from "zustand";
import { anilist } from "@/lib/api/anilist/client";
import { getDb } from "@/lib/db";
import { airedEpisodes, getCoverUrl, isMangaNode, preferredTitle } from "@/lib/format";
import { haptic } from "@/lib/haptics";
import { resolveFranchiseChain } from "@/lib/franchise/cascade";
import { isFranchiseOther, isFranchiseParent } from "@/lib/franchise/relatedness";
import { statusBlockReason } from "@/lib/statusValidation";
import { syncQueue } from "@/lib/sync/queue";
import { syncManager } from "@/lib/sync/syncManager";
import { useCatchUpStore } from "./catchUpStore";
import { recordEpisodeLog } from "./episodeUndo";
import { useSettingsStore } from "./settingsStore";
import { toast } from "./toastStore";
import type { AnimeSummary, AnimeTitle, RelationNode } from "@/types/anime";
import type {
  AnimeListEntry,
  ListEntryPatch,
  ListStatus,
} from "@/types/list";

interface ListState {
  loaded: boolean;
  entries: AnimeListEntry[];
  map: Record<number, AnimeListEntry>;

  load: () => Promise<void>;
  isInList: (anilistId: number) => boolean;
  getEntry: (anilistId: number) => AnimeListEntry | undefined;

  addFromSummary: (summary: AnimeSummary, status: ListStatus) => Promise<void>;
  /** Mark the given prior franchise entries as completed, in response to the
   *  catch-up prompt. Ties them to the shared franchise root. */
  addWatchedPrior: (rootId: number, nodes: RelationNode[]) => Promise<void>;
  importEntries: (toImport: AnimeListEntry[]) => Promise<number>;
  setDubStatus: (anilistId: number, hasDub: boolean) => Promise<void>;
  updateStatus: (anilistId: number, status: ListStatus) => Promise<void>;
  setEpisodes: (anilistId: number, episodes: number) => Promise<void>;
  incrementEpisodes: (anilistId: number, delta: number) => Promise<void>;
  setScore: (anilistId: number, score: number | null) => Promise<void>;
  /** Rewrite the plan queue's manual order. Takes the anilist_ids in their new
   *  order and stamps each one's rank, so the arrangement survives restarts
   *  and rides the Drive sync. */
  reorderPlan: (anilistIdsInOrder: number[]) => Promise<void>;
  /** Stamp a 1..UP_NEXT_CAP number onto an entry, or `null` to clear it.
   *  Swaps with whoever holds that number. */
  setPlanNumber: (anilistId: number, rank: number | null) => Promise<void>;
  /** Give an entry the lowest free number. False when the order is full or the
   *  entry already has one, so callers can say so instead of failing silently. */
  addToPlanOrder: (anilistId: number) => boolean;
  patch: (anilistId: number, patch: ListEntryPatch) => Promise<void>;
  /** Force re-resolve a franchise so its tracked members share one root card.
   *  Lets the user fix a grouping the background pass missed (e.g. a sequel
   *  added after the earlier season was already resolved as standalone). */
  regroupFranchise: (anilistId: number) => Promise<void>;
  remove: (anilistId: number) => void;
  removeMany: (anilistIds: number[]) => void;
  clearAll: (opts?: { propagateToDrive?: boolean }) => Promise<void>;
  restore: (entry: AnimeListEntry) => Promise<void>;
}

/**
 * How many cards Up Next holds. Small on purpose: a shortlist you can rank by
 * hand is the thing a total order over a thousand plan entries can never be.
 */
export const UP_NEXT_CAP = 10;

function indexBy(entries: AnimeListEntry[]): Record<number, AnimeListEntry> {
  const m: Record<number, AnimeListEntry> = {};
  for (const e of entries) m[e.anilist_id] = e;
  return m;
}

/** Toast copy honors the title-language preference like every rendered surface. */
function prefTitle(title: AnimeTitle): string {
  return preferredTitle(title, useSettingsStore.getState().titleLanguage);
}

/** Build a completed list entry for a franchise relation the user confirms
 *  they've already watched. */
function completedRelEntry(
  rel: RelationNode,
  rootId: number,
  now: number,
): AnimeListEntry {
  const total = rel.episodes ?? null;
  return {
    anilist_id: rel.id,
    mal_id: rel.idMal ?? null,
    title_romaji: rel.title.romaji,
    title_english: rel.title.english ?? null,
    title_native: rel.title.native ?? null,
    cover_url: getCoverUrl(rel.coverImage) || null,
    total_episodes: total,
    status: "completed",
    episodes_watched: total ?? 0,
    score: null,
    notes: null,
    has_dub: null,
    franchise_root_id: rootId,
    airing_status: rel.status ?? null,
    // Completed, so it never rides the plan queue.
    plan_rank: null,
    // Relation nodes don't carry duration; the detail visit backfills it.
    episode_duration: null,
    rewatch_count: 0,
    aired_episodes: airedEpisodes(rel),
    added_at: now,
    updated_at: now,
    started_at: null,
    completed_at: now,
  };
}

function queueSync(): void {
  syncQueue.scheduleWrite(() => syncManager.pushNow());
}

/** The chain walker needs the start entry's title to judge OTHER relation
 *  edges (followed only when the names claim the same franchise). */
function entryTitle(e: AnimeListEntry): AnimeTitle {
  return {
    romaji: e.title_romaji,
    english: e.title_english,
    native: e.title_native,
  };
}

export const useListStore = create<ListState>((set, get) => {
  /** Replace one entry in both `entries` and `map` (optimistic update). */
  const applyEntry = (entry: AnimeListEntry) => {
    set((s) => {
      const exists = s.map[entry.anilist_id];
      const entries = exists
        ? s.entries.map((e) => (e.anilist_id === entry.anilist_id ? entry : e))
        : [entry, ...s.entries];
      return { entries, map: { ...s.map, [entry.anilist_id]: entry } };
    });
  };

  const removeFromState = (anilistId: number) => {
    set((s) => {
      const map = { ...s.map };
      delete map[anilistId];
      return {
        entries: s.entries.filter((e) => e.anilist_id !== anilistId),
        map,
      };
    });
  };

  /**
   * Walk the PREQUEL chain for `primaryId`, stamp franchise_root_id on the
   * primary entry and any already-tracked ancestors, and — when earlier
   * entries aren't tracked yet — raise the catch-up prompt so the user says
   * what they actually watched (instead of everything auto-completing). Runs
   * in the background; errors are swallowed so they never block the add.
   *
   * `promptCatchUp` is off for dropped/not-interested entries: they still get
   * their franchise root (so grouping and later status flips work), but
   * neither status implies having watched what came before.
   */
  const runFranchiseCascade = async (
    primaryId: number,
    promptCatchUp = true,
  ): Promise<void> => {
    try {
      const inList = new Set(get().entries.map((e) => e.anilist_id));
      const primaryEntry = get().map[primaryId];
      const { rootId, toAdd, toUpdate } = await resolveFranchiseChain(
        primaryId,
        inList,
        "high",
        primaryEntry ? entryTitle(primaryEntry) : undefined,
      );

      // Give the newly added entry its franchise root.
      await patchEntryQuiet(primaryId, { franchise_root_id: rootId });

      // Stamp already-tracked ancestors that were added before this feature.
      for (const id of toUpdate) {
        await patchEntryQuiet(id, { franchise_root_id: rootId });
      }

      if (toAdd.length === 0 || !promptCatchUp) return;

      // Don't silently mark the earlier seasons/movies/OVAs as watched — that
      // was burying entries the user may never watch under "completed" and
      // dragging whole franchise cards into the wrong state. Ask what they
      // actually finished; the catch-up sheet calls addWatchedPrior to write.
      const primary = get().map[primaryId];
      const primaryTitle = primary
        ? preferredTitle({
            romaji: primary.title_romaji,
            english: primary.title_english,
            native: primary.title_native,
          })
        : "";
      useCatchUpStore.getState().open({ rootId, primaryTitle, candidates: toAdd });
    } catch (err) {
      console.warn("[cascade] franchise chain resolve failed:", err);
      // Non-fatal: the primary entry is already in the list, just ungrouped until
      // the user visits its detail page and the root is resolved there.
    }
  };

  /** Optimistic field patch with DB write + revert-on-failure. */
  const patchEntry = async (anilistId: number, patch: ListEntryPatch) => {
    const prev = get().map[anilistId];
    if (!prev) return;
    const updated_at = Date.now();
    applyEntry({ ...prev, ...patch, updated_at });
    try {
      const db = await getDb();
      await db.listUpdate(anilistId, { ...patch, updated_at });
      queueSync();
    } catch {
      applyEntry(prev); // revert
      toast.error("Couldn't save that change");
    }
  };

  /**
   * Write a batch of plan_rank values, optimistically and reversibly. A rank
   * means "position in Up Next"; null means the entry lives in the unordered
   * library. Only entries whose rank actually changes are written.
   */
  const writePlanRanks = async (
    updates: { id: number; rank: number | null }[],
  ): Promise<void> => {
    const prev = get().map;
    const changed = updates.filter(
      ({ id, rank }) => prev[id] && prev[id].plan_rank !== rank,
    );
    if (changed.length === 0) return;

    const now = Date.now();
    // The whole arrangement lands at once so the shelf can't flicker through a
    // half-applied order.
    set((s) => {
      const map = { ...s.map };
      for (const { id, rank } of changed) {
        map[id] = { ...map[id], plan_rank: rank, updated_at: now };
      }
      return { entries: s.entries.map((e) => map[e.anilist_id] ?? e), map };
    });

    try {
      const db = await getDb();
      for (const { id, rank } of changed) {
        await db.listUpdate(id, { plan_rank: rank, updated_at: now });
      }
      queueSync();
    } catch {
      // Put the old order back rather than leave a half-written queue.
      set((s) => {
        const map = { ...s.map };
        for (const { id } of changed) map[id] = prev[id];
        return { entries: s.entries.map((e) => map[e.anilist_id] ?? e), map };
      });
      toast.error("Couldn't save that order");
    }
  };

  /**
   * Force every watch-order number back into 1..UP_NEXT_CAP.
   *
   * Any backup written before the numbering rework carries the OLD model, where
   * plan_rank was a dense position across EVERY planned entry, so a restore
   * reintroduces numbers in the hundreds. Data arriving from outside has to be
   * made legal on the way in; leaving it to whichever screen notices first is
   * why the numbers appeared to "fix themselves after a few relaunches".
   *
   * The lowest ranks survive, because in the old model those were the entries
   * deliberately placed first. Everything past the cap is released. Returns the
   * number of rows changed so callers can skip the write when there is nothing
   * to do.
   */
  /**
   * The watch order is a DENSE queue: the planned+ranked entries always carry
   * exactly the numbers 1..N in position order, never a gap. The number is a
   * position, so every surface can show the same value (a card's stored rank
   * equals its place in the list) and removing one shifts the rest up.
   *
   * Every mutation funnels through here: pass the ids in their new order and
   * they become 1..N; anything ranked but not listed is released to the
   * unordered library. Beyond the cap is dropped, so the queue can never exceed
   * UP_NEXT_CAP however the data arrived.
   */
  const orderedPlanIds = (): number[] =>
    get()
      .entries.filter((e) => e.status === "plan_to_watch" && e.plan_rank != null)
      .sort((a, b) => (a.plan_rank ?? 0) - (b.plan_rank ?? 0))
      .map((e) => e.anilist_id);

  const commitPlanOrder = async (ids: number[]): Promise<void> => {
    const capped = ids.slice(0, UP_NEXT_CAP);
    const kept = new Set(capped);
    const updates: { id: number; rank: number | null }[] = capped.map((id, i) => ({
      id,
      rank: i + 1,
    }));
    // A rank that survives an operation but isn't in the new order is orphaned
    // (a removed entry, an overflow past the cap); release it.
    for (const e of get().entries) {
      if (
        e.status === "plan_to_watch" &&
        e.plan_rank != null &&
        !kept.has(e.anilist_id)
      ) {
        updates.push({ id: e.anilist_id, rank: null });
      }
    }
    await writePlanRanks(updates);
  };

  /** Force the order dense. Idempotent (writePlanRanks skips unchanged rows),
   *  so it is safe to run on every load and after any edit that could orphan a
   *  rank. Also repairs legacy data: a total order 0..N, duplicates, or numbers
   *  above the cap all collapse to a clean 1..N. */
  const normalizePlanNumbers = async (): Promise<void> => {
    await commitPlanOrder(orderedPlanIds());
  };

  /** Metadata patch that keeps updated_at where the user left it. Root stamps,
   *  dub backfills and the like are bookkeeping, not touches: letting them bump
   *  updated_at reorders "recently watched" (the Hero Binge's pick) and hands
   *  sync's last-write-wins to a write the user never made. No failure toast;
   *  bookkeeping retries on a later pass, the callers own any messaging. */
  const patchEntryQuiet = async (anilistId: number, patch: ListEntryPatch) => {
    const prev = get().map[anilistId];
    if (!prev) return;
    applyEntry({ ...prev, ...patch });
    try {
      const db = await getDb();
      await db.listUpdate(anilistId, { ...patch, updated_at: prev.updated_at });
      queueSync();
    } catch {
      applyEntry(prev); // revert
    }
  };

  /**
   * Background pass that stamps franchise_root_id on entries that were added
   * before this feature shipped. Runs at "low" priority so it never competes
   * with foreground API calls. Already-resolved entries are skipped, and when
   * one chain walk resolves multiple chain members those are also skipped in
   * subsequent iterations.
   */
  const resolveOrphanRoots = async (): Promise<void> => {
    // Cap per launch. Each entry is a network chain walk; grooming a freshly
    // imported list of hundreds in one go would be a long background burst.
    // Low priority already yields to the user, and the leftovers resolve on the
    // next launch, so a bounded slice keeps startup light.
    const ORPHAN_BUDGET = 25;
    const unresolved = get()
      .entries.filter((e) => e.franchise_root_id == null)
      .slice(0, ORPHAN_BUDGET);
    if (unresolved.length === 0) return;

    for (const entry of unresolved) {
      // Another iteration may have already resolved this via toUpdate.
      if (get().map[entry.anilist_id]?.franchise_root_id != null) continue;

      try {
        const inList = new Set(get().entries.map((e) => e.anilist_id));
        const { rootId, toUpdate } = await resolveFranchiseChain(
          entry.anilist_id,
          inList,
          "low",
          entryTitle(entry),
        );

        await patchEntryQuiet(entry.anilist_id, { franchise_root_id: rootId });

        // Stamp the rest of the chain that's already in the list so the loop
        // can skip them — avoids redundant chain walks for sibling seasons.
        for (const id of toUpdate) {
          if (get().map[id]?.franchise_root_id == null) {
            await patchEntryQuiet(id, { franchise_root_id: rootId });
          }
        }
      } catch {
        // Non-fatal. The entry stays ungrouped until the next app launch.
      }
    }
  };

  /**
   * Heal franchises that split into two cards because their halves resolved
   * different roots (S1 added long ago rooted itself; S2 added later resolved
   * its own root before S1 was reachable). A true franchise root has no
   * PREQUEL — so any current root that does have one is living under the
   * wrong id. Re-resolve just those and fold their members into the real
   * root. One batched relations read for all roots (relation snapshots make
   * repeat runs free); the full chain walk only runs for divergent roots.
   */
  const reconcileSplitRoots = async (): Promise<void> => {
    const roots = new Set<number>();
    for (const e of get().entries) {
      roots.add(e.franchise_root_id ?? e.anilist_id);
    }
    if (roots.size === 0) return;

    try {
      const relMap = await anilist.getRelationsBatch([...roots], "low");

      for (const rootId of roots) {
        const rootEntry = get().map[rootId];
        const rootTitle = rootEntry ? entryTitle(rootEntry) : undefined;
        // Three reasons this "root" may not be the real one: it has an earlier
        // season (PREQUEL), it's OTHER-linked to a same-named anime
        // (continuations like Edgerunners 2 carry no SEQUEL edge), or it's a
        // special/OVA whose only tie to the series is a same-named PARENT edge
        // (the stranded Eris-special shape that split Jobless Reincarnation).
        const suspect = (relMap[rootId] ?? []).some(
          (r) =>
            (r.relationType === "PREQUEL" && !isMangaNode(r)) ||
            isFranchiseOther(rootTitle, r) ||
            isFranchiseParent(rootTitle, r),
        );
        if (!suspect) continue;

        try {
          const inList = new Set(get().entries.map((e) => e.anilist_id));
          const { rootId: trueRoot, toUpdate } = await resolveFranchiseChain(
            rootId,
            inList,
            "low",
            rootTitle,
          );
          if (trueRoot === rootId) continue;

          const members = new Set(toUpdate);
          members.add(rootId);
          if (get().map[trueRoot]) members.add(trueRoot);
          for (const e of get().entries) {
            const current = e.franchise_root_id ?? e.anilist_id;
            const belongs = current === rootId || members.has(e.anilist_id);
            if (belongs && e.franchise_root_id !== trueRoot) {
              await patchEntryQuiet(e.anilist_id, { franchise_root_id: trueRoot });
            }
          }
        } catch {
          // Skip this root; the next launch retries.
        }
      }
    } catch {
      // Offline or rate-limited — nothing lost, next launch retries.
    }
  };

  /** Once per app session: backfills + split-root healing are idempotent but
   *  not free, and load() re-runs after airing scans update entries. */
  let groomingStarted = false;

  return {
    loaded: false,
    entries: [],
    map: {},

    load: async () => {
      const db = await getDb();
      const raw = await db.listAll();
      // Rows written before migration 9 (and old web-shim JSON) lack the time
      // accounting fields; normalize so the rest of the app never sees
      // undefined where the type promises a value.
      const entries = raw.map((e) => ({
        ...e,
        episode_duration: e.episode_duration ?? null,
        rewatch_count: e.rewatch_count ?? 0,
        aired_episodes: e.aired_episodes ?? null,
        plan_rank: e.plan_rank ?? null,
      }));
      set({ entries, map: indexBy(entries), loaded: true });
      // Rows can predate the numbering rework (a restored backup, or a device
      // that synced one). Settle them once here so every surface sees legal
      // numbers, rather than leaving it to whichever screen renders first.
      // A no-op once the data is already legal.
      void normalizePlanNumbers();
      if (!groomingStarted) {
        groomingStarted = true;
        void resolveOrphanRoots().then(() => reconcileSplitRoots());
      }
    },

    isInList: (anilistId) => !!get().map[anilistId],
    getEntry: (anilistId) => get().map[anilistId],

    addFromSummary: async (s, status) => {
      // Hard guard behind the UI's disabled options: an unaired show can't be
      // watched/completed, an airing one can't be completed, no matter which
      // surface tried to do it.
      const blocked = statusBlockReason(s.status ?? null, status);
      if (blocked) {
        toast.error(blocked);
        return;
      }
      const now = Date.now();
      const total = s.episodes ?? null;
      const entry: AnimeListEntry = {
        anilist_id: s.id,
        mal_id: s.idMal ?? null,
        title_romaji: s.title.romaji,
        title_english: s.title.english ?? null,
        title_native: s.title.native ?? null,
        cover_url: getCoverUrl(s.coverImage) || null,
        total_episodes: total,
        status,
        episodes_watched: status === "completed" ? (total ?? 0) : 0,
        score: null,
        notes: null,
        has_dub: null,
        franchise_root_id: null,
        airing_status: s.status ?? null,
        // Unranked: a fresh plan entry falls in by date-added until you drag it.
        plan_rank: null,
        episode_duration: s.duration ?? null,
        rewatch_count: 0,
        aired_episodes: airedEpisodes(s),
        added_at: now,
        updated_at: now,
        started_at:
          status === "watching" || status === "rewatching" ? now : null,
        completed_at: status === "completed" ? now : null,
      };
      applyEntry(entry);
      try {
        const db = await getDb();
        await db.listUpsert(entry);
        // Re-adding supersedes any prior deletion of this title.
        await db.tombstoneRemove(s.id);
        queueSync();
        haptic("light");
        // Immediately scan this one new seed for sequels when added as
        // completed/dropped (foreground priority — the user is right here).
        if (status === "completed" || status === "dropped") {
          const { useNotificationStore } = await import("./notificationStore");
          void useNotificationStore.getState().scanSeed(get().entries, s.id);
        }
        // Walk the PREQUEL chain, tag franchise members with a shared root, and
        // (if earlier entries are missing) raise the catch-up prompt. Dropped
        // skips the prompt (it doesn't imply watching what came before).
        // not_interested skips the cascade ENTIRELY: it's a mute on this one
        // entry and must never reach out to tag or regroup the rest of the
        // series. It also never forms a card, so it has nothing to group.
        if (status !== "not_interested") {
          void runFranchiseCascade(s.id, status !== "dropped");
        }
      } catch {
        removeFromState(s.id);
        toast.error("Couldn't add to your list");
      }
    },

    addWatchedPrior: async (rootId, nodes) => {
      if (nodes.length === 0) return;
      const db = await getDb();
      const now = Date.now();
      for (const rel of nodes) {
        // A candidate the user picked up in the meantime shouldn't be clobbered.
        if (get().map[rel.id]) continue;
        const entry = completedRelEntry(rel, rootId, now);
        applyEntry(entry);
        try {
          await db.listUpsert(entry);
          await db.tombstoneRemove(rel.id);
        } catch {
          removeFromState(rel.id);
        }
      }
      queueSync();
      haptic("light");
      toast.success(
        nodes.length === 1
          ? `Marked "${prefTitle(nodes[0].title)}" complete`
          : `Marked ${nodes.length} earlier entries complete`,
      );
    },

    importEntries: async (toImport) => {
      const db = await getDb();
      let count = 0;
      for (const incoming of toImport) {
        const existing = get().map[incoming.anilist_id];
        const entry: AnimeListEntry = existing
          ? {
              ...incoming,
              // Local notes/score win; take max episodes; keep earliest added_at.
              score: existing.score ?? incoming.score,
              notes: existing.notes ?? incoming.notes,
              episodes_watched: Math.max(existing.episodes_watched, incoming.episodes_watched),
              added_at: Math.min(existing.added_at, incoming.added_at),
              updated_at: Date.now(),
            }
          : incoming;
        applyEntry(entry);
        await db.listUpsert(entry);
        await db.tombstoneRemove(incoming.anilist_id);
        count++;
      }
      // Imported ranks come from whatever model wrote that backup, and the
      // merge can also push the combined list past the cap, so settle the
      // numbering before anything renders it.
      await normalizePlanNumbers();
      queueSync();
      return count;
    },

    setDubStatus: async (anilistId, hasDub) => {
      const entry = get().map[anilistId];
      if (!entry || entry.has_dub === hasDub) return;
      // Backfilled on a detail visit; looking at a show is not watching it.
      await patchEntryQuiet(anilistId, { has_dub: hasDub });
    },

    updateStatus: async (anilistId, status) => {
      const prev = get().map[anilistId];
      if (!prev) return;
      // Not Interested is a toggle: picking it again unselects the mute and
      // returns the title to untracked (the "bring it back" path). remove()
      // shows an Undo toast, so a mis-tap is one tap to reverse. Picking any
      // OTHER status while not-interested is a deliberate un-mute into that
      // status and is allowed to fall straight through — the user asked to be
      // able to change it to something else.
      if (status === "not_interested" && prev.status === "not_interested") {
        get().remove(anilistId);
        return;
      }
      // AniList's RELEASING can lag a finale; someone who watched the last
      // known episode has genuinely finished, so let that complete stand.
      const finishedByCount =
        prev.total_episodes != null &&
        prev.episodes_watched >= prev.total_episodes;
      const blocked = statusBlockReason(prev.airing_status, status);
      if (blocked && !(status === "completed" && finishedByCount)) {
        toast.error(blocked);
        return;
      }
      const patch: ListEntryPatch = { status };
      // A number means "this is next in my plan queue", so it cannot outlive
      // the plan status. Without this the rank leaks: start watching a
      // numbered title and it keeps #3 forever, still occupying a slot and
      // reappearing if it ever returns to planned.
      if (status !== "plan_to_watch" && prev.plan_rank != null) {
        patch.plan_rank = null;
      }
      if (status === "completed") {
        patch.completed_at = prev.completed_at ?? Date.now();
        if (prev.total_episodes != null) {
          patch.episodes_watched = prev.total_episodes;
        }
      }
      // Completed -> rewatching: the finished watch becomes a counted prior
      // watch (so its hours survive in Stats) and episode progress restarts.
      if (status === "rewatching" && prev.status === "completed") {
        patch.rewatch_count = (prev.rewatch_count ?? 0) + 1;
        patch.episodes_watched = 0;
      }
      if (
        (status === "watching" || status === "rewatching") &&
        prev.started_at == null
      ) {
        patch.started_at = Date.now();
      }
      await patchEntry(anilistId, patch);
      // Leaving the plan status vacates a slot; close the gap so the queue
      // stays a dense 1..N.
      if (patch.plan_rank === null) void commitPlanOrder(orderedPlanIds());
      haptic(status === "completed" ? "success" : "light");
      // Scan just this seed immediately when marked completed/dropped.
      if (status === "completed" || status === "dropped") {
        const { useNotificationStore } = await import("./notificationStore");
        void useNotificationStore.getState().scanSeed(get().entries, anilistId);
      }
      // An entry that never got a franchise root (added as dropped or
      // not-interested before grouping existed, or a failed cascade) picks it
      // up the moment it rejoins the living statuses — so changing your mind
      // from "not interested" to "plan to watch" puts it back under its
      // franchise card instead of leaving it standalone forever.
      if (prev.franchise_root_id == null && status !== "not_interested") {
        void runFranchiseCascade(anilistId, status !== "dropped");
      }
    },

    setEpisodes: async (anilistId, episodes) => {
      const prev = get().map[anilistId];
      if (!prev) return;
      const max = prev.total_episodes ?? Number.MAX_SAFE_INTEGER;
      const clamped = Math.max(0, Math.min(episodes, max));
      await patchEntry(anilistId, { episodes_watched: clamped });
      if (clamped > prev.episodes_watched) haptic("light");

      // Reaching the final episode from below — while still marked as actively
      // watching/rewatching — offers to close the entry out. Centralized here
      // so it fires no matter which surface did the increment (detail counter,
      // card quick-add, offline +1), which is what other trackers do. Only when
      // a real total is known and the run wasn't already finished.
      const reachedFinale =
        prev.total_episodes != null &&
        clamped >= prev.total_episodes &&
        prev.episodes_watched < prev.total_episodes &&
        (prev.status === "watching" || prev.status === "rewatching");
      if (reachedFinale) {
        const rewatch = prev.status === "rewatching";
        toast.action({
          message: rewatch ? "Rewatch complete" : "Reached the final episode",
          actionLabel: rewatch ? "Mark finished" : "Mark complete",
          duration: 5000,
          onAction: () => void get().updateStatus(anilistId, "completed"),
        });
      }
    },

    incrementEpisodes: async (anilistId, delta) => {
      const prev = get().map[anilistId];
      if (!prev) return;
      // Episode tracking only makes sense while actively watching.
      if (prev.status !== "watching" && prev.status !== "rewatching") return;
      const before = prev.episodes_watched;
      await get().setEpisodes(anilistId, before + delta);
      const after = get().map[anilistId]?.episodes_watched ?? before;
      // A quick +1 joins the shared undo batch, so a run of taps shares one
      // snackbar. The finale moment opts out: the mark-complete toast owns that
      // moment, and two stacked toasts fight for it.
      const reachedFinale = prev.total_episodes != null && after >= prev.total_episodes;
      if (delta > 0 && after > before && !reachedFinale) {
        recordEpisodeLog(anilistId, before, after);
      }
    },

    setScore: async (anilistId, score) => {
      await patchEntry(anilistId, { score });
    },

    /** Rewrite the whole order as 1..N. Numbers are 1-based because the user
     *  sees and assigns them directly; a 0 would be a slot nobody can name. */
    reorderPlan: async (anilistIdsInOrder) => {
      // Same dense committer every order edit uses, so drag, move-to-position
      // and append can never drift apart on how the numbers are written.
      await commitPlanOrder(anilistIdsInOrder);
    },

    /**
     * Stamp a number onto an entry, or clear it with `null`.
     *
     * The whole point of numbering instead of dragging: assigning "this is #3"
     * is one action no matter how long the list is, where MOVING something to
     * third place means traversing everything in between. At 1200 planned
     * titles that is the difference between possible and not.
     *
     * Collision swaps. If something already holds the number, the two trade
     * places (or the old holder is released when this entry had none). Nothing
     * cascades, exactly two entries change, and it is reversible by repeating
     * the action.
     *
     * Gaps are allowed and ranks are NEVER renumbered automatically. The number
     * is a label you chose, not an index into an array, so removing #3 leaves
     * 1, 2, 4 rather than silently rewriting the numbers you assigned.
     */
    /**
     * Append to the end of the queue, which in a dense order is the next
     * number. Synchronous return so a caller can report "full" in the same
     * gesture; the write itself is fire-and-forget like every optimistic patch.
     */
    addToPlanOrder: (anilistId) => {
      const entry = get().map[anilistId];
      if (!entry || entry.status !== "plan_to_watch" || entry.plan_rank != null) {
        return false;
      }
      const ids = orderedPlanIds();
      if (ids.length >= UP_NEXT_CAP) return false;
      void commitPlanOrder([...ids, anilistId]);
      return true;
    },

    setPlanNumber: async (anilistId, rank) => {
      const entry = get().map[anilistId];
      if (!entry || entry.status !== "plan_to_watch") return;

      // null clears the number and closes the gap it leaves behind.
      if (rank == null) {
        if (entry.plan_rank == null) return;
        await commitPlanOrder(orderedPlanIds().filter((id) => id !== anilistId));
        return;
      }

      // A number is a POSITION: move (or insert) this card to that slot and let
      // everything renumber densely around it. Replaces the old swap, so "make
      // this #3" now means "put it third", not "trade places with whoever is
      // third" — which is what a dense queue needs.
      const without = orderedPlanIds().filter((id) => id !== anilistId);
      if (entry.plan_rank == null && without.length >= UP_NEXT_CAP) return; // full
      const target = Math.max(0, Math.min(rank - 1, without.length));
      const next = [...without.slice(0, target), anilistId, ...without.slice(target)];
      await commitPlanOrder(next);
    },

    patch: async (anilistId, p) => {
      await patchEntry(anilistId, p);
    },

    regroupFranchise: async (anilistId) => {
      const entry = get().map[anilistId];
      if (!entry) return;
      try {
        const inList = new Set(get().entries.map((e) => e.anilist_id));
        // Force a fresh walk (ignores any cached root) and stamp the resolved
        // root onto this entry plus every tracked franchise member.
        const { rootId, toUpdate } = await resolveFranchiseChain(
          anilistId,
          inList,
          "high",
          entryTitle(entry),
        );
        await patchEntryQuiet(anilistId, { franchise_root_id: rootId });
        for (const id of toUpdate) {
          await patchEntryQuiet(id, { franchise_root_id: rootId });
        }
        const grouped = 1 + toUpdate.length;
        toast.success(
          grouped > 1 ? `Grouped ${grouped} entries` : "Nothing else to group here",
        );
      } catch {
        toast.error("Couldn't regroup right now");
      }
    },

    remove: (anilistId) => {
      const entry = get().map[anilistId];
      if (!entry) return;
      removeFromState(anilistId); // optimistic
      haptic("medium");
      let undone = false;
      toast.action({
        message: `Removed ${prefTitle({
          romaji: entry.title_romaji,
          english: entry.title_english,
          native: entry.title_native,
        })}`,
        actionLabel: "Undo",
        duration: 4000,
        onAction: () => {
          undone = true;
          applyEntry(entry);
        },
      });
      // Commit the DB delete only after the undo window closes.
      setTimeout(async () => {
        if (undone) return;
        try {
          const db = await getDb();
          await db.listRemove(anilistId);
          // Record a tombstone so the deletion propagates through sync instead
          // of being resurrected by the next merge.
          await db.tombstoneUpsert({ anilist_id: anilistId, deleted_at: Date.now() });
          queueSync();
          // Alerts this entry seeded (and its scan schedule) go with it —
          // otherwise they'd keep pointing at a title that's no longer tracked.
          const { useNotificationStore } = await import("./notificationStore");
          void useNotificationStore.getState().entriesRemoved([anilistId]);
          // Removing a numbered plan entry vacates its slot. Compacting only
          // AFTER the commit means Undo restores the exact gap the entry left,
          // so the order is dense again without any renumber-then-collide race.
          if (entry.status === "plan_to_watch" && entry.plan_rank != null) {
            void commitPlanOrder(orderedPlanIds());
          }
        } catch {
          applyEntry(entry);
          toast.error("Couldn't remove that entry");
        }
      }, 4000);
    },

    removeMany: (anilistIds) => {
      const removed = anilistIds
        .map((id) => get().map[id])
        .filter((e): e is AnimeListEntry => !!e);
      if (removed.length === 0) return;
      for (const e of removed) removeFromState(e.anilist_id);

      let undone = false;
      toast.action({
        message:
          removed.length === 1
            ? `Removed ${prefTitle({
                romaji: removed[0].title_romaji,
                english: removed[0].title_english,
                native: removed[0].title_native,
              })}`
            : `Removed ${removed.length} seasons`,
        actionLabel: "Undo",
        duration: 4000,
        onAction: () => {
          undone = true;
          for (const e of removed) applyEntry(e);
        },
      });
      setTimeout(async () => {
        if (undone) return;
        try {
          const db = await getDb();
          const now = Date.now();
          for (const e of removed) {
            await db.listRemove(e.anilist_id);
            await db.tombstoneUpsert({ anilist_id: e.anilist_id, deleted_at: now });
          }
          queueSync();
          const { useNotificationStore } = await import("./notificationStore");
          void useNotificationStore
            .getState()
            .entriesRemoved(removed.map((e) => e.anilist_id));
        } catch {
          for (const e of removed) applyEntry(e);
          toast.error("Couldn't remove those entries");
        }
      }, 4000);
    },

    clearAll: async ({ propagateToDrive = false } = {}) => {
      const previous = get().entries;
      if (previous.length === 0) return;
      // Optimistic wipe: the UI empties immediately.
      set({ entries: [], map: {} });
      try {
        const db = await getDb();
        await db.listReplaceAll([]);
        // Nothing tracked means nothing to alert on or scan — wipe both, and
        // let the notification store see the now-empty tables.
        await db.notificationsClear();
        await db.scheduleClear();
        const { useNotificationStore } = await import("./notificationStore");
        if (useNotificationStore.getState().loaded) {
          void useNotificationStore.getState().load();
        }
        if (propagateToDrive) {
          // Tombstone every cleared id so the empty state wins the next merge
          // on other devices instead of being resurrected.
          const now = Date.now();
          const tombstones = previous.map((e) => ({
            anilist_id: e.anilist_id,
            deleted_at: now,
          }));
          await db.tombstonesReplaceAll(tombstones);
          await syncManager.pushNow();
        } else {
          // Local-only clear: drop tombstones too so a future sign-in pulls
          // cleanly from Drive without local deletions overriding it.
          await db.tombstonesReplaceAll([]);
        }
      } catch {
        set({ entries: previous, map: indexBy(previous) });
        toast.error("Couldn't clear your list");
      }
    },

    restore: async (entry) => {
      applyEntry(entry);
      try {
        const db = await getDb();
        await db.listUpsert(entry);
        await db.tombstoneRemove(entry.anilist_id);
        queueSync();
      } catch {
        removeFromState(entry.anilist_id);
      }
    },
  };
});
