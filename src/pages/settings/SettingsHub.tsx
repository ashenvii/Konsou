import { useNavigate } from "react-router-dom";
import { Bell, CircleUserRound, Database, Heart, Info, Palette } from "lucide-react";
import { PageHeader } from "@/components/layout/PageHeader";
import { HubRow } from "@/components/settings/parts";
import { useAuthStore } from "@/lib/store/authStore";
import { goBack } from "@/hooks/useAppBack";

export function SettingsHub() {
  const navigate = useNavigate();
  const account = useAuthStore((s) => s.account);
  // All pushes replace: the per-tab stack (lib/navStacks) is the back history.
  const go = (to: string) => navigate(to, { replace: true });

  return (
    <div className="k-page">
      <PageHeader title="Settings" onBack={goBack} />
      <div className="k-settings konsou-scroll">
        <div className="k-hub">
          <HubRow
            icon={CircleUserRound}
            label={account ? account.name : "Account"}
            hint={account ? account.email : "Sign in to sync across devices"}
            tone="account"
            onClick={() => go("account")}
          />
          <HubRow
            icon={Heart}
            label="Support Konsou"
            hint="Free, no ads. Your support keeps it that way."
            accent
            onClick={() => go("support")}
          />
          <HubRow
            icon={Palette}
            label="Appearance"
            hint="Theme, accent, titles, layout"
            tone="appearance"
            onClick={() => go("appearance")}
          />
          <HubRow
            icon={Database}
            label="Library & Sync"
            hint="Backup, import, export"
            tone="library"
            onClick={() => go("library")}
          />
          <HubRow
            icon={Bell}
            label="Notifications"
            hint="Sequel radar alerts"
            tone="notifications"
            onClick={() => go("notifications")}
          />
          <HubRow
            icon={Info}
            label="About"
            hint="Version, updates, links"
            tone="about"
            onClick={() => go("about")}
          />
        </div>
      </div>
    </div>
  );
}
