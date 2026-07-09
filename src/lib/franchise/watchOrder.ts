import type { FuzzyDate, RelationType } from "@/types/anime";

/**
 * Watch order is graph knowledge, not calendar knowledge. Air dates lie about
 * franchises all the time: Fate/Zero aired five years after Fate/stay night
 * but is its story prequel; Demon Slayer's Mugen Train movie belongs between
 * S1 and S2. The relation edges encode the intended order, so they rank first
 * and the calendar only breaks ties or fills in where tags are missing.
 *
 * Implementation: a topological sort over "watch X before Y" edges derived
 * from relation types, with the ready set drained earliest-air-date-first.
 * That gives three properties at once:
 *   1. edge-connected entries always respect the graph (story order),
 *   2. entries the graph says nothing about fall into air-date position,
 *   3. bad data (cycles, contradictory tags) degrades to date order instead
 *      of dropping anything.
 */

/** One relation observation: `from`'s relation list contained `to` as `type`. */
export interface RelationEdge {
  from: number;
  to: number;
  type: RelationType;
}

export interface OrderableNode {
  id: number;
  startDate?: FuzzyDate | null;
  seasonYear?: number | null;
}

// The target is watched AFTER the node that listed it.
const AFTER_FROM: ReadonlySet<RelationType> = new Set([
  "SEQUEL",
  "SIDE_STORY",
  "SPIN_OFF",
  "SUMMARY",
]);
// The target is watched BEFORE the node that listed it.
const BEFORE_FROM: ReadonlySet<RelationType> = new Set(["PREQUEL", "PARENT"]);
// ALTERNATIVE / CHARACTER / OTHER / ADAPTATION carry no watch direction —
// those entries order purely by date.

function dateKey(n: OrderableNode): number {
  const d = n.startDate;
  if (d?.year) return Date.UTC(d.year, (d.month ?? 1) - 1, d.day ?? 1);
  if (n.seasonYear) return Date.UTC(n.seasonYear, 0, 1);
  return Number.MAX_SAFE_INTEGER; // undated (announced) sinks unless edges place it
}

/** Ids of `nodes` in watch order. Every input id appears exactly once. */
export function orderForWatching(
  nodes: OrderableNode[],
  edges: RelationEdge[],
): number[] {
  const byId = new Map(nodes.map((n) => [n.id, n]));

  // before → set of afters, restricted to known nodes, deduped, no self-loops.
  const after = new Map<number, Set<number>>();
  const indegree = new Map<number, number>();
  for (const n of nodes) {
    after.set(n.id, new Set());
    indegree.set(n.id, 0);
  }
  const addEdge = (before: number, then: number) => {
    if (before === then || !byId.has(before) || !byId.has(then)) return;
    const set = after.get(before)!;
    if (set.has(then)) return;
    set.add(then);
    indegree.set(then, (indegree.get(then) ?? 0) + 1);
  };
  for (const e of edges) {
    if (AFTER_FROM.has(e.type)) addEdge(e.from, e.to);
    else if (BEFORE_FROM.has(e.type)) addEdge(e.to, e.from);
  }

  // Sort key: a node's own date, pulled EARLIER to the date of anything it
  // must precede. Fate/Zero (2011) must come before Fate/stay night (2006),
  // so Zero inherits 2006 and the whole block sits at the original's spot —
  // instead of the original getting dragged after unrelated 2010+ remakes.
  const keyMemo = new Map<number, number>();
  const visiting = new Set<number>();
  const sortKey = (id: number): number => {
    const memo = keyMemo.get(id);
    if (memo != null) return memo;
    if (visiting.has(id)) return dateKey(byId.get(id)!); // cycle guard
    visiting.add(id);
    let k = dateKey(byId.get(id)!);
    for (const then of after.get(id) ?? []) {
      k = Math.min(k, sortKey(then));
    }
    visiting.delete(id);
    keyMemo.set(id, k);
    return k;
  };

  // Kahn's algorithm, always emitting the ready node with the earliest
  // (propagated, then raw) date. The ready set is small (a franchise, not a
  // database) — linear scans are fine.
  const remaining = new Set(byId.keys());
  const order: number[] = [];

  const pickMin = (candidates: number[]): number => {
    let best = candidates[0];
    for (const id of candidates) {
      const ka = sortKey(id);
      const kb = sortKey(best);
      const da = dateKey(byId.get(id)!);
      const db = dateKey(byId.get(best)!);
      if (ka < kb || (ka === kb && (da < db || (da === db && id < best)))) {
        best = id;
      }
    }
    return best;
  };

  while (remaining.size > 0) {
    const ready = [...remaining].filter((id) => (indegree.get(id) ?? 0) === 0);
    // No ready node means a cycle in the tags — break it at the earliest
    // date so everything still comes out, in the least surprising spot.
    const next = pickMin(ready.length > 0 ? ready : [...remaining]);
    remaining.delete(next);
    order.push(next);
    for (const then of after.get(next) ?? []) {
      if (remaining.has(then)) {
        indegree.set(then, (indegree.get(then) ?? 1) - 1);
      }
    }
  }

  return order;
}
