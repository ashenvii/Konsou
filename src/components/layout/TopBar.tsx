import { useNavigate } from "react-router-dom";
import { UserRound } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { useAuthStore } from "@/lib/store/authStore";

/**
 * Mobile-only top bar: brand on the left, account avatar on the right. The
 * avatar is the single entry point to Settings, Account, and Stats. Search
 * lives on the Discover page itself.
 */
export function TopBar() {
  const navigate = useNavigate();
  const account = useAuthStore((s) => s.account);

  return (
    <header className="k-topbar">
      <div className="k-topbar__brand">
        <img src="/konsou.svg" alt="" width={26} height={26} />
        <span className="k-topbar__word">Konsou</span>
      </div>
      <button
        type="button"
        className="k-topbar__avatar"
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
