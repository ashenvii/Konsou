import { create } from "zustand";
import { getUiState, setUiState } from "@/lib/uiState";

/**
 * The one place the Discover search state lives. The input renders on the
 * Discover page itself; keeping the query in a store (rather than page state)
 * lets any future surface read or drive it without threading props. `searching`
 * tracks whether the field is active, so Discover knows to show recents before
 * anything is typed. Mirrored into session uiState so it survives navigating
 * into a title and back.
 */
interface SearchState {
  query: string;
  searching: boolean;
  setQuery: (q: string) => void;
  setSearching: (b: boolean) => void;
}

export const useSearchStore = create<SearchState>((set) => ({
  query: getUiState("discover.query", ""),
  searching: false,
  setQuery: (q) => {
    setUiState("discover.query", q);
    set({ query: q });
  },
  setSearching: (b) => set({ searching: b }),
}));
