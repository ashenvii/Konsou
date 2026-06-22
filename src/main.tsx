import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { App } from "./App";
import { getDb } from "@/lib/db";
import { useAuthStore } from "@/lib/store/authStore";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { syncManager } from "@/lib/sync/syncManager";
import { checkAndNotify } from "@/lib/updater";
import { openExternal } from "@/lib/openExternal";
import { toast } from "@/lib/store/toastStore";

import "./styles/tokens.css";
import "./styles/global.css";
import "./styles/ui.css";
import "./styles/anime.css";
import "./styles/list.css";
import "./styles/layout.css";
import "./styles/pages.css";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      networkMode: "offlineFirst",
      refetchOnWindowFocus: false,
      staleTime: 5 * 60 * 1000,
    },
  },
});

/** Initialize storage, hydrate stores, then kick off sequel detection. */
async function bootstrap(): Promise<void> {
  try {
    await getDb();
    await useSettingsStore.getState().load();
    await useListStore.getState().load();
    await useNotificationStore.getState().load();
    // Restore previously signed-in Google account from localStorage.
    useAuthStore.getState().restore();
    // Pull from Drive if signed in (non-blocking — failures are logged).
    void syncManager.checkForUpdates();
    // Flagship: scan completed/dropped entries for continuations (6h cooldown).
    void useNotificationStore
      .getState()
      .runDetection(useListStore.getState().entries);
    // Check for app updates silently in background (no-op if VITE_GITHUB_REPO not set).
    void checkAndNotify((info) => {
      toast.action({
        message: `Konsou v${info.version} is available`,
        actionLabel: "Download",
        duration: 10_000,
        onAction: () => void openExternal(info.url),
      });
    });
  } catch (err) {
    console.error("Konsou bootstrap failed:", err);
  }
}

void bootstrap();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </StrictMode>,
);
