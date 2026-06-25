import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { isTauri } from "@/lib/platform";
import { toast } from "@/lib/store/toastStore";

/**
 * Routes the Android hardware back button / gesture through React Router instead
 * of letting it kill the app (Trap 1 — the default exits even when history
 * exists on Tauri 2.9.x). Only navigates back when there is history; on the root
 * it shows a "press back again to exit" toast before closing.
 *
 * Registered once at the app root.
 */
export function useAndroidBack() {
  const navigate = useNavigate();

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
        if (window.history.length > 1) {
          navigate(-1);
          return;
        }
        if (backPressedOnce) {
          void appWindow.close();
        } else {
          backPressedOnce = true;
          toast.show("Press back again to exit");
          if (resetTimer) clearTimeout(resetTimer);
          resetTimer = setTimeout(() => (backPressedOnce = false), 2000);
        }
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
