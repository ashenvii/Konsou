import { describe, it, expect } from "vitest";
import { isPromoNode, mainStoryIds, placementLabel } from "./storySplit";
import type { StoryMember } from "./storySplit";
import type { RelationEdge } from "./watchOrder";

/**
 * The split has to be seed-independent: opening a franchise from S1's page, from
 * an OVA's page, or from the quick menu must produce the same "main story".
 * These tests pin that, plus the format ranking that keeps a dated special from
 * stealing the main story from its own show.
 */

const tv = (id: number, year?: number): StoryMember => ({
  id,
  format: "TV",
  startDate: year ? { year } : null,
});
const ova = (id: number, year?: number): StoryMember => ({
  id,
  format: "OVA",
  startDate: year ? { year } : null,
});
const sequel = (from: number, to: number): RelationEdge => ({
  from,
  to,
  type: "SEQUEL",
});

describe("mainStoryIds", () => {
  it("returns nothing for an empty franchise", () => {
    expect(mainStoryIds([], []).size).toBe(0);
  });

  it("keeps the sequel-linked seasons and leaves the extras out", () => {
    const main = mainStoryIds(
      [tv(1, 2015), tv(2, 2017), ova(3, 2016), ova(4, 2018)],
      [sequel(1, 2)],
    );
    expect([...main].sort()).toEqual([1, 2]);
  });

  it("counts a movie that continues the plot as main story", () => {
    const movie: StoryMember = { id: 3, format: "MOVIE", startDate: { year: 2019 } };
    const main = mainStoryIds([tv(1, 2015), tv(2, 2017), movie], [
      sequel(1, 2),
      sequel(2, 3),
    ]);
    expect([...main].sort()).toEqual([1, 2, 3]);
  });

  it("leaves a retelling movie out even though it is a film", () => {
    const recap: StoryMember = { id: 3, format: "MOVIE", startDate: { year: 2016 } };
    const main = mainStoryIds([tv(1, 2015), tv(2, 2017), recap], [
      sequel(1, 2),
      { from: 1, to: 3, type: "SUMMARY" },
    ]);
    expect(main.has(3)).toBe(false);
  });

  it("gives a lone season the main story over its own larger pile of OVAs", () => {
    const main = mainStoryIds(
      [tv(1, 2015), ova(2, 2013), ova(3, 2014), ova(4, 2016)],
      [sequel(2, 3), sequel(3, 4)],
    );
    expect([...main]).toEqual([1]);
  });

  it("treats an unknown format as a probable season, not an extra", () => {
    // The quick menu's anchor: a list entry that carries no format at all.
    const anchor: StoryMember = { id: 1, format: null, startDate: { year: 2015 } };
    const main = mainStoryIds([anchor, ova(2, 2013)], []);
    expect([...main]).toEqual([1]);
  });

  it("breaks a tie by taking the longer chain", () => {
    const main = mainStoryIds(
      [tv(1, 2015), tv(2, 2016), tv(3, 2010)],
      [sequel(1, 2)],
    );
    expect([...main].sort()).toEqual([1, 2]);
  });

  it("breaks a remaining tie by which aired first", () => {
    const main = mainStoryIds([tv(1, 2020), tv(2, 2005)], []);
    expect([...main]).toEqual([2]);
  });

  it("does not depend on the order members are passed in", () => {
    const members = [tv(1, 2015), tv(2, 2017), ova(3, 2016)];
    const edges = [sequel(1, 2)];
    const forward = [...mainStoryIds(members, edges)].sort();
    const backward = [...mainStoryIds([...members].reverse(), edges)].sort();
    expect(backward).toEqual(forward);
  });

  it("ignores edges pointing at titles the franchise does not hold", () => {
    const main = mainStoryIds([tv(1, 2015)], [sequel(1, 999)]);
    expect([...main]).toEqual([1]);
  });
});

describe("placementLabel", () => {
  const main = [tv(1, 2015), tv(2, 2018), tv(3, 2021)];

  it("places an extra after the season it accompanies", () => {
    expect(placementLabel(ova(9, 2019), main)).toBe("after #2");
    expect(placementLabel(ova(9, 2016), main)).toBe("after #1");
    expect(placementLabel(ova(9, 2022), main)).toBe("after #3");
  });

  it("places an extra that predates the show before the first season", () => {
    expect(placementLabel(ova(9, 2014), main)).toBe("before #1");
  });

  it("says nothing when it cannot know", () => {
    expect(placementLabel({ id: 9, format: "OVA", startDate: null }, main)).toBeNull();
    expect(placementLabel(ova(9, 2019), [])).toBeNull();
  });

  it("treats a dateless first season as earlier than every extra", () => {
    const dateless = [{ id: 1, format: "TV" as const, startDate: null }, tv(2, 2018)];
    expect(placementLabel(ova(9, 2016), dateless)).toBe("after #1");
  });
});

describe("isPromoNode", () => {
  const t = (romaji: string) => ({ romaji });

  it("catches trailers and promos in short formats", () => {
    expect(isPromoNode({ title: t("Kimetsu no Yaiba PV"), format: "SPECIAL" })).toBe(true);
    expect(isPromoNode({ title: t("Steins;Gate Promotional Video"), format: "ONA" })).toBe(
      true,
    );
    expect(isPromoNode({ title: t("Frieren Teaser"), format: "OVA" })).toBe(true);
    expect(isPromoNode({ title: t("Some Show Character PV 2"), format: "ONA" })).toBe(true);
  });

  it("catches them when the format is unknown", () => {
    expect(isPromoNode({ title: t("Bocchi the Rock! Trailer"), format: null })).toBe(true);
  });

  it("never touches a real series, whatever the title says", () => {
    expect(isPromoNode({ title: t("Attack on Titan PV"), format: "TV" })).toBe(false);
    expect(isPromoNode({ title: t("Your Name Trailer"), format: "MOVIE" })).toBe(false);
  });

  it("leaves ordinary extras alone", () => {
    expect(isPromoNode({ title: t("Konosuba OVA"), format: "OVA" })).toBe(false);
    expect(isPromoNode({ title: t("Bakemonogatari Recap"), format: "SPECIAL" })).toBe(
      false,
    );
  });

  it("needs the promo word to stand alone", () => {
    expect(isPromoNode({ title: t("Pvc Figure Special"), format: "SPECIAL" })).toBe(false);
  });

  it("handles a node with no title at all", () => {
    expect(isPromoNode({ title: null, format: "ONA" })).toBe(false);
  });

  it("checks every title language", () => {
    expect(
      isPromoNode({
        title: { romaji: "Something", english: null, native: "何か PV" },
        format: "ONA",
      }),
    ).toBe(true);
  });
});
