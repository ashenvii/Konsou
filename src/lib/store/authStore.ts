import { create } from "zustand";
import {
  signOutGoogle,
  startGoogleOAuth,
  restoreGoogleAccount,
} from "@/lib/auth/googleAuth";
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
