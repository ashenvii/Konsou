import { anilist } from "@/lib/api/anilist/client";
import type { RelationNode, RelationType } from "@/types/anime";
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
  /** Chain members not in `inList` -- auto-added as completed. */
  toAdd: RelationNode[];
  /** anilist_ids of all franchise members already in `inList`, excluding startId. */
  toUpdate: number[];
}

/**
 * BFS the main story chain (SEQUEL + PREQUEL) from startId.
 * Returns a map of id to relations for every node discovered.
 * Placeholder entries (empty relations) may exist for nodes that were discovered
 * but not yet fetched when MAX_CHAIN_NODES was reached.
 */
async function bfsMainChain(
  startId: number,
  priority: Priority,
): Promise<Map<number, RelationNode[]>> {
  const visited = new Map<number, RelationNode[]>();
  visited.set(startId, []);
  const queue: number[] = [startId];

  while (queue.length > 0 && visited.size < MAX_CHAIN_NODES) {
    const batch = queue.splice(0, 12);
    const relMap = await anilist.getRelationsBatch(batch, priority);

    for (const id of batch) {
      const rels = relMap[id] ?? [];
      visited.set(id, rels);

      for (const rel of rels) {
        if (MAIN_CHAIN.has(rel.relationType) && !visited.has(rel.id)) {
          visited.set(rel.id, []); // placeholder to mark as discovered
          queue.push(rel.id);
        }
      }
    }
  }

  return visited;
}

/**
 * Walk the PREQUEL chain from startId to the franchise root.
 * Only follows edges that exist in chainMap (discovered during BFS).
 */
function findRootId(
  startId: number,
  chainMap: Map<number, RelationNode[]>,
): number {
  const seen = new Set<number>([startId]);
  let current = startId;

  for (let i = 0; i < MAX_CHAIN_NODES; i++) {
    const rels = chainMap.get(current) ?? [];
    const prequel = rels.find(
      (r) => r.relationType === "PREQUEL" && chainMap.has(r.id),
    );
    if (!prequel || seen.has(prequel.id)) break;
    seen.add(prequel.id);
    current = prequel.id;
  }

  return current;
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
      if (SIDE_ENTRY.has(rel.relationType)) {
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
export async function resolveFranchiseChain(
  startId: number,
  inList: Set<number>,
  priority: Priority = "high",
): Promise<FranchiseChainResult> {
  const chainMap = await bfsMainChain(startId, priority);
  const rootId = findRootId(startId, chainMap);
  const chain = buildPrequelChain(startId, chainMap);
  const allIds = buildFranchiseIds(chainMap);

  return {
    rootId,
    chain,
    toAdd: chain.filter((r) => !inList.has(r.id)),
    toUpdate: [...allIds].filter((id) => id !== startId && inList.has(id)),
  };
}
