import { NavLink } from "react-router-dom";
import { Icon } from "@/components/ui/Icon";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useAuthStore } from "@/lib/store/authStore";
import { NAV_ITEMS } from "./navConfig";

const APP_VERSION = "0.1.0";

export function Sidebar() {
  const unread = useNotificationStore((s) => s.unread);
  const account = useAuthStore((s) => s.account);

  return (
    <aside className="k-sidebar">
      <div className="k-sidebar__brand">
        <img src="/konsou.svg" alt="" width={32} height={32} />
        <span className="k-sidebar__wordmark">Konsou</span>
      </div>

      <nav className="k-sidebar__nav" aria-label="Primary">
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              `k-sidebar__item${isActive ? " k-sidebar__item--active" : ""}`
            }
          >
            {({ isActive }) => (
              <>
                <span className="k-sidebar__icon">
                  <Icon
                    icon={item.icon}
                    size={22}
                    weight={isActive ? "fill" : "regular"}
                  />
                  {item.badge && unread > 0 && (
                    <span className="k-nav__badge">
                      {unread > 9 ? "9+" : unread}
                    </span>
                  )}
                </span>
                <span>{item.label}</span>
              </>
            )}
          </NavLink>
        ))}
      </nav>

      <div className="k-sidebar__footer">
        <div className="k-sidebar__account">
          <div className="k-sidebar__avatar" aria-hidden>
            {account?.avatarUrl ? (
              <img src={account.avatarUrl} alt="" />
            ) : (
              <span>{account ? account.name.charAt(0) : "?"}</span>
            )}
          </div>
          <div className="k-sidebar__accountinfo">
            <span className="k-sidebar__accountname">
              {account?.name ?? "Offline"}
            </span>
            <span className="k-sidebar__accountmeta">
              {account?.email ?? "Not signed in"}
            </span>
          </div>
        </div>
        <span className="k-sidebar__version">v{APP_VERSION}</span>
      </div>
    </aside>
  );
}
