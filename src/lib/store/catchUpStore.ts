import { create } from "zustand";
import type { RelationNode } from "@/types/anime";

/**
 * A pending "what have you already watched?" prompt. Raised when a user adds a
 * later season of a franchise whose earlier entries aren't tracked yet, so the
 * app can ask what they actually finished instead of silently marking every
 * prior season/movie/OVA as completed.
 */
export interface CatchUpRequest {
  /** Franchise root the primary add resolved to. */
  rootId: number;
  /** Title of the season the user just added, for the prompt copy. */
  primaryTitle: string;
  /** Prior chain entries not yet tracked — the tickable candidates. */
  candidates: RelationNode[];
}

interface CatchUpState {
  /**
   * Pending prompts, oldest first. A queue (not a single slot) because the add
   * that raises a prompt resolves on a background chain walk: fire off two adds
   * quickly and the second used to land while the first was still resolving,
   * overwriting a prompt the user never saw. Each add now lines up and waits
   * its turn, so nothing gets lost to a race.
   */
  queue: CatchUpRequest[];
  enqueue: (req: CatchUpRequest) => void;
  /** Dismiss the current prompt (Skip/Mark) and surface the next one, if any. */
  close: () => void;
}

export const useCatchUpStore = create<CatchUpState>((set) => ({
  queue: [],
  enqueue: (req) =>
    set((s) => {
      const at = s.queue.findIndex((r) => r.rootId === req.rootId);
      if (at === -1) return { queue: [...s.queue, req] };
      // Same franchise already waiting (added two seasons of it in a row): fold
      // the new candidates into the queued prompt instead of stacking a second
      // one for the same series.
      const queue = s.queue.map((r, i) => {
        if (i !== at) return r;
        const seen = new Set(r.candidates.map((c) => c.id));
        const extra = req.candidates.filter((c) => !seen.has(c.id));
        return extra.length ? { ...r, candidates: [...r.candidates, ...extra] } : r;
      });
      return { queue };
    }),
  close: () => set((s) => ({ queue: s.queue.slice(1) })),
}));
