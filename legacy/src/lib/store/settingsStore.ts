import { create } from "zustand";
import { getDb } from "@/lib/db";
import { applyMotionMode, normalizeMotionMode } from "@/lib/motion";
import type {
  ColorTheme,
  MotionMode,
  SidebarMode,
  SortSpec,
  TitleLanguage,
  ViewMode,
} from "@/types/list";

const RECENT_SEARCH_LIMIT = 5;

/**
 * The eight Field Guide plates and the two Night Market prototypes all
 * collapse onto the two real worlds. Anyone who has run this app before has
 * one of the old keys sitting in their settings row, so it is migrated on
 * read rather than left to fall through to a default and silently reset a
 * choice they made.
 */
const THEME_MIGRATION: Record<string, ColorTheme> = {
  market: "lantern",
  marketneon: "neon",
  // The Field Guide plates split by temperature: the warm grounds land on
  // Lantern, the cold ones on Neon. Nobody gets moved to a world that reads
  // nothing like the one they picked.
  ember: "lantern",
  forest: "lantern",
  crimson: "lantern",
  paper: "lantern",
  ash: "lantern",
  void: "neon",
  ocean: "neon",
  midnight: "neon",
};

function normalizeColorTheme(raw: string | undefined): ColorTheme {
  if (raw === "lantern" || raw === "neon") return raw;
  if (raw && raw in THEME_MIGRATION) return THEME_MIGRATION[raw];
  return "lantern";
}

interface SettingsState {
  loaded: boolean;
  colorTheme: ColorTheme;
  defaultView: ViewMode;
  defaultSort: SortSpec;
  titleLanguage: TitleLanguage;
  sequelNotifications: boolean;
  telemetry: boolean;
  recentSearches: string[];
  devMode: boolean;
  sidebarMode: SidebarMode;
  motionMode: MotionMode;

  load: () => Promise<void>;
  setColorTheme: (t: ColorTheme) => void;
  setDefaultView: (v: ViewMode) => void;
  setDefaultSort: (s: SortSpec) => void;
  setTitleLanguage: (l: TitleLanguage) => void;
  setSequelNotifications: (on: boolean) => void;
  setTelemetry: (on: boolean) => void;
  addRecentSearch: (q: string) => void;
  removeRecentSearch: (q: string) => void;
  enableDevMode: () => void;
  setSidebarMode: (m: SidebarMode) => void;
  setMotionMode: (m: MotionMode) => void;
}

function applyColorTheme(theme: ColorTheme): void {
  document.documentElement.setAttribute("data-theme", theme);
}

/** Validate the persisted sidebar mode, migrating the old "always-open" value. */
function normalizeSidebarMode(raw: string | undefined): SidebarMode {
  if (raw === "rail" || raw === "hover" || raw === "expanded") return raw;
  if (raw === "always-open") return "expanded";
  return "hover";
}

async function persist(key: string, value: string): Promise<void> {
  try {
    const db = await getDb();
    await db.settingsSet(key, value);
  } catch {
    /* settings are best-effort; never block the UI */
  }
}

export const useSettingsStore = create<SettingsState>((set, get) => ({
  loaded: false,
  colorTheme: "lantern",
  defaultView: "grid",
  defaultSort: { key: "updated", order: "desc" },
  titleLanguage: "romaji",
  sequelNotifications: true,
  telemetry: true,
  recentSearches: [],
  devMode: false,
  sidebarMode: "hover",
  motionMode: "system",

  load: async () => {
    const db = await getDb();
    const s = await db.settingsGetAll();
    const colorTheme = normalizeColorTheme(s.color_theme);
    applyColorTheme(colorTheme);
    /* main.tsx already stamped the device-sniffed default so the first
       paint was right; this is where a stored choice takes over. */
    const motionMode = normalizeMotionMode(s.motion_mode);
    applyMotionMode(motionMode);
    set({
      loaded: true,
      colorTheme,
      defaultView: (s.default_view as ViewMode) ?? "grid",
      defaultSort: s.default_sort
        ? (JSON.parse(s.default_sort) as SortSpec)
        : { key: "updated", order: "desc" },
      titleLanguage: (s.title_language as TitleLanguage) ?? "romaji",
      sequelNotifications: s.sequel_notifications !== "false",
      telemetry: s.telemetry !== "false",
      recentSearches: s.recent_searches
        ? (JSON.parse(s.recent_searches) as string[])
        : [],
      sidebarMode: normalizeSidebarMode(s.sidebar_mode),
      motionMode,
    });
  },

  /** A world owns its own two hues, so picking one is the whole choice. */
  setColorTheme: (colorTheme) => {
    applyColorTheme(colorTheme);
    set({ colorTheme });
    void persist("color_theme", colorTheme);
  },
  setDefaultView: (defaultView) => {
    set({ defaultView });
    void persist("default_view", defaultView);
  },
  setDefaultSort: (defaultSort) => {
    set({ defaultSort });
    void persist("default_sort", JSON.stringify(defaultSort));
  },
  setTitleLanguage: (titleLanguage) => {
    set({ titleLanguage });
    void persist("title_language", titleLanguage);
  },
  setSequelNotifications: (on) => {
    set({ sequelNotifications: on });
    void persist("sequel_notifications", String(on));
  },
  setTelemetry: (on) => {
    set({ telemetry: on });
    void persist("telemetry", String(on));
  },
  addRecentSearch: (q) => {
    const query = q.trim();
    if (!query) return;
    const next = [query, ...get().recentSearches.filter((x) => x !== query)].slice(
      0,
      RECENT_SEARCH_LIMIT,
    );
    set({ recentSearches: next });
    void persist("recent_searches", JSON.stringify(next));
  },
  removeRecentSearch: (q) => {
    const next = get().recentSearches.filter((x) => x !== q);
    set({ recentSearches: next });
    void persist("recent_searches", JSON.stringify(next));
  },
  enableDevMode: () => set({ devMode: true }),
  setSidebarMode: (sidebarMode) => {
    set({ sidebarMode });
    void persist("sidebar_mode", sidebarMode);
  },
  /* Stamped on the document as well as stored, because every rule that
     reads it is CSS. See lib/motion.ts for what each value means. */
  setMotionMode: (motionMode) => {
    applyMotionMode(motionMode);
    set({ motionMode });
    void persist("motion_mode", motionMode);
  },
}));
