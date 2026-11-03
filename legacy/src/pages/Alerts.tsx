import { useEffect, useMemo, useState } from "react";
import type { CSSProperties } from "react";
import { useNavigate } from "react-router-dom";
import {
  Bell,
  BookmarkPlus,
  ChevronDown,
  EyeOff,
  MoreHorizontal,
  Play,
  X,
} from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { toast } from "@/lib/store/toastStore";
import { alertBucket } from "@/lib/sequel/detector";
import { formatFuzzyDate, preferredTitle, timeUntil } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AlertBucket, KonsouNotification } from "@/types/notification";

// "Upcoming", not "Announced": the Episodes segment already uses Announced for
// tracked titles waiting on a date. This bucket is untracked suggestions that
// haven't aired yet — a different thing deserves a different word.
//
// tone is the CSS var the bucket paints its countdown and header dot with.
// Airing = live blue, Upcoming = future amber, Already Aired = quiet grey.
const BUCKET_ORDER: { id: AlertBucket; label: string; tone: string }[] = [
  { id: "airing_now", label: "Airing Now", tone: "var(--color-status-watching)" },
  { id: "announced", label: "Upcoming", tone: "var(--color-status-plan_to_watch)" },
  { id: "already_aired", label: "Already Aired", tone: "var(--ink-label)" },
];

const REL_LABEL: Record<string, string> = {
  sequel: "Sequel",
  side_story: "Side story",
  spin_off: "Spin-off",
  movie: "Movie",
};

/** Minute-granular ticker: countdowns re-read the clock once a minute so
 *  "next ep in 2h 14m" stays honest without a per-second render storm. */
function useMinuteTick(): void {
  const [, force] = useState(0);
  useEffect(() => {
    const id = window.setInterval(() => force((n) => n + 1), 60_000);
    return () => window.clearInterval(id);
  }, []);
}

/** Strip the leading "in " so timeUntil reads as a compact pill body. */
function compactUntil(airingAtSeconds: number): string {
  return timeUntil(airingAtSeconds).replace(/^in /, "");
}

interface AirLine {
  /** True only while a show is actively airing — drives the live pulse dot. */
  live: boolean;
  /** Small context word on the hero's countdown rail ("next ep" / "airing"). */
  label: string;
  /** The big token on the hero rail ("44m", "2h 13m", "now"). */
  value: string;
  /** The full phrase used by the compact pill ("airs in 4d 23h", "date TBA"). */
  pill: string;
}

function airLine(n: KonsouNotification, bucket: AlertBucket): AirLine {
  const now = Math.floor(Date.now() / 1000);

  if (bucket === "airing_now") {
    if (n.airing_at && n.airing_at > now) {
      const v = compactUntil(n.airing_at);
      return { live: true, label: "next ep", value: v, pill: `next ep ${v}` };
    }
    return { live: true, label: "airing", value: "now", pill: "airing now" };
  }

  if (bucket === "announced") {
    if (n.airing_at && n.airing_at > now) {
      const v = compactUntil(n.airing_at);
      return { live: false, label: "airs in", value: v, pill: `airs in ${v}` };
    }
    const d = n.airing_at
      ? formatFuzzyDate({
          year: new Date(n.airing_at * 1000).getFullYear(),
          month: new Date(n.airing_at * 1000).getMonth() + 1,
          day: new Date(n.airing_at * 1000).getDate(),
        })
      : null;
    return d
      ? { live: false, label: "airs", value: d, pill: `airs ${d}` }
      : { live: false, label: "premiere", value: "TBA", pill: "date TBA" };
  }

  // already_aired — quiet, past tense.
  return { live: false, label: "", value: "aired", pill: "already aired" };
}

/** The secondary line: how this suggestion connects to what you finished. */
function relationLine(n: KonsouNotification, sourceTitle: string): string {
  const kind = REL_LABEL[n.type] ?? "Related";
  return `${kind} of ${sourceTitle}`;
}

interface AlertCardProps {
  n: KonsouNotification;
  bucket: AlertBucket;
  tone: string;
  variant: "hero" | "compact";
}

