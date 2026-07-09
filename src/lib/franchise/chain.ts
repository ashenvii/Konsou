import { anilist } from "@/lib/api/anilist/client";
import { isMangaNode } from "@/lib/format";
import { isFranchiseOther } from "./relatedness";
import type { RelationEdge } from "./watchOrder";
import type { AnimeMedia, AnimeTitle, RelationNode, RelationType } from "@/types/anime";

/**
 * Expands a title's one-hop AniList relations into the whole franchise chain.
 *
 * AniList only returns DIRECT relations, so from season 1 the detail payload
 * knows about season 2 and nothing beyond it. The Related tab wants the full
 * watch order, so we breadth-first walk relations-of-relations through the
 * season-forming edge types until nothing new turns up.
 *
 * getRelationsBatch reads the 6h snapshot cache first and batches <=12 ids
 * per request, so a typical franchise costs zero or one round-trip.
 */

const CHAIN_RELATIONS: RelationType[] = [
  "PREQUEL",
  "SEQUEL",
  "SIDE_STORY",
  "SPIN_OFF",
  "PARENT",
  "ALTERNATIVE",
];

// Mega-franchises (Gundam, Fate) connect half of AniList through ALTERNATIVE
// edges; the caps keep the walk to what a human would call "this series".
const MAX_DEPTH = 6;
const MAX_NODES = 40;

// OTHER edges join the walk only when the names on both ends claim the same
// franchise (see relatedness.ts) — that's how Edgerunners finds Edgerunners 2.
function isChainNode(r: RelationNode, fromTitle?: AnimeTitle): boolean {
  if (isMangaNode(r)) return false;
  return CHAIN_RELATIONS.includes(r.relationType) || isFranchiseOther(fromTitle, r);
}

export interface RelationChainResult {
  nodes: RelationNode[];
  /** Every chain-relevant relation observed during the walk, INCLUDING edges
   *  between already-known nodes — the watch-order sort needs the full mesh,
   *  not just the spanning tree the BFS happened to discover first. */
  edges: RelationEdge[];
}

export async function walkRelationChain(
  media: AnimeMedia,
): Promise<RelationChainResult> {
  const nodes = new Map<number, RelationNode>();
  const seen = new Set<number>([media.id]);
  const titleOf = new Map<number, AnimeTitle>([[media.id, media.title]]);
  const edges: RelationEdge[] = [];
  let frontier: number[] = [];

  for (const r of media.relations ?? []) {
    if (!isChainNode(r, media.title)) continue;
    edges.push({ from: media.id, to: r.id, type: r.relationType });
    if (seen.has(r.id)) continue;
    seen.add(r.id);
    nodes.set(r.id, r);
    titleOf.set(r.id, r.title);
    frontier.push(r.id);
  }

  for (
    let depth = 0;
    depth < MAX_DEPTH && frontier.length > 0 && nodes.size < MAX_NODES;
    depth++
  ) {
    const relMap = await anilist.getRelationsBatch(frontier, "high");
    const next: number[] = [];
    for (const id of frontier) {
      for (const r of relMap[id] ?? []) {
        if (!isChainNode(r, titleOf.get(id))) continue;
        edges.push({ from: id, to: r.id, type: r.relationType });
        if (seen.has(r.id)) continue;
        seen.add(r.id);
        nodes.set(r.id, r);
        titleOf.set(r.id, r.title);
        next.push(r.id);
        if (nodes.size >= MAX_NODES) break;
      }
      if (nodes.size >= MAX_NODES) break;
    }
    frontier = next;
  }

  return { nodes: [...nodes.values()], edges };
}
