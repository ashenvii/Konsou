import type { CSSProperties } from "react";
import { NavLink, useLocation, useNavigate } from "react-router-dom";
import { UserRound } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { useAuthStore } from "@/lib/store/authStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useNavStacks } from "@/lib/navStacks";
import { useTabPress } from "@/hooks/useTabPress";
import { NAV_ITEMS } from "./navConfig";

/**
 * The mobile tab ledger — DESIGN.md's own spec for this surface, which the
 * previous implementation never actually built: a flat mount surface with a
 * top keyline, not a floating boxed pill with a border and a glow-shadow.
 * The active tab is marked by one moving vermilion underscore that slides
 * to whichever tab is current, not a static bar redrawn per item — the
 * "interacting" quality without the glow/blob the Field Guide rules out.
 */
export function BottomNav() {
  const navigate = useNavigate();
  const alertCount = useNotificationStore((s) => s.items.length);
  const location = useLocation();
  const currentTab = useNavStacks((s) => s.currentTab);
  const account = useAuthStore((s) => s.account);
  const onTabPress = useTabPress();
  const onSettings = location.pathname.startsWith("/settings");

  // One shared definition of "active" for the label, the ink, and the
  // underscore's position — previously the ink/underscore keyed off an exact
  // pathname match while the label keyed off the owning tab, so a detail page
  // reached from My List showed the "My List" label without lighting it up.
  const activeIndex = onSettings
    ? NAV_ITEMS.length
    : Math.max(
        0,
        NAV_ITEMS.findIndex((item) => item.to === currentTab),
      );
  const railStyle = {
    "--active-index": activeIndex,
    "--nav-count": NAV_ITEMS.length + 1,
  } as CSSProperties;

  return (
    <nav className="k-bottomnav" aria-label="Primary">
      <div className="k-bottomnav__rail" style={railStyle}>
        <span className="k-bottomnav__underscore" aria-hidden />
        {NAV_ITEMS.map((item, i) => {
          // The owning tab stays lit even while a detail or settings page
          // from its stack is on screen.
          const active = activeIndex === i;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              className="k-bottomnav__item"
              // The visible label only exists on the active tab, so the name
              // must come from here or the other tabs are anonymous "link"s.
              aria-label={item.label}
              aria-current={active ? "page" : undefined}
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
        {/* Account, same peer footing as the desktop Sidebar gives it — a real
            tab, not a badge tucked in the corner of a page header. */}
        <button
          type="button"
          className="k-bottomnav__item"
          aria-label="Settings and account"
          aria-current={onSettings ? "page" : undefined}
          onClick={() => navigate("/settings", { replace: true })}
        >
          <span className="k-bottomnav__icon k-bottomnav__avatar">
            {account?.avatarUrl ? (
              <img src={account.avatarUrl} alt="" />
            ) : account ? (
              <span>{account.name.charAt(0).toUpperCase()}</span>
            ) : (
              // A person glyph, not "?": the question mark reads as a help button.
              <Icon icon={UserRound} size={18} weight={onSettings ? "fill" : "regular"} />
            )}
          </span>
          {onSettings && <span className="k-bottomnav__label">Account</span>}
        </button>
      </div>
    </nav>
  );
}
