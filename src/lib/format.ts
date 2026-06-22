import type {
  AnimeSummary,
  AnimeTitle,
  CoverImage,
  FuzzyDate,
  MediaFormat,
  AniListMediaStatus,
} from "@/types/anime";
import type { AnimeListEntry, ListStatus } from "@/types/list";

/** Build a card-level summary from a stored list entry (for offline rendering). */
export function entryToSummary(e: AnimeListEntry): AnimeSummary {
  return {
    id: e.anilist_id,
    idMal: e.mal_id,
    title: { romaji: e.title_romaji, english: e.title_english },
    coverImage: { large: e.cover_url ?? undefined },
    episodes: e.total_episodes,
  };
}

const COVER_SIZE: keyof CoverImage = "large";

/** Browser HTTP cache handles repeat cover requests — just normalize the URL.
 *  (Disk caching via asset:// is deferred to v1.1 — see Trap 4.) */
export function getCoverUrl(
  cover?: CoverImage | null,
  fallback = "",
): string {
  return cover?.[COVER_SIZE] ?? cover?.medium ?? cover?.extraLarge ?? fallback;
}

export function preferredTitle(title: AnimeTitle): string {
  return title.english?.trim() || title.romaji;
}

export function secondaryTitle(title: AnimeTitle): string | null {
  if (title.english && title.english.trim() && title.english !== title.romaji) {
    return title.romaji;
  }
  return null;
}

const STATUS_LABELS: Record<ListStatus, string> = {
  watching: "Watching",
  completed: "Completed",
  plan_to_watch: "Plan to Watch",
  on_hold: "On Hold",
  dropped: "Dropped",
  rewatching: "Rewatching",
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

export function formatScore(score?: number | null): string {
  if (score == null) return "—";
  return Number.isInteger(score) ? score.toFixed(1) : String(score);
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
