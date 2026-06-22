import { useState } from "react";
import { Bell, CloudArrowUp, List } from "@phosphor-icons/react";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { useAuthStore } from "@/lib/store/authStore";

const ONBOARDED_KEY = "konsou.onboarded";

const FEATURES = [
  {
    icon: List,
    title: "Your list, offline-first",
    desc: "Add, track, and score anime instantly. No account required.",
  },
  {
    icon: Bell,
    title: "Sequel radar",
    desc: "Get notified when a completed anime gets a new season or movie.",
  },
  {
    icon: CloudArrowUp,
    title: "Sync via Google Drive",
    desc: "Connect once and your list stays in sync across every device.",
  },
] as const;

export function Onboarding() {
  const [visible, setVisible] = useState(
    () => !localStorage.getItem(ONBOARDED_KEY),
  );
  const connect = useAuthStore((s) => s.connect);
  const connecting = useAuthStore((s) => s.connecting);

  if (!visible) return null;

  const dismiss = () => {
    localStorage.setItem(ONBOARDED_KEY, "1");
    setVisible(false);
  };

  const connectAndDismiss = async () => {
    await connect();
    dismiss();
  };

  return (
    <div className="k-onboarding" role="dialog" aria-modal aria-label="Welcome to Konsou">
      <div className="k-onboarding__card">
        <div className="k-onboarding__logo">
          <span className="k-onboarding__logomark">K</span>
        </div>
        <Text size="2xl" weight={700} className="k-onboarding__title">
          Welcome to Konsou
        </Text>
        <Text size="sm" color="secondary" className="k-onboarding__sub">
          The offline-first anime tracker with a sequel radar.
        </Text>

        <ul className="k-onboarding__features">
          {FEATURES.map((f) => (
            <li key={f.title} className="k-onboarding__feature">
              <span className="k-onboarding__featureicon">
                <Icon icon={f.icon} size={20} />
              </span>
              <div>
                <Text size="sm" weight={600}>
                  {f.title}
                </Text>
                <Text size="xs" color="secondary">
                  {f.desc}
                </Text>
              </div>
            </li>
          ))}
        </ul>

        <div className="k-onboarding__actions">
          <Button
            variant="primary"
            onClick={() => void connectAndDismiss()}
            disabled={connecting}
          >
            {connecting ? "Connecting…" : "Connect Google & get started"}
          </Button>
          <Button variant="ghost" onClick={dismiss}>
            Skip for now
          </Button>
        </div>
      </div>
    </div>
  );
}
