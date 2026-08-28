import type { CSSProperties } from "react";
import { Section, Row, SettingsSubPage } from "@/components/settings/parts";
import { Text } from "@/components/ui/Text";
import { useBreakpoint } from "@/hooks/useMediaQuery";
import { TITLE_LANGUAGE_OPTIONS } from "@/lib/format";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { ColorTheme, MotionMode, SidebarMode, ViewMode } from "@/types/list";

/* The two worlds. Each swatch shows the world's ground and both of its hues,
 * because a world IS its two hues: signage on the left, highlight on the
 * right. Approximations for the picker only; tokens.css does the real work. */
const COLOR_THEMES: {
  id: ColorTheme;
  label: string;
  hint: string;
  surface: string;
  signage: string;
  highlight: string;
}[] = [
  {
    id: "lantern",
    label: "Lantern",
    hint: "Warm, lit, soft corners",
    surface: "oklch(13% 0.035 18)",
    signage: "oklch(64% 0.25 16)",
    highlight: "oklch(83% 0.17 84)",
  },
  {
    id: "neon",
    label: "Neon",
    hint: "Cold, electric, hard corners",
    surface: "oklch(11% 0.025 262)",
    signage: "oklch(66% 0.29 346)",
    highlight: "oklch(82% 0.15 196)",
  },
];

const VIEWS: ViewMode[] = ["grid", "list", "compact"];

const MOTION_MODES: { id: MotionMode; label: string; hint: string }[] = [
  { id: "system", label: "Follow system", hint: "Full on a desktop, reduced on a phone" },
  { id: "full",   label: "Full",          hint: "Every glow, blur and ambient animation" },
  { id: "lite",   label: "Reduced",       hint: "Static equivalents, for a weaker GPU" },
];

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
          <Text size="base" weight={500}>World</Text>
          <Text size="xs" color="tertiary">
            Each world carries its own pair of colours, so there is nothing else to pick.
          </Text>
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
                  <span className="k-colortheme__strip" style={{ background: t.signage } as CSSProperties} />
                  <span className="k-colortheme__strip" style={{ background: t.highlight } as CSSProperties} />
                </span>
                <span className="k-colortheme__label">{t.label}</span>
                <span className="k-colortheme__hint">{t.hint}</span>
              </button>
            ))}
          </div>
        </div>
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
        <Row
          label="Motion"
          hint={MOTION_MODES.find((m) => m.id === settings.motionMode)?.hint ?? ""}
          stack
        >
          <div className="k-segmented">
            {MOTION_MODES.map((m) => (
              <button
                key={m.id}
                className={`k-segmented__btn${settings.motionMode === m.id ? " k-segmented__btn--active" : ""}`}
                onClick={() => settings.setMotionMode(m.id)}
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
