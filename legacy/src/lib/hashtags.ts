/**
 * Hashtags inside the notes people already write.
 *
 * A 6500-entry library needs categories, but every fixed taxonomy we could ship
 * would be wrong for someone: one person wants #with-mia, another wants #dubbed
 * or #comfort or #s2-when. So the taxonomy is not shipped at all. Anything
 * written as `#tag` in an entry's notes becomes a facet you can filter by, and
 * the vocabulary is whatever the user invented by typing.
 *
 * Lifted from DIM's inventory/note-hashtags.ts, which solves the same problem
 * for a large item collection.
 */

/**
 * Tags must follow a boundary so a URL fragment or a "#1" mid-sentence does not
 * silently become a category. Letters and digits are Unicode-aware, so Japanese
 * tags work as well as Latin ones.
 */
const HASHTAG_RE = /(?:^|[\s,(])(#[\p{L}\p{N}][\p{L}\p{N}_:-]*)/gu;

/** Tags written in one note, in the case they were written, deduped. */
export function getHashtags(text: string | null | undefined): string[] {
  if (!text || !text.includes("#")) return [];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const m of text.matchAll(HASHTAG_RE)) {
    const tag = m[1];
    const key = tag.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(tag);
  }
  return out;
}

/** True when `text` carries `tag` (compared case-insensitively). */
export function hasHashtag(text: string | null | undefined, tagKey: string): boolean {
  if (!text || !text.includes("#")) return false;
  for (const t of getHashtags(text)) {
    if (t.toLowerCase() === tagKey) return true;
  }
  return false;
}

export interface NoteSegment {
  text: string;
  /** True when this run is a hashtag, so it can be rendered as a chip. */
  tag: boolean;
}

/**
 * Split a note into plain runs and hashtag runs, so a note can be shown with
 * its tags picked out. Keeps the original text intact and in order; nothing is
 * dropped, which matters because this is the user's own writing.
 */
export function segmentHashtags(text: string): NoteSegment[] {
  const out: NoteSegment[] = [];
  let last = 0;
  for (const m of text.matchAll(HASHTAG_RE)) {
    const tag = m[1];
    // m[0] may carry a leading boundary character; the tag starts after it.
    const start = (m.index ?? 0) + m[0].length - tag.length;
    if (start > last) out.push({ text: text.slice(last, start), tag: false });
    out.push({ text: tag, tag: true });
    last = start + tag.length;
  }
  if (last < text.length) out.push({ text: text.slice(last), tag: false });
  return out;
}

/** Normalize what someone typed into a storable tag ("#" optional, no spaces). */
export function normalizeTagInput(raw: string): string | null {
  const trimmed = raw.trim().replace(/^#+/, "").replace(/\s+/g, "-");
  if (!trimmed) return null;
  // Reuse the parser as the validator: if it would not be found as a tag, it is
  // not a tag, so the picker cannot write something the filters can never see.
  const candidate = `#${trimmed}`;
  return getHashtags(candidate).length === 1 ? candidate : null;
}

/** Append a tag to a note, unless it is already there (case-insensitively). */
export function addHashtag(note: string, tag: string): string {
  const normalized = normalizeTagInput(tag);
  if (!normalized) return note;
  if (hasHashtag(note, normalized.toLowerCase())) return note;
  const base = note.trimEnd();
  return base.length === 0 ? normalized : `${base} ${normalized}`;
}

/**
 * Strip a tag from a note, leaving the surrounding prose intact. Only runs of
 * spaces are collapsed afterwards; newlines are the user's formatting and are
 * left alone.
 */
export function removeHashtag(note: string, tagKey: string): string {
  let out = "";
  for (const seg of segmentHashtags(note)) {
    if (seg.tag && seg.text.toLowerCase() === tagKey) continue;
    out += seg.text;
  }
  return out.replace(/[^\S\n]{2,}/g, " ").replace(/[^\S\n]+$/gm, "").trim();
}

export interface HashtagFacet {
  /** Lowercased, the identity used for matching and filter state. */
  key: string;
  /** The spelling to show: whichever casing the user used most often. */
  label: string;
  /** How many notes carry it. */
  count: number;
}

/**
 * Collect the tag vocabulary across many notes. Casing is normalized for
 * matching but the most-used spelling wins for display, so a library that
 * mostly says "#Rewatch" is not relabelled "#rewatch" by one stray note.
 */
export function collectHashtags(notes: (string | null | undefined)[]): HashtagFacet[] {
  const counts = new Map<string, number>();
  const spellings = new Map<string, Map<string, number>>();

  for (const note of notes) {
    for (const tag of getHashtags(note)) {
      const key = tag.toLowerCase();
      counts.set(key, (counts.get(key) ?? 0) + 1);
      let variants = spellings.get(key);
      if (!variants) {
        variants = new Map();
        spellings.set(key, variants);
      }
      variants.set(tag, (variants.get(tag) ?? 0) + 1);
    }
  }

  const facets: HashtagFacet[] = [];
  for (const [key, count] of counts) {
    let label = key;
    let best = -1;
    for (const [spelling, n] of spellings.get(key) ?? []) {
      if (n > best) {
        best = n;
        label = spelling;
      }
    }
    facets.push({ key, label, count });
  }

  // Most-used first, then alphabetical, so the row is stable between renders.
  return facets.sort((a, b) => b.count - a.count || a.key.localeCompare(b.key));
}
