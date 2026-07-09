import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ChevronRight, Film, Sparkles, Star, Tv } from "lucide-react";
import type { CSSProperties } from "react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { PageHeader } from "@/components/layout/PageHeader";
import { Text } from "@/components/ui/Text";
import { statusMeta } from "@/components/anime/statusMeta";
import { WrappedSheet } from "@/components/stats/WrappedSheet";
import { groupEntries } from "@/lib/franchise/grouping";
import { dailyFact } from "@/lib/trivia";
import { wrappedYears } from "@/lib/wrapped";
import { getCoverUrl, listStatusLabel, preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { LIST_STATUSES } from "@/types/list";
import type { ListStatus } from "@/types/list";

const MINUTES_PER_EP = 24;

interface TimeSegment {
  value: string;
  unit: string;
}

/** "1y 134d 6h" style segments for the hero figure; largest two or three
 *  units only, so the number stays readable at a glance. */
function timeSegments(totalMinutes: number): TimeSegment[] {
  const mins = Math.max(0, Math.round(totalMinutes));
  const years = Math.floor(mins / 525600);
  const days = Math.floor((mins % 525600) / 1440);
  const hours = Math.floor((mins % 1440) / 60);
  const minutes = mins % 60;
  if (years > 0) {
    return [
      { value: String(years), unit: years === 1 ? "year" : "years" },
      { value: String(days), unit: "days" },
      { value: String(hours), unit: "hrs" },
    ];
  }
  if (days > 0) {
    return [
      { value: String(days), unit: days === 1 ? "day" : "days" },
      { value: String(hours), unit: "hrs" },
    ];
  }
  if (hours > 0) {
    return [
      { value: String(hours), unit: hours === 1 ? "hour" : "hrs" },
      { value: String(minutes), unit: "min" },
    ];
  }
  return [{ value: String(minutes), unit: "min" }];
}

export function Stats() {
  const entries = useListStore((s) => s.entries);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const navigate = useNavigate();
  const [wrappedOpen, setWrappedOpen] = useState(false);
  const latestWrappedYear = useMemo(() => wrappedYears(entries)[0] ?? null, [entries]);

  const s = useMemo(() => {
    const byStatus = {} as Record<ListStatus, number>;
    for (const st of LIST_STATUSES) byStatus[st] = 0;
    // scoreDist[n] = how many entries scored n (1..10).
    const scoreDist = new Array(11).fill(0) as number[];

    // Episodes seen including completed rewatches, and real minutes: each
    // rewatch replays the full run, each episode counts at the show's own
    // length where known (movies stop being 24-minute fictions).
    const effectiveEpisodes = (e: (typeof entries)[number]) =>
      e.episodes_watched + (e.rewatch_count ?? 0) * (e.total_episodes ?? 0);
    const entryMinutes = (e: (typeof entries)[number]) =>
      effectiveEpisodes(e) * (e.episode_duration ?? MINUTES_PER_EP);

    let episodes = 0;
    let minutes = 0;
    let hasRealDurations = false;
    let scoreSum = 0;
    let rated = 0;
    let episodesLeft = 0;
    for (const e of entries) {
      byStatus[e.status]++;
      episodes += effectiveEpisodes(e);
      minutes += entryMinutes(e);
      if (e.episode_duration != null) hasRealDurations = true;
      if (e.score != null) {
        scoreSum += e.score;
        rated++;
        const bucket = Math.min(10, Math.max(1, Math.round(e.score)));
        scoreDist[bucket]++;
      }
      if (e.status === "watching" || e.status === "rewatching") {
        // Count against what can actually be watched: the aired count where
        // known (capped by the planned total), else the planned total.
        const target =
          e.aired_episodes != null
            ? e.total_episodes != null
              ? Math.min(e.aired_episodes, e.total_episodes)
              : e.aired_episodes
            : e.total_episodes;
        if (target != null) {
          episodesLeft += Math.max(0, target - e.episodes_watched);
        }
      }
    }
    const groups = groupEntries(entries);
    const topFranchises = [...groups]
      .map((g) => ({
        group: g,
        minutes: g.entries.reduce((m, e) => m + entryMinutes(e), 0),
      }))
      .filter((x) => x.minutes > 0)
      .sort((a, b) => b.minutes - a.minutes)
      .slice(0, 3);
    const finishedOrDropped = byStatus.completed + byStatus.dropped;
    return {
      total: entries.length,
      byStatus,
      episodes,
      rated,
      meanScore: rated > 0 ? scoreSum / rated : 0,
      series: groups.length,
      completed: byStatus.completed,
      watchingNow: byStatus.watching + byStatus.rewatching,
      episodesLeft,
      minutes,
      hasRealDurations,
      hours: Math.round(minutes / 60),
      movies: Math.round(minutes / 120),
      finishRate:
        finishedOrDropped > 0
          ? Math.round((byStatus.completed / finishedOrDropped) * 100)
          : null,
      scoreDist,
      topFranchises,
    };
  }, [entries]);

  if (entries.length === 0) {
    return (
      <div className="k-page">
        <PageHeader title="Stats" />
        <EmptyState
          icon={Tv}
          title="Nothing to crunch yet"
          subtitle="Add a few shows and your watch history takes shape here."
          showTip
        />
      </div>
    );
  }

  const maxStatus = Math.max(...LIST_STATUSES.map((st) => s.byStatus[st]), 1);
  const maxScore = Math.max(...s.scoreDist.slice(1), 1);
  const segments = timeSegments(s.minutes);
  const fact = dailyFact();

  return (
    <div className="k-page">
      <PageHeader title="Stats" subtitle="Your watching at a glance" />
      <div className="k-stats konsou-scroll">
        {/* The headline fact: how much of your life this actually is. */}
        <section className="k-stats__hero" aria-label="Total time watched">
          <div className="k-stats__time">
            {segments.map((seg) => (
              <span key={seg.unit} className="k-stats__seg">
                <span className="k-stats__segnum">{seg.value}</span>
                <span className="k-stats__segunit">{seg.unit}</span>
              </span>
            ))}
            <span className="k-stats__timetail">of your life in anime</span>
          </div>
          <p className="k-stats__lede">
            {s.episodes.toLocaleString()} episodes across {s.series.toLocaleString()} anime
            {s.total > s.series ? ` (${s.total.toLocaleString()} seasons)` : ""}, roughly{" "}
            {s.hours.toLocaleString()} hours.
          </p>
          <div className="k-stats__equiv">
            <span className="k-stats__equivchip">
              <Icon icon={Film} size={12} />
              like {s.movies.toLocaleString()} movies back to back
            </span>
            <span className="k-stats__equivchip k-stats__equivchip--dim">
              {s.hasRealDurations
                ? `real episode lengths, ~${MINUTES_PER_EP} min where unknown`
                : `at ~${MINUTES_PER_EP} min per episode`}
            </span>
          </div>
        </section>

        {/* The now: what's active and what it costs to catch up. */}
        <div className="k-stats__pulse">
          <div className="k-stats__pulseitem">
            <span className="k-stats__pulsenum">{s.watchingNow}</span>
            <span className="k-stats__pulselabel">Watching now</span>
          </div>
          <div className="k-stats__pulseitem">
            <span className="k-stats__pulsenum">
              {s.episodesLeft.toLocaleString()}
            </span>
            {/* "Left", not "catch up": the count runs to each show's planned
                end, so it can include episodes that haven't aired yet. */}
            <span className="k-stats__pulselabel">Episodes left</span>
          </div>
          {s.finishRate != null && (
            <div className="k-stats__pulseitem">
              <span className="k-stats__pulsenum">{s.finishRate}%</span>
              <span className="k-stats__pulselabel">Finish what you start</span>
            </div>
          )}
          <div className="k-stats__pulseitem">
            <span className="k-stats__pulsenum">
              {s.rated > 0 ? s.meanScore.toFixed(1) : "–"}
            </span>
            <span className="k-stats__pulselabel">
              {s.rated > 0 ? `Mean score, ${s.rated} rated` : "Nothing rated yet"}
            </span>
          </div>
        </div>

        <section className="k-stats__section">
          <Text as="h2" size="xs" weight={700} color="tertiary" className="k-stats__heading">
            BY STATUS
          </Text>
          <ul className="k-stats__bars">
            {LIST_STATUSES.map((st, i) => {
              const meta = statusMeta(st);
              const count = s.byStatus[st];
              const share = s.total > 0 ? Math.round((count / s.total) * 100) : 0;
              return (
                <li key={st} className="k-stats__barrow">
                  <span className="k-stats__barlabel" style={{ color: meta.color }}>
                    <Icon icon={meta.icon} size={14} weight="fill" />
                    {listStatusLabel(st)}
                  </span>
                  <span className="k-stats__bartrack">
                    <span
                      className="k-stats__barfill"
                      style={
                        {
                          width: `${(count / maxStatus) * 100}%`,
                          background: meta.color,
                          "--i": i,
                        } as CSSProperties
                      }
                    />
                  </span>
                  <span className="k-stats__barcount">
                    {count}
                    <span className="k-stats__barshare">{share}%</span>
                  </span>
                </li>
              );
            })}
          </ul>
        </section>

        {s.rated > 0 && (
          <section className="k-stats__section">
            <Text as="h2" size="xs" weight={700} color="tertiary" className="k-stats__heading">
              SCORE DISTRIBUTION
            </Text>
            <div
              className="k-stats__hist"
              role="img"
              aria-label={`Score distribution for ${s.rated} rated titles, mean score ${s.meanScore.toFixed(1)}`}
            >
              {Array.from({ length: 10 }, (_, i) => i + 1).map((n, i) => {
                const count = s.scoreDist[n];
                const peak = count === maxScore && count > 0;
                return (
                  <div key={n} className="k-stats__histcol">
                    <span className="k-stats__histtrack">
                      <span className="k-stats__histcount">
                        {count > 0 ? count : ""}
                      </span>
                      <span
                        className={`k-stats__histbar${peak ? " k-stats__histbar--peak" : ""}`}
                        style={
                          {
                            height: `${Math.max((count / maxScore) * 100, 2)}%`,
                            "--i": i,
                          } as CSSProperties
                        }
                      />
                    </span>
                    <span className="k-stats__histlabel">{n}</span>
                  </div>
                );
              })}
            </div>
            <Text size="xs" color="tertiary" className="k-stats__histmean">
              <Icon icon={Star} size={11} fill /> mean {s.meanScore.toFixed(1)} from{" "}
              {s.rated} rated
            </Text>
          </section>
        )}

        {s.topFranchises.length > 0 && (
          <section className="k-stats__section">
            <Text as="h2" size="xs" weight={700} color="tertiary" className="k-stats__heading">
              MOST WATCHED
            </Text>
            <ol className="k-stats__top">
              {s.topFranchises.map(({ group: g, minutes }, i) => {
                const e = g.displayEntry;
                const title = preferredTitle(
                  {
                    romaji: e.title_romaji,
                    english: e.title_english,
                    native: e.title_native,
                  },
                  titleLanguage,
                );
                const hours = Math.round(minutes / 60);
                const metaBits = [
                  `${g.totalWatched.toLocaleString()} eps`,
                  `${hours.toLocaleString()}h`,
                  g.isGroup ? `${g.entries.length} entries` : null,
                ].filter(Boolean);
                return (
                  <li key={g.rootId}>
                    <button
                      type="button"
                      className="k-stats__toprow"
                      onClick={() =>
                        navigate(`/anime/${e.anilist_id}`, { replace: true })
                      }
                    >
                      <span className="k-stats__toprank">{i + 1}</span>
                      <span className="k-stats__topcover">
                        <AnimeCover
                          src={getCoverUrl({ large: e.cover_url ?? undefined })}
                          alt={title}
                          decorative
                          radius="var(--radius-sm)"
                        />
                      </span>
                      <span className="k-stats__topbody">
                        <Text size="sm" weight={600} clamp={1}>
                          {title}
                        </Text>
                        <Text size="xs" color="tertiary">
                          {metaBits.join(" · ")}
                        </Text>
                      </span>
                    </button>
                  </li>
                );
              })}
            </ol>
          </section>
        )}

        {latestWrappedYear != null && (
          <button
            type="button"
            className="k-stats__wrappedbtn"
            onClick={() => setWrappedOpen(true)}
          >
            <span className="k-stats__wrappedicon">
              <Icon icon={Sparkles} size={16} />
            </span>
            <span className="k-stats__wrappedtext">
              <strong>Your {latestWrappedYear}, wrapped</strong>
              <span>The year in finishes, as a shareable card</span>
            </span>
            <Icon icon={ChevronRight} size={16} />
          </button>
        )}

        <footer className="k-stats__trivia">
          <span className="k-stats__triviaglyph" aria-hidden>
            {fact.glyph ?? "✧"}
          </span>
          <p className="k-stats__triviatext">
            <span className="k-stats__trivialabel">Did you know</span>
            {fact.text}
          </p>
        </footer>
      </div>

      <WrappedSheet
        open={wrappedOpen}
        onClose={() => setWrappedOpen(false)}
        entries={entries}
      />
    </div>
  );
}
