/**
 * Minimal MAL search via the Jikan API. Used ONLY as a forgiving prefix-match
 * fallback: AniList's SEARCH_MATCH ranks partial/incomplete queries
 * conservatively (e.g. "frier" → 0 results), whereas MAL does true substring
 * matching. We take Jikan's MAL ids and rehydrate them through AniList so every
 * surfaced result stays AniList-native (correct ids, covers, dub detection).
 *
 * Best-effort by design — any failure returns [] and the caller falls back to
 * AniList's own results.
 */
const JIKAN_SEARCH = "https://api.jikan.moe/v4/anime";

/** Returns MAL ids for a query, most-popular first. Empty on any failure. */
export async function jikanSearchMalIds(
  query: string,
  limit = 12,
): Promise<number[]> {
  const url = new URL(JIKAN_SEARCH);
  url.searchParams.set("q", query);
  url.searchParams.set("limit", String(limit));
  url.searchParams.set("sfw", "true");
  url.searchParams.set("order_by", "popularity");
  url.searchParams.set("sort", "asc");

  const res = await fetch(url);
  if (!res.ok) return [];

  const data = (await res.json()) as { data?: { mal_id?: number }[] };
  return (data.data ?? [])
    .map((a) => a.mal_id)
    .filter((id): id is number => typeof id === "number");
}
