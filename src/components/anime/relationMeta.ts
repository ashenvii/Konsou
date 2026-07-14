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
}

const REL_META: Partial<Record<RelationType, RelationChipMeta>> = {
  SEQUEL: { label: "sequel" },
  PREQUEL: { label: "prequel" },
  SIDE_STORY: { label: "side story" },
  SPIN_OFF: { label: "spin-off" },
  ALTERNATIVE: { label: "alternative" },
  PARENT: { label: "parent story" },
  SUMMARY: { label: "summary" },
  CHARACTER: { label: "shares characters" },
  ADAPTATION: { label: "adaptation" },
  OTHER: { label: "related" },
};

/** Formats worth calling out — a plain TV season stays chipless. */
const FORMAT_META: Partial<Record<MediaFormat, RelationChipMeta>> = {
  MOVIE: { label: "movie" },
  OVA: { label: "OVA" },
  ONA: { label: "ONA" },
  SPECIAL: { label: "special" },
  TV_SHORT: { label: "TV short" },
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
