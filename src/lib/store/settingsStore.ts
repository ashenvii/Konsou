import { create } from "zustand";
import { getDb } from "@/lib/db";
import type {
  AccentName,
  SortSpec,
  ThemeMode,
  ViewMode,
} from "@/types/list";

const RECENT_SEARCH_LIMIT = 5;

interface SettingsState {
  loaded: boolean;
  theme: ThemeMode;
  accent: AccentName;
  defaultView: ViewMode;
  defaultSort: SortSpec;
  sequelNotifications: boolean;
  telemetry: boolean;
  recentSearches: string[];
  devMode: boolean;

  load: () => Promise<void>;
  setTheme: (t: ThemeMode) => void;
  setAccent: (a: AccentName) => void;
  setDefaultView: (v: ViewMode) => void;
  setDefaultSort: (s: SortSpec) => void;
  setSequelNotifications: (on: boolean) => void;
  setTelemetry: (on: boolean) => void;
  addRecentSearch: (q: string) => void;
  removeRecentSearch: (q: string) => void;
  enableDevMode: () => void;
}

function applyAccent(accent: AccentName): void {
  document.documentElement.setAttribute("data-accent", accent);
}
function applyTheme(theme: ThemeMode): void {
  // Dark-first: light theme is a future addition. Persisted now for forward-compat.
  const resolved =
    theme === "system"
      ? window.matchMedia?.("(prefers-color-scheme: light)").matches
        ? "light"
        : "dark"
      : theme;
  document.documentElement.setAttribute("data-theme", resolved);
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
  theme: "dark",
  accent: "violet",
  defaultView: "grid",
  defaultSort: { key: "updated", order: "desc" },
  sequelNotifications: true,
  telemetry: true,
  recentSearches: [],
  devMode: false,

  load: async () => {
    const db = await getDb();
    const s = await db.settingsGetAll();
    const accent = (s.accent as AccentName) ?? "violet";
    const theme = (s.theme as ThemeMode) ?? "dark";
    applyAccent(accent);
    applyTheme(theme);
    set({
      loaded: true,
      accent,
      theme,
      defaultView: (s.default_view as ViewMode) ?? "grid",
      defaultSort: s.default_sort
        ? (JSON.parse(s.default_sort) as SortSpec)
        : { key: "updated", order: "desc" },
      sequelNotifications: s.sequel_notifications !== "false",
      telemetry: s.telemetry !== "false",
      recentSearches: s.recent_searches
        ? (JSON.parse(s.recent_searches) as string[])
        : [],
    });
  },

  setTheme: (theme) => {
    applyTheme(theme);
    set({ theme });
    void persist("theme", theme);
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
}));
