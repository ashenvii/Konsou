import type { ListStatus } from "@/types/list";

/**
 * Returns the set of list statuses that are logically impossible given the
 * anime's current AniList airing status.
 *
 * NOT_YET_RELEASED: the anime hasn't started — you can plan it, hold it, or
 *   drop it (decided not to watch), but you can't be watching it or have
 *   completed it.
 *
 * All other states (RELEASING, FINISHED, HIATUS, CANCELLED, or unknown) allow
 * every status. A RELEASING anime can be marked completed — AniList's status
 * field can lag reality, and we'd rather trust the user than block them.
 */
export function getDisabledStatuses(
  airingStatus: string | null,
): Set<ListStatus> {
  if (airingStatus === "NOT_YET_RELEASED") {
    return new Set<ListStatus>(["watching", "rewatching", "completed"]);
  }
  return new Set<ListStatus>();
}
