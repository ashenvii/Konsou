/**
 * Offline "did you mean" for search. Keeps an in-memory index of every title and
 * synonym the app has seen this session (search + discover results) and fuzzy-
 * matches a query against it — plus whatever extra candidates the caller passes
 * (the user's list). Never touches the network, so a typo'd query for something
 * already known still surfaces it.
 *
 * Deliberately imports nothing from the store or API client so it stays a leaf
 * module (no import cycle with the AniList client that feeds it).
 */
import { normalizeForSearch } from "@/lib/format";
import type { AnimeSummary } from "@/types/anime";
import { similarity } from "./fuzzy";

interface Indexed {
  summary: AnimeSummary;
  /** Normalized, de-duped title + synonym strings to match against. */
  terms: string[];
}

const registry = new Map<number, Indexed>();

function termsOf(s: AnimeSummary): string[] {
  const raw = [
    s.title?.romaji,
    s.title?.english,
    s.title?.native,
    ...(s.synonyms ?? []),
  ];
  const terms = raw
    .filter((t): t is string => typeof t === "string" && t.trim().length > 0)
    .map(normalizeForSearch)
    .filter((t) => t.length > 0);
  return [...new Set(terms)];
}

/** Feed summaries the app fetched (search/discover) into the index. */
export function indexSummaries(summaries: AnimeSummary[]): void {
  for (const s of summaries) {
    if (s?.id == null) continue;
    registry.set(s.id, { summary: s, terms: termsOf(s) });
  }
}

/**
 * Fuzzy-match a query against the local corpus and return the best candidates.
 * `extra` (typically the user's list, converted to summaries) is merged in and
 * takes second place to the session registry when ids collide.
 */
export function localFuzzySearch(
  query: string,
  extra: AnimeSummary[] = [],
  limit = 8,
  minScore = 0.5,
): AnimeSummary[] {
  const q = normalizeForSearch(query);
  if (q.length < 2) return [];

  const candidates = new Map<number, Indexed>(registry);
  for (const s of extra) {
    if (s?.id != null && !candidates.has(s.id)) {
      candidates.set(s.id, { summary: s, terms: termsOf(s) });
    }
  }

  const scored: { summary: AnimeSummary; score: number }[] = [];
  for (const { summary, terms } of candidates.values()) {
    let best = 0;
    for (const t of terms) {
      const s = similarity(q, t);
      if (s > best) best = s;
      if (best === 1) break;
    }
    if (best >= minScore) scored.push({ summary, score: best });
  }

  scored.sort((a, b) => b.score - a.score);
  return scored.slice(0, limit).map((x) => x.summary);
}
