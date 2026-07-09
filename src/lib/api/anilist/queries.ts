/** GraphQL query strings for AniList. Kept as plain strings — no codegen. */

const MEDIA_SUMMARY = `
  id
  idMal
  title { romaji english native }
  synonyms
  coverImage { extraLarge large medium color }
  bannerImage
  format
  episodes
  status
  season
  seasonYear
  averageScore
  genres
  studios(isMain: true) { nodes { name } }
  nextAiringEpisode { airingAt episode timeUntilAiring }
  countryOfOrigin
  duration
  externalLinks { language site type isDisabled }
`;

const RELATION_NODE = `
  relationType
  node {
    id
    idMal
    type
    title { romaji english native }
    format
    status
    coverImage { extraLarge large medium color }
    startDate { year month day }
    nextAiringEpisode { airingAt episode timeUntilAiring }
    episodes
    season
    seasonYear
  }
`;

export const SEARCH_QUERY = `
query Search($search: String!, $page: Int!, $perPage: Int!) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { hasNextPage currentPage }
    media(search: $search, type: ANIME, sort: SEARCH_MATCH, isAdult: false) {
      ${MEDIA_SUMMARY}
    }
  }
}`;

export const DETAIL_QUERY = `
query Detail($id: Int!) {
  Media(id: $id, type: ANIME) {
    ${MEDIA_SUMMARY}
    description(asHtml: true)
    source
    trailer { id site thumbnail }
    startDate { year month day }
    endDate { year month day }
    isFavourite
    tags { id name rank isMediaSpoiler }
    externalLinks { url site type language icon color isDisabled notes }
    relations { edges { ${RELATION_NODE} } }
    characters(sort: [ROLE, RELEVANCE], perPage: 8) {
      edges {
        role
        node { name { full } image { medium } }
        voiceActors(language: JAPANESE) { id name { full } }
      }
    }
    staff(perPage: 4) {
      edges { role node { name { full } image { medium } } }
    }
    recommendations(sort: RATING_DESC, perPage: 8) {
      nodes {
        mediaRecommendation { id title { romaji english } coverImage { large medium } format }
      }
    }
  }
}`;

/** Rehydrate MAL ids (from the Jikan search fallback) into AniList media. */
export const BY_MAL_IDS_QUERY = `
query ByMalIds($idMal_in: [Int], $perPage: Int!) {
  Page(page: 1, perPage: $perPage) {
    media(idMal_in: $idMal_in, type: ANIME, isAdult: false) {
      ${MEDIA_SUMMARY}
    }
  }
}`;

export interface BrowseQueryFlags {
  withFormatIn: boolean;
  withStatus: boolean;
  withCountry: boolean;
  withYear: boolean;
}

/**
 * Build the Discover browse query. Several AniList arguments misbehave when sent
 * as null instead of being omitted: `format_in` 500s, the `startDate_*` bounds
 * throw "Illegal operator and value combination," and `status`/`countryOfOrigin`
 * silently match "null" and return nothing. So each of those is stitched in only
 * when actually set. Genre/tag/season are null-safe and stay in the base query,
 * and `format_not_in` always carries a real value ([MUSIC]).
 */
export function buildBrowseQuery(opts: BrowseQueryFlags): string {
  const parts: { var: string; arg: string }[] = [];
  if (opts.withFormatIn)
    parts.push({ var: "$format_in: [MediaFormat]", arg: "format_in: $format_in" });
  if (opts.withStatus)
    parts.push({ var: "$status: MediaStatus", arg: "status: $status" });
  if (opts.withCountry)
    parts.push({
      var: "$countryOfOrigin: CountryCode",
      arg: "countryOfOrigin: $countryOfOrigin",
    });
  if (opts.withYear) {
    parts.push({
      var: "$startDate_greater: FuzzyDateInt",
      arg: "startDate_greater: $startDate_greater",
    });
    parts.push({
      var: "$startDate_lesser: FuzzyDateInt",
      arg: "startDate_lesser: $startDate_lesser",
    });
  }
  const extraVars = parts.map((p) => `\n  ${p.var}`).join("");
  const extraArgs = parts.map((p) => `\n      ${p.arg}`).join("");
  return `
query Browse(
  $page: Int!
  $perPage: Int!
  $sort: [MediaSort]
  $season: MediaSeason
  $seasonYear: Int
  $genre_in: [String]
  $tag_in: [String]
  $format_not_in: [MediaFormat]${extraVars}
) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { hasNextPage currentPage }
    media(
      type: ANIME
      isAdult: false
      sort: $sort
      season: $season
      seasonYear: $seasonYear
      genre_in: $genre_in
      tag_in: $tag_in
      format_not_in: $format_not_in${extraArgs}
    ) {
      ${MEDIA_SUMMARY}
    }
  }
}`;
}

export const USER_LIST_QUERY = `
query UserList($userName: String!) {
  MediaListCollection(userName: $userName, type: ANIME) {
    lists {
      entries {
        score(format: POINT_10)
        status
        progress
        repeat
        notes
        startedAt { year month day }
        completedAt { year month day }
        media {
          id
          idMal
          title { romaji english native }
          coverImage { medium }
          status
          episodes
          duration
          nextAiringEpisode { episode }
        }
      }
    }
  }
}`;

/** Build an aliased multi-Media query for sequel detection (≤50 ids per batch). */
export function buildRelationsBatchQuery(ids: number[]): string {
  const aliases = ids
    .map(
      (id) => `  m${id}: Media(id: ${id}, type: ANIME) {
    id
    relations { edges { ${RELATION_NODE} } }
  }`,
    )
    .join("\n");
  return `query RelationsBatch {\n${aliases}\n}`;
}

export function buildAiringStatusBatchQuery(ids: number[]): string {
  const aliases = ids
    .map(
      (id) => `  m${id}: Media(id: ${id}, type: ANIME) {
    id
    status
    episodes
    nextAiringEpisode { airingAt episode timeUntilAiring }
  }`,
    )
    .join("\n");
  return `query AiringStatusBatch {\n${aliases}\n}`;
}
