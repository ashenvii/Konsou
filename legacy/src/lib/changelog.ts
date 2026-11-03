import changelogRaw from "../../CHANGELOG.md?raw";
import { APP_VERSION } from "@/lib/version";

/**
 * The changelog is the single source of truth for "what changed": the
 * post-update What's New popup, the version history in About, and the
 * preview of a pending update all render from it.
 *
 * The file itself ships inside the bundle (?raw import), so the popup and the
 * history always work offline and always match the installed version exactly.
 * The only remote read is fetchRemoteChangelog(), used to show what a NEWER
 * version contains before the user has it; when that fails we just fall back
 * to the bundled copy.
 *
 * Format is Keep a Changelog: "## [X.Y.Z] - date" entries with "### Added /
 * Changed / Fixed" sections of "- item" bullets.
 */

export interface ChangelogSection {
  title: string;
  items: string[];
}

export interface ChangelogEntry {
  version: string;
  date: string | null;
  sections: ChangelogSection[];
}

const GITHUB_REPO =
  (import.meta.env.VITE_GITHUB_REPO as string | undefined) ?? "ashenvii/Konsou";

/** Strip the markdown we use in changelog bullets down to plain text with the
 *  bold lead intact. Links become their text; bold markers are preserved so
 *  the renderer can emphasize them. */
function cleanInline(text: string): string {
  return text
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1") // [text](url) -> text
    .replace(/\s+/g, " ")
    .trim();
}

/** Split a bullet on **bold** runs for rendering: even indexes are plain,
 *  odd indexes were bold. */
export function splitBold(text: string): string[] {
  return text.split(/\*\*/);
}

export function parseChangelog(markdown: string): ChangelogEntry[] {
  const entries: ChangelogEntry[] = [];
  let entry: ChangelogEntry | null = null;
  let section: ChangelogSection | null = null;

  for (const line of markdown.split(/\r?\n/)) {
    const version = line.match(/^## \[([^\]]+)\](?:\s*-\s*(\S+))?/);
    if (version) {
      section = null;
      if (version[1].toLowerCase() === "unreleased") {
        entry = null; // never show unshipped notes
        continue;
      }
      entry = { version: version[1], date: version[2] ?? null, sections: [] };
      entries.push(entry);
      continue;
    }

    const heading = line.match(/^### (.+)$/);
    if (heading && entry) {
      section = { title: heading[1].trim(), items: [] };
      entry.sections.push(section);
      continue;
    }

    const bullet = line.match(/^- (.+)$/);
    if (bullet && section) {
      section.items.push(cleanInline(bullet[1]));
      continue;
    }

    // Indented continuation of the previous bullet.
    if (/^\s{2,}\S/.test(line) && section && section.items.length > 0) {
      const last = section.items.length - 1;
      section.items[last] = cleanInline(`${section.items[last]} ${line.trim()}`);
    }
  }

  return entries;
}

let bundled: ChangelogEntry[] | null = null;

/** All released entries from the changelog shipped in this build, newest first. */
export function getBundledChangelog(): ChangelogEntry[] {
  if (!bundled) bundled = parseChangelog(changelogRaw);
  return bundled;
}

/** The bundled entry for the version currently running, if the changelog has one. */
export function getCurrentVersionEntry(): ChangelogEntry | null {
  return getBundledChangelog().find((e) => e.version === APP_VERSION) ?? null;
}

/** Pull the changelog from the repo's main branch: the only way to read notes
 *  for versions newer than this build. Throws on network failure; callers fall
 *  back to the bundled copy. */
export async function fetchRemoteChangelog(): Promise<ChangelogEntry[]> {
  const res = await fetch(
    `https://raw.githubusercontent.com/${GITHUB_REPO}/main/CHANGELOG.md`,
  );
  if (!res.ok) throw new Error(`changelog fetch failed: ${res.status}`);
  return parseChangelog(await res.text());
}

/** Numeric semver-ish compare: positive when a > b. Non-numeric parts tie. */
export function compareVersions(a: string, b: string): number {
  const pa = a.split(".").map((n) => parseInt(n, 10) || 0);
  const pb = b.split(".").map((n) => parseInt(n, 10) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d !== 0) return d;
  }
  return 0;
}

// ── Last-seen version (drives the post-update What's New popup) ────────────

const LAST_SEEN_KEY = "konsou.last_seen_version";

/**
 * Returns the entry to show in the What's New popup, or null when nothing
 * should show. First run records the current version silently — a fresh
 * install has no "what changed" story to tell. After an update (stored
 * version differs), the current version's notes are due.
 */
export function pendingWhatsNew(): ChangelogEntry | null {
  const seen = localStorage.getItem(LAST_SEEN_KEY);
  if (!seen) {
    localStorage.setItem(LAST_SEEN_KEY, APP_VERSION);
    return null;
  }
  if (seen === APP_VERSION) return null;
  const entry = getCurrentVersionEntry();
  // No notes for this version: nothing to show, but still advance the marker
  // so we do not re-check (and possibly mis-fire) on every boot.
  if (!entry) localStorage.setItem(LAST_SEEN_KEY, APP_VERSION);
  return entry;
}

/** Call when the user confirms the What's New popup (or when there is nothing
 *  to show for this version) so it never reappears for this version. */
export function markVersionSeen(): void {
  localStorage.setItem(LAST_SEEN_KEY, APP_VERSION);
}
