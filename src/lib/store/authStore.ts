import { create } from "zustand";
import {
  signOutGoogle,
  startGoogleOAuth,
  restoreGoogleAccount,
} from "@/lib/auth/googleAuth";
import { syncManager } from "@/lib/sync/syncManager";
import { useListStore } from "./listStore";
import { useReconcileStore } from "./reconcileStore";
import { toast } from "./toastStore";
import type { GoogleAccount } from "@/lib/auth/googleAuth";

interface AuthState {
  account: GoogleAccount | null;
  connecting: boolean;
  /** Call once on app boot to reload a previously signed-in account. */
  restore: () => void;
  connect: () => Promise<void>;
  disconnect: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  account: null,
  connecting: false,

  restore: () => {
    const account = restoreGoogleAccount();
    if (account) set({ account });
  },

  connect: async () => {
    set({ connecting: true });
    try {
      const account = await startGoogleOAuth();
      set({ account });
      // Sign-in itself does not pull — without this the user's existing Drive
      // list never loads and the app comes up empty on a fresh device or after
      // a re-login. Probe both sides: if they conflict, prompt the user how to
      // reconcile; otherwise the safe action has already been applied.
      const plan = await syncManager.signInSync();
      if (plan.promptNeeded) {
        useReconcileStore.getState().show(plan.localCount, plan.remoteCount);
      } else {
        await useListStore.getState().load();
      }
    } catch (e) {
      toast.show(
        e instanceof Error ? e.message : "Sign-in failed",
        "default",
      );
    } finally {
      set({ connecting: false });
    }
  },

  disconnect: async () => {
    await signOutGoogle();
    set({ account: null });
  },
}));
