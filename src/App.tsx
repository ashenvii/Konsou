import { HashRouter, Navigate, Route, Routes } from "react-router-dom";
import { AppShell } from "@/components/layout/AppShell";
import { ErrorBoundary } from "@/components/ui/ErrorBoundary";
import { Onboarding } from "@/components/Onboarding";
import { MyList } from "@/pages/MyList";
import { Search } from "@/pages/Search";
import { Discover } from "@/pages/Discover";
import { Schedule } from "@/pages/Schedule";
import { Alerts } from "@/pages/Alerts";
import { AnimeDetail } from "@/pages/AnimeDetail";
import { Settings } from "@/pages/Settings";
import { Stats } from "@/pages/Stats";

function Wrap({ name, children }: { name: string; children: React.ReactNode }) {
  return <ErrorBoundary name={name}>{children}</ErrorBoundary>;
}

export function App() {
  return (
    <HashRouter>
      <Onboarding />
      <Routes>
        <Route element={<AppShell />}>
          <Route index element={<Wrap name="My List"><MyList /></Wrap>} />
          <Route path="search" element={<Wrap name="Search"><Search /></Wrap>} />
          <Route path="discover" element={<Wrap name="Discover"><Discover /></Wrap>} />
          <Route path="schedule" element={<Wrap name="Schedule"><Schedule /></Wrap>} />
          <Route path="alerts" element={<Wrap name="Alerts"><Alerts /></Wrap>} />
          <Route path="settings" element={<Wrap name="Settings"><Settings /></Wrap>} />
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
