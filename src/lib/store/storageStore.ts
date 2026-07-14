import { create } from "zustand";

/**
 * Tracks whether the local database initialized. When SQLite fails to open in a
 * packaged build (Trap: dev runs the web shim, so the real driver is only ever
 * exercised once installed), every DB-backed feature dies at once while
 * Discover keeps working off the network. Boot used to swallow that failure and
 * also skip auth restore, so the app looked signed out with an empty list and
 * no clue why. This holds the real error so the UI can show it plainly.
 */
interface StorageState {
  failed: boolean;
  error: string | null;
  reportFailure: (err: unknown) => void;
}

export const useStorageStore = create<StorageState>((set) => ({
  failed: false,
  error: null,
  reportFailure: (err) => {
    const message =
      err instanceof Error ? err.message : typeof err === "string" ? err : String(err);
    set({ failed: true, error: message });
  },
}));
