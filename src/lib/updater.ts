import { check } from "@tauri-apps/plugin-updater";
import { relaunch } from "@tauri-apps/plugin-process";
import { isTauri } from "@/lib/platform";

// Re-exported so existing imports (Sidebar, Settings) keep working.
export { APP_VERSION } from "@/lib/version";

export interface PendingUpdate {
  version: string;
  install: () => Promise<void>;
}

// Held after download so repeated checks return immediately
let pending: PendingUpdate | null = null;

/**
 * Check GitHub for a newer release, download it silently, return it when ready.
 * Throws on network/API errors so callers can surface them in UI if needed.
 * Returns null if already up to date.
 */
export async function checkForUpdate(): Promise<PendingUpdate | null> {
  if (pending) return pending;
  if (!isTauri()) return null;

  const update = await check();
  if (!update?.available) return null;

  // Download silently in the background, no progress UI
  await update.download();

  pending = {
    version: update.version,
    install: async () => {
      await update.install();
      await relaunch();
    },
  };

  return pending;
}

/**
 * Called once on startup. Silently checks and downloads any update, then calls
 * onReady so the caller can show a "ready to install" notification.
 * Swallows all errors; update checks must never crash the app.
 */
export async function autoCheckAndDownload(
  onReady: (update: PendingUpdate) => void,
): Promise<void> {
  try {
    const u = await checkForUpdate();
    if (u) onReady(u);
  } catch {
    // Silent
  }
}
