import type { MediaFormat, RelationType } from "@/types/anime";

/**
 * One label language for franchise anatomy, shared by every surface that
 * lists a series (Related tab, quick menu, catch-up sheet). The relation
 * chip says how an entry connects to the story; the format chip says what
 * kind of thing it is when that isn't a plain TV season. Chips are neutral
 * on purpose: the label carries the meaning, and seven competing hues per
 * row was noise, not information.
 */
export interface RelationChipMeta {
  label: string;
  /**
   * The lead column's version: three or four characters, uppercase.
   *
   * The franchise list's first column carries the running story number for a
   * main-story entry, and this for everything else — so a reader scanning that
   * one column down the list gets "1, 2, OVA, 3, MOV, 4", which is the shape of
   * how the franchise actually came out. The full `label` used to be the only
   * signal and it sat in the metadata line as one more 11px word among several,
   * where it read as nothing.
   *
   * Abbreviations rather than glyphs on purpose: OVA, ONA and SP are the
   * vocabulary this audience already reads everywhere else, and no drawn mark
   * distinguishes an OVA from an ONA to somebody who has not been taught it.
   */
  tag?: string;
}

const REL_META: Partial<Record<RelationType, RelationChipMeta>> = {
  SEQUEL: { label: "sequel" },
  PREQUEL: { label: "prequel" },
  SIDE_STORY: { label: "side story", tag: "SIDE" },
  SPIN_OFF: { label: "spin-off", tag: "SPIN" },
  ALTERNATIVE: { label: "alternative", tag: "ALT" },
  PARENT: { label: "parent story", tag: "PAR" },
  SUMMARY: { label: "summary", tag: "SUM" },
  CHARACTER: { label: "shares characters" },
  ADAPTATION: { label: "adaptation" },
  OTHER: { label: "related" },
};

/** Formats worth calling out — a plain TV season stays chipless. */
const FORMAT_META: Partial<Record<MediaFormat, RelationChipMeta>> = {
  MOVIE: { label: "movie", tag: "MOV" },
  OVA: { label: "OVA", tag: "OVA" },
  ONA: { label: "ONA", tag: "ONA" },
  SPECIAL: { label: "special", tag: "SP" },
  TV_SHORT: { label: "TV short", tag: "SH" },
};

export function relationChipMeta(
  type?: RelationType | "CURRENT" | null,
): RelationChipMeta | null {
  if (!type || type === "CURRENT") return null;
  return REL_META[type] ?? null;
}

export function formatChipMeta(
  format?: MediaFormat | null,
): RelationChipMeta | null {
  if (!format) return null;
  return FORMAT_META[format] ?? null;
}
