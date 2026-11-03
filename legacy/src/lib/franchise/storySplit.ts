import type { RelationEdge } from "./watchOrder";
import type { AnimeTitle, FuzzyDate, MediaFormat } from "@/types/anime";

/**
 * Main story vs extras.
 *
 * Viewers think of a franchise as "the story" (the seasons, plus movies that
 * genuinely continue it) with extras hanging off the side (OVAs, specials,
 * side stories, spin-offs, recaps). The old flat #1..#N list mixed both, so
 * a 13-entry DanMachi wall never told you which five entries ARE DanMachi.
 * The community's own advice for extras (r/Animesuggest and every filler
 * guide) is: judge them per title, and watch the ones you want after the
 * season they accompany. That needs the app to say what an extra IS and
 * WHERE it falls, not to hide it and not to number it like a season.
 *
 * The split is structural, not format-based: the main story is the connected
 * component of SEQUEL/PREQUEL edges, so a movie that continues the plot
 * (linked SEQUEL) is main story, while a movie retelling or side event
 * (SIDE_STORY/ALTERNATIVE/SUMMARY) is an extra regardless of being a film.
 */

export interface StoryMember {
  id: number;
  format?: MediaFormat | null;
  startDate?: FuzzyDate | null;
}

function dateMs(d?: FuzzyDate | null): number | null {
  if (!d?.year) return null;
  return Date.UTC(d.year, (d.month ?? 6) - 1, d.day ?? 15);
}

/**
 * The ids forming the franchise's main story: the SEQUEL/PREQUEL-connected
 * component that best claims to be "the show". Deterministic and
 * seed-independent (never derived from which member's page you happen to be
 * on), so the Related tab and the quick menu always agree:
 *   1. components containing a TV/TV_SHORT member outrank ones that don't
 *      (a one-season show beats its own earlier-airing special);
 *   2. larger components outrank smaller;
 *   3. earliest first-air date breaks remaining ties.
 * A franchise with no SEQUEL/PREQUEL edges at all (single season + extras)
 * resolves to that same rule over size-1 components.
 */
export function mainStoryIds(
  members: StoryMember[],
  edges: RelationEdge[],
): Set<number> {
  if (members.length === 0) return new Set();
  const byId = new Map(members.map((m) => [m.id, m]));

  // Union the backbone edges into components (undirected).
  const parent = new Map<number, number>();
  const find = (x: number): number => {
    let r = x;
    while (parent.get(r) !== r) r = parent.get(r)!;
    let c = x;
    while (parent.get(c) !== c) {
      const next = parent.get(c)!;
      parent.set(c, r);
      c = next;
    }
    return r;
  };
  for (const m of members) parent.set(m.id, m.id);
  for (const e of edges) {
    if (e.type !== "SEQUEL" && e.type !== "PREQUEL") continue;
    if (!parent.has(e.from) || !parent.has(e.to)) continue;
    parent.set(find(e.from), find(e.to));
  }

  const components = new Map<number, StoryMember[]>();
  for (const m of members) {
    const root = find(m.id);
    const bucket = components.get(root);
    if (bucket) bucket.push(m);
    else components.set(root, [m]);
  }

  let best: StoryMember[] | null = null;
  let bestKey: [number, number, number] = [-1, -1, -Infinity];
  for (const comp of components.values()) {
    // TV outranks everything; UNKNOWN format outranks a known extra format.
    // The unknown case is the quick menu's anchor (list entries don't carry a
    // format), and it's almost always the TV root — without the middle rank,
    // a lone S1 anchor would lose "main story" to its own dated OVA.
    const hasTv = comp.some((m) => m.format === "TV" || m.format === "TV_SHORT")
      ? 2
      : comp.some((m) => m.format == null)
        ? 1
        : 0;
    const dates = comp
      .map((m) => dateMs(m.startDate))
      .filter((v): v is number => v != null);
    const earliest = dates.length ? Math.min(...dates) : Infinity;
    // Negated so that "earlier" compares as "greater".
    const key: [number, number, number] = [hasTv, comp.length, -earliest];
    if (
      key[0] > bestKey[0] ||
      (key[0] === bestKey[0] &&
        (key[1] > bestKey[1] || (key[1] === bestKey[1] && key[2] > bestKey[2])))
    ) {
      best = comp;
      bestKey = key;
    }
  }

  return new Set((best ?? [...byId.values()]).map((m) => m.id));
}

/**
 * Where an extra falls relative to the numbered main story, from air dates:
 * "before #1", "after #2" (started after main #2 began — which is also when
 * you'd watch it), or null when dates can't say. Mirrors how people are told
 * to watch extras: after the season they accompany.
 */
export function placementLabel(
  extra: StoryMember,
  mainInWatchOrder: StoryMember[],
): string | null {
  const at = dateMs(extra.startDate);
  if (at == null || mainInWatchOrder.length === 0) return null;
  let lastBefore = 0;
  for (let i = 0; i < mainInWatchOrder.length; i++) {
    const mainAt = dateMs(mainInWatchOrder[i].startDate);
    // A dateless FIRST main entry counts as earlier than everything: watch
    // order already put it first, and without this a dateless anchor makes
    // every extra claim "before #1", which is almost never true. Dateless
    // entries later in the chain stay skipped — position alone can't say
    // whether an extra precedes them.
    if (mainAt != null ? mainAt <= at : i === 0) lastBefore = i + 1;
  }
  return lastBefore === 0 ? "before #1" : `after #${lastBefore}`;
}

// Promotional shorts (PVs, CMs, teasers, web trailers) are advertising, not
// content: nobody tracks episodes of a trailer, and they were most of the
// clutter difference between AniList's relation graph and a curated site's
// franchise page. Matched conservatively: the promo word must stand alone in
// the title AND the format must be a short-form one (or unknown), so a real
// series that happens to contain such a word in a longer title survives.
const PROMO_TITLE = /(^|[\s:;~・(-])(PV|CM|CMs|Teaser|Trailer|Promo(?:tion(?:al)?)?(\s*(Video|Movie))?|Web\s*(CM|PV)|Character\s*(PV|CM))([\s:;~・)!.-]|$)/i;
const PROMO_FORMATS = new Set<string>(["SPECIAL", "ONA", "OVA", "MUSIC"]);

export function isPromoNode(node: {
  title?: AnimeTitle | null;
  format?: string | null;
}): boolean {
  if (node.format != null && !PROMO_FORMATS.has(node.format)) return false;
  const t = node.title;
  if (!t) return false;
  return [t.romaji, t.english, t.native].some(
    (v) => typeof v === "string" && PROMO_TITLE.test(v),
  );
}
