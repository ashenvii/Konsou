import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { App } from "./App";
import { getDb } from "@/lib/db";
import { useAuthStore } from "@/lib/store/authStore";
import { useCompletionStore } from "@/lib/store/completionStore";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { useStorageStore } from "@/lib/store/storageStore";
import { openExternal } from "@/lib/openExternal";
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
import "./styles/perf.css";

// Backdrop blurs and glow shadows re-rasterize every scroll frame; that paint
// cost stole frames from the scroll on desktop WebViews too, not just phone
// GPUs. perf.css swaps them for static, near-identical equivalents under this
// class — applied everywhere now, since the win outweighs the flourish.
document.documentElement.classList.add("perf-lite");

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
  // Auth lives in localStorage, not the DB. Restore it first and on its own so a
  // storage failure can never masquerade as a signed-out account.
  try {
    useAuthStore.getState().restore();
  } catch (err) {
    console.error("Konsou auth restore failed:", err);
  }

  // Open the database. If this throws (real SQLite only runs in a packaged
  // build), record it so the UI can show the actual reason, and stop here —
  // the DB-backed stores below would only throw the same error again.
  try {
    await getDb();
  } catch (err) {
    console.error("Konsou storage init failed:", err);
    useStorageStore.getState().reportFailure(err);
    return;
  }

  try {
    await useSettingsStore.getState().load();
    await useListStore.getState().load();
    await useNotificationStore.getState().load();
    // The completion ledger backs the Completed room and the Stats hours. It
    // loads after the list because nothing on the first paint needs it.
    void useCompletionStore.getState().load();
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
    // Check for app updates silently. Desktop downloads in the background and
    // offers the install; Android can only be told (no updater plugin there),
    // so it links to the release instead.
    void autoCheckAndDownload((update) => {
      if (update.kind === "install") {
        toast.action({
          message: `Konsou v${update.version} downloaded, ready to install`,
          actionLabel: "Update Now",
          duration: 0, // persist until dismissed
          onAction: () => void update.install(),
        });
      } else {
        toast.action({
          message: `Konsou v${update.version} is available`,
          actionLabel: "View",
          duration: 0,
          onAction: () => void openExternal(update.releaseUrl),
        });
      }
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
