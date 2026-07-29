import type { CSSProperties } from "react";
import { Section, Row, SettingsSubPage } from "@/components/settings/parts";
import { Text } from "@/components/ui/Text";
import { useBreakpoint } from "@/hooks/useMediaQuery";
import { TITLE_LANGUAGE_OPTIONS } from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AccentName, ColorTheme, SidebarMode, ViewMode } from "@/types/list";

/* The eight plates of the Field Guide: six examination grounds and two printed
 * pages. The swatch colors are approximations; the CSS vars do the real work.
 * (ids stay the legacy keys so stored settings keep working.) */
const COLOR_THEMES: { id: ColorTheme; label: string; surface: string; accent: string }[] = [
  { id: "ember",    label: "Herbarium",     surface: "oklch(20% 0.024 158)", accent: "oklch(58% 0.19 32)"  },
  { id: "void",     label: "Nocturne",      surface: "oklch(19% 0.046 288)", accent: "oklch(58% 0.18 300)" },
  { id: "ocean",    label: "Cyanotype",     surface: "oklch(19% 0.058 250)", accent: "oklch(66% 0.13 75)"  },
  { id: "forest",   label: "Foxing",        surface: "oklch(21% 0.034 55)",  accent: "oklch(60% 0.10 190)" },
  { id: "midnight", label: "Slate",         surface: "oklch(23% 0.012 250)", accent: "oklch(58% 0.19 32)"  },
  { id: "crimson",  label: "Oxblood",       surface: "oklch(19% 0.058 20)",  accent: "oklch(66% 0.13 75)"  },
  { id: "paper",    label: "Vellum",        surface: "oklch(95% 0.020 85)",  accent: "oklch(48% 0.16 25)"  },
  { id: "ash",      label: "Specimen Card", surface: "oklch(96% 0.005 240)", accent: "oklch(45% 0.15 250)" },
];

const ACCENTS: { id: AccentName; label: string; color: string }[] = [
  { id: "coral",   label: "Vermilion",  color: "oklch(58% 0.19 32)"  },
  { id: "crimson", label: "Oxblood",    color: "oklch(50% 0.16 22)"  },
  { id: "amber",   label: "Ochre",      color: "oklch(66% 0.13 75)"  },
  { id: "jade",    label: "Sage",       color: "oklch(60% 0.13 155)" },
  { id: "aqua",    label: "Verdigris",  color: "oklch(60% 0.10 190)" },
  { id: "cobalt",  label: "Prussian",   color: "oklch(52% 0.16 250)" },
  { id: "violet",  label: "Ink Violet", color: "oklch(58% 0.18 300)" },
  { id: "sakura",  label: "Rose",       color: "oklch(62% 0.15 0)"   },
];

const VIEWS: ViewMode[] = ["grid", "list", "compact"];

const SIDEBAR_MODES: { id: SidebarMode; label: string; hint: string }[] = [
  { id: "rail",     label: "Icon rail",   hint: "Just icons — never expands" },
  { id: "hover",    label: "On hover",    hint: "Icons that expand when you point at them" },
  { id: "expanded", label: "Always open", hint: "Full sidebar, pinned open" },
];

export function AppearanceSettings() {
  const settings = useSettingsStore();
  const { isDesktop } = useBreakpoint();

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
        <Row label="Accent" hint="Override the theme's paired color" stack>
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
          stack
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
        <Row label="Default view" stack>
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
        {/* The sidebar only exists on desktop; offering its setting on a phone
            is dead weight. */}
        {isDesktop && (
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
        )}
      </Section>
    </SettingsSubPage>
  );
}
