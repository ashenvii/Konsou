import { useState } from "react";
import { Code2, ExternalLink, History, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Section, Row, SettingsSubPage } from "@/components/settings/parts";
import { Text } from "@/components/ui/Text";
import { ChangelogBody } from "@/components/WhatsNew";
import { getBundledChangelog } from "@/lib/changelog";
import { isTauri } from "@/lib/platform";
import { openExternal } from "@/lib/openExternal";
import { syncManager } from "@/lib/sync/syncManager";
import { checkForUpdate, APP_VERSION } from "@/lib/updater";
import { toast } from "@/lib/store/toastStore";
import { useSettingsStore } from "@/lib/store/settingsStore";

const GITHUB_URL = (import.meta.env.VITE_GITHUB_URL as string | undefined) ?? "https://github.com";

/** How many more versions each "Show older versions" tap reveals. */
const HISTORY_PAGE = 3;

export function AboutSettings() {
  const settings = useSettingsStore();
  const [versionTaps, setVersionTaps] = useState(0);
  const [checking, setChecking] = useState(false);
  // Newest first; entry 0 is always visible, the rest reveal in pages.
  const changelog = getBundledChangelog();
  const [shown, setShown] = useState(1);

  const checkUpdate = async () => {
    setChecking(true);
    try {
      const update = await checkForUpdate();
      if (!update) {
        toast.show("Konsou is up to date");
      } else if (update.kind === "install") {
        toast.action({
          message: `v${update.version} ready, click to restart`,
          actionLabel: "Update Now",
          duration: 0,
          onAction: () => void update.install(),
        });
      } else {
        // Android: no auto-update yet; point at the release to grab the APK.
        toast.action({
          message: `v${update.version} is available`,
          actionLabel: "View",
          duration: 0,
          onAction: () => void openExternal(update.releaseUrl),
        });
      }
    } catch {
      toast.show("Couldn't reach update server. You may already be on the latest version");
    }
    setChecking(false);
  };

  const onVersionTap = () => {
    const n = versionTaps + 1;
    setVersionTaps(n);
    if (n >= 3 && !settings.devMode) {
      settings.enableDevMode();
      toast.show("Developer mode enabled");
    }
  };

  return (
    <SettingsSubPage title="About">
      <Section>
        <Row label="Check for updates" hint={`Current version: ${APP_VERSION}`}>
          <Button variant="ghost" onClick={() => void checkUpdate()} disabled={checking}>
            {checking ? "Checking…" : <><Icon icon={RefreshCw} size={15} /> Check</>}
          </Button>
        </Row>
        <Row label="Source code" hint="Konsou is open source">
          <Button variant="secondary" onClick={() => void openExternal(GITHUB_URL)}>
            <Icon icon={Code2} size={15} /> GitHub <Icon icon={ExternalLink} size={13} />
          </Button>
        </Row>
      </Section>

      {changelog.length > 0 && (
        <Section title="What's new">
          <div className="k-settings__row k-settings__row--col">
            {changelog.slice(0, shown).map((entry) => (
              <div key={entry.version} className="k-changelog__entry">
                <div className="k-changelog__version">
                  <Text size="base" weight={600}>v{entry.version}</Text>
                  {entry.date && (
                    <Text size="xs" color="tertiary">{entry.date}</Text>
                  )}
                </div>
                <ChangelogBody entry={entry} />
              </div>
            ))}
            {shown < changelog.length && (
              <Button
                variant="ghost"
                onClick={() => setShown((n) => Math.min(n + HISTORY_PAGE, changelog.length))}
              >
                <Icon icon={History} size={15} /> Show older versions
              </Button>
            )}
          </div>
        </Section>
      )}

      <button className="k-settings__row k-settings__version" onClick={onVersionTap}>
        <Text size="sm" color="tertiary">
          Konsou v{APP_VERSION} · {isTauri() ? "desktop" : "web preview"}
        </Text>
      </button>

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
                    .map((l) => `${new Date(l.at).toLocaleTimeString()} [${l.level}] ${l.msg}`)
                    .join("\n")}
            </pre>
          </div>
        </Section>
      )}
    </SettingsSubPage>
  );
}
