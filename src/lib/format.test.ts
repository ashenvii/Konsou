import { describe, it, expect } from "vitest";
import { stripFranchisePrefix } from "./format";

/**
 * The franchise quick menu repeated the series name on every row ("The Seven
 * Deadly Sins: …" twelve times). stripFranchisePrefix drops it so only the
 * distinguishing part shows, and it must NEVER mangle a title — the worst it's
 * allowed to do is leave one unchanged. Cases are the real Seven Deadly Sins
 * titles plus the boundary traps.
 */
describe("stripFranchisePrefix", () => {
  const base = "The Seven Deadly Sins";

  it("drops the franchise name after a colon", () => {
    expect(stripFranchisePrefix(`${base}: Revival of the Commandments`, base)).toBe(
      "Revival of the Commandments",
    );
    expect(stripFranchisePrefix(`${base}: Dragon's Judgement`, base)).toBe(
      "Dragon's Judgement",
    );
    expect(
      stripFranchisePrefix(`${base}: Four Knights of the Apocalypse Season 2`, base),
    ).toBe("Four Knights of the Apocalypse Season 2");
  });

  it("drops it before a plain-space suffix (OVA, Movie)", () => {
    expect(stripFranchisePrefix(`${base} OVA`, base)).toBe("OVA");
    expect(
      stripFranchisePrefix("Nanatsu no Taizai Movie: Tenkuu no Torawarebito", "Nanatsu no Taizai"),
    ).toBe("Movie: Tenkuu no Torawarebito");
  });

  it("handles dash separators", () => {
    expect(
      stripFranchisePrefix("Nanatsu no Taizai: Ensa no Edinburgh - Zenpen", "Nanatsu no Taizai"),
    ).toBe("Ensa no Edinburgh - Zenpen");
  });

  it("keeps the root title (equal to the base) whole", () => {
    expect(stripFranchisePrefix(base, base)).toBe(base);
    expect(stripFranchisePrefix("Nanatsu no Taizai", "Nanatsu no Taizai")).toBe(
      "Nanatsu no Taizai",
    );
  });

  it("never strips across a non-boundary — no false prefix match", () => {
    // "Fate/Zero" under base "Fate": "/" isn't a boundary, keep it whole.
    expect(stripFranchisePrefix("Fate/Zero", "Fate")).toBe("Fate/Zero");
    // A different series that merely shares leading letters.
    expect(stripFranchisePrefix("Nanatsu no Maken ga Shihai Suru", "Nanatsu no Taizai")).toBe(
      "Nanatsu no Maken ga Shihai Suru",
    );
    // Base is a strict prefix word but no separator follows.
    expect(stripFranchisePrefix("Narutoverse", "Naruto")).toBe("Narutoverse");
  });

  it("keeps the title when nothing meaningful is left", () => {
    expect(stripFranchisePrefix("Naruto: !", "Naruto")).toBe("Naruto: !");
  });

  it("is case-insensitive on the prefix and tolerates an empty base", () => {
    expect(stripFranchisePrefix("THE SEVEN DEADLY SINS: X marks", base)).toBe("X marks");
    expect(stripFranchisePrefix("Anything", "")).toBe("Anything");
  });
});
