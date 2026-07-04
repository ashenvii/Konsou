import { useEffect, useRef } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { isTauri } from "@/lib/platform";
import { closeTopSheet } from "@/lib/sheetStack";
import { toast } from "@/lib/store/toastStore";

/**
 * Routes the Android hardware back button / gesture through the app's own
 * back policy instead of letting it kill the app (Trap 1 on Tauri 2.9.x):
 *
 *   1. An open sheet? Close it — back never navigates under a sheet.
 *   2. On a sub-page (anime detail, settings)? Go back one step.
 *   3. On a tab root? "Press back again to exit", then close the app if the
 *      second press lands within the window. The 2s window is deliberately
 *      generous so both button-nav and edge-swipe users can repeat in time.
 *
 * Registered once at the app root.
 */

// Bottom-nav destinations. Back never hops between these; from a root the
// only place left to go is out of the app.
const TAB_ROOTS = new Set(["/", "/discover", "/stats", "/schedule", "/alerts"]);

const EXIT_WINDOW_MS = 2000;

export function useAndroidBack() {
  const navigate = useNavigate();
  const location = useLocation();
  const pathRef = useRef(location.pathname);

  useEffect(() => {
    pathRef.current = location.pathname;
  }, [location.pathname]);

  useEffect(() => {
    if (!isTauri()) return;

    let backPressedOnce = false;
    let resetTimer: ReturnType<typeof setTimeout> | null = null;
    let unlisten: (() => void) | undefined;
    let active = true;

    (async () => {
      if (!active) return;
      const appWindow = getCurrentWindow();

      const stop = await appWindow.listen("tauri://back", () => {
        // 1. Sheets swallow back before any navigation happens.
        if (closeTopSheet()) return;

        // 2. Sub-pages step back normally (settings → wherever you came
        //    from, detail → the list you opened it from).
        if (!TAB_ROOTS.has(pathRef.current)) {
          navigate(-1);
          return;
        }

        // 3. Tab root: double-back to exit.
        if (backPressedOnce) {
          void appWindow.close();
          return;
        }
        backPressedOnce = true;
        toast.show("Press back again to exit");
        if (resetTimer) clearTimeout(resetTimer);
        resetTimer = setTimeout(() => (backPressedOnce = false), EXIT_WINDOW_MS);
      });
      unlisten = stop;
    })();

    return () => {
      active = false;
      if (resetTimer) clearTimeout(resetTimer);
      unlisten?.();
    };
  }, [navigate]);
}
