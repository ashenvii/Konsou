import { getCurrentWindow } from "@tauri-apps/api/window";
import { isTauri } from "./platform";
import { syncQueue } from "./sync/queue";
import { syncManager } from "./sync/syncManager";
import { useListStore } from "./store/listStore";

/**
 * Flush pending writes before Android suspends the app, and check Drive for
 * changes when returning to the foreground (Traps 5). No-op off Tauri.
 * Returns a cleanup function.
 */
export async function registerLifecycleHandlers(): Promise<() => void> {
  if (!isTauri()) return () => {};

  const appWindow = getCurrentWindow();

  const unBlur = await appWindow.listen("tauri://blur", () => {
    void syncQueue.flushNow();
  });
  const unFocus = await appWindow.listen("tauri://focus", () => {
    void syncManager.checkForUpdates().then((changed) => {
      if (changed) void useListStore.getState().load();
    });
  });

  return () => {
    unBlur();
    unFocus();
  };
}
