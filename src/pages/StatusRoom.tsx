import { useMemo } from "react";
import { Navigate, useParams } from "react-router-dom";
import { ChevronLeft } from "lucide-react";
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
 * A dedicated status page ("room"). Reached from the My List overview by
 * tapping a band; pushed onto the My List tab's own back stack (any non-tab
 * path joins the current tab, so back returns to the overview). Each room
 * shows the franchise members whose status matches it — a series appears in
 * Watching for its airing season and in Completed for a finished one.
 */

interface RoomDef {
  title: string;
  /** Statuses this room collects. Watching folds rewatching in with it. */
  statuses: ListStatus[];
  /** The card language, mirroring this status's overview section so opening a
   *  room reads as more of the same surface, not a different place. */
  variant: RoomVariant;
}

const ROOMS: Record<string, RoomDef> = {
  watching: { title: "Watching", statuses: ["watching", "rewatching"], variant: "hero" },
  plan: { title: "Want to watch", statuses: ["plan_to_watch"], variant: "poster" },
  completed: { title: "Completed", statuses: ["completed"], variant: "shelf" },
};

export function StatusRoom() {
  const { status = "" } = useParams();
  const room = ROOMS[status];

  const entries = useListStore((s) => s.entries);
  const defaultView = useSettingsStore((s) => s.defaultView);

  // Filter to this room's statuses first, then group: a franchise resolves to
  // just the members that belong here (S2 in Watching, S1 in Completed).
  const groups = useMemo(() => {
    if (!room) return [];
    const wanted = new Set(room.statuses);
    const scoped = entries.filter((e) => wanted.has(e.status));
    const built = groupEntries(scoped);
    // Recency key differs by room: Completed sorts by when you FINISHED it (not
    // any later edit), so a re-scored title doesn't jump the queue. Plan uses
    // date-added until the persisted rank lands; Watching uses last-touched.
    const keyOf = (g: FranchiseGroup) => {
      if (status === "completed") {
        return Math.max(...g.entries.map((e) => e.completed_at ?? e.updated_at));
      }
      if (status === "plan") return g.sortAdded;
      return g.sortUpdated;
    };
    return [...built].sort((a, b) => keyOf(b) - keyOf(a));
  }, [entries, room, status]);

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
