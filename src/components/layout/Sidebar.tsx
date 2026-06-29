import { useRef, useState } from "react";
import { NavLink } from "react-router-dom";
import { Icon } from "@/components/ui/Icon";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useAuthStore } from "@/lib/store/authStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { NAV_ITEMS } from "./navConfig";
import { APP_VERSION } from "@/lib/updater";

/**
 * In "hover" mode the rail expands to the full width, but we collapse it early
 * once the pointer drifts past the labels into the empty zone on the right — so
 * the user never has to travel to the 220px edge to dismiss it. CLOSE_X is
 * measured from the sidebar's LEFT edge, which stays put while the width
 * animates; reading the right edge mid-animation is what caused the old flicker.
 */
const EXPANDED_WIDTH = 220;
const CLOSE_X = EXPANDED_WIDTH - 48; // 172px — past the labels, before the edge
const CLOSE_DELAY = 160;

export function Sidebar() {
  const alertCount = useNotificationStore((s) => s.items.length);
  const account = useAuthStore((s) => s.account);
  const sidebarMode = useSettingsStore((s) => s.sidebarMode);

  const [hovered, setHovered] = useState(false);
  const closeTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);

  const isHoverMode = sidebarMode === "hover";
  const expanded = sidebarMode === "expanded" || (isHoverMode && hovered);

  const cancelClose = () => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = undefined;
    }
  };
  const scheduleClose = () => {
    if (closeTimer.current) return;
    closeTimer.current = setTimeout(() => {
      closeTimer.current = undefined;
      setHovered(false);
    }, CLOSE_DELAY);
  };
  const open = () => {
    cancelClose();
    setHovered(true);
  };
  const closeNow = () => {
    cancelClose();
    setHovered(false);
  };

  // Collapse early when the pointer enters the empty strip right of the labels.
  const onMove = (e: React.MouseEvent<HTMLElement>) => {
    if (!isHoverMode || !hovered) return;
    const x = e.clientX - e.currentTarget.getBoundingClientRect().left;
    if (x > CLOSE_X) scheduleClose();
    else cancelClose();
  };

  // Only the hover mode reacts to the pointer/focus; rail and expanded are static.
  const hoverProps = isHoverMode
    ? {
        onMouseEnter: open,
        onMouseLeave: closeNow,
        onMouseMove: onMove,
        onFocusCapture: open,
        onBlurCapture: (e: React.FocusEvent<HTMLElement>) => {
          if (!e.currentTarget.contains(e.relatedTarget as Node | null)) closeNow();
        },
      }
    : {};

  return (
    <aside
      className="k-sidebar"
      data-mode={sidebarMode}
      data-expanded={expanded || undefined}
      {...hoverProps}
    >
      <div className="k-sidebar__brand">
        <span className="k-sidebar__logomark">
          <img src="/konsou.svg" alt="Konsou" width={32} height={32} />
        </span>
        <span className="k-sidebar__wordmark">Konsou</span>
      </div>

      <nav className="k-sidebar__nav" aria-label="Primary">
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            title={item.label}
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
                  {item.badge && alertCount > 0 && (
                    <span className="k-nav__badge">
                      {alertCount > 9 ? "9+" : alertCount}
                    </span>
                  )}
                </span>
                <span className="k-sidebar__label">{item.label}</span>
              </>
            )}
          </NavLink>
        ))}
      </nav>

      <div className="k-sidebar__footer">
        <NavLink
          to="/settings"
          title="Settings, account & stats"
          className={({ isActive }) =>
            `k-sidebar__account${isActive ? " k-sidebar__account--active" : ""}`
          }
        >
          <div className="k-sidebar__avatar" aria-hidden>
            {account?.avatarUrl ? (
              <img src={account.avatarUrl} alt="" />
            ) : (
              <span>{account ? account.name.charAt(0) : "?"}</span>
            )}
          </div>
          <div className="k-sidebar__accountinfo">
            <span className="k-sidebar__accountname">
              {account?.name ?? "Settings"}
            </span>
            <span className="k-sidebar__accountmeta">
              {account?.email ?? "Account & stats"}
            </span>
          </div>
        </NavLink>
        <span className="k-sidebar__version">v{APP_VERSION}</span>
      </div>
    </aside>
  );
}
