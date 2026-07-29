import type {
  AnimeSummary,
  AnimeTitle,
  CoverImage,
  FuzzyDate,
  MediaFormat,
  AniListMediaStatus,
} from "@/types/anime";
import type { AnimeListEntry, ListStatus, TitleLanguage } from "@/types/list";

/** Build a card-level summary from a stored list entry (for offline rendering). */
export function entryToSummary(e: AnimeListEntry): AnimeSummary {
  return {
    id: e.anilist_id,
    idMal: e.mal_id,
    title: {
      romaji: e.title_romaji,
      english: e.title_english,
      native: e.title_native,
    },
    coverImage: { large: e.cover_url ?? undefined },
    episodes: e.total_episodes,
  };
}

const COVER_SIZE: keyof CoverImage = "large";

/** AniList serves a literal grey "No Image" JPEG (…/default.jpg) for media
 *  without cover art. Treat it as no URL at all, so every surface renders our
 *  own designed fallback tile instead of their placeholder photo. */
function realCover(url: string | null | undefined): string | null {
  if (!url) return null;
  return /\/default\.(jpe?g|png|webp)(\?|$)/i.test(url) ? null : url;
}

/** Browser HTTP cache handles repeat cover requests — just normalize the URL.
 *  (Disk caching via asset:// is deferred to v1.1 — see Trap 4.) */
export function getCoverUrl(
  cover?: CoverImage | null,
  fallback = "",
): string {
  return (
    realCover(cover?.[COVER_SIZE]) ??
    realCover(cover?.medium) ??
    realCover(cover?.extraLarge) ??
    fallback
  );
}

/** Selectable title languages with labels + a live example (shown in onboarding
 *  and Settings). Example uses Frieren across all three scripts. */
export const TITLE_LANGUAGE_OPTIONS: {
  id: TitleLanguage;
  label: string;
  example: string;
}[] = [
  { id: "romaji", label: "Romaji", example: "Sousou no Frieren" },
  { id: "english", label: "English", example: "Frieren: Beyond Journey's End" },
  { id: "native", label: "Japanese", example: "葬送のフリーレン" },
];

/** Order in which to fall back when a title is missing for the chosen language. */
const TITLE_FALLBACK: Record<TitleLanguage, (keyof AnimeTitle)[]> = {
  romaji: ["romaji", "english", "native"],
  english: ["english", "romaji", "native"],
  native: ["native", "romaji", "english"],
};

/** Order in which to pick a *secondary* (other-language) title to surface. */
const SECONDARY_ORDER: Record<TitleLanguage, (keyof AnimeTitle)[]> = {
  // Romaji shown → English is the most useful "other name" to check.
  romaji: ["english", "native"],
  // English shown → Romaji is the most recognizable Japanese form.
  english: ["romaji", "native"],
  // Native shown → Romaji reads for non-JP users, English as backup.
  native: ["romaji", "english"],
};

function pick(title: AnimeTitle, key: keyof AnimeTitle): string {
  const v = title[key];
  return typeof v === "string" ? v.trim() : "";
}

/** The title to show first, honoring the user's language preference. */
export function preferredTitle(
  title: AnimeTitle,
  pref: TitleLanguage = "romaji",
): string {
  for (const key of TITLE_FALLBACK[pref]) {
    const v = pick(title, key);
    if (v) return v;
  }
  return "Untitled";
}

/** Every distinct title other than the primary — shown behind the info toggle
 *  on the detail page, never inline. One name per surface everywhere else. */
export function alternateTitles(
  title: AnimeTitle,
  pref: TitleLanguage = "romaji",
): string[] {
  const primary = preferredTitle(title, pref);
  const out: string[] = [];
  const seen = new Set([primary]);
  for (const key of SECONDARY_ORDER[pref]) {
    const v = pick(title, key);
    if (v && !seen.has(v)) {
      seen.add(v);
      out.push(v);
    }
  }
  return out;
}

/**
 * Drop the franchise name from a member's title so a franchise list reads the
 * way a curated site's cards do: the root keeps its full name, and every later
 * entry shows only what sets it apart. A Seven Deadly Sins sheet stops being a
 * wall of "The Seven Deadly Sins: …" and becomes "Revival of the Commandments",
 * "Dragon's Judgement", "Four Knights of the Apocalypse".
 *
 * Conservative on purpose: it only strips when the title literally begins with
 * the base (case-insensitive) AND a real boundary follows — a colon, a dash, or
 * a space. No boundary, nothing left, or a title no longer than the base (the
 * root itself, or an unrelated name) all keep the full title, so the worst it
 * can do is leave a title untouched. `base` should be in the same title
 * language as `title`, so their prefixes line up.
 */
export function stripFranchisePrefix(title: string, base: string): string {
  const t = title.trim();
  const b = base.trim();
  if (!b || t.length <= b.length) return t;
  if (t.slice(0, b.length).toLowerCase() !== b.toLowerCase()) return t;
  const rest = t.slice(b.length);
  // Separator between the franchise name and its subtitle: ": ", " - ", "- ",
  // an en/em dash, or plain whitespace ("… OVA", "… Movie: …"). A "/" is not a
  // boundary, so "Fate/Zero" under base "Fate" is left whole.
  const m = rest.match(/^\s*[:\-–—]\s*(.+)$/) ?? rest.match(/^\s+(.+)$/);
  if (!m) return t;
  const sub = m[1].trim();
  return sub.length >= 2 ? sub : t;
}

