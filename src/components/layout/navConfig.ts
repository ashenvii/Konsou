import { BarChart3, CalendarClock, Compass, List } from "lucide-react";
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
