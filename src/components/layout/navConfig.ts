import { Bell, Compass, List, Search, Settings } from "lucide-react";
import type { IconComponent } from "@/components/ui/Icon";

export interface NavItem {
  to: string;
  label: string;
  icon: IconComponent;
  /** Shows the unread badge (Alerts only). */
  badge?: boolean;
}

export const NAV_ITEMS: NavItem[] = [
  { to: "/", label: "My List", icon: List },
  { to: "/search", label: "Search", icon: Search },
  { to: "/discover", label: "Discover", icon: Compass },
  { to: "/alerts", label: "Alerts", icon: Bell, badge: true },
  { to: "/settings", label: "Settings", icon: Settings },
];
