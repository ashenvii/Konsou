import { anilist } from "@/lib/api/anilist/client";
import { isMangaNode } from "@/lib/format";
import { isFranchiseOther } from "./relatedness";
import type { AnimeTitle, RelationNode, RelationType } from "@/types/anime";
import type { Priority } from "@/lib/api/rateLimiter";

const MAX_CHAIN_NODES = 30;

// Relation types that form the main story backbone (walked recursively).
const MAIN_CHAIN: ReadonlySet<RelationType> = new Set(["PREQUEL", "SEQUEL"]);

// Relation types that belong to the franchise but are not recursively expanded --
// direct neighbors of main-chain nodes only, to keep the scope bounded.
const SIDE_ENTRY: ReadonlySet<RelationType> = new Set([
  "SIDE_STORY",
  "SPIN_OFF",
  "PARENT",
  "SUMMARY",
]);

export interface FranchiseChainResult {
  rootId: number;
  /** PREQUEL chain from root to just before startId, oldest first. */
  chain: RelationNode[];
  /** Catch-up candidates not in `inList`: the prequel chain plus finished
   *  side entries (OVAs, movies, spin-offs) hanging off the already-watched
   *  part of it — a viewer on S3 may well have seen the S2 OVA too. */
  toAdd: RelationNode[];
  /** anilist_ids of all franchise members already in `inList`, excluding startId. */
  toUpdate: number[];
}

interface ChainWalk {
  /** id → relations for every node discovered. Placeholder entries (empty
   *  relations) may exist for nodes discovered after MAX_CHAIN_NODES hit. */
  chainMap: Map<number, RelationNode[]>;
  /** id → the RelationNode some other member pointed at it with — carries the
   *  title and start date of everything except (possibly) the start node. */
  nodeOf: Map<number, RelationNode>;
}

/**
 * BFS the main story chain (SEQUEL + PREQUEL) from startId, plus OTHER-linked
 * anime whose names claim the same franchise — some continuations
 * (Edgerunners 2) are connected ONLY by an OTHER edge, and skipping them
 * leaves the whole feature blind to the franchise.
 */
async function bfsMainChain(
  startId: number,
  priority: Priority,
  seedTitle?: AnimeTitle,
): Promise<ChainWalk> {
  const visited = new Map<number, RelationNode[]>();
  const nodeOf = new Map<number, RelationNode>();
  const titleOf = new Map<number, AnimeTitle>();
  if (seedTitle) titleOf.set(startId, seedTitle);
  visited.set(startId, []);
  const queue: number[] = [startId];

  while (queue.length > 0 && visited.size < MAX_CHAIN_NODES) {
    const batch = queue.splice(0, 12);
    const relMap = await anilist.getRelationsBatch(batch, priority);

    for (const id of batch) {
      const rels = relMap[id] ?? [];
      visited.set(id, rels);

      for (const rel of rels) {
        if (isMangaNode(rel)) continue; // manga source, not a watchable season
        if (!nodeOf.has(rel.id)) nodeOf.set(rel.id, rel);
        if (!titleOf.has(rel.id)) titleOf.set(rel.id, rel.title);
        const follow =
          MAIN_CHAIN.has(rel.relationType) ||
          isFranchiseOther(titleOf.get(id), rel);
        if (follow && !visited.has(rel.id)) {
          visited.set(rel.id, []); // placeholder to mark as discovered
          queue.push(rel.id);
        }
      }
    }
  }

  return { chainMap: visited, nodeOf };
}

/**
 * The franchise root. Chains walked purely along SEQUEL/PREQUEL have exactly
 * one head (a member with no anime prequel) and it wins, same as the old
 * prequel-walk. OTHER-linked members can create several heads with no
 * direction between them — there the earliest start date decides, with the
 * smaller id as the tiebreak, so every member of the component resolves the
 * SAME root no matter which side the walk started from. (Divergent roots are
 * exactly what splits one franchise into two cards.)
 */
function findRootId(
  startId: number,
  { chainMap, nodeOf }: ChainWalk,
): number {
  const heads = [...chainMap.keys()].filter((id) => {
    const rels = chainMap.get(id) ?? [];
    return !rels.some(
      (r) =>
        r.relationType === "PREQUEL" && !isMangaNode(r) && chainMap.has(r.id),
    );
  });
  if (heads.length === 0) return startId; // pure cycle — arbitrary but stable per walk
  if (heads.length === 1) return heads[0];

  const key = (id: number): number => {
    const n = nodeOf.get(id);
    if (!n) return Number.MAX_SAFE_INTEGER;
    const d = n.startDate;
    if (d?.year) return Date.UTC(d.year, (d.month ?? 1) - 1, d.day ?? 1);
    if (n.seasonYear) return Date.UTC(n.seasonYear, 0, 1);
    return Number.MAX_SAFE_INTEGER;
  };
  heads.sort((a, b) => key(a) - key(b) || a - b);
  return heads[0];
}

