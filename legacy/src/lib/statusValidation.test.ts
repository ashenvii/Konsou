import { describe, it, expect } from "vitest";
import { getDisabledStatuses, statusBlockReason } from "./statusValidation";
import { LIST_STATUSES } from "@/types/list";

describe("getDisabledStatuses", () => {
  it("blocks watching and completing a show that has not aired yet", () => {
    const blocked = getDisabledStatuses("NOT_YET_RELEASED");
    expect([...blocked].sort()).toEqual(["completed", "rewatching", "watching"]);
  });

  it("blocks only completing while a show is still airing", () => {
    expect([...getDisabledStatuses("RELEASING")]).toEqual(["completed"]);
  });

  it("allows everything once a show is finished, cancelled, or unknown", () => {
    for (const airing of ["FINISHED", "CANCELLED", "HIATUS", null, "SOMETHING_NEW"]) {
      expect(getDisabledStatuses(airing).size, String(airing)).toBe(0);
    }
  });

  it("never blocks the not-interested mute — it is always reachable", () => {
    for (const airing of ["NOT_YET_RELEASED", "RELEASING", "FINISHED", null]) {
      expect(getDisabledStatuses(airing).has("not_interested"), String(airing)).toBe(false);
    }
  });

  it("always leaves at least one status open to pick", () => {
    for (const airing of ["NOT_YET_RELEASED", "RELEASING", "FINISHED", null]) {
      const blocked = getDisabledStatuses(airing);
      expect(LIST_STATUSES.some((s) => !blocked.has(s)), String(airing)).toBe(true);
    }
  });
});

describe("statusBlockReason", () => {
  it("explains an unaired show in the user's terms", () => {
    expect(statusBlockReason("NOT_YET_RELEASED", "watching")).toContain("hasn't aired yet");
  });

  it("explains why an airing show cannot be completed", () => {
    expect(statusBlockReason("RELEASING", "completed")).toContain("still airing");
  });

  it("says nothing when the status is allowed", () => {
    expect(statusBlockReason("RELEASING", "watching")).toBeNull();
    expect(statusBlockReason("FINISHED", "completed")).toBeNull();
    expect(statusBlockReason(null, "completed")).toBeNull();
  });

  it("gives a reason for every status it blocks", () => {
    for (const airing of ["NOT_YET_RELEASED", "RELEASING"]) {
      for (const status of getDisabledStatuses(airing)) {
        expect(statusBlockReason(airing, status), `${airing}/${status}`).toBeTruthy();
      }
    }
  });
});
