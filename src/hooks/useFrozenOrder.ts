import { useCallback, useMemo, useRef, useState } from "react";

export interface FrozenOrder<T> {
  /** The list to render: the frozen arrangement, not the live sort. */
  items: T[];
  /** How many entries would move UP if the order were refreshed now. This is
   *  the count worth showing: the entries you just touched, not the ones that
   *  shuffle down a slot to make room for them. */
  staleCount: number;
  /** Adopt the fresh order. */
  reorder: () => void;
}

/**
 * Hold a sorted list still while the user works in it.
 *
 * A recency-sorted list re-sorts the instant anything is touched, so logging an
 * episode halfway down throws that card to the top and shifts everything under
 * your finger; on a long list you then have to find your place again. The sort
 * is not wrong, its timing is: order should settle BETWEEN interactions, not
 * during them.
 *
 * So the arrangement is captured once and mutations land in place. Entries that
 * newly join the surface lead (they are new information, not a card sliding
 * away), removed entries drop out, and everything else holds position until the
 * caller re-freezes: a changed `resetKey` (a different filter or sort), a
 * remount (leaving and coming back), or the user tapping the reorder pill.
 *
 * DIM does the same thing structurally: its sorts are explicit per bucket, with
 * an outright denylist for buckets that must never re-sort under the user.
 */
export function useFrozenOrder<T>(
  /** The freshly sorted list. Re-sorting on every change is fine; it is only
   *  consulted for staleness while the frozen arrangement drives rendering. */
  sorted: T[],
  keyOf: (item: T) => number,
  /** Change this to re-freeze (filter, sort mode, query). */
  resetKey: string,
): FrozenOrder<T> {
  const [order, setOrder] = useState<number[]>(() => sorted.map(keyOf));
  const resetRef = useRef(resetKey);

  // Adjusting state during render when an input changes: React's supported
  // pattern for derived state, and it avoids rendering one frame of stale order.
  if (resetRef.current !== resetKey) {
    resetRef.current = resetKey;
    setOrder(sorted.map(keyOf));
  } else if (order.length === 0 && sorted.length > 0) {
    // First arrival. The surface almost always mounts before the list has
    // loaded from SQLite, so the initial freeze would otherwise capture an
    // empty order: every entry then reads as newly arrived on every render and
    // nothing is ever actually held still.
    setOrder(sorted.map(keyOf));
  }

  const reorder = useCallback(() => {
    setOrder(sorted.map(keyOf));
  }, [sorted, keyOf]);

  return useMemo(() => {
    const byKey = new Map<number, T>();
    for (const item of sorted) byKey.set(keyOf(item), item);

    const held: T[] = [];
    const seen = new Set<number>();
    for (const key of order) {
      const item = byKey.get(key);
      if (item) {
        held.push(item);
        seen.add(key);
      }
    }
    // Newly arrived entries lead: every list this drives is recency-sorted, so
    // the top is where a new entry belongs anyway.
    const arrived = sorted.filter((item) => !seen.has(keyOf(item)));
    const items = arrived.length > 0 ? [...arrived, ...held] : held;

    const freshIndex = new Map<number, number>();
    sorted.forEach((item, i) => freshIndex.set(keyOf(item), i));
    let staleCount = 0;
    items.forEach((item, i) => {
      const fresh = freshIndex.get(keyOf(item));
      if (fresh != null && fresh < i) staleCount++;
    });

    return { items, staleCount, reorder };
  }, [sorted, order, keyOf, reorder]);
}
