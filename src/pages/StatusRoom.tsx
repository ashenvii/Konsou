import { useMemo, useState } from "react";
import { Navigate, useParams } from "react-router-dom";
import { ChevronLeft, X } from "lucide-react";
import { FranchiseCollection } from "@/components/list/FranchiseCollection";
import type { RoomVariant } from "@/components/list/FranchiseCollection";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/EmptyState";
import { goBack } from "@/hooks/useAppBack";
import { groupEntries } from "@/lib/franchise/grouping";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { ListStatus } from "@/types/list";

/**
 * A dedicated status page ("room"). Reached from the overview by tapping a
 * section; pushed onto the My List tab's own back stack, so back returns to the
 * overview. Each room shows the franchise members whose status matches it and
 * renders its section's card language, so drilling in reads as more of the same
 * surface.
 *
 * The minor statuses live here rather than getting rooms of their own: Watching
 * carries Paused (on-hold) at the bottom, Completed offers Dropped as a filter.
 */

interface RoomDef {
  title: string;
  /** Statuses this room collects. Watching folds rewatching and on-hold in. */
  statuses: ListStatus[];
  variant: RoomVariant;
}

const ROOMS: Record<string, RoomDef> = {
  watching: {
    title: "Watching",
    statuses: ["watching", "rewatching", "on_hold"],
    variant: "hero",
  },
  plan: { title: "Want to watch", statuses: ["plan_to_watch"], variant: "poster" },
  completed: { title: "Completed", statuses: ["completed"], variant: "shelf" },
};

const isPaused = (g: FranchiseGroup) => g.displayEntry.status === "on_hold";

export function StatusRoom() {
  const { status = "" } = useParams();
  const room = ROOMS[status];
  const isCompleted = status === "completed";

  const entries = useListStore((s) => s.entries);
  const defaultView = useSettingsStore((s) => s.defaultView);
  const [showDropped, setShowDropped] = useState(false);

  // Dropped is part of your record, not a place of its own: it hides behind a
  // filter in Completed, where the "have I dealt with this?" answer lives.
  const droppedCount = useMemo(
    () => (isCompleted ? entries.filter((e) => e.status === "dropped").length : 0),
    [entries, isCompleted],
  );

  const groups = useMemo(() => {
    if (!room) return [];
    const wanted = new Set<ListStatus>(room.statuses);
    if (isCompleted && showDropped) wanted.add("dropped");
    const scoped = entries.filter((e) => wanted.has(e.status));
    const built = groupEntries(scoped);

    // Recency key differs by room: Completed sorts by when you FINISHED it (not
    // any later edit), so a re-scored title doesn't jump the queue. Plan uses
    // date-added until the persisted rank lands; Watching uses last-touched.
    const keyOf = (g: FranchiseGroup) => {
      if (isCompleted) {
        return Math.max(...g.entries.map((e) => e.completed_at ?? e.updated_at));
      }
      if (status === "plan") return g.sortAdded;
      return g.sortUpdated;
    };
    return [...built].sort((a, b) => {
      // Paused sinks below everything you're actually watching.
      if (status === "watching") {
        const paused = Number(isPaused(a)) - Number(isPaused(b));
        if (paused !== 0) return paused;
      }
      return keyOf(b) - keyOf(a);
    });
  }, [entries, room, status, isCompleted, showDropped]);

  if (!room) return <Navigate to="/" replace />;

  return (
    <div className="k-page">
      <div className="k-roomhead">
        <button
          type="button"
          className="k-roomhead__back"
          onClick={goBack}
          aria-label="Back to My List"
        >
          <Icon icon={ChevronLeft} size={22} />
        </button>
        <h1 className="k-roomhead__title">{room.title}</h1>
        <span className="k-roomhead__count">{groups.length}</span>

        {isCompleted && droppedCount > 0 && (
          <button
            type="button"
            className={`k-roomhead__chip${showDropped ? " k-roomhead__chip--on" : ""}`}
            onClick={() => setShowDropped((v) => !v)}
            aria-pressed={showDropped}
          >
            <Icon icon={X} size={13} />
            Dropped {droppedCount}
          </button>
        )}
      </div>

      {groups.length === 0 ? (
        <EmptyState
          title={`Nothing ${room.title.toLowerCase()} yet`}
          subtitle="Add something from Discover and it lands here."
        />
      ) : (
        <FranchiseCollection
          groups={groups}
          view={defaultView}
          variant={room.variant}
          restoreKey={`room.${status}.scroll`}
        />
      )}
    </div>
  );
}
