import { useState } from "react";
import { useNavigate } from "react-router-dom";
import type { CSSProperties, ReactNode } from "react";
import { BarChart3, ChevronRight, CodeXml, ExternalLink, Heart, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { ConfirmSheet } from "@/components/ui/ConfirmSheet";
import { Icon } from "@/components/ui/Icon";
import { ImportSheet } from "@/components/ui/ImportSheet";
import { PageHeader } from "@/components/layout/PageHeader";
import { Text } from "@/components/ui/Text";
import { TITLE_LANGUAGE_OPTIONS } from "@/lib/format";
import { isTauri } from "@/lib/platform";
import { openExternal } from "@/lib/openExternal";
import { syncManager } from "@/lib/sync/syncManager";
import { checkForUpdate, APP_VERSION } from "@/lib/updater";
import { toast } from "@/lib/store/toastStore";
import { useAuthStore } from "@/lib/store/authStore";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AccentName, ColorTheme, SidebarMode, ViewMode } from "@/types/list";

const KOFI_URL = (import.meta.env.VITE_KOFI_URL as string | undefined) ?? "https://ko-fi.com";
const GITHUB_URL = (import.meta.env.VITE_GITHUB_URL as string | undefined) ?? "https://github.com";

/** Visual previews for each color theme. `surface` = what the dark backgrounds look
 *  like; `accent` = the paired default accent strip. These are approximations for
 *  the swatch — the actual CSS vars do the real work. */
/* Curated to four strong, distinct moods: brand-violet dark, cool teal dark,
 * warm ember dark, and a clean light. Quality over a wall of swatches. */
const COLOR_THEMES: { id: ColorTheme; label: string; surface: string; accent: string }[] = [
  { id: "void",  label: "Void",  surface: "oklch(15%   0.038 280)", accent: "oklch(65% 0.23 350)" },
  { id: "ocean", label: "Ocean", surface: "oklch(14.5% 0.046 218)", accent: "oklch(71% 0.18 190)" },
  { id: "ember", label: "Ember", surface: "oklch(15%   0.044 28)",  accent: "oklch(70% 0.20 55)"  },
  { id: "paper", label: "Paper", surface: "oklch(98.5% 0.003 280)", accent: "oklch(65% 0.23 350)" },
];

const ACCENTS: { id: AccentName; label: string; color: string }[] = [
  { id: "violet",  label: "Violet",  color: "oklch(52% 0.27 290)" },
  { id: "sakura",  label: "Sakura",  color: "oklch(65% 0.23 350)" },
  { id: "cobalt",  label: "Cobalt",  color: "oklch(58% 0.18 240)" },
  { id: "amber",   label: "Amber",   color: "oklch(70% 0.18 55)"  },
  { id: "aqua",    label: "Aqua",    color: "oklch(71% 0.16 190)" },
];
const VIEWS: ViewMode[] = ["grid", "list", "compact"];

const SIDEBAR_MODES: { id: SidebarMode; label: string; hint: string }[] = [
  { id: "rail",     label: "Icon rail",   hint: "Just icons — never expands" },
  { id: "hover",    label: "On hover",    hint: "Icons that expand when you point at them" },
  { id: "expanded", label: "Always open", hint: "Full sidebar, pinned open" },
];

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="k-settings__section">
      <Text size="xs" weight={600} color="tertiary" className="k-settings__sectiontitle">
        {title.toUpperCase()}
      </Text>
      <div className="k-settings__card">{children}</div>
    </section>
  );
}

function Row({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children?: ReactNode;
}) {
  return (
    <div className="k-settings__row">
      <div className="k-settings__rowlabel">
        <Text size="base" weight={500}>
          {label}
        </Text>
        {hint && (
          <Text size="xs" color="tertiary">
            {hint}
          </Text>
        )}
      </div>
      {children}
    </div>
  );
}

