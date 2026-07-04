import { useEffect } from "react";
import { Outlet, useLocation } from "react-router-dom";
import { BottomNav } from "./BottomNav";
import { Sidebar } from "./Sidebar";
import { TopBar } from "./TopBar";
import { Toasts } from "@/components/ui/Toasts";
import { ReconcilePrompt } from "@/components/ReconcilePrompt";
import { useAppBack } from "@/hooks/useAppBack";
import { useTabPress } from "@/hooks/useTabPress";
import { useViewportDragScroll } from "@/hooks/useViewportDragScroll";
import { useBreakpoint } from "@/hooks/useMediaQuery";
import { registerLifecycleHandlers } from "@/lib/lifecycle";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { NAV_ITEMS } from "./navConfig";

export function AppShell() {
  const { isDesktop } = useBreakpoint();
  const sidebarMode = useSettingsStore((s) => s.sidebarMode);
  const location = useLocation();
  const onTabPress = useTabPress();
  // The detail page owns the whole viewport (immersive banner + its own back
  // bar), so the mobile top bar stands down there.
  const isImmersive = location.pathname.startsWith("/anime/");
  useAppBack();
  useViewportDragScroll();

  useEffect(() => {
    let cleanup: (() => void) | undefined;
    void registerLifecycleHandlers().then((fn) => (cleanup = fn));
    return () => cleanup?.();
  }, []);

  // Desktop: keys 1–5 jump to each tab (ignored while typing in a field).
  useEffect(() => {
    if (!isDesktop) return;
    const onKey = (e: KeyboardEvent) => {
      const el = document.activeElement;
      if (
        el instanceof HTMLInputElement ||
        el instanceof HTMLTextAreaElement ||
        (el as HTMLElement)?.isContentEditable
      ) {
        return;
      }
      const n = Number(e.key);
      if (n >= 1 && n <= NAV_ITEMS.length) onTabPress(NAV_ITEMS[n - 1].to);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [isDesktop, onTabPress]);

  return (
    <div
      className={`k-shell${isDesktop ? " k-shell--desktop" : ""}`}
      data-sidebar={isDesktop ? sidebarMode : undefined}
    >
      {isDesktop && <Sidebar />}
      {!isDesktop && !isImmersive && <TopBar />}
      <main className="k-shell__content">
        <Outlet />
      </main>
      {!isDesktop && <BottomNav />}
      <Toasts />
      <ReconcilePrompt />
    </div>
  );
}
