import type {
  AnimeMedia,
  AnimeSummary,
  CharacterEdge,
  RecommendationEntry,
  RelationNode,
  StaffEdge,
} from "@/types/anime";

/* Raw AniList JSON → Konsou internal shapes. Tolerant of missing fields. */

const DUB_SITE_HINTS = [
  "crunchyroll", "hidive", "netflix", "hulu",
  "disney", "prime video", "funimation",
];

function detectDub(links: any[] | null | undefined): boolean | null {
  const streaming = (links ?? []).filter(
    (l: any) => !l.isDisabled && (!l.type || l.type === "STREAMING"),
  );
  if (!streaming.length) return null;
  const hasDub = streaming.some((l: any) => {
    if (l.language) return l.language.toLowerCase().includes("english");
    return DUB_SITE_HINTS.some((h) => l.site?.toLowerCase().includes(h));
  });
  return hasDub;
}

export function mapSummary(raw: any): AnimeSummary {
  return {
    id: raw.id,
    idMal: raw.idMal ?? null,
    title: raw.title,
    synonyms: raw.synonyms ?? [],
    coverImage: raw.coverImage ?? null,
    bannerImage: raw.bannerImage ?? null,
    format: raw.format ?? null,
    episodes: raw.episodes ?? null,
    status: raw.status ?? null,
    season: raw.season ?? null,
    seasonYear: raw.seasonYear ?? null,
    averageScore: raw.averageScore ?? null,
    genres: raw.genres ?? [],
    studio: raw.studios?.nodes?.[0]?.name ?? null,
    nextAiringEpisode: raw.nextAiringEpisode ?? null,
    hasDub: detectDub(raw.externalLinks),
  };
}

export function mapRelations(raw: any): RelationNode[] {
  const edges = raw?.relations?.edges ?? raw?.edges ?? [];
  return edges
    .filter((e: any) => e?.node)
    .map((e: any) => ({
      relationType: e.relationType,
      id: e.node.id,
      idMal: e.node.idMal ?? null,
      title: e.node.title,
      format: e.node.format ?? null,
      status: e.node.status ?? null,
      coverImage: e.node.coverImage ?? null,
      startDate: e.node.startDate ?? null,
      nextAiringEpisode: e.node.nextAiringEpisode ?? null,
      episodes: e.node.episodes ?? null,
      season: e.node.season ?? null,
      seasonYear: e.node.seasonYear ?? null,
    }));
}

function mapCharacters(raw: any): CharacterEdge[] {
  const edges = raw?.characters?.edges ?? [];
  return edges.map((e: any) => ({
    role: e.role,
    name: e.node?.name?.full ?? "Unknown",
    image: e.node?.image?.medium ?? null,
    voiceActor: e.voiceActors?.[0]?.name?.full ?? null,
    voiceActorId: e.voiceActors?.[0]?.id ?? null,
  }));
}

function mapStaff(raw: any): StaffEdge[] {
  const edges = raw?.staff?.edges ?? [];
  return edges.map((e: any) => ({
    role: e.role,
    name: e.node?.name?.full ?? "Unknown",
    image: e.node?.image?.medium ?? null,
  }));
}

function mapRecommendations(raw: any): RecommendationEntry[] {
  const nodes = raw?.recommendations?.nodes ?? [];
  return nodes
    .map((n: any) => n.mediaRecommendation)
    .filter(Boolean)
    .map((m: any) => ({
      id: m.id,
      title: m.title,
      coverImage: m.coverImage ?? null,
      format: m.format ?? null,
    }));
}

export function mapDetail(raw: any): AnimeMedia {
  return {
    ...mapSummary(raw),
    description: raw.description ?? null,
    duration: raw.duration ?? null,
    source: raw.source ?? null,
    startDate: raw.startDate ?? null,
    endDate: raw.endDate ?? null,
    isFavourite: raw.isFavourite ?? false,
    tags: (raw.tags ?? []).filter((t: any) => !t.isMediaSpoiler),
    externalLinks: (raw.externalLinks ?? []).map((l: any) => ({
      url: l.url,
      site: l.site,
      type: l.type ?? null,
      language: l.language ?? null,
      icon: l.icon ?? null,
      color: l.color ?? null,
      isDisabled: l.isDisabled ?? false,
      notes: l.notes ?? null,
    })),
    relations: mapRelations(raw),
    characters: mapCharacters(raw),
    staff: mapStaff(raw),
    recommendations: mapRecommendations(raw),
  };
}