/**
 * Normalize text for forgiving local matching: lowercase, fold diacritics and
 * macrons (ō→o, é→e), drop combining marks, and collapse runs of whitespace.
 * Used for My List search and to clean query input before it hits the network.
 */
export function normalizeForSearch(s: string): string {
  return s
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
}

const STATUS_LABELS: Record<ListStatus, string> = {
  watching: "Watching",
  completed: "Completed",
  plan_to_watch: "Plan to Watch",
  on_hold: "On Hold",
  dropped: "Dropped",
  rewatching: "Rewatching",
  not_interested: "Not Interested",
};

export function listStatusLabel(s: ListStatus): string {
  return STATUS_LABELS[s];
}

const FORMAT_LABELS: Record<MediaFormat, string> = {
  TV: "TV",
  TV_SHORT: "TV Short",
  MOVIE: "Movie",
  SPECIAL: "Special",
  OVA: "OVA",
  ONA: "ONA",
  MUSIC: "Music",
};

export function formatLabel(f?: MediaFormat | null): string | null {
  return f ? FORMAT_LABELS[f] : null;
}

// AniList manga/light-novel formats. A relation carrying one of these (or an
// explicit MANGA type) is source material, not a watchable season.
const MANGA_FORMATS = new Set(["MANGA", "NOVEL", "ONE_SHOT"]);

/**
 * True when a relation node is manga/novel source material rather than anime.
 * Guards every place relations are offered as watchable (Related, franchise
 * chain, sequel alerts). Tests `format` as well as `type` because relation
 * snapshots cached before the `type` field was added still carry `format`, so
 * this catches leaks like "Cyberpunk: Edgerunners MADNESS" without a cache wipe.
 */
export function isMangaNode(
  node: { type?: string | null; format?: string | null } | null | undefined,
): boolean {
  if (!node) return false;
  if (node.type === "MANGA") return true;
  return node.format != null && MANGA_FORMATS.has(node.format);
}

const AIRING_LABELS: Record<AniListMediaStatus, string> = {
  FINISHED: "Finished",
  RELEASING: "Airing",
  NOT_YET_RELEASED: "Not Yet Aired",
  CANCELLED: "Cancelled",
  HIATUS: "Hiatus",
};

export function airingStatusLabel(s?: AniListMediaStatus | null): string | null {
  return s ? AIRING_LABELS[s] : null;
}

/** "12 / 24", "12 / ?", "12" — never throws on null totals. */
export function episodeProgress(watched: number, total?: number | null): string {
  return `${watched} / ${total ?? "?"}`;
}

/**
 * Best-known aired episode count for a media shape: the episode before the
 * next airing one, or the full total once the show has FINISHED. null when
 * the data can't say (announced shows, stale snapshots).
 */
export function airedEpisodes(s: {
  status?: string | null;
  episodes?: number | null;
  nextAiringEpisode?: { episode: number } | null;
}): number | null {
  if (s.nextAiringEpisode?.episode != null) {
    return Math.max(0, s.nextAiringEpisode.episode - 1);
  }
  if (s.status === "FINISHED") return s.episodes ?? null;
  return null;
}

export function formatScore(score?: number | null): string {
  if (score == null) return "—";
  // "9" and "8.5", never "9.0": the trailing zero is chip noise.
  return String(score);
}

export function formatFuzzyDate(d?: FuzzyDate | null): string | null {
  if (!d || !d.year) return null;
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];
  if (d.month && d.day) return `${months[d.month - 1]} ${d.day}, ${d.year}`;
  if (d.month) return `${months[d.month - 1]} ${d.year}`;
  return String(d.year);
}

export function seasonYearLabel(s?: AnimeSummary): string | null {
  if (!s?.seasonYear) return s?.season ? titleCase(s.season) : null;
  return s.season ? `${titleCase(s.season)} ${s.seasonYear}` : String(s.seasonYear);
}

function titleCase(v: string): string {
  return v.charAt(0).toUpperCase() + v.slice(1).toLowerCase();
}

/** Compact relative time: "just now", "3m", "5h", "2d", "3w", or a date. */
export function relativeTime(ms: number): string {
  const diff = Date.now() - ms;
  const sec = Math.round(diff / 1000);
  if (sec < 45) return "just now";
  const min = Math.round(sec / 60);
  if (min < 60) return `${min}m`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `${hr}h`;
  const day = Math.round(hr / 24);
  if (day < 7) return `${day}d`;
  const wk = Math.round(day / 7);
  if (wk < 5) return `${wk}w`;
  return new Date(ms).toLocaleDateString();
}

/** "in 2d 4h", "in 3h", "in 25m" from a unix-seconds airing time. */
export function timeUntil(airingAtSeconds: number): string {
  const diff = airingAtSeconds * 1000 - Date.now();
  if (diff <= 0) return "aired";
  const min = Math.floor(diff / 60000);
  const days = Math.floor(min / 1440);
  const hrs = Math.floor((min % 1440) / 60);
  const mins = min % 60;
  if (days > 0) return `in ${days}d ${hrs}h`;
  if (hrs > 0) return `in ${hrs}h ${mins}m`;
  return `in ${mins}m`;
}

/** AniList descriptions contain HTML — strip to plain text for collapsed previews. */
export function stripHtml(html?: string | null): string {
  if (!html) return "";
  return html
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&mdash;/g, "—")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .trim();
}
