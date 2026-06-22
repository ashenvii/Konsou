/** Feature flags. Unfinished features merge dark and flip on via env. */

const flags = {
  ANILIST_SYNC: import.meta.env.VITE_FF_ANILIST_SYNC === "true",
  DRIVE_SYNC: import.meta.env.VITE_FF_DRIVE_SYNC !== "false",
  EXTENDED_STATS: import.meta.env.VITE_FF_EXTENDED_STATS === "true",
  // Discover ships in v1.2 per the roadmap but the page is built; default on in dev.
  DISCOVER: import.meta.env.VITE_FF_DISCOVER !== "false",
  // Sequel radar / Alerts — the flagship. On by default.
  SEQUEL_RADAR: import.meta.env.VITE_FF_SEQUEL_RADAR !== "false",
} as const;

export type FeatureFlag = keyof typeof flags;

export function isEnabled(flag: FeatureFlag): boolean {
  return flags[flag];
}
