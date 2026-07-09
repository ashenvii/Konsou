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
  request: CatchUpRequest | null;
  open: (req: CatchUpRequest) => void;
  close: () => void;
}

export const useCatchUpStore = create<CatchUpState>((set) => ({
  request: null,
  open: (request) => set({ request }),
  close: () => set({ request: null }),
}));
