import { Bell, Compass, Gear, List, MagnifyingGlass } from "@phosphor-icons/react";
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
  { to: "/search", label: "Search", icon: MagnifyingGlass },
  { to: "/discover", label: "Discover", icon: Compass },
  { to: "/alerts", label: "Alerts", icon: Bell, badge: true },
  { to: "/settings", label: "Settings", icon: Gear },
];
