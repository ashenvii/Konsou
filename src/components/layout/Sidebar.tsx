import { useRef, useState } from "react";
import type { FocusEvent, MouseEvent } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { UserRound } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { useAuthStore } from "@/lib/store/authStore";
import { useNavStacks } from "@/lib/navStacks";
import { useTabPress } from "@/hooks/useTabPress";
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
  const navigate = useNavigate();
  const alertCount = useNotificationStore((s) => s.items.length);
  const sidebarMode = useSettingsStore((s) => s.sidebarMode);
  const currentTab = useNavStacks((s) => s.currentTab);
  const account = useAuthStore((s) => s.account);
  const onTabPress = useTabPress();

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
  const onMove = (e: MouseEvent<HTMLElement>) => {
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
        onBlurCapture: (e: FocusEvent<HTMLElement>) => {
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
          <img src="/konsou.svg" alt="" width={32} height={32} />
        </span>
        <span className="k-sidebar__wordmark">Konsou</span>
      </div>

      <nav className="k-sidebar__nav" aria-label="Primary">
        {NAV_ITEMS.map((item) => {
          // The owning tab stays lit while its detail/settings pages are up.
          const active = currentTab === item.to;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              title={item.label}
              className={`k-sidebar__item${active ? " k-sidebar__item--active" : ""}`}
              onClick={(e) => {
                // Per-tab stack policy (lib/navStacks), not browser history.
                e.preventDefault();
                onTabPress(item.to);
              }}
            >
              <span className="k-sidebar__icon">
                <Icon
                  icon={item.icon}
                  size={22}
                  weight={active ? "fill" : "regular"}
                />
                {item.badge && alertCount > 0 && (
                  <span className="k-nav__badge">
                    {alertCount > 9 ? "9+" : alertCount}
                  </span>
                )}
              </span>
              <span className="k-sidebar__label">{item.label}</span>
            </NavLink>
          );
        })}
      </nav>

      <div className="k-sidebar__footer">
        <button
          type="button"
          className="k-sidebar__account"
          onClick={() => navigate("/settings", { replace: true })}
          aria-label="Settings and account"
        >
          <span className="k-sidebar__avatar">
            {account?.avatarUrl ? (
              <img src={account.avatarUrl} alt="" />
            ) : account ? (
              <span>{account.name.charAt(0).toUpperCase()}</span>
            ) : (
              <Icon icon={UserRound} size={15} />
            )}
          </span>
          <span className="k-sidebar__accountinfo">
            <span className="k-sidebar__accountname">{account?.name ?? "Settings"}</span>
            <span className="k-sidebar__accountmeta">
              {account ? "Account & settings" : "Local only"}
            </span>
          </span>
        </button>
        <span className="k-sidebar__version">v{APP_VERSION}</span>
      </div>
    </aside>
  );
}
