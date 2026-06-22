import { useEffect } from "react";
import { Outlet, useNavigate } from "react-router-dom";
import { BottomNav } from "./BottomNav";
import { Sidebar } from "./Sidebar";
import { Toasts } from "@/components/ui/Toasts";
import { useAndroidBack } from "@/hooks/useAndroidBack";
import { useBreakpoint } from "@/hooks/useMediaQuery";
import { registerLifecycleHandlers } from "@/lib/lifecycle";
import { NAV_ITEMS } from "./navConfig";

export function AppShell() {
  const { isDesktop } = useBreakpoint();
  const navigate = useNavigate();
  useAndroidBack();

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
      if (n >= 1 && n <= NAV_ITEMS.length) navigate(NAV_ITEMS[n - 1].to);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [isDesktop, navigate]);

  return (
    <div className={`k-shell${isDesktop ? " k-shell--desktop" : ""}`}>
      {isDesktop && <Sidebar />}
      <main className="k-shell__content">
        <Outlet />
      </main>
      {!isDesktop && <BottomNav />}
      <Toasts />
    </div>
  );
}
