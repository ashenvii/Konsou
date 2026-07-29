import { lazy } from "react";
import type { ReactNode } from "react";
import { HashRouter, Navigate, Route, Routes } from "react-router-dom";
import { AppShell } from "@/components/layout/AppShell";
import { ErrorBoundary } from "@/components/ui/ErrorBoundary";
import { Onboarding } from "@/components/Onboarding";
// Overview is the landing route, so it stays in the main chunk — splitting it
// would only trade a smaller bundle for a spinner on the very first paint.
import { Overview } from "@/pages/Overview";

// Everything else loads on navigation. These pages pull in the heavy weight —
// the Discover filter graph, the stats canvas, the whole detail view and the
// settings tree — that has no business sitting in the first paint. Each becomes
// its own chunk; AppShell's Suspense boundary covers the fetch.
const StatusRoom = lazy(() => import("@/pages/StatusRoom").then((m) => ({ default: m.StatusRoom })));
// Planned and Completed are the two rooms people live in, so they get built
// surfaces of their own instead of the generic status room: an ordered watch
// plan, and the completion ledger.
const PlanRoom = lazy(() => import("@/pages/PlanRoom").then((m) => ({ default: m.PlanRoom })));
const CompletedRoom = lazy(() =>
  import("@/pages/CompletedRoom").then((m) => ({ default: m.CompletedRoom })),
);
// The watch order is a place you go, not a sheet you summon: it was the sheet
// gestures fighting the row drag that made it feel broken.
const OrderPage = lazy(() => import("@/pages/OrderPage").then((m) => ({ default: m.OrderPage })));
const Discover = lazy(() => import("@/pages/Discover").then((m) => ({ default: m.Discover })));
const Airing = lazy(() => import("@/pages/Airing").then((m) => ({ default: m.Airing })));
const AnimeDetail = lazy(() => import("@/pages/AnimeDetail").then((m) => ({ default: m.AnimeDetail })));
const Stats = lazy(() => import("@/pages/Stats").then((m) => ({ default: m.Stats })));
const SettingsHub = lazy(() => import("@/pages/settings/SettingsHub").then((m) => ({ default: m.SettingsHub })));
const AccountSettings = lazy(() => import("@/pages/settings/AccountSettings").then((m) => ({ default: m.AccountSettings })));
const AppearanceSettings = lazy(() => import("@/pages/settings/AppearanceSettings").then((m) => ({ default: m.AppearanceSettings })));
const LibrarySettings = lazy(() => import("@/pages/settings/LibrarySettings").then((m) => ({ default: m.LibrarySettings })));
const SyncHistory = lazy(() => import("@/pages/settings/SyncHistory").then((m) => ({ default: m.SyncHistory })));
const NotificationsSettings = lazy(() => import("@/pages/settings/NotificationsSettings").then((m) => ({ default: m.NotificationsSettings })));
const SupportSettings = lazy(() => import("@/pages/settings/SupportSettings").then((m) => ({ default: m.SupportSettings })));
const AboutSettings = lazy(() => import("@/pages/settings/AboutSettings").then((m) => ({ default: m.AboutSettings })));

function Wrap({ name, children }: { name: string; children: ReactNode }) {
  return <ErrorBoundary name={name}>{children}</ErrorBoundary>;
}

export function App() {
  return (
    <HashRouter>
      <Onboarding />
      <Routes>
        <Route element={<AppShell />}>
          <Route index element={<Wrap name="My List"><Overview /></Wrap>} />
          {/* Dedicated status rooms, pushed onto the My List tab's back stack.
              The two bespoke rooms match first; watching and on-hold keep the
              generic one. */}
          <Route path="list/plan" element={<Wrap name="Planned"><PlanRoom /></Wrap>} />
          <Route path="list/plan/order" element={<Wrap name="My order"><OrderPage /></Wrap>} />
          <Route path="list/completed" element={<Wrap name="Completed"><CompletedRoom /></Wrap>} />
          <Route path="list/:status" element={<Wrap name="List"><StatusRoom /></Wrap>} />
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
            <Route path="sync-history" element={<Wrap name="Sync history"><SyncHistory /></Wrap>} />
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
