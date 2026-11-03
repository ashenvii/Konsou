import { describe, it, expect, vi } from "vitest";
import {
  STABLE_BASE_INTERVAL,
  STABLE_MAX_INTERVAL,
  VOLATILE_INTERVAL,
  computeNextCheck,
  selectDueSeeds,
} from "./schedule";
import type { ScanScheduleEntry } from "@/lib/db/contract";

/**
 * The scan schedule is what keeps sequel detection O(due now) instead of
 * O(list size). If backoff stops growing, a 6500-entry list goes back to
 * hammering the rate limiter on every launch.
 */

const NOW = 1_700_000_000_000;
const JITTER = 0.15;

/** Jitter is random by design, so assert the band rather than an exact value. */
function expectInterval(row: ScanScheduleEntry, target: number) {
  const gap = row.next_check_at - NOW;
  expect(gap).toBeGreaterThanOrEqual(Math.round(target * (1 - JITTER)));
  expect(gap).toBeLessThanOrEqual(Math.round(target * (1 + JITTER)));
}

describe("computeNextCheck — volatile franchises", () => {
  it("checks back soon and clears the backoff streak", () => {
    const row = computeNextCheck(42, 5, true, NOW);
    expect(row.anilist_id).toBe(42);
    expect(row.last_check_at).toBe(NOW);
    expect(row.quiet_streak).toBe(0);
    expectInterval(row, VOLATILE_INTERVAL);
  });
});

describe("computeNextCheck — stable franchises", () => {
  it("doubles the wait for each quiet check", () => {
    expectInterval(computeNextCheck(1, 0, false, NOW), STABLE_BASE_INTERVAL);
    expectInterval(computeNextCheck(1, 1, false, NOW), STABLE_BASE_INTERVAL * 2);
    expectInterval(computeNextCheck(1, 2, false, NOW), STABLE_BASE_INTERVAL * 4);
    expectInterval(computeNextCheck(1, 3, false, NOW), STABLE_BASE_INTERVAL * 8);
  });

  it("counts the streak up", () => {
    expect(computeNextCheck(1, 0, false, NOW).quiet_streak).toBe(1);
    expect(computeNextCheck(1, 4, false, NOW).quiet_streak).toBe(5);
  });

  it("caps the wait at 30 days no matter how long it has been quiet", () => {
    for (const streak of [6, 12, 500]) {
      expectInterval(computeNextCheck(1, streak, false, NOW), STABLE_MAX_INTERVAL);
    }
  });

  it("spreads a freshly imported list instead of stacking it on one morning", () => {
    // Same inputs, different draws — a mass import must not come due together.
    const gaps = new Set(
      Array.from({ length: 20 }, () => computeNextCheck(1, 0, false, NOW).next_check_at),
    );
    expect(gaps.size).toBeGreaterThan(1);
  });

  it("applies jitter in both directions", () => {
    const early = vi.spyOn(Math, "random").mockReturnValue(0);
    expect(computeNextCheck(1, 0, false, NOW).next_check_at - NOW).toBe(
      Math.round(STABLE_BASE_INTERVAL * (1 - JITTER)),
    );
    early.mockReturnValue(1);
    expect(computeNextCheck(1, 0, false, NOW).next_check_at - NOW).toBe(
      Math.round(STABLE_BASE_INTERVAL * (1 + JITTER)),
    );
  });
});

describe("selectDueSeeds", () => {
  const sched = (rows: Record<number, number>): Record<number, ScanScheduleEntry> =>
    Object.fromEntries(
      Object.entries(rows).map(([id, next]) => [
        id,
        {
          anilist_id: Number(id),
          last_check_at: NOW - 1,
          next_check_at: next,
          quiet_streak: 0,
        },
      ]),
    );

  it("treats a never-scanned seed as due", () => {
    expect(selectDueSeeds([1, 2], sched({ 1: NOW + 10_000 }), 10, NOW)).toEqual([2]);
  });

  it("leaves seeds alone until their time comes", () => {
    expect(selectDueSeeds([1], sched({ 1: NOW + 1 }), 10, NOW)).toEqual([]);
    expect(selectDueSeeds([1], sched({ 1: NOW }), 10, NOW)).toEqual([1]);
  });

  it("takes the most overdue first, with never-scanned ahead of everything", () => {
    const due = selectDueSeeds(
      [1, 2, 3],
      sched({ 1: NOW - 1_000, 2: NOW - 90_000 }),
      10,
      NOW,
    );
    expect(due).toEqual([3, 2, 1]);
  });

  it("stops at the tick's budget so one launch stays gentle on the rate limit", () => {
    const ids = Array.from({ length: 50 }, (_, i) => i + 1);
    expect(selectDueSeeds(ids, {}, 8, NOW)).toHaveLength(8);
  });
});
