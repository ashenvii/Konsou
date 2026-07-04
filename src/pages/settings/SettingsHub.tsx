import { useNavigate } from "react-router-dom";
import { Bell, CircleUserRound, Database, Heart, Info, Palette } from "lucide-react";
import { PageHeader } from "@/components/layout/PageHeader";
import { HubRow } from "@/components/settings/parts";
import { useAuthStore } from "@/lib/store/authStore";

export function SettingsHub() {
  const navigate = useNavigate();
  const account = useAuthStore((s) => s.account);

  return (
    <div className="k-page">
      <PageHeader title="Settings" onBack={() => navigate(-1)} />
      <div className="k-settings konsou-scroll">
        <div className="k-hub">
          <HubRow
            icon={CircleUserRound}
            label={account ? account.name : "Account"}
            hint={account ? account.email : "Sign in to sync across devices"}
            onClick={() => navigate("account")}
          />
          <HubRow
            icon={Heart}
            label="Support Konsou"
            hint="Free, no ads. Your support keeps it that way."
            accent
            onClick={() => navigate("support")}
          />
          <HubRow
            icon={Palette}
            label="Appearance"
            hint="Theme, accent, titles, layout"
            onClick={() => navigate("appearance")}
          />
          <HubRow
            icon={Database}
            label="Library & Sync"
            hint="Backup, import, export"
            onClick={() => navigate("library")}
          />
          <HubRow
            icon={Bell}
            label="Notifications"
            hint="Sequel radar alerts"
            onClick={() => navigate("notifications")}
          />
          <HubRow
            icon={Info}
            label="About"
            hint="Version, updates, links"
            onClick={() => navigate("about")}
          />
        </div>
      </div>
    </div>
  );
}
