import { create } from "zustand";
import { syncManager, type ReconcileStrategy } from "@/lib/sync/syncManager";
import { useListStore } from "./listStore";
import { toast } from "./toastStore";

/**
 * Drives the one-time "your device list and your Drive backup both have data"
 * prompt shown after sign-in. `authStore.connect()` opens it via {@link open};
 * the global <ReconcilePrompt /> overlay renders the choice and calls
 * {@link resolve}. The sheet is non-dismissable, so the user always lands on a
 * defined state — there is no silent cancel that could leave the list empty.
 */
interface ReconcileState {
  open: boolean;
  localCount: number;
  remoteCount: number;
  /** True while a chosen strategy is being applied (guards double-taps). */
  busy: boolean;
  show: (localCount: number, remoteCount: number) => void;
  resolve: (strategy: ReconcileStrategy) => Promise<void>;
}

export const useReconcileStore = create<ReconcileState>((set, get) => ({
  open: false,
  localCount: 0,
  remoteCount: 0,
  busy: false,

  show: (localCount, remoteCount) =>
    set({ open: true, localCount, remoteCount, busy: false }),

  resolve: async (strategy) => {
    if (get().busy) return;
    set({ busy: true });
    try {
      await syncManager.reconcile(strategy);
      await useListStore.getState().load();
      toast.success(
        strategy === "use_drive"
          ? "Loaded your list from Drive"
          : strategy === "use_local"
            ? "Replaced your Drive backup"
            : "Lists merged",
      );
      set({ open: false, busy: false });
    } catch {
      set({ busy: false });
      toast.error("Couldn't sync — please try again");
    }
  },
}));
