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
import { formatFuzzyDate, preferredTitle, relativeTime, timeUntil } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AlertBucket, KonsouNotification } from "@/types/notification";

// "Upcoming", not "Announced": Schedule already uses Announced for tracked
// titles waiting on a date. This bucket is untracked suggestions that haven't
// aired yet — a different thing deserves a different word.
const BUCKET_ORDER: { id: AlertBucket; label: string }[] = [
  { id: "airing_now", label: "Airing Now" },
  { id: "announced", label: "Upcoming" },
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
    return d ? `Not aired yet · airs ${d}` : "Not aired yet · date TBD";
  }
  return "Already aired, you may have missed it";
}

/** Soonest upcoming air time first, then most recently aired, then no-date. */
function byUrgency(a: KonsouNotification, b: KonsouNotification): number {
  const now = Math.floor(Date.now() / 1000);
  const rank = (n: KonsouNotification): [number, number] => {
    if (n.airing_at == null) return [2, 0];
    return n.airing_at >= now
      ? [0, n.airing_at - now]
      : [1, now - n.airing_at];
  };
  const [ga, va] = rank(a);
  const [gb, vb] = rank(b);
  return ga !== gb ? ga - gb : va - vb;
}

function AlertCard({ n }: { n: KonsouNotification }) {
  const navigate = useNavigate();
  const sourceEntry = useListStore((s) => s.map[n.source_id]);
  const addFromSummary = useListStore((s) => s.addFromSummary);
  const dismissRelated = useNotificationStore((s) => s.dismissRelated);
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
    void dismissRelated([n.related_id]);
    toast.success(status === "watching" ? "Added to Watching" : "Added to Plan to Watch");
  };

  // "Not interested" parks the title on the list as not_interested. Because it
  // now counts as tracked, the radar's later scans skip it, so this exact
  // suggestion never resurfaces.
  const markNotInterested = () => {
    addFromSummary(
      {
        id: n.related_id,
        title: { romaji: n.related_title },
        coverImage: { large: n.related_cover ?? undefined },
        episodes: null,
      },
      "not_interested",
    );
    void dismissRelated([n.related_id]);
    toast.success("Won't suggest this again");
  };

  return (
    <div className="k-alert">
      <button
        className="k-alert__cover"
        onClick={() => navigate(`/anime/${n.related_id}`, { replace: true })}
        aria-label={`Open ${n.related_title}`}
      >
        <AnimeCover src={n.related_cover} alt={n.related_title} decorative />
      </button>
      <div className="k-alert__body">
        <button
          type="button"
          className="k-alert__titlebtn"
          onClick={() => navigate(`/anime/${n.related_id}`, { replace: true })}
        >
          <Text size="base" weight={600} clamp={2}>
            {n.related_title}
          </Text>
        </button>
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
              <Button size="sm" variant="ghost" onClick={markNotInterested}>
                Not interested
              </Button>
            </>
          )}
          {n.type === "started_airing" && (
            <Button
              size="sm"
              variant="primary"
              onClick={() => {
                navigate(`/anime/${n.related_id}`, { replace: true });
              }}
            >
              View
            </Button>
          )}
          <Button
            size="sm"
            variant="ghost"
            onClick={() => void dismissRelated([n.related_id])}
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
  const lastCheckedAt = useNotificationStore((s) => s.lastCheckedAt);
  const markAllSeen = useNotificationStore((s) => s.markAllSeen);
  const refreshAll = useNotificationStore((s) => s.refreshAll);
  const dismissRelated = useNotificationStore((s) => s.dismissRelated);
  const entries = useListStore((s) => s.entries);
  const listMap = useListStore((s) => s.map);
  const [collapsed, setCollapsed] = useState<Set<AlertBucket>>(new Set());

  useEffect(() => {
    void markAllSeen();
  }, [markAllSeen]);

  // A title the user tagged "not interested" should never be recommended
  // again — hide any alert pointing at one, even if it was inserted earlier.
  const visible = useMemo(
    () => items.filter((n) => listMap[n.related_id]?.status !== "not_interested"),
    [items, listMap],
  );

  const groups = useMemo(() => {
    const map: Record<AlertBucket, KonsouNotification[]> = {
      airing_now: [],
      announced: [],
      already_aired: [],
    };
    for (const n of visible) map[alertBucket(n)].push(n);
    // The thing airing in two hours belongs above the one airing in five
    // days, no matter which scan found it first. Already Aired keeps the
    // newest-discovery-first order it arrives in.
    map.airing_now.sort(byUrgency);
    map.announced.sort(byUrgency);
    return map;
  }, [visible]);

  const toggle = (b: AlertBucket) =>
    setCollapsed((s) => {
      const next = new Set(s);
      if (next.has(b)) next.delete(b);
      else next.add(b);
      return next;
    });

  // "checked 3h ago" / "checked just now" / "checked Oct 6": a radar you
  // trust says when it last swept. relativeTime falls back to a locale date
  // for old stamps, where "ago" would read wrong.
  let checkedLabel: string | null = null;
  if (lastCheckedAt != null) {
    const rel = relativeTime(lastCheckedAt);
    checkedLabel =
      rel === "just now"
        ? "checked just now"
        : /^\d+[mhdw]$/.test(rel)
          ? `checked ${rel} ago`
          : `checked ${rel}`;
  }

  return (
    <div className="k-page">
      <PageHeader
        title="Alerts"
        subtitle={
          checking
            ? progress && progress.total > 0
              ? `Scanning ${progress.done}/${progress.total}…`
              : "Scanning…"
            : checkedLabel
              ? `Sequel radar · ${checkedLabel}`
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

      {visible.length === 0 ? (
        <EmptyState
          icon={Bell}
          title="You're all caught up"
          subtitle="Finish a show and the radar watches for its sequels, so you hear it here first."
          showTip
        />
      ) : (
        <div className="k-alerts konsou-scroll">
          {BUCKET_ORDER.map(({ id, label }) => {
            const list = groups[id];
            if (list.length === 0) return null;
            const isCollapsed = collapsed.has(id);
            return (
              <section key={id} className="k-alertgroup">
                <div className="k-alertgroup__header">
                  <button
                    className="k-alertgroup__toggle"
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
                  <button
                    className="k-alertgroup__clear"
                    onClick={() => {
                      void dismissRelated(list.map((n) => n.related_id));
                      toast.show(
                        `Cleared ${list.length} alert${list.length === 1 ? "" : "s"}`,
                      );
                    }}
                    aria-label={`Clear all ${label} alerts`}
                  >
                    Clear all
                  </button>
                </div>
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
