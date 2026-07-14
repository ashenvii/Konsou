import { useEffect, useRef, useState } from "react";
import type { KeyboardEvent as ReactKeyboardEvent } from "react";
import { RotateCw } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { PageHeader } from "@/components/layout/PageHeader";
import { EpisodesPanel } from "./Schedule";
import { SequelsPanel } from "./Alerts";
import { relativeTime } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";

type Segment = "episodes" | "sequels";

const SEGMENTS: { id: Segment; label: string }[] = [
  { id: "episodes", label: "Episodes" },
  { id: "sequels", label: "New sequels" },
];

/**
 * The Airing tab: Schedule and Alerts under one roof. Two segments a tap apart —
 * "Episodes" is a calendar of what's next from shows you already track, "New
 * sequels" is the radar's discoveries to add or dismiss. Opens on Episodes (the
 * everyday glance); the badge is what pulls you to the other side.
 */
export function Airing() {
  const [segment, setSegment] = useState<Segment>("episodes");
  const tabsRef = useRef<HTMLDivElement>(null);

  const items = useNotificationStore((s) => s.items);
  const checking = useNotificationStore((s) => s.checking);
  const progress = useNotificationStore((s) => s.progress);
  const lastCheckedAt = useNotificationStore((s) => s.lastCheckedAt);
  const markAllSeen = useNotificationStore((s) => s.markAllSeen);
  const refreshAll = useNotificationStore((s) => s.refreshAll);
  const entries = useListStore((s) => s.entries);

  const sequelCount = items.length;

  // Seen only counts once you actually look at the sequels. Viewing Episodes
  // leaves them unread, so the badge survives until the radar's had your eyes.
  useEffect(() => {
    if (segment === "sequels") void markAllSeen();
  }, [segment, markAllSeen]);

  // "checked 3h ago" / "checked just now" / "checked Oct 6": a radar you trust
  // says when it last swept. relativeTime falls back to a locale date for old
  // stamps, where "ago" would read wrong.
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

  const subtitle =
    segment === "episodes"
      ? "What's airing from your list"
      : checking
        ? progress && progress.total > 0
          ? `Scanning ${progress.done}/${progress.total}…`
          : "Scanning…"
        : checkedLabel
          ? `Sequel radar · ${checkedLabel}`
          : "Sequel radar";

  // Arrow keys walk the segments; the roving tab index keeps focus on the
  // active one so Tab lands there, not on the first control every time.
  const onKeyDown = (e: ReactKeyboardEvent) => {
    if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
    e.preventDefault();
    const dir = e.key === "ArrowRight" ? 1 : -1;
    const idx = SEGMENTS.findIndex((s) => s.id === segment);
    const next = SEGMENTS[(idx + dir + SEGMENTS.length) % SEGMENTS.length];
    setSegment(next.id);
    const btns = tabsRef.current?.querySelectorAll<HTMLButtonElement>("[role=tab]");
    btns?.[SEGMENTS.indexOf(next)]?.focus();
  };

  return (
    <div className="k-page">
      <PageHeader
        title="Airing"
        subtitle={subtitle}
        right={
          segment === "sequels" ? (
            <button
              type="button"
              className={`k-icon-btn${checking ? " k-icon-btn--spin" : ""}`}
              onClick={() => void refreshAll(entries)}
              aria-label="Check for new sequels"
              disabled={checking}
            >
              <Icon icon={RotateCw} size={18} />
            </button>
          ) : undefined
        }
      />

      <div
        className="k-airing__seg"
        role="tablist"
        aria-label="Airing view"
        ref={tabsRef}
        onKeyDown={onKeyDown}
      >
        <span
          className="k-airing__seg-thumb"
          style={{ transform: `translateX(${segment === "sequels" ? 100 : 0}%)` }}
          aria-hidden
        />
        {SEGMENTS.map((s) => {
          const active = s.id === segment;
          return (
            <button
              key={s.id}
              type="button"
              role="tab"
              aria-selected={active}
              tabIndex={active ? 0 : -1}
              className={`k-airing__seg-btn${active ? " k-airing__seg-btn--active" : ""}`}
              onClick={() => setSegment(s.id)}
            >
              {s.label}
              {s.id === "sequels" && sequelCount > 0 && (
                <span className="k-airing__seg-badge">{sequelCount > 9 ? "9+" : sequelCount}</span>
              )}
            </button>
          );
        })}
      </div>

      {segment === "episodes" ? <EpisodesPanel /> : <SequelsPanel />}
    </div>
  );
}
