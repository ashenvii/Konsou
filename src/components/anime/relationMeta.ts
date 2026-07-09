import type { MediaFormat, RelationType } from "@/types/anime";

/**
 * One color language for franchise anatomy, shared by every surface that
 * lists a series (Related tab, quick menu, catch-up sheet). The relation
 * chip says how an entry connects to the story; the format chip says what
 * kind of thing it is when that isn't a plain TV season. Hues live in
 * tokens.css (--color-rel-*) so themes stay in charge.
 */
export interface RelationChipMeta {
  label: string;
  /** CSS color value (custom property reference). */
  color: string;
}

const REL_META: Partial<Record<RelationType, RelationChipMeta>> = {
  SEQUEL: { label: "sequel", color: "var(--color-rel-main)" },
  PREQUEL: { label: "prequel", color: "var(--color-rel-main)" },
  SIDE_STORY: { label: "side story", color: "var(--color-rel-side)" },
  SPIN_OFF: { label: "spin-off", color: "var(--color-rel-spin)" },
  ALTERNATIVE: { label: "alternative", color: "var(--color-rel-alt)" },
  PARENT: { label: "parent story", color: "var(--color-rel-struct)" },
  SUMMARY: { label: "summary", color: "var(--color-rel-struct)" },
  CHARACTER: { label: "shares characters", color: "var(--color-rel-struct)" },
  ADAPTATION: { label: "adaptation", color: "var(--color-rel-struct)" },
  OTHER: { label: "related", color: "var(--color-rel-struct)" },
};

/** Formats worth calling out — a plain TV season stays chipless. */
const FORMAT_META: Partial<Record<MediaFormat, RelationChipMeta>> = {
  MOVIE: { label: "movie", color: "var(--color-rel-movie)" },
  OVA: { label: "OVA", color: "var(--color-rel-extra)" },
  ONA: { label: "ONA", color: "var(--color-rel-extra)" },
  SPECIAL: { label: "special", color: "var(--color-rel-extra)" },
  TV_SHORT: { label: "TV short", color: "var(--color-rel-extra)" },
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
