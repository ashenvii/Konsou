import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Bell, ChevronDown, RotateCw } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { PageHeader } from "@/components/layout/PageHeader";
import { Text } from "@/components/ui/Text";
import { toast } from "@/lib/store/toastStore";
import { alertBucket } from "@/lib/sequel/detector";
import { formatFuzzyDate, preferredTitle, timeUntil } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AlertBucket, KonsouNotification } from "@/types/notification";

const BUCKET_ORDER: { id: AlertBucket; label: string }[] = [
  { id: "airing_now", label: "Airing Now" },
  { id: "announced", label: "Announced" },
  { id: "already_aired", label: "Already Aired" },
];

function statusLine(n: KonsouNotification): string {
  if (n.type === "started_airing") {
    return n.airing_at
      ? `Now airing · estimated finish ${timeUntil(n.airing_at)}`
      : "Now airing";
  }
  if (n.related_status === "RELEASING")
    return n.airing_at ? `Airing now · next ${timeUntil(n.airing_at)}` : "Airing now";
  if (n.related_status === "NOT_YET_RELEASED") {
    const d = n.airing_at
      ? formatFuzzyDate({
          year: new Date(n.airing_at * 1000).getFullYear(),
          month: new Date(n.airing_at * 1000).getMonth() + 1,
          day: new Date(n.airing_at * 1000).getDate(),
        })
      : null;
    return d ? `Announced · ${d}` : "Announced · date TBD";
  }
  return "Already aired — you may have missed it";
}

function AlertCard({ n }: { n: KonsouNotification }) {
  const navigate = useNavigate();
  const sourceEntry = useListStore((s) => s.map[n.source_id]);
  const addFromSummary = useListStore((s) => s.addFromSummary);
  const dismiss = useNotificationStore((s) => s.dismiss);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const sourceTitle = sourceEntry
    ? preferredTitle(
        {
          romaji: sourceEntry.title_romaji,
          english: sourceEntry.title_english,
          native: sourceEntry.title_native,
        },
        titleLanguage,
      )
    : "a completed anime";

  const add = (status: "watching" | "plan_to_watch") => {
    addFromSummary(
      {
        id: n.related_id,
        title: { romaji: n.related_title },
        coverImage: { large: n.related_cover ?? undefined },
        episodes: null,
      },
      status,
    );
    if (n.id != null) void dismiss(n.id);
    toast.success(status === "watching" ? "Added to Watching" : "Added to Plan to Watch");
  };

  return (
    <div className="k-alert">
      <button
        className="k-alert__cover"
        onClick={() => navigate(`/anime/${n.related_id}`)}
        aria-label={`Open ${n.related_title}`}
      >
        <AnimeCover src={n.related_cover} alt={n.related_title} decorative />
      </button>
      <div className="k-alert__body">
        <Text size="base" weight={600} clamp={2}>
          {n.related_title}
        </Text>
        <Text size="xs" color="secondary" clamp={1}>
          {n.type === "started_airing"
            ? "In your plan-to-watch"
            : `${n.type.replace(/_/g, " ")} of ${sourceTitle}`}
        </Text>
        <Text size="xs" color="tertiary">
          {statusLine(n)}
        </Text>
        <div className="k-alert__actions">
          {n.type !== "started_airing" && (
            <>
              <Button size="sm" variant="primary" onClick={() => add("watching")}>
                Watching
              </Button>
              <Button size="sm" variant="secondary" onClick={() => add("plan_to_watch")}>
                Plan
              </Button>
            </>
          )}
          {n.type === "started_airing" && (
            <Button
              size="sm"
              variant="primary"
              onClick={() => {
                navigate(`/anime/${n.related_id}`);
              }}
            >
              View
            </Button>
          )}
          <Button
            size="sm"
            variant="ghost"
            onClick={() => {
              if (n.id != null) void dismiss(n.id);
            }}
          >
            Dismiss
          </Button>
        </div>
      </div>
    </div>
  );
}

export function Alerts() {
  const items = useNotificationStore((s) => s.items);
  const checking = useNotificationStore((s) => s.checking);
  const progress = useNotificationStore((s) => s.progress);
  const markAllSeen = useNotificationStore((s) => s.markAllSeen);
  const refreshAll = useNotificationStore((s) => s.refreshAll);
  const entries = useListStore((s) => s.entries);
  const [collapsed, setCollapsed] = useState<Set<AlertBucket>>(new Set());

  useEffect(() => {
    void markAllSeen();
  }, [markAllSeen]);

  const groups = useMemo(() => {
    const map: Record<AlertBucket, KonsouNotification[]> = {
      airing_now: [],
      announced: [],
      already_aired: [],
    };
    for (const n of items) map[alertBucket(n)].push(n);
    return map;
  }, [items]);

  const toggle = (b: AlertBucket) =>
    setCollapsed((s) => {
      const next = new Set(s);
      if (next.has(b)) next.delete(b);
      else next.add(b);
      return next;
    });

  return (
    <div className="k-page">
      <PageHeader
        title="Alerts"
        subtitle={
          checking
            ? progress && progress.total > 0
              ? `Scanning ${progress.done}/${progress.total}…`
              : "Scanning…"
            : "Sequel radar"
        }
        right={
          <button
            type="button"
            className={`k-icon-btn${checking ? " k-icon-btn--spin" : ""}`}
            onClick={() => void refreshAll(entries)}
            aria-label="Check for new sequels"
            disabled={checking}
          >
            <Icon icon={RotateCw} size={18} />
          </button>
        }
      />

      {items.length === 0 ? (
        <EmptyState
          icon={Bell}
          title="You're all caught up"
          subtitle="We'll alert you when something related to your completed anime is announced."
        />
      ) : (
        <div className="k-alerts konsou-scroll">
          {BUCKET_ORDER.map(({ id, label }) => {
            const list = groups[id];
            if (list.length === 0) return null;
            const isCollapsed = collapsed.has(id);
            return (
              <section key={id} className="k-alertgroup">
                <button
                  className="k-alertgroup__header"
                  onClick={() => toggle(id)}
                  aria-expanded={!isCollapsed}
                >
                  <Text size="sm" weight={600} color="secondary">
                    {label} · {list.length}
                  </Text>
                  <span
                    className="k-alertgroup__chevron"
                    style={{ transform: isCollapsed ? "rotate(-90deg)" : "none" }}
                  >
                    <Icon icon={ChevronDown} size={16} />
                  </span>
                </button>
                {!isCollapsed &&
                  list.map((n) => <AlertCard key={n.related_id} n={n} />)}
              </section>
            );
          })}
        </div>
      )}
    </div>
  );
}
