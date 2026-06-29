import { Bell, CalendarClock, Compass, List, Search } from "lucide-react";
import type { IconComponent } from "@/components/ui/Icon";

export interface NavItem {
  to: string;
  label: string;
  icon: IconComponent;
  /** Shows the unread badge (Alerts only). */
  badge?: boolean;
}

/** Primary destinations. Settings, Account, and Stats live behind the avatar
 *  (mobile top bar / desktop sidebar footer), freeing this slot for Schedule. */
export const NAV_ITEMS: NavItem[] = [
  { to: "/", label: "My List", icon: List },
  { to: "/search", label: "Search", icon: Search },
  { to: "/discover", label: "Discover", icon: Compass },
  { to: "/schedule", label: "Schedule", icon: CalendarClock },
  { to: "/alerts", label: "Alerts", icon: Bell, badge: true },
];
