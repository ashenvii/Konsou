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

/** How the plan queue is arranged. */
type PlanSort = "manual" | "length" | "added";
const PLAN_SORTS: { key: PlanSort; label: string }[] = [
  { key: "manual", label: "My order" },
  { key: "length", label: "Shortest" },
  { key: "added", label: "Recently added" },
];

const isPaused = (g: FranchiseGroup) => g.displayEntry.status === "on_hold";

/** Total runtime of everything tracked under this card. AniList's duration is
 *  per-episode; 24 is the same fallback Stats uses when it's unknown. */
function totalMinutes(g: FranchiseGroup): number {
  return g.entries.reduce(
    (sum, e) => sum + (e.total_episodes ?? 0) * (e.episode_duration ?? 24),
    0,
  );
}

/** A franchise's place in the queue is its earliest-ranked member; never-ranked
 *  cards sort after the arranged ones. */
function planRankOf(g: FranchiseGroup): number {
  let min = Number.POSITIVE_INFINITY;
  for (const e of g.entries) {
    if (e.plan_rank != null && e.plan_rank < min) min = e.plan_rank;
  }
  return min;
}

export function StatusRoom() {
  const { status = "" } = useParams();
  const room = ROOMS[status];
  const isCompleted = status === "completed";
  const isPlan = status === "plan";

  const entries = useListStore((s) => s.entries);
  const reorderPlan = useListStore((s) => s.reorderPlan);
  const defaultView = useSettingsStore((s) => s.defaultView);
  const [showDropped, setShowDropped] = useState(false);
  const [planSort, setPlanSort] = useState<PlanSort>("manual");

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

    if (isPlan) {
      if (planSort === "length") {
        // Shortest first: the queue's job is helping you pick something you can
        // actually finish tonight.
        return [...built].sort((a, b) => totalMinutes(a) - totalMinutes(b));
      }
      if (planSort === "added") return [...built].sort((a, b) => b.sortAdded - a.sortAdded);
      return [...built].sort((a, b) => {
        const ra = planRankOf(a);
        const rb = planRankOf(b);
        if (ra !== rb) return ra - rb;
        return b.sortAdded - a.sortAdded;
      });
    }

    // Recency key differs by room: Completed sorts by when you FINISHED it (not
    // any later edit), so a re-scored title doesn't jump the queue. Watching
    // uses last-touched.
    const keyOf = (g: FranchiseGroup) =>
      isCompleted
        ? Math.max(...g.entries.map((e) => e.completed_at ?? e.updated_at))
        : g.sortUpdated;

    return [...built].sort((a, b) => {
      // Paused sinks below everything you're actually watching.
      if (status === "watching") {
        const paused = Number(isPaused(a)) - Number(isPaused(b));
        if (paused !== 0) return paused;
      }
      return keyOf(b) - keyOf(a);
    });
  }, [entries, room, status, isCompleted, isPlan, showDropped, planSort]);

  if (!room) return <Navigate to="/" replace />;

  /** Swap a card one slot, then rewrite the whole queue's ranks. Members of a
   *  franchise move together, so a grouped card never splits across the queue. */
  const onMove = (rootId: number, dir: -1 | 1) => {
    const idx = groups.findIndex((g) => g.rootId === rootId);
    const next = idx + dir;
    if (idx < 0 || next < 0 || next >= groups.length) return;
    const reordered = [...groups];
    [reordered[idx], reordered[next]] = [reordered[next], reordered[idx]];
    void reorderPlan(reordered.flatMap((g) => g.entries.map((e) => e.anilist_id)));
  };

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

        {isPlan && (
          <div className="k-roomhead__sorts" role="group" aria-label="Sort the queue">
            {PLAN_SORTS.map((s) => (
              <button
                key={s.key}
                type="button"
                className={`k-roomhead__chip${planSort === s.key ? " k-roomhead__chip--sel" : ""}`}
                onClick={() => setPlanSort(s.key)}
                aria-pressed={planSort === s.key}
              >
                {s.label}
              </button>
            ))}
          </div>
        )}

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
          // Reranking only means something while the queue is on your order.
          onMove={isPlan && planSort === "manual" ? onMove : undefined}
          restoreKey={`room.${status}.scroll`}
        />
      )}
    </div>
  );
}