export function Settings() {
  const navigate = useNavigate();
  const settings = useSettingsStore();
  const account = useAuthStore((s) => s.account);
  const connect = useAuthStore((s) => s.connect);
  const connecting = useAuthStore((s) => s.connecting);
  const restoreDismissed = useNotificationStore((s) => s.restoreDismissed);
  const clearAll = useListStore((s) => s.clearAll);
  const entryCount = useListStore((s) => s.entries.length);
  const [versionTaps, setVersionTaps] = useState(0);
  const [importOpen, setImportOpen] = useState(false);
  const [confirmClear, setConfirmClear] = useState(false);
  const [checking, setChecking] = useState(false);

  const exportJson = () => {
    const entries = useListStore.getState().entries;
    const blob = new Blob([JSON.stringify(entries, null, 2)], {
      type: "application/json",
    });
    const filename = `konsou-list-${new Date().toISOString().slice(0, 10)}.json`;
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
    toast.success(`Saved "${filename}" to your Downloads folder`);
  };

  const onVersionTap = () => {
    const n = versionTaps + 1;
    setVersionTaps(n);
    if (n >= 3 && !settings.devMode) {
      settings.enableDevMode();
      toast.show("Developer mode enabled");
    }
  };

  const checkUpdate = async () => {
    setChecking(true);
    try {
      const update = await checkForUpdate();
      if (update) {
        toast.action({
          message: `v${update.version} ready, click to restart`,
          actionLabel: "Update Now",
          duration: 0,
          onAction: () => void update.install(),
        });
      } else {
        toast.show("Konsou is up to date");
      }
    } catch {
      toast.show("Couldn't reach update server. You may already be on the latest version");
    }
    setChecking(false);
  };

  return (
    <div className="k-page">
      <PageHeader title="Settings" onBack={() => navigate(-1)} />
      <div className="k-settings konsou-scroll">
        <button
          type="button"
          className="k-settings__statslink"
          onClick={() => navigate("/stats")}
        >
          <span className="k-settings__statsicon">
            <Icon icon={BarChart3} size={20} />
          </span>
          <span className="k-settings__statstext">
            <Text size="base" weight={600}>Your stats</Text>
            <Text size="xs" color="tertiary">Episodes, time watched, and status breakdown</Text>
          </span>
          <Icon icon={ChevronRight} size={18} color="var(--color-text-tertiary)" />
        </button>

        <Section title="Account">
          <Row
            label={account ? account.name : "Not signed in"}
            hint={account ? account.email : "Sync your list across devices with Google Drive"}
          >
            {account ? (
              <Button variant="ghost" onClick={() => void useAuthStore.getState().disconnect()}>
                Sign out
              </Button>
            ) : (
              <Button variant="secondary" onClick={() => void connect()} disabled={connecting}>
                {connecting ? "Connecting…" : "Connect Google"}
              </Button>
            )}
          </Row>
        </Section>

        <Section title="Appearance">
          {/* Color theme — sets both the surface palette AND the default accent */}
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
                  <span
                    className="k-colortheme__preview"
                    style={{ background: t.surface } as CSSProperties}
                  >
                    <span
                      className="k-colortheme__strip"
                      style={{ background: t.accent } as CSSProperties}
                    />
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
          <Row
            label="Sidebar"
            hint={
              SIDEBAR_MODES.find((m) => m.id === settings.sidebarMode)?.hint ??
              "Desktop navigation"
            }
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

        <Section title="List">
          <Row
            label="Title language"
            hint={`Example: ${
              TITLE_LANGUAGE_OPTIONS.find((o) => o.id === settings.titleLanguage)
                ?.example ?? ""
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
        </Section>

        <Section title="Alerts">
          <Row label="Sequel notifications" hint="Scan completed anime for new seasons">
            <Toggle
              on={settings.sequelNotifications}
              onChange={settings.setSequelNotifications}
            />
          </Row>
          <Row label="Dismissed alerts">
            <Button variant="ghost" onClick={() => void restoreDismissed()}>
              Restore all
            </Button>
          </Row>
        </Section>

        <Section title="Data">
          <Row label="Export list" hint="Download your list as JSON">
            <Button variant="secondary" onClick={exportJson}>
              Export
            </Button>
          </Row>
          <Row label="Import from AniList" hint="Merge any public AniList into your list">
            <Button variant="secondary" onClick={() => setImportOpen(true)}>
              Import
            </Button>
          </Row>
          <Row
            label={account ? "Clear synced list" : "Clear local list"}
            hint={
              account
                ? "Erases every entry here and on Google Drive"
                : "Erases every entry stored on this device"
            }
          >
            <Button
              variant="danger"
              disabled={entryCount === 0}
              onClick={() => setConfirmClear(true)}
            >
              <Icon icon={Trash2} size={15} /> Clear
            </Button>
          </Row>
        </Section>

        <Section title="About">
          <Row label="Support Konsou" hint="It's free, always. Optional tips welcome.">
            <div style={{ display: "flex", gap: "var(--space-2)" }}>
              <Button
                variant="secondary"
                onClick={() => void openExternal(KOFI_URL)}
              >
                <Icon icon={Heart} size={16} color="var(--color-error)" /> Ko-fi
              </Button>
              <Button
                variant="secondary"
                onClick={() => void openExternal(GITHUB_URL)}
              >
                <Icon icon={CodeXml} size={16} /> GitHub
              </Button>
            </div>
          </Row>
          <Row label="Check for updates" hint={`Current version: ${APP_VERSION}`}>
            <Button
              variant="ghost"
              onClick={() => void checkUpdate()}
              disabled={checking}
            >
              {checking ? "Checking…" : <><Icon icon={ExternalLink} size={15} /> Check</>}
            </Button>
          </Row>
          <button className="k-settings__row k-settings__version" onClick={onVersionTap}>
            <Text size="sm" color="tertiary">
              Konsou v{APP_VERSION} · {isTauri() ? "desktop" : "web preview"}
            </Text>
          </button>
        </Section>

        <ImportSheet open={importOpen} onClose={() => setImportOpen(false)} />

        <ConfirmSheet
          open={confirmClear}
          onClose={() => setConfirmClear(false)}
          icon={Trash2}
          danger
          title={account ? "Clear synced list?" : "Clear local list?"}
          message={
            account
              ? `This permanently removes all ${entryCount} ${entryCount === 1 ? "entry" : "entries"} from this device and your Google Drive. This can't be undone.`
              : `This permanently removes all ${entryCount} ${entryCount === 1 ? "entry" : "entries"} stored on this device. This can't be undone.`
          }
          confirmLabel="Clear everything"
          onConfirm={() => {
            void clearAll({ propagateToDrive: !!account });
            toast.show(account ? "List cleared everywhere" : "Local list cleared");
          }}
        />

        {settings.devMode && (
          <Section title="Developer">
            <div className="k-settings__row k-settings__row--col">
              <Text size="sm" color="secondary">
                Storage backend: {isTauri() ? "sqlite" : "web (localStorage)"}
              </Text>
              <Text size="xs" color="tertiary">
                Sync log ({syncManager.getDebugLog().length})
              </Text>
              <pre className="k-devlog">
                {syncManager.getDebugLog().length === 0
                  ? "no sync events yet"
                  : syncManager
                      .getDebugLog()
                      .map(
                        (l) =>
                          `${new Date(l.at).toLocaleTimeString()} [${l.level}] ${l.msg}`,
                      )
                      .join("\n")}
              </pre>
            </div>
          </Section>
        )}
      </div>
    </div>
  );
}

function Toggle({ on, onChange }: { on: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      className={`k-toggle${on ? " k-toggle--on" : ""}`}
      onClick={() => onChange(!on)}
    >
      <span className="k-toggle__knob" />
    </button>
  );
}
