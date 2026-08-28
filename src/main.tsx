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
import { syncManager } from "@/lib/sync/syncManager";
import { autoCheckAndDownload } from "@/lib/updater";
import { useUpdateStore } from "@/lib/store/updateStore";

import "./styles/tokens.css";
import "./styles/global.css";
import "./styles/ui.css";
import "./styles/anime.css";
import "./styles/list.css";
import "./styles/layout.css";
import "./styles/pages.css";
import "./styles/perf.css";
import { applyMotionMode } from "@/lib/motion";

// Backdrop blurs and glow shadows re-rasterize every scroll frame, and perf.css
// swaps them for static equivalents under `perf-lite`. That class used to be
// added here unconditionally, which meant no device could ever run the full
// build. It is a resolved tier now: this is the device-sniffed default, applied
// synchronously so the first paint is already correct, and settingsStore.load()
// replaces it a moment later with whatever the person actually chose.
applyMotionMode("system");

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
    // Check for app updates silently. Desktop downloads in the background so
    // the install is instant when it is asked for; Android can only be told
    // (no updater plugin there), so What's New links to the release instead.
    //
    // This used to raise a `duration: 0` toast, which is a banner sitting over
    // the app until it is dismissed and then gone for good — the two outcomes
    // were "in your way" and "never mentioned again". The fact goes into the
    // store now, the What's New door wears a dot for as long as it is true, and
    // the sentence opens itself a rationed few times (see updateStore).
    void autoCheckAndDownload((update) => {
      useUpdateStore.getState().found(update);
      useUpdateStore.getState().nudge();
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