function AlertCard({ n, bucket, tone, variant }: AlertCardProps) {
  const navigate = useNavigate();
  const sourceEntry = useListStore((s) => s.map[n.source_id]);
  const addFromSummary = useListStore((s) => s.addFromSummary);
  const dismissRelated = useNotificationStore((s) => s.dismissRelated);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const [menuOpen, setMenuOpen] = useState(false);

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

  const open = () => navigate(`/anime/${n.related_id}`, { replace: true });

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

  const dismiss = () => void dismissRelated([n.related_id]);

  const air = airLine(n, bucket);
  const rel = relationLine(n, sourceTitle);

  // Primary action is context-aware: you can't "watch" what hasn't aired, so
  // Upcoming leads with Plan; everything airing or aired leads with Watching.
  const primaryStatus: "watching" | "plan_to_watch" =
    bucket === "announced" ? "plan_to_watch" : "watching";
  const altStatus: "watching" | "plan_to_watch" =
    primaryStatus === "watching" ? "plan_to_watch" : "watching";
  const primaryLabel = primaryStatus === "watching" ? "Watching" : "Plan to watch";
  const PrimaryIcon = primaryStatus === "watching" ? Play : BookmarkPlus;

  return (
    <article
      className={`k-alert k-alert--${variant}`}
      style={{ "--alert-tone": tone } as CSSProperties}
    >
      <button
        className="k-alert__cover"
        onClick={open}
        aria-label={`Open ${n.related_title}`}
      >
        <AnimeCover src={n.related_cover} alt={n.related_title} decorative radius="var(--radius-md)" />
      </button>

      <div className="k-alert__body">
        <button type="button" className="k-alert__titlebtn" onClick={open}>
          <Text size={variant === "hero" ? "lg" : "base"} weight={700} clamp={2}>
            {n.related_title}
          </Text>
        </button>

        <Text size="xs" color="secondary" clamp={1}>
          {rel}
        </Text>

        <div className="k-alert__actions">
          <button
            type="button"
            className="k-alert__primary"
            onClick={() => add(primaryStatus)}
          >
            <Icon icon={PrimaryIcon} size={15} strokeWidth={2.4} fill={PrimaryIcon === Play} />
            {primaryLabel}
          </button>
          <button
            type="button"
            className="k-alert__more"
            onClick={() => setMenuOpen(true)}
            aria-label={`More actions for ${n.related_title}`}
          >
            <Icon icon={MoreHorizontal} size={18} />
          </button>
        </div>
      </div>

      {variant === "hero" ? (
        <div className="k-alert__countdown" aria-label={air.pill}>
          <span className="k-alert__countdown-label">
            {air.live && <span className="k-alert__pulse" aria-hidden />}
            {air.label}
          </span>
          <span className="k-alert__countdown-value">{air.value}</span>
        </div>
      ) : (
        <div className="k-alert__pillrail">
          <span className={`k-alert__pill${air.live ? " k-alert__pill--live" : ""}`}>
            {air.live && <span className="k-alert__pulse" aria-hidden />}
            {air.pill}
          </span>
        </div>
      )}

      <BottomSheet open={menuOpen} onClose={() => setMenuOpen(false)} title={n.related_title}>
        <div className="k-alertmenu">
          <button
            type="button"
            className="k-alertmenu__row"
            onClick={() => {
              add(altStatus);
              setMenuOpen(false);
            }}
          >
            <Icon
              icon={altStatus === "watching" ? Play : BookmarkPlus}
              size={20}
              color="var(--ink-meta)"
              fill={altStatus === "watching"}
            />
            {altStatus === "watching" ? "Add to Watching" : "Add to Plan to watch"}
          </button>
          <button
            type="button"
            className="k-alertmenu__row"
            onClick={() => {
              markNotInterested();
              setMenuOpen(false);
            }}
          >
            <Icon icon={EyeOff} size={20} color="var(--ink-meta)" />
            Not interested
          </button>
          <button
            type="button"
            className="k-alertmenu__row k-alertmenu__row--muted"
            onClick={() => {
              dismiss();
              setMenuOpen(false);
            }}
          >
            <Icon icon={X} size={20} color="var(--ink-label)" />
            Dismiss
          </button>
        </div>
      </BottomSheet>
    </article>
  );
}

/** Soonest upcoming air time first, then most recently aired, then no-date. */
function byUrgency(a: KonsouNotification, b: KonsouNotification): number {
  const now = Math.floor(Date.now() / 1000);
  const rank = (n: KonsouNotification): [number, number] => {
    if (n.airing_at == null) return [2, 0];
    return n.airing_at >= now ? [0, n.airing_at - now] : [1, now - n.airing_at];
  };
  const [ga, va] = rank(a);
  const [gb, vb] = rank(b);
  return ga !== gb ? ga - gb : va - vb;
}

/**
 * The New sequels segment of the Airing tab: continuations the radar found for
 * shows you finished, grouped by release state and sorted by urgency. The
 * Airing shell owns the page header, the scan refresh, and marking these seen,
 * so this renders content only.
 */
export function SequelsPanel() {
  const items = useNotificationStore((s) => s.items);
  const dismissRelated = useNotificationStore((s) => s.dismissRelated);
  const listMap = useListStore((s) => s.map);
  const [collapsed, setCollapsed] = useState<Set<AlertBucket>>(new Set());

  useMinuteTick();

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

  if (visible.length === 0) {
    return (
      <EmptyState
        icon={Bell}
        title="You're all caught up"
        subtitle="Finish a show and the radar watches for its sequels, so you hear it here first."
        showTip
      />
    );
  }

  return (
    <div className="k-alerts konsou-scroll">
      {BUCKET_ORDER.map(({ id, label, tone }) => {
        const list = groups[id];
        if (list.length === 0) return null;
        const isCollapsed = collapsed.has(id);
        const variant = id === "airing_now" ? "hero" : "compact";
        return (
          <section key={id} className="k-alertgroup">
            <div className="k-alertgroup__header">
              <button
                className="k-alertgroup__toggle"
                onClick={() => toggle(id)}
                aria-expanded={!isCollapsed}
              >
                <span className="k-alertgroup__label">
                  <span
                    className="k-alertgroup__dot"
                    style={{ background: tone }}
                    aria-hidden
                  />
                  {label}
                  <span className="k-alertgroup__count">{list.length}</span>
                </span>
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
            {!isCollapsed && (
              <div className={`k-alertlist k-alertlist--${variant}`}>
                {list.map((n) => (
                  <AlertCard
                    key={n.related_id}
                    n={n}
                    bucket={id}
                    tone={tone}
                    variant={variant}
                  />
                ))}
              </div>
            )}
          </section>
        );
      })}
    </div>
  );
}
