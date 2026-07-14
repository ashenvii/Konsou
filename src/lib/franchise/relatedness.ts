import { isMangaNode, normalizeForSearch } from "@/lib/format";
import { diceSimilarity } from "@/lib/search/fuzzy";
import type { AnimeTitle, RelationNode } from "@/types/anime";

/**
 * AniList's OTHER relation is a grab-bag: commercials, crossovers, music
 * videos, and — the case that matters — direct continuations that just never
 * got a proper SEQUEL edge. Cyberpunk: Edgerunners → Cyberpunk: Edgerunners 2
 * is linked ONLY this way, so a walker that ignores OTHER is blind to the
 * whole franchise: no Related tab, no grouping, no radar alert.
 *
 * The gate: follow an OTHER edge only when the two names clearly claim the
 * same franchise. Names are the most stable cross-entry signal AniList gives
 * us ("Cyberpunk: Edgerunners" / "Cyberpunk: Edgerunners 2",
 * "Mushoku Tensei" / "Mushoku Tensei II"), and the bigram similarity already
 * powering offline search tolerates numbering, subtitles, and romanization
 * differences. Crossovers and ads fail it: their names don't contain the
 * source show's full name.
 */

/** Similarity floor for "these names claim the same franchise". */
const FRANCHISE_SIMILARITY = 0.6;
/** A shared prefix shorter than this proves nothing ("Fate/" matches half of AniList). */
const MIN_PREFIX = 8;

function variants(t: AnimeTitle): string[] {
  const out: string[] = [];
  for (const v of [t.romaji, t.english, t.native]) {
    if (typeof v === "string" && v.trim()) out.push(normalizeForSearch(v));
  }
  return out;
}

/** True when any name variant of one title contains or closely matches one of the other's. */
export function titlesShareFranchise(a: AnimeTitle, b: AnimeTitle): boolean {
  const va = variants(a);
  const vb = variants(b);
  for (const x of va) {
    for (const y of vb) {
      const shorter = x.length <= y.length ? x : y;
      const longer = x.length <= y.length ? y : x;
      if (shorter.length >= MIN_PREFIX && longer.startsWith(shorter)) return true;
      if (diceSimilarity(x, y) >= FRANCHISE_SIMILARITY) return true;
    }
  }
  return false;
}

/**
 * Should this OTHER-linked relation be treated as a franchise member?
 * `fromTitle` is the title of the node whose relations are being walked;
 * without it there is nothing to compare against, so the edge is skipped
 * (conservative: a wrong grouping costs more trust than a missed one).
 */
export function isFranchiseOther(
  fromTitle: AnimeTitle | undefined,
  rel: RelationNode,
): boolean {
  if (rel.relationType !== "OTHER") return false;
  if (isMangaNode(rel) || rel.format === "MUSIC") return false;
  if (!fromTitle) return false;
  return titlesShareFranchise(fromTitle, rel.title);
}

/**
 * Should this PARENT edge be climbed back to the main series?
 *
 * A special/OVA's only link to its franchise is often a single PARENT edge
 * (the Mushoku Tensei Eris special is typed exactly this way). A walk that
 * starts AT such a node and never follows PARENT can't reach the backbone,
 * resolves itself as a one-member root, and splits the franchise into two
 * cards. The same name-gate as OTHER keeps this from swallowing branded
 * spin-offs (Prisma Illya's PARENT edge to Fate/stay night fails the name
 * test, so it stays its own franchise — which is what viewers expect).
 */
export function isFranchiseParent(
  fromTitle: AnimeTitle | undefined,
  rel: RelationNode,
): boolean {
  if (rel.relationType !== "PARENT") return false;
  if (isMangaNode(rel) || rel.format === "MUSIC") return false;
  if (!fromTitle) return false;
  return titlesShareFranchise(fromTitle, rel.title);
}
