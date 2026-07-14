import { anilist } from "@/lib/api/anilist/client";
import { isMangaNode } from "@/lib/format";
import { isFranchiseOther } from "./relatedness";
import { isPromoNode } from "./storySplit";
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
 * getRelationsBatch runs in staleOk mode here: any stored snapshot serves
 * immediately (refreshing in the background once past the 6h TTL), and ids are
 * batched <=12 per request, so a franchise seen before costs zero foreground
 * round-trips no matter how long ago.
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
// MUSIC and promo shorts (PVs/CMs/teasers) are advertising, not watchable
// members; excluding them HERE keeps every surface (Related tab, quick menu,
// ledger) agreeing they don't exist.
function isChainNode(r: RelationNode, fromTitle?: AnimeTitle): boolean {
  if (isMangaNode(r)) return false;
  if (r.format === "MUSIC" || isPromoNode(r)) return false;
  return CHAIN_RELATIONS.includes(r.relationType) || isFranchiseOther(fromTitle, r);
}

export interface RelationChainResult {
  nodes: RelationNode[];
  /** Every chain-relevant relation observed during the walk, INCLUDING edges
   *  between already-known nodes — the watch-order sort needs the full mesh,
   *  not just the spanning tree the BFS happened to discover first. */
  edges: RelationEdge[];
  /** The seed as OTHER members see it (a later season's PREQUEL edge back to
   *  it carries full node data). Callers that only know the seed's id — the
   *  quick menu — read its format and air date from here; without it the
   *  anchor is dateless and extras mis-place around "#1". */
  seedNode?: RelationNode | null;
}

/**
 * THE franchise membership walk. Every surface that lists a franchise (the
 * Related tab, the quick menu) derives from this one function, so they can
 * never show different franchises again. Root RESOLUTION for card grouping
 * (cascade.ts) is deliberately more conservative and stays separate — see
 * docs/FRANCHISE_MODEL.md for the contract.
 *
 * The seed's own relations may be passed when already known (the detail page
 * has them in its payload); otherwise they're fetched like any other node's.
 */
export async function walkFranchise(seed: {
  id: number;
  title: AnimeTitle;
  relations?: RelationNode[] | null;
}): Promise<RelationChainResult> {
  const nodes = new Map<number, RelationNode>();
  const seen = new Set<number>([seed.id]);
  const titleOf = new Map<number, AnimeTitle>([[seed.id, seed.title]]);
  const edges: RelationEdge[] = [];
  let seedNode: RelationNode | null = null;
  let frontier: number[] = [];

  let seedRelations = seed.relations;
  if (!seedRelations) {
    // staleOk: this walk is presentation (Related tab, quick menu). A stored
    // snapshot of any age renders instantly and revalidates in the background,
    // so reopening a big franchise costs zero foreground requests.
    const relMap = await anilist.getRelationsBatch([seed.id], "high", {
      staleOk: true,
    });
    seedRelations = relMap[seed.id] ?? [];
  }

  for (const r of seedRelations) {
    if (!isChainNode(r, seed.title)) continue;
    edges.push({ from: seed.id, to: r.id, type: r.relationType });
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
    const relMap = await anilist.getRelationsBatch(frontier, "high", {
      staleOk: true,
    });
    const next: number[] = [];
    for (const id of frontier) {
      for (const r of relMap[id] ?? []) {
        if (!isChainNode(r, titleOf.get(id))) continue;
        edges.push({ from: id, to: r.id, type: r.relationType });
        if (r.id === seed.id && !seedNode) seedNode = r;
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

  return { nodes: [...nodes.values()], edges, seedNode };
}

/** Detail-page entry point: seeds the walk with the relations already in the
 *  detail payload, saving the first round-trip. */
export async function walkRelationChain(
  media: AnimeMedia,
): Promise<RelationChainResult> {
  return walkFranchise({
    id: media.id,
    title: media.title,
    relations: media.relations,
  });
}
