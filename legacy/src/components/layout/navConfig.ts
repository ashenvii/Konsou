import { BarChart3, CalendarClock, Compass, Heart, Info, List, Sparkles } from "lucide-react";
import type { IconComponent } from "@/components/ui/Icon";

export interface NavItem {
  to: string;
  label: string;
  icon: IconComponent;
  /** Shows the unread badge (Airing → New sequels). */
  badge?: boolean;
}

/** Primary destinations. Search lives on top of Discover (one page); Schedule
 *  and Alerts merged into a single Airing tab (Episodes + New sequels segments).
 *  Settings and Account sit behind the avatar (mobile top bar / desktop sidebar
 *  footer). */
export const NAV_ITEMS: NavItem[] = [
  { to: "/", label: "My List", icon: List },
  { to: "/discover", label: "Discover", icon: Compass },
  { to: "/stats", label: "Stats", icon: BarChart3 },
  { to: "/airing", label: "Airing", icon: CalendarClock, badge: true },
];

/**
 * The app's own pages, as opposed to the library's.
 *
 * One list, two shells: the desktop rail renders them as its second group of
 * nav rows, and the mobile brand strip renders them as icons beside the
 * wordmark. Defining them here keeps the two from drifting — the rail had
 * them and the phone simply didn't, so the same three destinations existed
 * on one platform and not the other.
 */
export interface UtilityItem extends NavItem {
  /** Marks the one entry that may draw a little attention to itself. */
  spark?: boolean;
  /** This door owns the "an update is waiting" signal. */
  update?: boolean;
}

export const UTILITY_ITEMS: UtilityItem[] = [
  // `update: true` is the one door allowed to say an update is waiting. Every
  // other surface that used to mention it (a boot toast, About's own check
  // button and its toast) now points here instead, so the fact has one home
  // and cannot end up stated three different ways.
  { to: "/settings/whats-new", label: "What's new", icon: Sparkles, update: true },
  { to: "/settings/support", label: "Support", icon: Heart, spark: true },
  { to: "/settings/about", label: "About", icon: Info },
];
