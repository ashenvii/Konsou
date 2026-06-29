import { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { CalendarClock, Clock } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { PageHeader } from "@/components/layout/PageHeader";
import { Skeleton } from "@/components/ui/Skeleton";
import { Text } from "@/components/ui/Text";
import { useAiringSchedule } from "@/hooks/useAniList";
import { preferredTitle, timeUntil } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AnimeListEntry } from "@/types/list";

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

export function Schedule() {
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

  const { data: airing, isLoading, isError } = useAiringSchedule(ids);

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
      <div className="k-page">
        <PageHeader title="Schedule" subtitle="What's airing from your list" />
        <div className="k-sched konsou-scroll">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} height={72} radius="var(--radius-lg)" style={{ marginBottom: 8 }} />
          ))}
        </div>
      </div>
    );
  }

  const hasContent = days.length > 0 || announced.length > 0;

  return (
    <div className="k-page">
      <PageHeader
        title="Schedule"
        subtitle={
          isError
            ? "Showing what we last knew"
            : "What's airing from your list"
        }
      />

      {!hasContent ? (
        <EmptyState
          icon={CalendarClock}
          title="Nothing on the calendar"
          subtitle="When something you're watching or plan to watch is airing, its next episodes show up here."
        />
      ) : (
        <div className="k-sched konsou-scroll">
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
                  onClick={() => navigate(`/anime/${it.entry.anilist_id}`)}
                >
                  <AnimeCover
                    src={it.entry.cover_url ?? undefined}
                    alt={title(it.entry)}
                    decorative
                    radius="var(--radius-sm)"
                    className="k-schedrow__cover"
                  />
                  <div className="k-schedrow__main">
                    <Text size="base" weight={600} clamp={1}>
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
                  onClick={() => navigate(`/anime/${e.anilist_id}`)}
                >
                  <AnimeCover
                    src={e.cover_url ?? undefined}
                    alt={title(e)}
                    decorative
                    radius="var(--radius-sm)"
                    className="k-schedrow__cover"
                  />
                  <div className="k-schedrow__main">
                    <Text size="base" weight={600} clamp={1}>
                      {title(e)}
                    </Text>
                    <span className="k-schedrow__ep">Release date to be announced</span>
                  </div>
                </button>
              ))}
            </section>
          )}
        </div>
      )}
    </div>
  );
}
