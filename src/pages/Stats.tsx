import { useMemo } from "react";
import { CircleCheck, Clock, Eye, Hourglass, Layers, Play, Star, Tv } from "lucide-react";
import type { CSSProperties, ReactNode } from "react";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { PageHeader } from "@/components/layout/PageHeader";
import { Text } from "@/components/ui/Text";
import type { IconComponent } from "@/components/ui/Icon";
import { statusMeta } from "@/components/anime/statusMeta";
import { groupEntries } from "@/lib/franchise/grouping";
import { listStatusLabel } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { LIST_STATUSES } from "@/types/list";
import type { ListStatus } from "@/types/list";

const MINUTES_PER_EP = 24;

function formatWatchTime(totalEpisodes: number): string {
  const min = totalEpisodes * MINUTES_PER_EP;
  const days = Math.floor(min / 1440);
  const hrs = Math.floor((min % 1440) / 60);
  if (days > 0) return `${days}d ${hrs}h`;
  const mins = min % 60;
  return hrs > 0 ? `${hrs}h ${mins}m` : `${mins}m`;
}

export function Stats() {
  const entries = useListStore((s) => s.entries);

  const s = useMemo(() => {
    const byStatus = {} as Record<ListStatus, number>;
    for (const st of LIST_STATUSES) byStatus[st] = 0;
    // scoreDist[n] = how many entries scored n (1..10).
    const scoreDist = new Array(11).fill(0) as number[];
    let episodes = 0;
    let scoreSum = 0;
    let rated = 0;
    let episodesLeft = 0;
    for (const e of entries) {
      byStatus[e.status]++;
      episodes += e.episodes_watched;
      if (e.score != null) {
        scoreSum += e.score;
        rated++;
        const bucket = Math.min(10, Math.max(1, Math.round(e.score)));
        scoreDist[bucket]++;
      }
      if (
        (e.status === "watching" || e.status === "rewatching") &&
        e.total_episodes != null
      ) {
        episodesLeft += Math.max(0, e.total_episodes - e.episodes_watched);
      }
    }
    return {
      total: entries.length,
      byStatus,
      episodes,
      rated,
      meanScore: rated > 0 ? scoreSum / rated : 0,
      series: groupEntries(entries).length,
      completed: byStatus.completed,
      watchingNow: byStatus.watching + byStatus.rewatching,
      episodesLeft,
      watchTime: formatWatchTime(episodes),
      scoreDist,
    };
  }, [entries]);

  if (entries.length === 0) {
    return (
      <div className="k-page">
        <PageHeader title="Stats" />
        <EmptyState
          icon={Tv}
          title="No stats yet"
          subtitle="Track a few anime and your watching history shows up here."
        />
      </div>
    );
  }

  const maxStatus = Math.max(...LIST_STATUSES.map((st) => s.byStatus[st]), 1);
  const maxScore = Math.max(...s.scoreDist.slice(1), 1);

  return (
    <div className="k-page">
      <PageHeader title="Stats" subtitle="Your watching at a glance" />
      <div className="k-stats konsou-scroll">
        <div className="k-stats__grid">
          <StatCard icon={Tv} label="Anime tracked" value={s.total} />
          <StatCard icon={Layers} label="Series" value={s.series} />
          <StatCard icon={Play} label="Episodes watched" value={s.episodes.toLocaleString()} />
          <StatCard icon={Clock} label="Time watched" value={s.watchTime} sub="~24 min / ep" />
          <StatCard icon={Eye} label="Watching now" value={s.watchingNow} />
          <StatCard
            icon={Hourglass}
            label="Episodes left"
            value={s.episodesLeft.toLocaleString()}
            sub="to catch up"
          />
          <StatCard icon={CircleCheck} label="Completed" value={s.completed} />
          <StatCard
            icon={Star}
            label="Mean score"
            value={s.rated > 0 ? s.meanScore.toFixed(1) : "0.0"}
            sub={`${s.rated} rated`}
            accent
          />
        </div>

        <section className="k-stats__section">
          <Text as="h2" size="xs" weight={700} color="tertiary" className="k-stats__heading">
            BY STATUS
          </Text>
          <ul className="k-stats__bars">
            {LIST_STATUSES.map((st) => {
              const meta = statusMeta(st);
              const count = s.byStatus[st];
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
                        } as CSSProperties
                      }
                    />
                  </span>
                  <span className="k-stats__barcount">{count}</span>
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
            <ul className="k-stats__bars">
              {Array.from({ length: 10 }, (_, i) => 10 - i).map((n) => {
                const count = s.scoreDist[n];
                return (
                  <li key={n} className="k-stats__barrow k-stats__barrow--score">
                    <span className="k-stats__barlabel k-stats__barlabel--score">
                      <Icon icon={Star} size={12} weight="fill" />
                      {n}
                    </span>
                    <span className="k-stats__bartrack">
                      <span
                        className="k-stats__barfill"
                        style={{
                          width: `${(count / maxScore) * 100}%`,
                          background: "var(--color-accent)",
                        }}
                      />
                    </span>
                    <span className="k-stats__barcount">{count}</span>
                  </li>
                );
              })}
            </ul>
          </section>
        )}
      </div>
    </div>
  );
}

function StatCard({
  icon,
  label,
  value,
  sub,
  accent,
}: {
  icon: IconComponent;
  label: string;
  value: ReactNode;
  sub?: string;
  accent?: boolean;
}) {
  return (
    <div className={`k-statcard${accent ? " k-statcard--accent" : ""}`}>
      <span className="k-statcard__icon">
        <Icon icon={icon} size={18} />
      </span>
      <span className="k-statcard__value">{value}</span>
      <span className="k-statcard__label">{label}</span>
      {sub && <span className="k-statcard__sub">{sub}</span>}
    </div>
  );
}
