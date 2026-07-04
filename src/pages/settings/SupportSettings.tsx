import { ArrowUpRight, Code2, Coffee, Heart, Share2, Star } from "lucide-react";
import type { ReactNode } from "react";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import type { IconComponent } from "@/components/ui/Icon";
import { SettingsSubPage } from "@/components/settings/parts";
import { Text } from "@/components/ui/Text";
import { openExternal } from "@/lib/openExternal";
import { toast } from "@/lib/store/toastStore";

const KOFI_URL = (import.meta.env.VITE_KOFI_URL as string | undefined) ?? "https://ko-fi.com";
const GITHUB_URL = (import.meta.env.VITE_GITHUB_URL as string | undefined) ?? "https://github.com";

/** One way to help: a whole-row tap target with its own color identity. */
function SupportAction({
  icon,
  tone,
  title,
  hint,
  onClick,
}: {
  icon: IconComponent;
  tone: "kofi" | "code" | "star" | "share";
  title: string;
  hint: string;
  onClick: () => void;
}) {
  return (
    <button type="button" className="k-supportaction" onClick={onClick}>
      <span className={`k-supportaction__icon k-supportaction__icon--${tone}`}>
        <Icon icon={icon} size={19} />
      </span>
      <span className="k-supportaction__text">
        <Text size="base" weight={600}>
          {title}
        </Text>
        <Text size="xs" color="tertiary">
          {hint}
        </Text>
      </span>
      <span className="k-supportaction__arrow">
        <Icon icon={ArrowUpRight} size={16} />
      </span>
    </button>
  );
}

function SupportHeading({ children }: { children: ReactNode }) {
  return (
    <Text
      size="xs"
      weight={600}
      color="tertiary"
      className="k-settings__sectiontitle"
    >
      {children}
    </Text>
  );
}

export function SupportSettings() {
  const share = async () => {
    const text = "Konsou, a free offline-first anime tracker with a sequel radar.";
    if (navigator.share) {
      try {
        await navigator.share({ title: "Konsou", text, url: GITHUB_URL });
      } catch {
        /* user dismissed the share sheet */
      }
      return;
    }
    try {
      await navigator.clipboard.writeText(GITHUB_URL);
      toast.success("Link copied to clipboard");
    } catch {
      void openExternal(GITHUB_URL);
    }
  };

  return (
    <SettingsSubPage title="Support Konsou">
      <div className="k-support__hero">
        <span className="k-support__heroicon">
          <Icon icon={Heart} size={26} />
        </span>
        <Text as="h2" size="lg" weight={700} className="k-support__herotitle">
          Free, and staying that way
        </Text>
        <Text size="sm" color="secondary" className="k-support__herotext">
          Konsou has no ads and no premium tier. It's built and given away for
          free. If it earns a place on your home screen, chipping in keeps it
          running and pays for what comes next.
        </Text>
        <Button variant="primary" onClick={() => void openExternal(KOFI_URL)}>
          <Icon icon={Coffee} size={16} /> Buy me a coffee
        </Button>
        <span className="k-support__heronote">
          No ads, no premium tier, no unlock codes.
        </span>
      </div>

      <section className="k-settings__section">
        <SupportHeading>MORE WAYS TO HELP</SupportHeading>
        <div className="k-support__actions">
          <SupportAction
            icon={Heart}
            tone="kofi"
            title="Tip on Ko-fi"
            hint="One-off or monthly, any amount helps"
            onClick={() => void openExternal(KOFI_URL)}
          />
          <SupportAction
            icon={Code2}
            tone="code"
            title="Contribute on GitHub"
            hint="Report bugs, suggest features, send a pull request"
            onClick={() => void openExternal(GITHUB_URL)}
          />
          <SupportAction
            icon={Star}
            tone="star"
            title="Star the repo"
            hint="A quick way to help others find Konsou"
            onClick={() => void openExternal(GITHUB_URL)}
          />
          <SupportAction
            icon={Share2}
            tone="share"
            title="Share Konsou"
            hint="Tell a friend who's still juggling spreadsheets"
            onClick={() => void share()}
          />
        </div>
      </section>
    </SettingsSubPage>
  );
}
