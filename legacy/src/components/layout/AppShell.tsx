import { Suspense, useEffect } from "react";
import { Outlet, useLocation } from "react-router-dom";
import { Spinner } from "@/components/ui/Spinner";
import { BottomNav } from "./BottomNav";
import { Sidebar } from "./Sidebar";
import { Header } from "./Header";
import { CommandPalette } from "@/components/CommandPalette";
import { CatchUpSheet } from "@/components/list/CatchUpSheet";
import { Toasts } from "@/components/ui/Toasts";
import { StorageBanner } from "@/components/ui/StorageBanner";
import { ReconcilePrompt } from "@/components/ReconcilePrompt";
import { WhatsNew } from "@/components/WhatsNew";
import { useAppBack } from "@/hooks/useAppBack";
import { useScrollElevation } from "@/hooks/useScrollElevation";
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
  // Settings is backstage: all primary nav chrome (sidebar, top bar, bottom
  // nav) stands down so it reads as a distinct mode, not another page. The
  // pages' own back arrow (and hardware back) is the way out.
  const isBackstage = location.pathname.startsWith("/settings");
  useAppBack();
  useViewportDragScroll();
  useScrollElevation();

  useEffect(() => {
    let cleanup: (() => void) | undefined;
    void registerLifecycleHandlers().then((fn) => (cleanup = fn));
    return () => cleanup?.();
  }, []);

  // Landing on a new page always starts with full chrome; the scrolled state
  // is a property of the reading session, not of the app.
  useEffect(() => {
    delete document.documentElement.dataset.pageScrolled;
  }, [location.pathname]);

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
      className={`k-shell${isDesktop ? " k-shell--desktop" : ""}${isBackstage ? " k-shell--backstage" : ""}`}
      data-sidebar={isDesktop ? sidebarMode : undefined}
    >
      {isDesktop && !isBackstage && <Sidebar />}
      <main className="k-shell__content">
        {/* Desktop identity + account live in the index rail now, so the top bar
            is mobile-only; on desktop the content column reclaims that height. */}
        {!isDesktop && !isImmersive && !isBackstage && <Header />}
        {/* Lazily-loaded routes suspend here, so only the page area waits — the
            nav, header and overlays around it stay put during the chunk fetch. */}
        <Suspense
          fallback={
            <div style={{ display: "grid", placeItems: "center", minHeight: "40vh" }}>
              <Spinner size={22} />
            </div>
          }
        >
          <Outlet />
        </Suspense>
      </main>
      {!isDesktop && !isBackstage && <BottomNav />}
      <StorageBanner />
      <Toasts />
      <ReconcilePrompt />
      <WhatsNew />
      <CommandPalette />
      <CatchUpSheet />
    </div>
  );
}
