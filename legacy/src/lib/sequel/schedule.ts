import type { ScanScheduleEntry } from "@/lib/db/contract";

/**
 * Adaptive re-scan scheduling — the "dating system" that keeps sequel detection
 * scalable to lists in the thousands. Each completed/dropped seed is re-checked
 * on a cadence proportional to how likely it is to change, instead of scanning
 * the whole list on every launch:
 *
 *  - A *volatile* franchise (it contains an entry that is RELEASING or
 *    NOT_YET_RELEASED) is where new seasons actually appear, so it's checked
 *    often and its backoff streak resets.
 *  - A *stable* franchise (everything already FINISHED) almost never sprouts a
 *    new entry, so each quiet check doubles its interval — 1d, 2d, 4d … capped
 *    at 30d — with ±15% jitter so a freshly-imported list doesn't all come due
 *    on the same morning (thundering herd).
 *
 * Net effect: steady-state work is O(items actually due now), not O(list size).
 */
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

export const VOLATILE_INTERVAL = 12 * HOUR;
export const STABLE_BASE_INTERVAL = DAY;
export const STABLE_MAX_INTERVAL = 30 * DAY;
const JITTER_RATIO = 0.15;

function withJitter(ms: number): number {
  const spread = ms * JITTER_RATIO;
  return Math.round(ms + (Math.random() * 2 - 1) * spread);
}

/**
 * Given a seed's previous quiet streak and whether its franchise currently looks
 * volatile, return the next schedule row (when to check again + the new streak).
 */
export function computeNextCheck(
  anilistId: number,
  quietStreak: number,
  volatile: boolean,
  now: number = Date.now(),
): ScanScheduleEntry {
  let interval: number;
  let nextStreak: number;

  if (volatile) {
    interval = VOLATILE_INTERVAL;
    nextStreak = 0;
  } else {
    nextStreak = quietStreak + 1;
    // 1d, 2d, 4d, 8d, 16d, 32d→clamped. Exponent capped to avoid overflow.
    const doublings = Math.min(nextStreak - 1, 6);
    interval = Math.min(STABLE_BASE_INTERVAL * 2 ** doublings, STABLE_MAX_INTERVAL);
  }

  return {
    anilist_id: anilistId,
    last_check_at: now,
    next_check_at: now + withJitter(interval),
    quiet_streak: nextStreak,
  };
}

/**
 * Pick which seeds to scan on this background tick: those with no schedule row
 * (never checked) or whose `next_check_at` has passed, most-overdue first,
 * capped to `budget` so a single tick stays gentle on the rate limit.
 */
export function selectDueSeeds(
  seedIds: number[],
  schedule: Record<number, ScanScheduleEntry>,
  budget: number,
  now: number = Date.now(),
): number[] {
  const due = seedIds.filter((id) => {
    const row = schedule[id];
    return !row || row.next_check_at <= now;
  });
  // Never-scheduled seeds sort first (next_check_at treated as 0), then by how
  // overdue each is.
  due.sort((a, b) => (schedule[a]?.next_check_at ?? 0) - (schedule[b]?.next_check_at ?? 0));
  return due.slice(0, budget);
}
