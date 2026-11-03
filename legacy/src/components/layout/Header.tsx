import { useLocation, useNavigate } from "react-router-dom";
import { Icon } from "@/components/ui/Icon";
import { SparkIcon } from "@/components/ui/SparkIcon";
import { UpdateMark } from "./UpdateMark";
import { UTILITY_ITEMS } from "./navConfig";

/**
 * Mobile-only brand strip: the wordmark, and the app's own pages beside it.
 *
 * The account button used to live here and now sits in the tab ledger with the
 * rest of primary navigation. What replaced it is the set the desktop rail
 * already carries in its second group — What's new, Support, About — which
 * existed on desktop and simply had no home on a phone, where they were buried
 * two taps deep behind Settings. Same three destinations, same order, both
 * platforms; only the shell differs (rows on the rail, marks on the strip).
 *
 * Pure chrome, so it stays put rather than folding away on scroll.
 */
export function Header() {
  const navigate = useNavigate();
  const { pathname } = useLocation();

  return (
    <header className="k-header">
      <span className="k-header__word">Konsou</span>

      <nav className="k-header__utility" aria-label="App">
        {UTILITY_ITEMS.map((item) => {
          const active = pathname === item.to;
          return (
            <button
              key={item.to}
              type="button"
              className={`k-header__util${active ? " k-header__util--active" : ""}`}
              aria-label={item.label}
              aria-current={active ? "page" : undefined}
              onClick={() => navigate(item.to, { replace: true })}
            >
              {item.spark ? (
                <SparkIcon icon={item.icon} size={17} />
              ) : (
                <Icon icon={item.icon} size={17} weight={active ? "fill" : "regular"} />
              )}
              {item.update && <UpdateMark side="strip" />}
            </button>
          );
        })}
      </nav>
    </header>
  );
}
