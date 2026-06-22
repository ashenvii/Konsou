import { NavLink, useLocation } from "react-router-dom";
import { Icon } from "@/components/ui/Icon";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { NAV_ITEMS } from "./navConfig";

export function BottomNav() {
  const unread = useNotificationStore((s) => s.unread);
  const location = useLocation();

  return (
    <nav className="k-bottomnav" aria-label="Primary">
      {NAV_ITEMS.map((item) => {
        const active = location.pathname === item.to;
        return (
          <NavLink
            key={item.to}
            to={item.to}
            className="k-bottomnav__item"
            aria-current={active ? "page" : undefined}
            onClick={() => {
              if (active) window.dispatchEvent(new CustomEvent("konsou:scrolltop"));
            }}
          >
            <span className="k-bottomnav__iconwrap">
              {active && <span className="k-bottomnav__pill" />}
              <span className="k-bottomnav__icon">
                <Icon
                  icon={item.icon}
                  size={24}
                  weight={active ? "fill" : "regular"}
                />
                {item.badge && unread > 0 && (
                  <span className="k-nav__badge">{unread > 9 ? "9+" : unread}</span>
                )}
              </span>
            </span>
            <span className="k-bottomnav__label">{item.label}</span>
          </NavLink>
        );
      })}
    </nav>
  );
}
