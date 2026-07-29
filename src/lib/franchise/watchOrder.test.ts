import { describe, it, expect } from "vitest";
import { orderByRelease } from "./watchOrder";
import type { OrderableNode } from "./watchOrder";

/**
 * Release order is the list's honest default, so it has to be dead simple and
 * dead stable: sort by air date, undated last, ties broken by id. No graph, no
 * surprises. These lock that in.
 */

const n = (id: number, year?: number, month?: number, day?: number): OrderableNode => ({
  id,
  startDate: year ? { year, month: month ?? null, day: day ?? null } : null,
});

describe("orderByRelease", () => {
  it("sorts by air date, earliest first", () => {
    const out = orderByRelease([n(3, 2019), n(1, 2014), n(2, 2016)]);
    expect(out).toEqual([1, 2, 3]);
  });

  it("respects month and day within a year", () => {
    const out = orderByRelease([n(2, 2018, 10), n(1, 2018, 4), n(3, 2018, 10, 15)]);
    expect(out).toEqual([1, 2, 3]);
  });

  it("does NOT reorder for story sense: a late-airing prequel stays at its release slot", () => {
    // Fate/stay night (2006) then Fate/Zero (2011). Release order keeps Zero
    // after Stay night — the whole point of defaulting to release, not watch.
    const out = orderByRelease([n(20, 2011), n(10, 2006)]);
    expect(out).toEqual([10, 20]);
  });

  it("sinks undated (unannounced) entries to the end", () => {
    const out = orderByRelease([n(3), n(1, 2015), n(2, 2020)]);
    expect(out).toEqual([1, 2, 3]);
  });

  it("breaks exact ties by id so the order is stable", () => {
    const out = orderByRelease([n(5, 2020, 1, 1), n(2, 2020, 1, 1)]);
    expect(out).toEqual([2, 5]);
  });

  it("falls back to seasonYear when startDate is missing", () => {
    const out = orderByRelease([
      { id: 2, seasonYear: 2020 },
      { id: 1, seasonYear: 2017 },
    ]);
    expect(out).toEqual([1, 2]);
  });
});
