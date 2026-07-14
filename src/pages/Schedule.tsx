import { useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { CalendarClock, Clock } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Skeleton } from "@/components/ui/Skeleton";
import { Text } from "@/components/ui/Text";
import { useAiringSchedule } from "@/hooks/useAniList";
import { airedEpisodes, preferredTitle, timeUntil } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AnimeListEntry, ListEntryPatch } from "@/types/list";

const DAY_MS = 86_400_000;
const WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

function startOfDay(ms: number): number {
  const d = new Date(ms);
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
}

function clockLabel(ms: number): string {
  return new Date(ms).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
}

interface ScheduledItem {
  entry: AnimeListEntry;
  airMs: number;
  episode: number | null;
}

interface DayBucket {
  key: string;
  label: string;
  sort: number;
  items: ScheduledItem[];
}

/**
 * The Episodes segment of the Airing tab: a weekly calendar of the next
 * episodes for shows you already track. The Airing shell owns the page header
 * and the segment switcher, so this renders content only.
 */
export function EpisodesPanel() {
  const navigate = useNavigate();
  const loaded = useListStore((s) => s.loaded);
  const entries = useListStore((s) => s.entries);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  // Only shows you're keeping up with, and only those that could still air.
  const candidates = useMemo(
    () =>
      entries.filter(
        (e) =>
          (e.status === "watching" ||
            e.status === "rewatching" ||
            e.status === "plan_to_watch") &&
          e.airing_status !== "FINISHED" &&
          e.airing_status !== "CANCELLED",
      ),
    [entries],
  );
  const ids = useMemo(() => candidates.map((e) => e.anilist_id), [candidates]);

  const { data: airing, isLoading, isError, refetch } = useAiringSchedule(ids);
  const patchEntry = useListStore((s) => s.patch);

  // Persist what the airing lookup just learned: fresh aired counts keep
  // "episodes left" honest, totals backfill data gaps, and airing_status
  // stays current for the status-picker guards. Value-guarded, so the write
  // storm settles after one pass.
  useEffect(() => {
    if (!airing) return;
    for (const e of candidates) {
      const info = airing[e.anilist_id];
      if (!info) continue;
      const p: ListEntryPatch = {};
      const aired = airedEpisodes({
        status: info.status,
        episodes: info.episodes,
        nextAiringEpisode:
          info.nextEpisode != null ? { episode: info.nextEpisode } : null,
      });
      if (aired != null && e.aired_episodes !== aired) p.aired_episodes = aired;
      if (e.total_episodes == null && info.episodes != null) {
        p.total_episodes = info.episodes;
      }
      if (info.status && e.airing_status !== info.status) {
        p.airing_status = info.status;
      }
      if (Object.keys(p).length > 0) void patchEntry(e.anilist_id, p);
    }
  }, [airing, candidates, patchEntry]);

  const { days, announced } = useMemo(() => {
    const buckets = new Map<string, DayBucket>();
    const announced: AnimeListEntry[] = [];
    const todayStart = startOfDay(Date.now());

    for (const entry of candidates) {
      const info = airing?.[entry.anilist_id];
      const airAt = info?.nextAiringAt;
      if (!airAt) {
        // No upcoming episode: an announced/not-yet-aired title with no date.
        if ((info?.status ?? entry.airing_status) === "NOT_YET_RELEASED") {
          announced.push(entry);
        }
        continue;
      }
      const airMs = airAt * 1000;
      const diff = Math.round((startOfDay(airMs) - todayStart) / DAY_MS);
      let key: string;
      let label: string;
      let sort: number;
      if (diff <= 0) {
        key = "today";
        label = "Today";
        sort = 0;
      } else if (diff === 1) {
        key = "tomorrow";
        label = "Tomorrow";
        sort = 1;
      } else if (diff < 7) {
        key = `d${diff}`;
        label = WEEKDAYS[new Date(airMs).getDay()];
        sort = diff;
      } else {
        key = "later";
        label = "Later";
        sort = 99;
      }
      let bucket = buckets.get(key);
      if (!bucket) {
        bucket = { key, label, sort, items: [] };
        buckets.set(key, bucket);
      }
      bucket.items.push({ entry, airMs, episode: info.nextEpisode });
    }

    const days = [...buckets.values()].sort((a, b) => a.sort - b.sort);
    for (const d of days) d.items.sort((a, b) => a.airMs - b.airMs);
    return { days, announced };
  }, [candidates, airing]);

  const title = (e: AnimeListEntry) =>
    preferredTitle(
      { romaji: e.title_romaji, english: e.title_english, native: e.title_native },
      titleLanguage,
    );

  if (!loaded || (isLoading && ids.length > 0)) {
    return (
      <div className="k-sched konsou-scroll">
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} height={72} radius="var(--radius-lg)" style={{ marginBottom: 8 }} />
        ))}
      </div>
    );
  }

  const hasContent = days.length > 0 || announced.length > 0;

  if (!hasContent) {
    // "Couldn't check" and "nothing airing" are different facts; with no
    // cached airing data and a failed fetch, claiming an empty calendar
    // would be a lie.
    return isError ? (
      <EmptyState
        icon={CalendarClock}
        title="Couldn't check the schedule"
        subtitle="Konsou can't reach AniList right now."
        action={
          <Button size="sm" variant="primary" onClick={() => void refetch()}>
            Try again
          </Button>
        }
      />
    ) : (
      <EmptyState
        icon={CalendarClock}
        title="Nothing on the calendar"
        subtitle="When something you're watching or plan to watch is airing, its next episodes show up here."
      />
    );
  }

  return (
    <div className="k-sched konsou-scroll">
      {isError && (
        // We have cached days but the latest refetch failed — say so instead of
        // passing stale times off as current.
        <p className="k-airing__note">Showing what we last knew · offline</p>
      )}
      {days.map((bucket) => (
            <section key={bucket.key} className="k-sched__day">
              <header className="k-sched__dayhead">
                <span>{bucket.label}</span>
                <span className="k-sched__daycount">{bucket.items.length}</span>
              </header>
              {bucket.items.map((it) => (
                <button
                  key={it.entry.anilist_id}
                  type="button"
                  className="k-schedrow"
                  onClick={() => navigate(`/anime/${it.entry.anilist_id}`, { replace: true })}
                >
                  <AnimeCover
                    src={it.entry.cover_url ?? undefined}
                    alt={title(it.entry)}
                    decorative
                    radius="var(--radius-sm)"
                    className="k-schedrow__cover"
                  />
                  <div className="k-schedrow__main">
                    <Text size="base" weight={600} clamp={2}>
                      {title(it.entry)}
                    </Text>
                    <span className="k-schedrow__ep">
                      {it.episode != null ? `Episode ${it.episode}` : "Next episode"}
                    </span>
                  </div>
                  <div className="k-schedrow__time">
                    <span className="k-schedrow__clock">{clockLabel(it.airMs)}</span>
                    <span className="k-schedrow__count">
                      <Icon icon={Clock} size={11} />
                      {timeUntil(Math.floor(it.airMs / 1000))}
                    </span>
                  </div>
                </button>
              ))}
            </section>
          ))}

          {announced.length > 0 && (
            <section className="k-sched__day">
              <header className="k-sched__dayhead">
                <span>Announced</span>
                <span className="k-sched__daycount">{announced.length}</span>
              </header>
              {announced.map((e) => (
                <button
                  key={e.anilist_id}
                  type="button"
                  className="k-schedrow k-schedrow--announced"
                  onClick={() => navigate(`/anime/${e.anilist_id}`, { replace: true })}
                >
                  <AnimeCover
                    src={e.cover_url ?? undefined}
                    alt={title(e)}
                    decorative
                    radius="var(--radius-sm)"
                    className="k-schedrow__cover"
                  />
                  <div className="k-schedrow__main">
                    <Text size="base" weight={600} clamp={2}>
                      {title(e)}
                    </Text>
                    <span className="k-schedrow__ep">Release date to be announced</span>
                  </div>
                </button>
              ))}
            </section>
      )}
    </div>
  );
}
