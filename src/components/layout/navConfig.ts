import { BarChart3, Bell, CalendarClock, Compass, List } from "lucide-react";
import type { IconComponent } from "@/components/ui/Icon";

export interface NavItem {
  to: string;
  label: string;
  icon: IconComponent;
  /** Shows the unread badge (Alerts only). */
  badge?: boolean;
}

/** Primary destinations. Search now lives on top of Discover (one page); Stats
 *  took the slot that freed up. Settings and Account sit behind the avatar
 *  (mobile top bar / desktop sidebar footer). */
export const NAV_ITEMS: NavItem[] = [
  { to: "/", label: "My List", icon: List },
  { to: "/discover", label: "Discover", icon: Compass },
  { to: "/stats", label: "Stats", icon: BarChart3 },
  { to: "/schedule", label: "Schedule", icon: CalendarClock },
  { to: "/alerts", label: "Alerts", icon: Bell, badge: true },
];
