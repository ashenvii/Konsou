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
import { autoCheckAndDownload } from "@/lib/updater";
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
    // Refresh the list store if the pull merged anything, otherwise the merged
    // entries sit in the DB but never reach the already-hydrated UI store.
    void syncManager.checkForUpdates().then((changed) => {
      if (changed) void useListStore.getState().load();
    });
    // Flagship: drip-scan completed/dropped entries for continuations. Only the
    // seeds whose adaptive schedule is due are checked, at background priority,
    // so this never competes with the user's first searches. A periodic tick
    // keeps draining due seeds while the app stays open — spreading even a
    // multi-thousand-entry list across days instead of one startup burst.
    const scheduledScan = () =>
      void useNotificationStore
        .getState()
        .runScheduledScan(useListStore.getState().entries);
    scheduledScan();
    setInterval(scheduledScan, 15 * 60 * 1000);
    // Check for app updates silently; download in background; notify when ready to install.
    void autoCheckAndDownload((update) => {
      toast.action({
        message: `Konsou v${update.version} downloaded — ready to install`,
        actionLabel: "Update Now",
        duration: 0, // persist until dismissed
        onAction: () => void update.install(),
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
