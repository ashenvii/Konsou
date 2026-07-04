/**
 * Forgiving string matching for the offline "did you mean" fallback.
 *
 * Uses the Sørensen–Dice coefficient over character bigrams: it tolerates typos,
 * transpositions, and dropped letters far better than a substring test, and it's
 * cheap enough to run across the whole local title corpus on every empty search.
 */

/** Bigram multiset of a string, as bigram -> count. */
function bigrams(s: string): Map<string, number> {
  const m = new Map<string, number>();
  for (let i = 0; i < s.length - 1; i++) {
    const bg = s.slice(i, i + 2);
    m.set(bg, (m.get(bg) ?? 0) + 1);
  }
  return m;
}

/** Sørensen–Dice similarity of two strings, 0..1. Expects normalized input. */
export function diceSimilarity(a: string, b: string): number {
  if (a === b) return a.length ? 1 : 0;
  if (a.length < 2 || b.length < 2) return 0;

  const aB = bigrams(a);
  const bB = bigrams(b);
  let intersection = 0;
  for (const [bg, count] of aB) {
    const other = bB.get(bg);
    if (other) intersection += Math.min(count, other);
  }
  const total = a.length - 1 + (b.length - 1);
  return (2 * intersection) / total;
}

/**
 * Match score of a query against one target title, 0..1. A clean substring is a
 * strong signal that a typo rarely produces, so it's floored high; otherwise the
 * Dice coefficient carries it. Both inputs must already be normalized.
 */
export function similarity(query: string, target: string): number {
  if (!query || !target) return 0;
  if (query.length >= 3 && target.includes(query)) {
    return Math.max(diceSimilarity(query, target), 0.85);
  }
  return diceSimilarity(query, target);
}
