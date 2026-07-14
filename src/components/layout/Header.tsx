import { useNavigate } from "react-router-dom";
import { UserRound } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { useAuthStore } from "@/lib/store/authStore";

/**
 * The app's single persistent header: identity on the left, account on the
 * right. Present on every primary page, desktop and mobile. Search deliberately
 * lives on the Discover surface, not here.
 *
 * On desktop it spans the content column to the right of the sidebar: the
 * sidebar owns navigation, this owns identity + account, so the logo and avatar
 * live in exactly one place across both platforms. It folds away on scroll-down
 * and returns on scroll-up (useScrollElevation), and stays pinned under reduced
 * motion.
 */
export function Header() {
  const navigate = useNavigate();
  const account = useAuthStore((s) => s.account);

  return (
    <header className="k-header">
      <div className="k-header__brand">
        <img className="k-header__logo" src="/konsou.svg" alt="" width={26} height={26} />
        <span className="k-header__word">Konsou</span>
      </div>
      <button
        type="button"
        className="k-header__avatar"
        onClick={() => navigate("/settings", { replace: true })}
        aria-label="Settings and account"
      >
        {account?.avatarUrl ? (
          <img src={account.avatarUrl} alt="" />
        ) : account ? (
          <span>{account.name.charAt(0).toUpperCase()}</span>
        ) : (
          // A person glyph, not "?": the question mark reads as a help button.
          <Icon icon={UserRound} size={16} />
        )}
      </button>
    </header>
  );
}