/**
 * Walk backward from startId collecting PREQUEL RelationNodes, then reverse
 * to return them oldest-first (root at index 0).
 */
function buildPrequelChain(
  startId: number,
  chainMap: Map<number, RelationNode[]>,
): RelationNode[] {
  const chain: RelationNode[] = [];
  const seen = new Set<number>([startId]);
  let current = startId;

  for (let i = 0; i < MAX_CHAIN_NODES; i++) {
    const rels = chainMap.get(current) ?? [];
    const prequel = rels.find(
      (r) => r.relationType === "PREQUEL" && chainMap.has(r.id),
    );
    if (!prequel || seen.has(prequel.id)) break;
    seen.add(prequel.id);
    chain.push(prequel);
    current = prequel.id;
  }

  return chain.reverse();
}

/**
 * Collect all franchise member ids: main-chain nodes plus any peripheral
 * entries (side stories, spin-offs, etc.) that appear as direct relations
 * of main-chain nodes. Peripheral entries are not recursively expanded.
 */
function buildFranchiseIds(chainMap: Map<number, RelationNode[]>): Set<number> {
  const ids = new Set(chainMap.keys());

  for (const rels of chainMap.values()) {
    for (const rel of rels) {
      if (SIDE_ENTRY.has(rel.relationType) && !isMangaNode(rel)) {
        ids.add(rel.id);
      }
    }
  }

  return ids;
}

/**
 * Walk the full franchise graph from startId, returning the franchise root
 * and which members need to be added or tagged.
 *
 * Key improvement over the original PREQUEL-only walk:
 * - Walks SEQUEL as well so later seasons already in the list get tagged
 *   when an earlier season is processed (fixes "S1 and S2 show as separate
 *   cards" when S1 was added first or resolved first in orphan backfill).
 * - Collects side entries (SIDE_STORY, SPIN_OFF, PARENT, SUMMARY) from
 *   main-chain nodes so movies and OVAs that are already tracked get grouped
 *   without needing a detail-page visit.
 */
function startMs(r: RelationNode): number {
  const d = r.startDate;
  if (d?.year) return Date.UTC(d.year, (d.month ?? 1) - 1, d.day ?? 1);
  if (r.seasonYear) return Date.UTC(r.seasonYear, 0, 1);
  return Number.MAX_SAFE_INTEGER; // date unknown — sort to the end
}

/**
 * Finished side entries (OVAs, movies, spin-offs) attached to the part of the
 * chain the user has presumably watched: the prequel chain plus the entry they
 * just added. Side stories of later, unwatched seasons don't qualify — nobody
 * should be asked whether they've seen the S5 OVA when they just added S3.
 */
function priorSideEntries(
  startId: number,
  chain: RelationNode[],
  chainMap: Map<number, RelationNode[]>,
): RelationNode[] {
  const priorIds = new Set<number>([startId, ...chain.map((r) => r.id)]);
  const out = new Map<number, RelationNode>();

  for (const id of priorIds) {
    for (const rel of chainMap.get(id) ?? []) {
      if (!SIDE_ENTRY.has(rel.relationType)) continue;
      if (isMangaNode(rel)) continue;
      if (chainMap.has(rel.id) || priorIds.has(rel.id)) continue;
      // Only things that finished airing can already have been watched.
      if (rel.status !== "FINISHED") continue;
      if (!out.has(rel.id)) out.set(rel.id, rel);
    }
  }

  return [...out.values()].sort((a, b) => startMs(a) - startMs(b));
}

export async function resolveFranchiseChain(
  startId: number,
  inList: Set<number>,
  priority: Priority = "high",
  seedTitle?: AnimeTitle,
): Promise<FranchiseChainResult> {
  const walk = await bfsMainChain(startId, priority, seedTitle);
  const { chainMap } = walk;
  const rootId = findRootId(startId, walk);
  const chain = buildPrequelChain(startId, chainMap);
  const allIds = buildFranchiseIds(chainMap);
  const sides = priorSideEntries(startId, chain, chainMap);

  return {
    rootId,
    chain,
    toAdd: [...chain, ...sides].filter((r) => !inList.has(r.id)),
    toUpdate: [...allIds].filter((id) => id !== startId && inList.has(id)),
  };
}
