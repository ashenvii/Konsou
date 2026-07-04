import { useState } from "react";
import { Code2, ExternalLink, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Section, Row, SettingsSubPage } from "@/components/settings/parts";
import { Text } from "@/components/ui/Text";
import { isTauri } from "@/lib/platform";
import { openExternal } from "@/lib/openExternal";
import { syncManager } from "@/lib/sync/syncManager";
import { checkForUpdate, APP_VERSION } from "@/lib/updater";
import { toast } from "@/lib/store/toastStore";
import { useSettingsStore } from "@/lib/store/settingsStore";

const GITHUB_URL = (import.meta.env.VITE_GITHUB_URL as string | undefined) ?? "https://github.com";

export function AboutSettings() {
  const settings = useSettingsStore();
  const [versionTaps, setVersionTaps] = useState(0);
  const [checking, setChecking] = useState(false);

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
