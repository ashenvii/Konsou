import type { AnimeListEntry } from "@/types/list";

const FALLBACK_MINUTES = 24;

const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

export interface WrappedStats {
  year: number;
  /** Everything completed during the year, in finish order. */
  finished: AnimeListEntry[];
  finishedCount: number;
  episodes: number;
  minutes: number;
  hours: number;
  busiestMonth: { name: string; count: number } | null;
  /** Best-scored finishes of the year, up to three. */
  topRated: AnimeListEntry[];
  firstFinish: AnimeListEntry | null;
  lastFinish: AnimeListEntry | null;
  /** The franchise with the most finishes this year, when 2+ of them landed. */
  franchise: { display: AnimeListEntry; count: number } | null;
  meanScore: number | null;
  addedCount: number;
}

/**
 * The year in review, computed entirely from local data. Attribution is by
 * finish date: the app records when a show was completed, not when each
 * episode was watched, so "your year" means "what you finished in it".
 * Episode counts use the full run (a finish implies the whole show), timed at
 * each show's real episode length where known.
 */
export function computeWrapped(
  entries: AnimeListEntry[],
  year: number,
): WrappedStats {
  const start = new Date(year, 0, 1).getTime();
  const end = new Date(year + 1, 0, 1).getTime();
  const inYear = (ms: number | null) => ms != null && ms >= start && ms < end;

  const finished = entries
    .filter((e) => e.status === "completed" && inYear(e.completed_at))
    .sort((a, b) => (a.completed_at ?? 0) - (b.completed_at ?? 0));

  let episodes = 0;
  let minutes = 0;
  const monthCounts = new Array(12).fill(0) as number[];
  let scoreSum = 0;
  let scored = 0;
  const byFranchise = new Map<number, AnimeListEntry[]>();

  for (const e of finished) {
    const eps = e.total_episodes ?? e.episodes_watched;
    episodes += eps;
    minutes += eps * (e.episode_duration ?? FALLBACK_MINUTES);
    monthCounts[new Date(e.completed_at!).getMonth()]++;
    if (e.score != null) {
      scoreSum += e.score;
      scored++;
    }
    const key = e.franchise_root_id ?? e.anilist_id;
    const bucket = byFranchise.get(key);
    if (bucket) bucket.push(e);
    else byFranchise.set(key, [e]);
  }

  let busiestMonth: WrappedStats["busiestMonth"] = null;
  for (let m = 0; m < 12; m++) {
    if (monthCounts[m] > (busiestMonth?.count ?? 0)) {
      busiestMonth = { name: MONTHS[m], count: monthCounts[m] };
    }
  }

  let franchise: WrappedStats["franchise"] = null;
  for (const members of byFranchise.values()) {
    if (members.length >= 2 && members.length > (franchise?.count ?? 0)) {
      franchise = { display: members[0], count: members.length };
    }
  }

  const topRated = [...finished]
    .filter((e) => e.score != null)
    .sort((a, b) => (b.score ?? 0) - (a.score ?? 0))
    .slice(0, 3);

  return {
    year,
    finished,
    finishedCount: finished.length,
    episodes,
    minutes,
    hours: Math.round(minutes / 60),
    busiestMonth,
    topRated,
    firstFinish: finished[0] ?? null,
    lastFinish: finished.length > 0 ? finished[finished.length - 1] : null,
    franchise,
    meanScore: scored > 0 ? scoreSum / scored : null,
    addedCount: entries.filter((e) => inYear(e.added_at)).length,
  };
}

/** Years with at least one finish, newest first — drives the year switcher. */
export function wrappedYears(entries: AnimeListEntry[]): number[] {
  const years = new Set<number>();
  for (const e of entries) {
    if (e.status === "completed" && e.completed_at != null) {
      years.add(new Date(e.completed_at).getFullYear());
    }
  }
  return [...years].sort((a, b) => b - a);
}
