import { NavLink, useLocation } from "react-router-dom";
import { Icon } from "@/components/ui/Icon";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useNavStacks } from "@/lib/navStacks";
import { useTabPress } from "@/hooks/useTabPress";
import { NAV_ITEMS } from "./navConfig";

export function BottomNav() {
  const alertCount = useNotificationStore((s) => s.items.length);
  const location = useLocation();
  const currentTab = useNavStacks((s) => s.currentTab);
  const onTabPress = useTabPress();

  return (
    <nav className="k-bottomnav" aria-label="Primary">
      <div className="k-bottomnav__rail">
        {NAV_ITEMS.map((item) => {
          // The owning tab stays lit even while a detail or settings page
          // from its stack is on screen.
          const active = currentTab === item.to;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              className="k-bottomnav__item"
              aria-current={location.pathname === item.to ? "page" : undefined}
              onClick={(e) => {
                // Tab presses go through the per-tab stack policy
                // (lib/navStacks), never through browser history.
                e.preventDefault();
                onTabPress(item.to);
              }}
            >
              <span className="k-bottomnav__icon">
                <Icon
                  icon={item.icon}
                  size={22}
                  weight={active ? "fill" : "regular"}
                />
                {item.badge && alertCount > 0 && (
                  <span className="k-nav__badge">{alertCount > 9 ? "9+" : alertCount}</span>
                )}
              </span>
              {active && (
                <span className="k-bottomnav__label">{item.label}</span>
              )}
            </NavLink>
          );
        })}
      </div>
    </nav>
  );
}
