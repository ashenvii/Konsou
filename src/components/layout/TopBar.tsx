import { useNavigate } from "react-router-dom";
import { useAuthStore } from "@/lib/store/authStore";

/**
 * Mobile-only top bar: brand on the left, account avatar on the right. The
 * avatar is the single entry point to Settings, Account, and Stats now that
 * Settings has left the bottom bar.
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
        onClick={() => navigate("/settings")}
        aria-label="Settings and account"
      >
        {account?.avatarUrl ? (
          <img src={account.avatarUrl} alt="" />
        ) : (
          <span>{account ? account.name.charAt(0).toUpperCase() : "?"}</span>
        )}
      </button>
    </header>
  );
}
