import { useEffect, useState } from "react";
import { Check, Download, ExternalLink, RefreshCw } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { openExternal } from "@/lib/openExternal";
import { checkForUpdate } from "@/lib/updater";
import { useUpdateStore } from "@/lib/store/updateStore";
import { APP_NAME, APP_VERSION } from "@/lib/version";

/**
 * The update, on the one page allowed to talk about it.
 *
 * Everything an update needs to say lives here: that there is one, what version
 * it is, and the way to get it on the platform you are actually running. The
 * patch notes sit directly underneath, which is the pairing that was missing —
 * "what changed" and "how do I get it" were two different menus, and neither
 * linked to the other.
 *
 * ## Why the action is a list rather than a branch
 *
 * There are already two ways to update (desktop installs in place, Android
 * points at the release) and Google Play will be a third. Written as an
 * if/else those become nested conditions that every future path has to be
 * threaded through. Written as a list of routes, each one states its own
 * condition and adding Play is adding an entry — which is the shape this has to
 * be in before Play arrives rather than after.
 */
interface Route {
  key: string;
  icon: typeof Download;
  label: string;
  /** What the button actually does. */
  run: () => void | Promise<void>;
  /** The main way to update on this platform, drawn as the filled button. */
  primary?: boolean;
}

export function UpdateBlock() {
  const update = useUpdateStore((s) => s.update);
  const found = useUpdateStore((s) => s.found);
  const hush = useUpdateStore((s) => s.hush);
  const [checking, setChecking] = useState(false);
  const [current, setCurrent] = useState(false);

  // Landing here is dealing with it, as far as the notice is concerned. The dot
  // stays — it is still true that an update is waiting — but the sentence has
  // done its job and stops opening itself. In an effect, not in the render:
  // setting store state during render re-enters the component mid-pass.
  useEffect(() => {
    hush();
  }, [hush]);

  const recheck = async () => {
    setChecking(true);
    setCurrent(false);
    try {
      const u = await checkForUpdate();
      if (u) found(u);
      else setCurrent(true);
    } catch {
      setCurrent(false);
    }
    setChecking(false);
  };

  if (!update) {
    return (
      <div className="k-upblock k-upblock--current">
        <div className="k-upblock__line">
          <Icon icon={Check} size={16} color="var(--color-success)" />
          <span>
            {current
              ? `${APP_NAME} is up to date.`
              : `You're on v${APP_VERSION}.`}
          </span>
        </div>
        <button
          type="button"
          className="k-upblock__ghost"
          onClick={() => void recheck()}
          disabled={checking}
        >
          <Icon icon={RefreshCw} size={14} />
          {checking ? "Checking…" : "Check again"}
        </button>
      </div>
    );
  }

  const routes: Route[] =
    update.kind === "install"
      ? [
          {
            key: "install",
            icon: Download,
            label: "Install and restart",
            run: () => update.install(),
            primary: true,
          },
        ]
      : [
          {
            key: "release",
            icon: ExternalLink,
            label: "Download the APK",
            run: () => openExternal(update.releaseUrl),
            primary: true,
          },
        ];

  return (
    <div className="k-upblock">
      <div className="k-upblock__head">
        <span className="k-upblock__kicker">Update available</span>
        <p className="k-upblock__version">
          {APP_NAME} v{update.version}
        </p>
        <p className="k-upblock__from">
          You're on v{APP_VERSION}. What changed is below.
        </p>
      </div>
      <div className="k-upblock__routes">
        {routes.map((r) => (
          <button
            key={r.key}
            type="button"
            className={`k-upblock__route${r.primary ? " k-upblock__route--primary" : ""}`}
            onClick={() => void r.run()}
          >
            <Icon icon={r.icon} size={15} />
            {r.label}
          </button>
        ))}
      </div>
      {update.kind === "install" && (
        <p className="k-upblock__note">
          Already downloaded, so this takes a second. Your list is on this
          device and updating does not touch it.
        </p>
      )}
    </div>
  );
}
