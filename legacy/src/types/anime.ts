/**
 * AniList-facing media types and Konsou's internal media shapes.
 * AniList GraphQL schema: https://anilist.github.io/ApiV2-GraphQL-Docs/
 */

export type AniListMediaStatus =
  | "FINISHED"
  | "RELEASING"
  | "NOT_YET_RELEASED"
  | "CANCELLED"
  | "HIATUS";

export type MediaFormat =
  | "TV"
  | "TV_SHORT"
  | "MOVIE"
  | "SPECIAL"
  | "OVA"
  | "ONA"
  | "MUSIC";

export type MediaSeason = "WINTER" | "SPRING" | "SUMMER" | "FALL";

export type RelationType =
  | "SEQUEL"
  | "PREQUEL"
  | "SIDE_STORY"
  | "SPIN_OFF"
  | "PARENT"
  | "ALTERNATIVE"
  | "CHARACTER"
  | "SUMMARY"
  | "ADAPTATION"
  | "OTHER";

export interface CoverImage {
  extraLarge?: string | null;
  large?: string | null;
  medium?: string | null;
  color?: string | null;
}

export interface AnimeTitle {
  romaji: string;
  english?: string | null;
  native?: string | null;
}

export interface FuzzyDate {
  year?: number | null;
  month?: number | null;
  day?: number | null;
}

export interface NextAiringEpisode {
  airingAt: number; // unix seconds
  episode: number;
  timeUntilAiring: number; // seconds
}

export interface ExternalLink {
  url: string;
  site: string;
  type?: string | null;
  language?: string | null;
  icon?: string | null;
  color?: string | null;
  isDisabled?: boolean | null;
  notes?: string | null;
}

export interface MediaTag {
  id: number;
  name: string;
  rank?: number | null;
  isMediaSpoiler?: boolean | null;
}

export interface CharacterEdge {
  role: string; // MAIN | SUPPORTING | BACKGROUND
  name: string;
  image?: string | null;
  /** Japanese (sub) voice actor. */
  voiceActor?: string | null;
  voiceActorId?: number | null;
  /** English (dub) voice actor, when a dub exists. */
  dubActor?: string | null;
}

export interface StaffEdge {
  role: string;
  name: string;
  image?: string | null;
}

export interface RecommendationEntry {
  id: number;
  title: AnimeTitle;
  coverImage?: CoverImage | null;
  format?: MediaFormat | null;
}

/** A node within a relations edge — kept light for sequel detection + chain UI. */
export interface RelationNode {
  relationType: RelationType;
  id: number;
  idMal?: number | null;
  /** "ANIME" | "MANGA" — relations can point at manga (e.g. ALTERNATIVE
   *  source versions); those must not be offered as openable anime. */
  type?: "ANIME" | "MANGA" | null;
  title: AnimeTitle;
  format?: MediaFormat | null;
  status?: AniListMediaStatus | null;
  coverImage?: CoverImage | null;
  startDate?: FuzzyDate | null;
  nextAiringEpisode?: NextAiringEpisode | null;
  episodes?: number | null;
  season?: MediaSeason | null;
  seasonYear?: number | null;
}

/** The light, card-level shape used by search results, discover grids, alerts. */
export interface AnimeSummary {
  id: number;
  idMal?: number | null;
  title: AnimeTitle;
  /** AniList alt names: fan abbreviations + alternate romanizations ("AoT", "SnK"). */
  synonyms?: string[];
  coverImage?: CoverImage | null;
  bannerImage?: string | null;
  format?: MediaFormat | null;
  episodes?: number | null;
  status?: AniListMediaStatus | null;
  seasonYear?: number | null;
  season?: MediaSeason | null;
  averageScore?: number | null;
  genres?: string[];
  studio?: string | null;
  nextAiringEpisode?: NextAiringEpisode | null;
  /** ISO-3166 alpha-2, e.g. "JP", "CN", "KR". Lets the UI label donghua/aeni
   *  instead of hiding them, and drives the Discover Country filter. */
  countryOfOrigin?: string | null;
  /** Minutes per episode. On summaries so list entries can store it at add
   *  time and Stats can count real time instead of a flat 24-minute guess. */
  duration?: number | null;
  /** Derived from externalLinks at query time. null = no streaming links found. */
  hasDub?: boolean | null;
}

/** The full media object used by the detail page (cached 24h). */
export interface AnimeMedia extends AnimeSummary {
  description?: string | null;
  source?: string | null;
  /** Official trailer; site is usually "youtube" (id = video id). */
  trailer?: { id: string; site: string; thumbnail: string | null } | null;
  startDate?: FuzzyDate | null;
  endDate?: FuzzyDate | null;
  tags?: MediaTag[];
  externalLinks?: ExternalLink[];
  relations?: RelationNode[];
  characters?: CharacterEdge[];
  staff?: StaffEdge[];
  recommendations?: RecommendationEntry[];
  isFavourite?: boolean;
}
