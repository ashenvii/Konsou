import { useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import type { NavigateFunction } from "react-router-dom";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { isTauri } from "@/lib/platform";
import { clearStash, popBack, recordNavigation } from "@/lib/navStacks";
import { closeTopSheet } from "@/lib/sheetStack";
import { toast } from "@/lib/store/toastStore";

/**
 * One back policy for every trigger — Android hardware back / edge swipe,
 * the mouse back button, Alt+Left, and the in-app back arrows:
 *
 *   1. An open sheet? Close it — back never navigates under a sheet.
 *   2. Deeper than the tab root? Pop the CURRENT TAB's own stack
 *      (see lib/navStacks). Back never hops between tabs and never unwinds
 *      the whole session history.
 *   3. At a tab root? "Press back again to exit", then close the app if the
 *      second press lands within the window. The 2s window is deliberately
 *      generous so both button-nav and edge-swipe users can repeat in time.
 *
 * Registered once at the app root.
 */

const EXIT_WINDOW_MS = 2000;

let navigateFn: NavigateFunction | null = null;
let backArmedAt = 0;

/** Runs the back policy. Usable from any component once the shell mounted. */
export function goBack() {
  // 1. Sheets swallow back before any navigation happens.
  if (closeTopSheet()) return;

  // 2. Sub-pages step back through their own tab's sequence.
  const target = popBack();
  if (target !== null) {
    navigateFn?.(target, { replace: true });
    return;
  }

  // 3. Tab root: double-back to exit.
  const now = Date.now();
  if (now - backArmedAt < EXIT_WINDOW_MS) {
    if (isTauri()) void getCurrentWindow().close();
    return;
  }
  backArmedAt = now;
  toast.show("Press back again to exit");
}

export function useAppBack() {
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    navigateFn = navigate;
  }, [navigate]);

  // Feed every location change into the per-tab stacks.
  useEffect(() => {
    recordNavigation(location.pathname);
  }, [location.pathname]);

  useEffect(() => {
    // Mouse back button (XButton1). History is a single replaced entry, so
    // the webview's own "go back" has nothing to do; we own the gesture.
    const onPointerUp = (e: PointerEvent) => {
      if (e.button === 3) {
        e.preventDefault();
        goBack();
      }
      if (e.button === 4) e.preventDefault(); // forward: nothing to go to
    };
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.altKey && e.key === "ArrowLeft") {
        e.preventDefault();
        goBack();
      }
    };
    // Any real click inside the page (not the nav chrome) while a re-tap
    // stash exists means the user moved on: forget the old sequence. Bubble
    // phase, so clicks swallowed by drag-to-scroll never count.
    const onClick = (e: MouseEvent) => {
      const t = e.target as HTMLElement | null;
      if (t && !t.closest(".k-bottomnav, .k-sidebar")) clearStash();
    };
    window.addEventListener("pointerup", onPointerUp);
    window.addEventListener("keydown", onKeyDown);
    window.addEventListener("click", onClick);
    return () => {
      window.removeEventListener("pointerup", onPointerUp);
      window.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("click", onClick);
    };
  }, []);

  // Android hardware back / predictive edge swipe (Trap 1 on Tauri 2.9.x).
  useEffect(() => {
    if (!isTauri()) return;

    let unlisten: (() => void) | undefined;
    let active = true;

    (async () => {
      if (!active) return;
      const appWindow = getCurrentWindow();
      const stop = await appWindow.listen("tauri://back", () => goBack());
      unlisten = stop;
    })();

    return () => {
      active = false;
      unlisten?.();
    };
  }, []);
}
