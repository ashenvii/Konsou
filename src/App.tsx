import type { ReactNode } from "react";
import { HashRouter, Navigate, Route, Routes } from "react-router-dom";
import { AppShell } from "@/components/layout/AppShell";
import { ErrorBoundary } from "@/components/ui/ErrorBoundary";
import { Onboarding } from "@/components/Onboarding";
import { MyList } from "@/pages/MyList";
import { Discover } from "@/pages/Discover";
import { Airing } from "@/pages/Airing";
import { AnimeDetail } from "@/pages/AnimeDetail";
import { SettingsHub } from "@/pages/settings/SettingsHub";
import { AccountSettings } from "@/pages/settings/AccountSettings";
import { AppearanceSettings } from "@/pages/settings/AppearanceSettings";
import { LibrarySettings } from "@/pages/settings/LibrarySettings";
import { NotificationsSettings } from "@/pages/settings/NotificationsSettings";
import { SupportSettings } from "@/pages/settings/SupportSettings";
import { AboutSettings } from "@/pages/settings/AboutSettings";
import { Stats } from "@/pages/Stats";

function Wrap({ name, children }: { name: string; children: ReactNode }) {
  return <ErrorBoundary name={name}>{children}</ErrorBoundary>;
}

export function App() {
  return (
    <HashRouter>
      <Onboarding />
      <Routes>
        <Route element={<AppShell />}>
          <Route index element={<Wrap name="My List"><MyList /></Wrap>} />
          {/* Search merged into Discover; keep the path alive for old links. */}
          <Route path="search" element={<Navigate to="/discover" replace />} />
          <Route path="discover" element={<Wrap name="Discover"><Discover /></Wrap>} />
          <Route path="airing" element={<Wrap name="Airing"><Airing /></Wrap>} />
          {/* Schedule + Alerts merged into Airing; keep old paths alive for links. */}
          <Route path="schedule" element={<Navigate to="/airing" replace />} />
          <Route path="alerts" element={<Navigate to="/airing" replace />} />
          <Route path="settings">
            <Route index element={<Wrap name="Settings"><SettingsHub /></Wrap>} />
            <Route path="account" element={<Wrap name="Account"><AccountSettings /></Wrap>} />
            <Route path="appearance" element={<Wrap name="Appearance"><AppearanceSettings /></Wrap>} />
            <Route path="library" element={<Wrap name="Library & Sync"><LibrarySettings /></Wrap>} />
            <Route path="notifications" element={<Wrap name="Notifications"><NotificationsSettings /></Wrap>} />
            <Route path="support" element={<Wrap name="Support"><SupportSettings /></Wrap>} />
            <Route path="about" element={<Wrap name="About"><AboutSettings /></Wrap>} />
          </Route>
          <Route path="stats" element={<Wrap name="Stats"><Stats /></Wrap>} />
          <Route path="anime/:id" element={<Wrap name="Anime Detail"><AnimeDetail /></Wrap>} />
        </Route>
        {/* Neutral route for the OAuth deep-link re-registration workaround (Trap 9) */}
        <Route path="/auth-redirect" element={<div />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </HashRouter>
  );
}
