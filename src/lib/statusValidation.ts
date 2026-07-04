import type { ListStatus } from "@/types/list";

/**
 * Returns the set of list statuses that are logically impossible given the
 * anime's current AniList airing status.
 *
 * NOT_YET_RELEASED: the anime hasn't started — you can plan it, hold it, or
 *   drop it (decided not to watch), but you can't be watching it or have
 *   completed it.
 *
 * RELEASING: episodes are still coming out, so "completed" is impossible.
 *   (AniList's status can lag a finale by a little; the tradeoff is accepted —
 *   accidental completes of airing shows were a real reported problem.)
 *
 * FINISHED, HIATUS, CANCELLED, or unknown allow every status.
 */
export function getDisabledStatuses(
  airingStatus: string | null,
): Set<ListStatus> {
  if (airingStatus === "NOT_YET_RELEASED") {
    return new Set<ListStatus>(["watching", "rewatching", "completed"]);
  }
  if (airingStatus === "RELEASING") {
    return new Set<ListStatus>(["completed"]);
  }
  return new Set<ListStatus>();
}

/** Human explanation for why a status is blocked, or null if it isn't. */
export function statusBlockReason(
  airingStatus: string | null,
  status: ListStatus,
): string | null {
  if (!getDisabledStatuses(airingStatus).has(status)) return null;
  return airingStatus === "NOT_YET_RELEASED"
    ? "This show hasn't aired yet — plan it, put it on hold, or drop it."
    : "This show is still airing, so it can't be marked completed.";
}
