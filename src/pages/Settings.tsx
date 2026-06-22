import { useState } from "react";
import type { ReactNode } from "react";
import { ArrowSquareOut, GithubLogo, Heart } from "@phosphor-icons/react";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { ImportSheet } from "@/components/ui/ImportSheet";
import { PageHeader } from "@/components/layout/PageHeader";
import { Text } from "@/components/ui/Text";
import { isTauri } from "@/lib/platform";
import { openExternal } from "@/lib/openExternal";
import { syncManager } from "@/lib/sync/syncManager";
import { checkForUpdate, APP_VERSION } from "@/lib/updater";
import { toast } from "@/lib/store/toastStore";
import { useAuthStore } from "@/lib/store/authStore";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AccentName, ThemeMode, ViewMode } from "@/types/list";

const KOFI_URL = (import.meta.env.VITE_KOFI_URL as string | undefined) ?? "https://ko-fi.com";
const GITHUB_URL = (import.meta.env.VITE_GITHUB_URL as string | undefined) ?? "https://github.com";

const ACCENTS: { id: AccentName; label: string; color: string }[] = [
  { id: "violet", label: "Violet", color: "#7C5CFC" },
  { id: "cobalt", label: "Cobalt", color: "#2B8FE8" },
  { id: "crimson", label: "Crimson", color: "#E8507A" },
];
const THEMES: ThemeMode[] = ["light", "dark", "system"];
const VIEWS: ViewMode[] = ["grid", "list", "compact"];

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
  const settings = useSettingsStore();
  const account = useAuthStore((s) => s.account);
  const connect = useAuthStore((s) => s.connect);
  const connecting = useAuthStore((s) => s.connecting);
  const restoreDismissed = useNotificationStore((s) => s.restoreDismissed);
  const [versionTaps, setVersionTaps] = useState(0);
  const [importOpen, setImportOpen] = useState(false);
  const [checking, setChecking] = useState(false);

  const exportJson = () => {
    const entries = useListStore.getState().entries;
    const blob = new Blob([JSON.stringify(entries, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `konsou-list-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success("List exported");
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
          message: `v${update.version} ready — click to restart`,
          actionLabel: "Update Now",
          duration: 0,
          onAction: () => void update.install(),
        });
      } else {
        toast.show("Konsou is up to date");
      }
    } catch {
      toast.error("Update check failed — try again later");
    }
    setChecking(false);
  };

  return (
    <div className="k-page">
      <PageHeader title="Settings" />
      <div className="k-settings konsou-scroll">
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
          <Row label="Theme">
            <div className="k-segmented">
              {THEMES.map((t) => (
                <button
                  key={t}
                  className={`k-segmented__btn${settings.theme === t ? " k-segmented__btn--active" : ""}`}
                  onClick={() => settings.setTheme(t)}
                >
                  {t[0].toUpperCase() + t.slice(1)}
                </button>
              ))}
            </div>
          </Row>
          <Row label="Accent color">
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

        <Section title="List">
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
                <Icon icon={GithubLogo} size={16} /> GitHub
              </Button>
            </div>
          </Row>
          <Row label="Check for updates" hint={`Current version: ${APP_VERSION}`}>
            <Button
              variant="ghost"
              onClick={() => void checkUpdate()}
              disabled={checking}
            >
              {checking ? "Checking…" : <><Icon icon={ArrowSquareOut} size={15} /> Check</>}
            </Button>
          </Row>
          <button className="k-settings__row k-settings__version" onClick={onVersionTap}>
            <Text size="sm" color="tertiary">
              Konsou v{APP_VERSION} · {isTauri() ? "desktop" : "web preview"}
            </Text>
          </button>
        </Section>

        <ImportSheet open={importOpen} onClose={() => setImportOpen(false)} />

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
