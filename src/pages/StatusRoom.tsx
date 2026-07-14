import { useMemo } from "react";
import { Navigate, useParams } from "react-router-dom";
import { ChevronLeft } from "lucide-react";
import { FranchiseCollection } from "@/components/list/FranchiseCollection";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/EmptyState";
import { goBack } from "@/hooks/useAppBack";
import { groupEntries } from "@/lib/franchise/grouping";
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
}

const ROOMS: Record<string, RoomDef> = {
  watching: { title: "Watching", statuses: ["watching", "rewatching"] },
  plan: { title: "Want to watch", statuses: ["plan_to_watch"] },
  completed: { title: "Completed", statuses: ["completed"] },
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
    // Recent-first: last touched at the top. Plan's deliberate rank comes with
    // the persisted-order migration; date-added stands in until then.
    return [...built].sort((a, b) => b.sortUpdated - a.sortUpdated);
  }, [entries, room]);

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
          restoreKey={`room.${status}.scroll`}
        />
      )}
    </div>
  );
}
