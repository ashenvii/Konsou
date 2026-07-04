import type { CSSProperties } from "react";
import { Section, Row, SettingsSubPage } from "@/components/settings/parts";
import { Text } from "@/components/ui/Text";
import { TITLE_LANGUAGE_OPTIONS } from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AccentName, ColorTheme, SidebarMode, ViewMode } from "@/types/list";

/* Curated to four strong, distinct moods: warm ember dark, brand-violet dark,
 * cool teal dark, and a clean light. The swatch colors are approximations; the
 * CSS vars do the real work. */
const COLOR_THEMES: { id: ColorTheme; label: string; surface: string; accent: string }[] = [
  { id: "ember", label: "Ember", surface: "oklch(16%   0.052 34)",  accent: "oklch(70% 0.20 45)"  },
  { id: "void",  label: "Void",  surface: "oklch(15%   0.038 280)", accent: "oklch(65% 0.23 350)" },
  { id: "ocean", label: "Ocean", surface: "oklch(14.5% 0.046 218)", accent: "oklch(71% 0.18 190)" },
  { id: "paper", label: "Paper", surface: "oklch(98.5% 0.003 280)", accent: "oklch(65% 0.23 350)" },
];

const ACCENTS: { id: AccentName; label: string; color: string }[] = [
  { id: "coral",  label: "Coral",  color: "oklch(70% 0.20 45)"  },
  { id: "violet", label: "Violet", color: "oklch(52% 0.27 290)" },
  { id: "sakura", label: "Sakura", color: "oklch(65% 0.23 350)" },
  { id: "cobalt", label: "Cobalt", color: "oklch(58% 0.18 240)" },
  { id: "amber",  label: "Amber",  color: "oklch(70% 0.18 55)"  },
  { id: "aqua",   label: "Aqua",   color: "oklch(71% 0.16 190)" },
];

const VIEWS: ViewMode[] = ["grid", "list", "compact"];

const SIDEBAR_MODES: { id: SidebarMode; label: string; hint: string }[] = [
  { id: "rail",     label: "Icon rail",   hint: "Just icons — never expands" },
  { id: "hover",    label: "On hover",    hint: "Icons that expand when you point at them" },
  { id: "expanded", label: "Always open", hint: "Full sidebar, pinned open" },
];

export function AppearanceSettings() {
  const settings = useSettingsStore();

  return (
    <SettingsSubPage title="Appearance">
      <Section title="Theme">
        <div className="k-settings__row k-settings__row--col">
          <Text size="base" weight={500}>Color theme</Text>
          <Text size="xs" color="tertiary">Picking a theme also sets its paired accent. Change Accent below to mix.</Text>
          <div className="k-colorthemes">
            {COLOR_THEMES.map((t) => (
              <button
                key={t.id}
                className={`k-colortheme${settings.colorTheme === t.id ? " k-colortheme--active" : ""}`}
                onClick={() => settings.setColorTheme(t.id)}
                aria-label={t.label}
                aria-pressed={settings.colorTheme === t.id}
              >
                <span className="k-colortheme__preview" style={{ background: t.surface } as CSSProperties}>
                  <span className="k-colortheme__strip" style={{ background: t.accent } as CSSProperties} />
                </span>
                <span className="k-colortheme__label">{t.label}</span>
              </button>
            ))}
          </div>
        </div>
        <Row label="Accent" hint="Override the theme's paired color">
          <div className="k-swatches">
            {ACCENTS.map((a) => (
              <button
                key={a.id}
                className={`k-swatch${settings.accent === a.id ? " k-swatch--active" : ""}`}
                style={{ background: a.color }}
                onClick={() => settings.setAccent(a.id)}
                aria-label={a.label}
                aria-pressed={settings.accent === a.id}
              />
            ))}
          </div>
        </Row>
      </Section>

      <Section title="Layout">
        <Row
          label="Title language"
          hint={`Example: ${
            TITLE_LANGUAGE_OPTIONS.find((o) => o.id === settings.titleLanguage)?.example ?? ""
          }`}
        >
          <div className="k-segmented">
            {TITLE_LANGUAGE_OPTIONS.map((o) => (
              <button
                key={o.id}
                className={`k-segmented__btn${settings.titleLanguage === o.id ? " k-segmented__btn--active" : ""}`}
                onClick={() => settings.setTitleLanguage(o.id)}
              >
                {o.label}
              </button>
            ))}
          </div>
        </Row>
        <Row label="Default view">
          <div className="k-segmented">
            {VIEWS.map((v) => (
              <button
                key={v}
                className={`k-segmented__btn${settings.defaultView === v ? " k-segmented__btn--active" : ""}`}
                onClick={() => settings.setDefaultView(v)}
              >
                {v[0].toUpperCase() + v.slice(1)}
              </button>
            ))}
          </div>
        </Row>
        <Row
          label="Sidebar"
          hint={SIDEBAR_MODES.find((m) => m.id === settings.sidebarMode)?.hint ?? "Desktop navigation"}
        >
          <div className="k-segmented">
            {SIDEBAR_MODES.map((m) => (
              <button
                key={m.id}
                className={`k-segmented__btn${settings.sidebarMode === m.id ? " k-segmented__btn--active" : ""}`}
                onClick={() => settings.setSidebarMode(m.id)}
                title={m.hint}
              >
                {m.label}
              </button>
            ))}
          </div>
        </Row>
      </Section>
    </SettingsSubPage>
  );
}
