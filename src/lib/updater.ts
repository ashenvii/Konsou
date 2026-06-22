/**
 * Lightweight update checker using the GitHub releases API.
 * No signing keys or tauri-plugin-updater required — just fetch.
 *
 * Set VITE_GITHUB_REPO=owner/repo in your .env to enable.
 * When a newer tag is found, returns the release info so the caller
 * can show a toast / prompt. Actual download opens the release page
 * in the browser.
 */

const GITHUB_REPO = import.meta.env.VITE_GITHUB_REPO as string | undefined;
export const APP_VERSION = "0.1.0";

export interface ReleaseInfo {
  version: string;
  url: string;
  notes: string | null;
}

/** Compare semver strings. Returns true if `a` is newer than `b`. */
function isNewer(a: string, b: string): boolean {
  const parse = (v: string) => v.replace(/^v/, "").split(".").map(Number);
  const [aMaj, aMin, aPatch] = parse(a);
  const [bMaj, bMin, bPatch] = parse(b);
  if (aMaj !== bMaj) return aMaj > bMaj;
  if (aMin !== bMin) return aMin > bMin;
  return aPatch > bPatch;
}

/**
 * Check GitHub for a newer release.
 * Returns the release info if an update is available, null otherwise.
 * Silently swallows network/parse errors — update checks must never break the app.
 */
export async function checkForUpdate(): Promise<ReleaseInfo | null> {
  if (!GITHUB_REPO) return null;
  try {
    const res = await fetch(
      `https://api.github.com/repos/${GITHUB_REPO}/releases/latest`,
      { headers: { Accept: "application/vnd.github+json" } },
    );
    if (!res.ok) return null;
    const data = await res.json() as {
      tag_name?: string;
      html_url?: string;
      body?: string;
    };
    const latest = data.tag_name?.replace(/^v/, "");
    if (!latest || !isNewer(latest, APP_VERSION)) return null;
    return {
      version: latest,
      url: data.html_url ?? `https://github.com/${GITHUB_REPO}/releases`,
      notes: data.body?.split("\n")[0] ?? null,
    };
  } catch {
    return null;
  }
}

/** Manually trigger a check and open the release page if an update exists. */
export async function checkAndNotify(
  onUpdate: (info: ReleaseInfo) => void,
): Promise<void> {
  const info = await checkForUpdate();
  if (info) onUpdate(info);
}
