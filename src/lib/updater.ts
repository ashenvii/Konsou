import { check } from "@tauri-apps/plugin-updater";
import { relaunch } from "@tauri-apps/plugin-process";
import { compareVersions } from "@/lib/changelog";
import { isAndroidUA, isTauri } from "@/lib/platform";
import { APP_VERSION } from "@/lib/version";

// Re-exported so existing imports (Sidebar, Settings) keep working.
export { APP_VERSION } from "@/lib/version";

const GITHUB_REPO =
  (import.meta.env.VITE_GITHUB_REPO as string | undefined) ?? "ashenvii/Konsou";

/** Desktop: downloaded and ready, install() applies and relaunches. */
export interface PendingUpdate {
  kind: "install";
  version: string;
  install: () => Promise<void>;
}

/** Mobile: a newer release exists; we can only tell the user and point at it.
 *  The updater plugin has no Android implementation, so no auto-update yet. */
export interface AvailableUpdate {
  kind: "notify";
  version: string;
  releaseUrl: string;
}

export type UpdateResult = PendingUpdate | AvailableUpdate | null;

// Held after a successful check so repeated checks return immediately.
let pending: UpdateResult = null;

/**
 * Android has no updater plugin, but the desktop updater's own manifest
 * (latest.json on the latest GitHub release) is a plain static file with the
 * version in it — so mobile reads that same single source of truth and
 * compares against the running build.
 */
async function checkMobile(): Promise<AvailableUpdate | null> {
  const res = await fetch(
    `https://github.com/${GITHUB_REPO}/releases/latest/download/latest.json`,
  );
  if (!res.ok) throw new Error(`update manifest fetch failed: ${res.status}`);
  const manifest = (await res.json()) as { version?: string };
  if (!manifest.version) return null;
  if (compareVersions(manifest.version, APP_VERSION) <= 0) return null;
  return {
    kind: "notify",
    version: manifest.version,
    releaseUrl: `https://github.com/${GITHUB_REPO}/releases/latest`,
  };
}

/** Desktop: check GitHub, download silently, hand back an installer. */
async function checkDesktop(): Promise<PendingUpdate | null> {
  const update = await check();
  if (!update?.available) return null;

  // Download silently in the background, no progress UI
  await update.download();

  return {
    kind: "install",
    version: update.version,
    install: async () => {
      await update.install();
      await relaunch();
    },
  };
}

/**
 * Check for a newer release. Desktop resolves to an installable update,
 * Android to a notification-only result, web preview to null. Throws on
 * network/API errors so callers can surface them in UI if needed.
 * Returns null if already up to date.
 */
export async function checkForUpdate(): Promise<UpdateResult> {
  if (pending) return pending;
  if (!isTauri()) return null;

  pending = isAndroidUA() ? await checkMobile() : await checkDesktop();
  return pending;
}

/**
 * Called once on startup. Silently checks (and on desktop downloads) any
 * update, then calls onReady so the caller can notify.
 * Swallows all errors; update checks must never crash the app.
 */
export async function autoCheckAndDownload(
  onReady: (update: PendingUpdate | AvailableUpdate) => void,
): Promise<void> {
  try {
    const u = await checkForUpdate();
    if (u) onReady(u);
  } catch {
    // Silent
  }
}
