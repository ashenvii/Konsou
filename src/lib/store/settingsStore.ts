import { create } from "zustand";
import { getDb } from "@/lib/db";
import type {
  AccentName,
  ColorTheme,
  SidebarMode,
  SortSpec,
  TitleLanguage,
  ViewMode,
} from "@/types/list";

const RECENT_SEARCH_LIMIT = 5;

/** Each color theme ships with a paired accent. Picking a theme auto-sets it;
 *  the user can override the accent independently afterwards. */
export const THEME_DEFAULT_ACCENTS: Record<ColorTheme, AccentName> = {
  void:     "sakura",
  ocean:    "aqua",
  ember:    "amber",
  forest:   "jade",
  midnight: "cobalt",
  crimson:  "crimson",
  paper:    "sakura",
  ash:      "cobalt",
};

interface SettingsState {
  loaded: boolean;
  colorTheme: ColorTheme;
  accent: AccentName;
  defaultView: ViewMode;
  defaultSort: SortSpec;
  titleLanguage: TitleLanguage;
  sequelNotifications: boolean;
  telemetry: boolean;
  recentSearches: string[];
  devMode: boolean;
  sidebarMode: SidebarMode;

  load: () => Promise<void>;
  setColorTheme: (t: ColorTheme) => void;
  setAccent: (a: AccentName) => void;
  setDefaultView: (v: ViewMode) => void;
  setDefaultSort: (s: SortSpec) => void;
  setTitleLanguage: (l: TitleLanguage) => void;
  setSequelNotifications: (on: boolean) => void;
  setTelemetry: (on: boolean) => void;
  addRecentSearch: (q: string) => void;
  removeRecentSearch: (q: string) => void;
  enableDevMode: () => void;
  setSidebarMode: (m: SidebarMode) => void;
}

function applyColorTheme(theme: ColorTheme): void {
  document.documentElement.setAttribute("data-theme", theme);
}

function applyAccent(accent: AccentName): void {
  document.documentElement.setAttribute("data-accent", accent);
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
  colorTheme: "void",
  accent: "sakura",
  defaultView: "grid",
  defaultSort: { key: "updated", order: "desc" },
  titleLanguage: "romaji",
  sequelNotifications: true,
  telemetry: true,
  recentSearches: [],
  devMode: false,
  sidebarMode: "hover",

  load: async () => {
    const db = await getDb();
    const s = await db.settingsGetAll();
    const colorTheme = (s.color_theme as ColorTheme) ?? "void";
    const accent =
      (s.accent as AccentName) ?? THEME_DEFAULT_ACCENTS[colorTheme];
    applyColorTheme(colorTheme);
    applyAccent(accent);
    set({
      loaded: true,
      colorTheme,
      accent,
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
    });
  },

  /** Picking a theme updates both the surface palette and resets accent to
   *  the theme's paired default. User can override accent afterwards. */
  setColorTheme: (colorTheme) => {
    const accent = THEME_DEFAULT_ACCENTS[colorTheme];
    applyColorTheme(colorTheme);
    applyAccent(accent);
    set({ colorTheme, accent });
    void persist("color_theme", colorTheme);
    void persist("accent", accent);
  },

  setAccent: (accent) => {
    applyAccent(accent);
    set({ accent });
    void persist("accent", accent);
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
}));
