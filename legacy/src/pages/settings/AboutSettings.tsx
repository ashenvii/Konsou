import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Code2, Heart, RefreshCw, Shield, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { LinkRow, Section, Row, SettingsSubPage } from "@/components/settings/parts";
import { Text } from "@/components/ui/Text";
import { isTauri } from "@/lib/platform";
import { openExternal } from "@/lib/openExternal";
import { syncManager } from "@/lib/sync/syncManager";
import { checkForUpdate, APP_VERSION } from "@/lib/updater";
import { APP_NAME } from "@/lib/version";
import { useUpdateStore } from "@/lib/store/updateStore";
import { toast } from "@/lib/store/toastStore";
import { useSettingsStore } from "@/lib/store/settingsStore";

const GITHUB_URL = (import.meta.env.VITE_GITHUB_URL as string | undefined) ?? "https://github.com";

/**
 * What this app is, what version you have, and where to go next.
 *
 * It briefly carried the release notes and the support pitch inline, which made
 * one page answer three unrelated questions. Each of those is its own door now;
 * what stays here is identity and version, plus the two doors themselves.
 */
export function AboutSettings() {
  const navigate = useNavigate();
  const settings = useSettingsStore();
  const [versionTaps, setVersionTaps] = useState(0);
  const [checking, setChecking] = useState(false);

  const go = (to: string) => navigate(to, { replace: true });

  /**
   * Look for a newer build, then hand the answer to the page that owns it.
   *
   * This used to resolve the update here and fire its own toast — a second,
   * differently-worded presentation of the same fact the boot check was already
   * presenting, in a menu whose job is "what is this app". Now About can still
   * ask the question (it is the natural place to look), and What's New is the
   * only place that answers it.
   */
  const checkUpdate = async () => {
    setChecking(true);
    try {
      const update = await checkForUpdate();
      if (!update) {
        toast.show(`${APP_NAME} is up to date`);
      } else {
        useUpdateStore.getState().found(update);
        go("/settings/whats-new");
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
      <div className="k-about__id">
        <img className="k-about__logo" src="/konsou.svg" alt="" width={44} height={44} />
        <p className="k-about__name">Konsou</p>
        <p className="k-about__tagline">
          An offline-first anime tracker with a sequel radar. Your list lives on
          your device; sync runs through your own Google Drive.
        </p>
        <span className="k-about__version">
          v{APP_VERSION} · {isTauri() ? "desktop" : "web preview"}
        </span>
      </div>

      <Section>
        <Row label="Check for updates" hint={`You have v${APP_VERSION}`}>
          <Button variant="secondary" onClick={() => void checkUpdate()} disabled={checking}>
            {checking ? "Checking…" : <><Icon icon={RefreshCw} size={15} /> Check</>}
          </Button>
        </Row>
      </Section>

      <Section>
        <LinkRow
          icon={Sparkles}
          title="What's new"
          hint="Release notes for this version and the ones before it"
          onClick={() => go("/settings/whats-new")}
        />
        <LinkRow
          icon={Heart}
          title="Support Konsou"
          hint="Free, no ads. Ways to help keep it that way"
          onClick={() => go("/settings/support")}
        />
        <LinkRow
          icon={Code2}
          title="Source code"
          hint="Konsou is open source, MIT licensed"
          external
          onClick={() => void openExternal(GITHUB_URL)}
        />
        <LinkRow
          icon={Shield}
          title="Privacy"
          hint="No account, no tracking, no Konsou server to send data to"
          external
          onClick={() => void openExternal(`${GITHUB_URL}#privacy`)}
        />
      </Section>

      {/* Three taps on the version line opens developer mode — the standard
          hidden-but-findable gesture, kept from the previous version. */}
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
