import { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { CircleCheck, Clock, Layers, Star, Tv, Play } from "lucide-react";
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
  const navigate = useNavigate();
  const entries = useListStore((s) => s.entries);

  const s = useMemo(() => {
    const byStatus = {} as Record<ListStatus, number>;
    for (const st of LIST_STATUSES) byStatus[st] = 0;
    let episodes = 0;
    let scoreSum = 0;
    let rated = 0;
    for (const e of entries) {
      byStatus[e.status]++;
      episodes += e.episodes_watched;
      if (e.score != null) {
        scoreSum += e.score;
        rated++;
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
      watchTime: formatWatchTime(episodes),
    };
  }, [entries]);

  if (entries.length === 0) {
    return (
      <div className="k-page">
        <PageHeader title="Stats" onBack={() => navigate(-1)} />
        <EmptyState
          icon={Tv}
          title="No stats yet"
          subtitle="Track a few anime and your watching history shows up here."
        />
      </div>
    );
  }

  const maxStatus = Math.max(...LIST_STATUSES.map((st) => s.byStatus[st]), 1);

  return (
    <div className="k-page">
      <PageHeader title="Stats" subtitle="Your watching at a glance" onBack={() => navigate(-1)} />
      <div className="k-stats konsou-scroll">
        <div className="k-stats__grid">
          <StatCard icon={Tv} label="Anime tracked" value={s.total} />
          <StatCard icon={Play} label="Episodes watched" value={s.episodes.toLocaleString()} />
          <StatCard icon={Clock} label="Time watched" value={s.watchTime} sub="~24 min / ep" />
          <StatCard icon={Layers} label="Series" value={s.series} />
          <StatCard
            icon={Star}
            label="Mean score"
            value={s.rated > 0 ? s.meanScore.toFixed(1) : "0.0"}
            sub={`${s.rated} rated`}
            accent
          />
          <StatCard icon={CircleCheck} label="Completed" value={s.completed} />
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
