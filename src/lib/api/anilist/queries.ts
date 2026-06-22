/** GraphQL query strings for AniList. Kept as plain strings — no codegen. */

const MEDIA_SUMMARY = `
  id
  idMal
  title { romaji english native }
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
  externalLinks { language site type isDisabled }
`;

const RELATION_NODE = `
  relationType
  node {
    id
    idMal
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
    duration
    source
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

export const BROWSE_QUERY = `
query Browse($page: Int!, $perPage: Int!, $sort: [MediaSort], $season: MediaSeason, $seasonYear: Int, $genre: String) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { hasNextPage currentPage }
    media(type: ANIME, sort: $sort, season: $season, seasonYear: $seasonYear, genre: $genre, isAdult: false) {
      ${MEDIA_SUMMARY}
    }
  }
}`;

export const USER_LIST_QUERY = `
query UserList($userName: String!) {
  MediaListCollection(userName: $userName, type: ANIME) {
    lists {
      entries {
        score(format: POINT_10)
        status
        progress
        notes
        startedAt { year month day }
        completedAt { year month day }
        media {
          id
          idMal
          title { romaji english }
          coverImage { medium }
          episodes
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
